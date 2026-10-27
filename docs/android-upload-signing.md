# Android upload-signing preparation — R4

Development APK and `Android Release AAB` presets are unchanged. The latter still
produces an **unsigned, test-ad** AAB. Signing does not activate production ads or
establish store/device readiness. No key is created, replaced or deleted by this
workflow, and nothing is uploaded.

## Owner configuration and use

1. Keep an existing owner-controlled upload keystore **outside this repository**,
   with restricted filesystem access and an independent secure backup. Supported:
   JKS/PKCS12, RSA of at least 2048 bits, matching store/private-key passwords.
   If none exists, stop: key provisioning is a separate owner-controlled action.
2. In a dedicated local process, inject these environment values from your trusted
   secret manager. Never put a password literal in commands, shell history,
   `setx`, profiles, presets, `.env`, transcripts, CI logs or chat. Never dump the
   environment. Close the dedicated process after use.

   | Process variable | Owner-supplied value |
   |---|---|
   | `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` | Absolute path to existing external keystore |
   | `GODOT_ANDROID_KEYSTORE_RELEASE_USER` | Existing private-key alias |
   | `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` | Secret-manager supplied shared store/key password |
   | `NOSPACE_UPLOAD_CERT_SHA256` | Independently approved upload certificate SHA-256; 64 hex digits, colons optional |

   The first three names are the [Godot 4.6 supported release environment
   overrides](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html#environment-variables).
   The fourth is a project identity pin, not a Godot setting. Obtain it from a
   trusted record/copy of the public upload certificate, and compare with the
   account upload certificate when available. It is public metadata, not a key
   or password. Do not approve an unknown key just because it can be opened.
   Aliases currently accept ASCII letters/digits and `._-`; debug/test/example
   names are intentionally rejected. Do not rename or replace a key to bypass a
   failed preflight; resolve ownership/configuration first.
3. Run preflight with the installed JDK (current workstation path shown):

   ```powershell
   python tools/android_upload_signing.py --java-home 'D:/android studio/jbr'
   ```

   Success: `UPLOAD_KEY_READY; no artifact signed`. Missing credentials, relative/
   missing/in-repo paths, debug/test names, common test passwords, invalid/mismatched
   certificate pin, invalid/expired certificate, non-private alias, wrong store/key
   password or unsupported key block the operation. The Java helper reads the
   existing keystore and proves private-key access in memory, never exports key
   bytes. Pinning and owner review matter: arbitrary custom test keys cannot be
   recognized from their names alone.
4. Produce and review a fresh unsigned AAB using the unchanged [R1 isolated
   workflow](android-integrations.md), in a **separate process without signing
   credentials**. Check package/SDK, non-debuggable manifest, assets and hash.
   After approving that exact input, run in the signing process:

   ```powershell
   python tools/android_upload_signing.py --java-home 'D:/android studio/jbr' `
     --sign-aab export/REVIEWED-WORKSPACE/project/export/nospace_arena-release-unsigned.aab `
     --sha256 REVIEWED_UNSIGNED_AAB_SHA256 `
     --output export/upload/nospace_arena-upload.aab
   ```

   Replace the two uppercase review placeholders. Output must be a new path under
   ignored `export/`; existing output and unsigned source are never overwritten.
   A failed output is unusable. Success requires signing and verifying payload
   entries against the pinned certificate. No already-signed input is accepted.

## Why signing follows unsigned export

The preflight/signer uses Godot's supported release variable names, but does not
pass them to Godot/Gradle. Signed Gradle build failure diagnostics can expose
command arguments; keeping `package/signed=false` separates credentials from that
path. The [Godot 4.6.3 Android exporter](https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp)
and local R1 workflow are the implementation references.

The signer uses JDK [jarsigner environment-password
options](https://docs.oracle.com/en/java/javase/17/docs/specs/man/jarsigner.html),
not literal password arguments. Child output and exception details are captured
and discarded, never logged/forwarded. Diagnostics contain fixed codes only;
Java launcher option-injection variables are removed for signing children.
Do not run signing under shell tracing, debuggers or environment instrumentation.
Environment credentials remain accessible to sufficiently privileged local
processes; this does not protect a compromised workstation.

The tool verifies integrity and identity, not binary Android manifest semantics:
approve the unsigned hash only after R1 artifact checks. It does not establish
production-ad, Android runtime, Play account or store readiness.

## Validation and remaining owner actions

`python tools/test_android_upload_signing.py` runs focused negative tests using
mocks and synthetic AAB fixtures, without creating/reading/deleting any keystore.
Real-key positive preflight and signed-artifact validation remain untested until
the owner supplies configuration locally. Negative tests and unsigned smoke do
not imply that positive signing has been validated.

Verified on 2026-10-27 from `main@81f9b8b`: 19 focused tooling tests passed;
the real JDK compiled/executed the helper and rejected missing environment and
an existing PNG supplied as an invalid store (no keystore touched). The unchanged
R1 workflow imported and exported with exit 0 in `export/r4-signing-unsigned/`.
Final unsigned AAB: 42,321,445 bytes; SHA-256
`f4766d6a15e4a1ace293531460e522b6ae033b7421202f8e835d80693b2df7ca`.
Manifest: `com.tugrahek.nospace`, min/target 24/36, non-debuggable, arm64 only;
no signature or test/GUT/docs/tools assets. Both native libraries' six load
segments remain 16 KB aligned and bundle configuration is `PAGE_ALIGNMENT_16K`.
Both export profiles and R1 preparation script are byte-identical to baseline.
These are unsigned-artifact checks; owner-key signing and device acceptance are
still pending. Local detailed evidence is `export/r4-signing-unsigned/r4-evidence.json`.

[Android signing guidance](https://developer.android.com/studio/publish/app-signing)
distinguishes the owner-held upload key from the app-signing key managed through
Play App Signing. The owner retains key/backup responsibility and confirms the
account certificate association. This step does not configure Console or upload.

Tuğra acceptance: after later owner-side signing/Play delivery, install the
exported device build, verify identity/update behavior, controls, pause/resume and
the existing consent flow. Physical-device acceptance remains pending.
