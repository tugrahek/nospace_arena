"""Fail-closed upload-key preflight and optional signing of an approved unsigned AAB.

Credentials are accepted only through Godot's release-keystore environment names.
Child output is never forwarded: build/signing tools may print sensitive arguments.
"""
import argparse
import configparser
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "GODOT_ANDROID_KEYSTORE_RELEASE_"
CERT_PIN = "NOSPACE_UPLOAD_CERT_SHA256"
KNOWN_RESULTS = {"READY", "KEYSTORE_INVALID", "ALIAS_NOT_PRIVATE", "CERT_INVALID",
                 "DEBUG_CERTIFICATE", "CERT_MISMATCH", "KEY_UNUSABLE", "MISSING_ENV"}


class SigningError(Exception):
    """Carries a fixed, non-sensitive diagnostic code only."""


class SafeArgumentParser(argparse.ArgumentParser):
    """Do not echo accidentally supplied credential arguments in parser errors."""

    def error(self, message):
        self.exit(2, "SIGNING_BLOCKED: INVALID_ARGUMENTS\n")


def fail(code):
    raise SigningError(code)


def child_environment(environment):
    """Avoid Java launcher option injection/echo and supply a private child copy."""
    result = dict(environment)
    for key in ("JAVA_TOOL_OPTIONS", "JDK_JAVA_OPTIONS", "_JAVA_OPTIONS"):
        result.pop(key, None)
    return result


def check_environment(environment, root=ROOT):
    """Check required values and canonical outside-repository key location."""
    for suffix in ("PATH", "USER", "PASSWORD"):
        if not environment.get(PREFIX + suffix, "").strip():
            fail("MISSING_RELEASE_" + suffix)
    alias = environment[PREFIX + "USER"]
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,127}", alias):
        fail("INVALID_ALIAS")
    if re.search(r"debug|test|example|placeholder", alias, re.I):
        fail("DEBUG_OR_TEST_ALIAS")
    if environment[PREFIX + "PASSWORD"].lower() in ("android", "changeit", "password"):
        fail("TEST_PASSWORD")
    pin = environment.get(CERT_PIN, "").replace(":", "").lower()
    if not re.fullmatch(r"[0-9a-f]{64}", pin) or len(set(pin)) == 1:
        fail("MISSING_OR_INVALID_CERT_PIN")
    raw_path = Path(environment[PREFIX + "PATH"])
    if not raw_path.is_absolute():
        fail("KEYSTORE_PATH_NOT_ABSOLUTE")
    path = raw_path.resolve()
    if path.is_relative_to(root.resolve()):
        fail("KEYSTORE_INSIDE_REPOSITORY")
    if re.search(r"debug|test|example|placeholder", path.name, re.I) or any(
            part.lower() == ".android" for part in path.parts):
        fail("DEBUG_OR_TEST_KEYSTORE")
    if not path.is_file():
        fail("KEYSTORE_NOT_FOUND")
    return path, alias, pin


def check_presets(path=ROOT / "export_presets.cfg"):
    """Never convert either original profile into a credential-bearing profile."""
    config = configparser.ConfigParser(interpolation=None, strict=True)
    config.read(path, encoding="utf-8")
    for section in ("preset.0.options", "preset.1.options"):
        if section not in config:
            fail("PRESET_MISSING")
        for key, value in config[section].items():
            if key.startswith("keystore/") and value.strip('"'):
                fail("PRESET_CONTAINS_KEYSTORE_CONFIG")
    release = config["preset.1.options"]
    if (config["preset.1"]["name"] != '"Android Release AAB"'
            or release["package/signed"] != "false"
            or release["gradle_build/export_format"] != "1"
            or release["package/unique_name"] != '"com.tugrahek.nospace"'):
        fail("UNSAFE_RELEASE_PRESET")
    if config["preset.0.options"]["gradle_build/export_format"] != "0":
        fail("UNSAFE_DEVELOPMENT_PRESET")


def run_tool(arguments, environment):
    """Capture and discard tool diagnostics, including timeout/launch exceptions."""
    try:
        return subprocess.run(arguments, env=environment, stdin=subprocess.DEVNULL,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              timeout=120, check=False)
    except (OSError, subprocess.TimeoutExpired):
        fail("TOOL_UNAVAILABLE_OR_TIMEOUT")


def preflight(java_home, environment=None):
    """Read/unlock the existing key in memory; never export or modify a keystore."""
    environment = os.environ if environment is None else environment
    key_path, alias, pin = check_environment(environment)
    check_presets()
    jdk = Path(java_home).resolve()
    java = jdk / "bin" / ("java.exe" if os.name == "nt" else "java")
    jarsigner = jdk / "bin" / ("jarsigner.exe" if os.name == "nt" else "jarsigner")
    if not java.is_file() or not jarsigner.is_file():
        fail("JDK_TOOLS_MISSING")
    child = child_environment(environment)
    child[PREFIX + "PATH"] = str(key_path)
    child[CERT_PIN] = pin
    result = run_tool([str(java), str(ROOT / "tools/UploadKeyPreflight.java")], child)
    token = result.stdout.decode("ascii", errors="replace").strip()
    if result.returncode != 0 or token != "READY":
        fail(token if token in KNOWN_RESULTS and token != "READY" else "KEY_PREFLIGHT_FAILED")
    return jarsigner, child, key_path, alias


def check_bundle(source, expected_sha256, output, root=ROOT):
    """Require an explicitly approved unsigned artifact and a fresh ignored output."""
    source, output = Path(source).resolve(), Path(output).resolve()
    if (source.suffix.lower() != ".aab" or output.suffix.lower() != ".aab"
            or not source.is_file()):
        fail("INVALID_AAB_PATH")
    if output == source or output.exists():
        fail("OUTPUT_MUST_BE_NEW")
    if not output.is_relative_to((root / "export").resolve()):
        fail("OUTPUT_MUST_BE_UNDER_EXPORT")
    if not re.fullmatch(r"[0-9a-fA-F]{64}", expected_sha256):
        fail("INVALID_ARTIFACT_HASH")
    if hashlib.sha256(source.read_bytes()).hexdigest() != expected_sha256.lower():
        fail("ARTIFACT_HASH_MISMATCH")
    with zipfile.ZipFile(source) as archive:
        names = archive.namelist()
        if "base/manifest/AndroidManifest.xml" not in names:
            fail("NOT_ANDROID_BUNDLE")
        if any(n.upper().startswith("META-INF/") and n.upper().endswith(
                (".SF", ".RSA", ".DSA", ".EC")) for n in names):
            fail("BUNDLE_ALREADY_SIGNED")
    return source, output


def sign_bundle(source, expected_sha256, output, signing):
    """Sign a separate artifact, preserving the unsigned input and verifying all entries."""
    source, output = check_bundle(source, expected_sha256, output)
    jarsigner, environment, key_path, alias = signing
    output.parent.mkdir(parents=True, exist_ok=True)
    result = run_tool([str(jarsigner), "-keystore", str(key_path),
        "-storepass:env", PREFIX + "PASSWORD", "-keypass:env", PREFIX + "PASSWORD",
        "-digestalg", "SHA-256", "-sigalg", "SHA256withRSA", "-signedjar", str(output),
        str(source), alias], environment)
    if result.returncode != 0:
        fail("SIGNING_FAILED_DO_NOT_USE_OUTPUT")
    java = jarsigner.with_name("java.exe" if os.name == "nt" else "java")
    result = run_tool([str(java), str(ROOT / "tools/UploadKeyPreflight.java"),
                       "verify", str(output)], environment)
    if result.returncode != 0 or result.stdout.strip() != b"VERIFIED":
        fail("SIGNATURE_VERIFICATION_FAILED_DO_NOT_USE_OUTPUT")


def main():
    parser = SafeArgumentParser(description=__doc__)
    parser.add_argument("--java-home", required=True)
    parser.add_argument("--sign-aab", type=Path)
    parser.add_argument("--sha256")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        if args.sign_aab and (not args.sha256 or not args.output):
            fail("SIGNING_REQUIRES_APPROVED_HASH_AND_NEW_OUTPUT")
        if not args.sign_aab and (args.sha256 or args.output):
            fail("SIGNING_INPUT_MISSING")
        signing = preflight(args.java_home)
        if args.sign_aab:
            sign_bundle(args.sign_aab, args.sha256, args.output, signing)
            print("UPLOAD_AAB_SIGNED_AND_VERIFIED; publication/device acceptance still required")
        else:
            print("UPLOAD_KEY_READY; no artifact signed")
        return 0
    except SigningError as error:
        print("SIGNING_BLOCKED: " + str(error), file=sys.stderr)
    except Exception:
        # Never expose tool output, paths, alias, credentials or provider errors.
        print("SIGNING_BLOCKED: CHECK_FAILED", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
