"""Focused tooling tests. No keystore is created, inspected, replaced or deleted."""
import contextlib
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import secrets
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("upload_signing", Path(__file__).with_name("android_upload_signing.py"))
signing = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(signing)


class UploadSigningTests(unittest.TestCase):
    def setUp(self):
        self.environment = {
            signing.PREFIX + "PATH": str(Path.home() / "NoSpaceUpload/upload.jks"),
            signing.PREFIX + "USER": "upload",
            signing.PREFIX + "PASSWORD": secrets.token_urlsafe(24),
            signing.CERT_PIN: "ab" * 32,
        }

    def blocked(self, code, function, *args):
        with self.assertRaises(signing.SigningError) as caught:
            function(*args)
        self.assertEqual(str(caught.exception), code)

    def test_each_missing_credential_is_blocked_without_echo(self):
        for suffix in ("PATH", "USER", "PASSWORD"):
            environment = self.environment.copy()
            environment.pop(signing.PREFIX + suffix)
            self.blocked("MISSING_RELEASE_" + suffix, signing.check_environment, environment)

    def test_empty_credential_is_blocked(self):
        self.environment[signing.PREFIX + "PASSWORD"] = "  "
        self.blocked("MISSING_RELEASE_PASSWORD", signing.check_environment, self.environment)

    def test_missing_pin_is_blocked(self):
        self.environment.pop(signing.CERT_PIN)
        self.blocked("MISSING_OR_INVALID_CERT_PIN", signing.check_environment, self.environment)

    def test_placeholder_and_invalid_pins_are_blocked(self):
        for pin in ("00" * 32, "x" * 64, "abcd"):
            self.environment[signing.CERT_PIN] = pin
            self.blocked("MISSING_OR_INVALID_CERT_PIN", signing.check_environment, self.environment)

    def test_debug_and_test_aliases_are_blocked(self):
        for alias in ("androiddebugkey", "upload-test", "example", "placeholder"):
            self.environment[signing.PREFIX + "USER"] = alias
            self.blocked("DEBUG_OR_TEST_ALIAS", signing.check_environment, self.environment)

    def test_alias_with_tool_options_is_blocked(self):
        self.environment[signing.PREFIX + "USER"] = "-storepass anything"
        self.blocked("INVALID_ALIAS", signing.check_environment, self.environment)

    def test_test_password_is_blocked(self):
        self.environment[signing.PREFIX + "PASSWORD"] = "changeit"
        self.blocked("TEST_PASSWORD", signing.check_environment, self.environment)

    def test_relative_and_in_repo_key_paths_are_blocked(self):
        self.environment[signing.PREFIX + "PATH"] = "upload.jks"
        self.blocked("KEYSTORE_PATH_NOT_ABSOLUTE", signing.check_environment, self.environment)
        self.environment[signing.PREFIX + "PATH"] = str(signing.ROOT / "export/upload.jks")
        self.blocked("KEYSTORE_INSIDE_REPOSITORY", signing.check_environment, self.environment)

    def test_debug_file_and_missing_key_are_blocked(self):
        self.environment[signing.PREFIX + "PATH"] = str(Path.home() / "debug.keystore")
        self.blocked("DEBUG_OR_TEST_KEYSTORE", signing.check_environment, self.environment)
        self.environment[signing.PREFIX + "PATH"] = str(Path.home() / "NoSpaceUpload/upload.jks")
        with patch.object(Path, "is_file", return_value=False):
            self.blocked("KEYSTORE_NOT_FOUND", signing.check_environment, self.environment)

    def test_real_presets_remain_unsigned_and_credential_free(self):
        signing.check_presets()

    def test_java_failures_are_sanitized_and_unknown_output_is_not_echoed(self):
        key = Path(self.environment[signing.PREFIX + "PATH"])
        for token in ("ALIAS_NOT_PRIVATE", "CERT_MISMATCH", "DEBUG_CERTIFICATE", "KEY_UNUSABLE"):
            result = subprocess.CompletedProcess([], 2, token.encode(), self.environment[signing.PREFIX + "PASSWORD"].encode())
            with patch.object(signing, "check_environment", return_value=(key, "upload", "ab" * 32)), \
                    patch.object(Path, "is_file", return_value=True), patch.object(signing, "run_tool", return_value=result):
                self.blocked(token, signing.preflight, ".", self.environment)
        result = subprocess.CompletedProcess([], 2, self.environment[signing.PREFIX + "PASSWORD"].encode(), b"")
        with patch.object(signing, "check_environment", return_value=(key, "upload", "ab" * 32)), \
                patch.object(Path, "is_file", return_value=True), patch.object(signing, "run_tool", return_value=result):
            self.blocked("KEY_PREFLIGHT_FAILED", signing.preflight, ".", self.environment)

    def test_timeout_does_not_echo_command_or_secret(self):
        with patch.object(subprocess, "run", side_effect=subprocess.TimeoutExpired(self.environment, 120)):
            self.blocked("TOOL_UNAVAILABLE_OR_TIMEOUT", signing.run_tool, [], self.environment)

    def test_java_option_injection_is_removed(self):
        self.environment["JAVA_TOOL_OPTIONS"] = "unused"
        self.environment["JDK_JAVA_OPTIONS"] = "unused"
        self.environment["_JAVA_OPTIONS"] = "unused"
        self.assertTrue(all(k not in signing.child_environment(self.environment)
                            for k in ("JAVA_TOOL_OPTIONS", "JDK_JAVA_OPTIONS", "_JAVA_OPTIONS")))

    def test_cli_missing_credentials_never_echoes_secret(self):
        self.environment.pop(signing.PREFIX + "USER")
        with patch.dict(os.environ, self.environment, clear=True), patch.object(sys, "argv", ["tool", "--java-home", "."]):
            output = io.StringIO()
            with contextlib.redirect_stderr(output):
                self.assertEqual(signing.main(), 2)
            self.assertEqual(output.getvalue(), "SIGNING_BLOCKED: MISSING_RELEASE_USER\n")
            self.assertNotIn(self.environment[signing.PREFIX + "PASSWORD"], output.getvalue())

    def test_unknown_cli_argument_cannot_echo_accidental_password(self):
        with patch.object(sys, "argv", ["tool", "--java-home", ".", "--password",
                                       self.environment[signing.PREFIX + "PASSWORD"]]):
            output = io.StringIO()
            with contextlib.redirect_stderr(output), self.assertRaises(SystemExit):
                signing.main()
            self.assertEqual(output.getvalue(), "SIGNING_BLOCKED: INVALID_ARGUMENTS\n")

    def test_credential_bearing_or_signed_presets_are_blocked(self):
        original = (signing.ROOT / "export_presets.cfg").read_text()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "presets.cfg"
            path.write_text(original.replace('[preset.1.options]', '[preset.1.options]\nkeystore/release="unused"'))
            self.blocked("PRESET_CONTAINS_KEYSTORE_CONFIG", signing.check_presets, path)
            path.write_text(original.replace('package/signed=false', 'package/signed=true'))
            self.blocked("UNSAFE_RELEASE_PRESET", signing.check_presets, path)

    def test_artifact_hash_existing_output_and_signature_rejection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, output = root / "source.aab", root / "export/upload.aab"
            with zipfile.ZipFile(source, "w") as archive:
                archive.writestr("base/manifest/AndroidManifest.xml", b"synthetic non-game fixture")
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            self.blocked("ARTIFACT_HASH_MISMATCH", signing.check_bundle, source, "00" * 32, output, root)
            self.blocked("OUTPUT_MUST_BE_NEW", signing.check_bundle, source, digest, source, root)
            self.blocked("OUTPUT_MUST_BE_UNDER_EXPORT", signing.check_bundle, source, digest, root / "other.aab", root)
            with zipfile.ZipFile(source, "a") as archive:
                archive.writestr("META-INF/ALREADY.SF", b"not a real signature")
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            self.blocked("BUNDLE_ALREADY_SIGNED", signing.check_bundle, source, digest, output, root)

    def test_signer_password_is_environment_only_and_failure_is_not_forwarded(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "result.aab"
            prepared = (Path("jarsigner"), self.environment, Path("unused-key-path"), "upload")
            result = subprocess.CompletedProcess([], 1, self.environment[signing.PREFIX + "PASSWORD"].encode(), b"")
            with patch.object(signing, "check_bundle", return_value=(Path("source.aab"), output)), \
                    patch.object(signing, "run_tool", return_value=result) as tool:
                self.blocked("SIGNING_FAILED_DO_NOT_USE_OUTPUT", signing.sign_bundle, "unused", "unused", "unused", prepared)
                arguments, environment = tool.call_args.args
                self.assertNotIn(self.environment[signing.PREFIX + "PASSWORD"], arguments)
                self.assertIn("-storepass:env", arguments)
                self.assertIn("-keypass:env", arguments)
                self.assertEqual(environment, self.environment)

    def test_signature_verification_failure_does_not_report_success(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "result.aab"
            prepared = (Path("jarsigner"), self.environment, Path("unused-key-path"), "upload")
            results = [subprocess.CompletedProcess([], 0, b"", b""),
                       subprocess.CompletedProcess([], 2, b"CERT_MISMATCH", b"")]
            with patch.object(signing, "check_bundle", return_value=(Path("source.aab"), output)), \
                    patch.object(signing, "run_tool", side_effect=results):
                self.blocked("SIGNATURE_VERIFICATION_FAILED_DO_NOT_USE_OUTPUT", signing.sign_bundle,
                             "unused", "unused", "unused", prepared)


if __name__ == "__main__":
    unittest.main()
