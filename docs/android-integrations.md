# Android integration notes

This page keeps the project's Android service and export details out of the portfolio overview. It describes the current development setup, not a production release configuration.

## Ads and consent

- The project uses Poing Studios' [Godot AdMob plugin 5.1.0](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0), pinned to that release. The integration package is `poing-godot-admob-v5.1.0.zip`; the matching Godot 4.6.3 Android template package is `android-template-v4.6.3.zip`.
- Package SHA-256: `8c53ff52719edf6a81cc7d32a9cdaad2d9e11693c85faca25008a1c19355726f`.
- Android template SHA-256: `f7fdf644d50c0e231d8f02ae044057e489d0bcafcf50e908a4858477e7ee05ee`.
- The template's `ads/` directory and `package.gd` belong under `addons/admob/android/bin/`. The required plugin AARs are vendored. Signing keys and production credentials must remain outside Git.
- Android export uses the Godot 4.6.3 Gradle template, arm64, and network permissions. Enable **Use Gradle Build** in the local Android export preset; no manual plugin ProGuard rules are required.
- UMP consent information is refreshed each session. Any required consent form is presented before `AdsService` initializes or loads ads. Settings exposes privacy choices only when UMP requires them.
- Development defaults use Google's official test configuration for the plugin Android App ID and test ads. The production rewarded unit is unset. Configure both production IDs before disabling test mode. Desktop ads use a no-op backend.

### Production configuration gate (R2; production remains disabled)

`config/ads_config.gd` resolves these ProjectSettings together at Android boot:

| Setting | Development default | Future production requirement |
|---|---|---|
| `monetization/ads/use_test_ads` | `true` | Explicit boolean `false` |
| `monetization/ads/production_enabled` | `false` | Explicit boolean `true`, only after release approval |
| `admob/general/android/app_id` | Plugin's official Google test App ID | Publisher's verified Android App ID |
| `monetization/ads/android_rewarded_id` | Empty | Verified rewarded unit belonging to that publisher/app |

Test mode always selects Google's rewarded test unit. Production requires both flags
and an exact-format App ID (`~`) / unit ID (`/`) pair with the same non-test publisher.
Missing, malformed, mixed-publisher, Google-test or zero-publisher pairs resolve to an
empty unit; `NativeAdsBackend` then refuses SDK initialization as well as loading.
Malformed non-boolean mode flags also block requests. This is structural validation;
it cannot establish ownership, app membership, rewarded format or AdMob approval.
Configuration is a build/boot snapshot, not a supported live runtime toggle.

For a later authorized production build, create a separate export workspace and set
all four keys in that workspace's `project.godot` before Godot import/export. Do not
edit the source project's development defaults or reuse the R1 smoke workspace for
production. The R1 preparation script intentionally requires test mode and an empty
production unit. No production config file or real ID is supplied by R2. The old
`config/ad_ids.example.gd` is a reference, not a loader; copying it does not configure ads.

The plugin exporter maps the App ID setting to manifest metadata
`com.google.android.gms.ads.APPLICATION_ID`. Inspection of the vendored release AAR's
`PoingGodotAdMob.initialize` confirms it reads this metadata and passes it to the
Next-Gen SDK's `InitializationConfig.Builder`; UMP uses the same manifest ID.
Always inspect the final bundle manifest against the workspace setting before release.
AdMob IDs are routing identifiers visible in distributed apps, **not signing secrets**.
Keep real account config out of this public repository per project policy; never mix
keystore paths/passwords, account tokens or service credentials into these settings.

UMP remains the session consent gate before SDK initialization/loading. Required forms,
privacy-options availability, pending-form blocking and revocation remain covered by
the existing injectable integration tests. A config failure blocks ads even if UMP
allows them; privacy options still use the existing Settings entry when required.
Native delivery and account-configured messages require device/account acceptance.

Publisher follow-up: confirm real IDs/app/package association, AdMob readiness and
`app-ads.txt`, message publication and regions, audience/under-age treatment, and the
policy/Data Safety declarations. Drafts: [privacy policy](privacy-policy.draft.md)
and [Data Safety worksheet](data-safety-worksheet.md). No production activation or
public policy URL is included in R2.

## Google Play billing

- The project vendors [GodotGooglePlayBilling 3.3.0](https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0) with Google Play Billing Library 9.1.0 under `addons/GodotGooglePlayBilling/`, including its MIT notice and debug/release AARs.
- Release ZIP SHA-256: `20d75623d6f337f08d8283c83098b73678d5f575e39247af5a8eb80588b18568`.
- The editor plugin adds the variant-specific AAR and pinned Maven dependency to Android Gradle exports. `PurchaseService` selects the Android adapter only when the native singleton is available; desktop remains a no-op.
- The adapter supports non-consumables with one purchase offer and uses Google-provided localized product metadata. The default catalog is empty: no products, consumables, subscriptions, or server-side receipt validation are configured.
- Purchase callbacks are correlated with immutable request data and opaque flow markers; purchase tokens identify durable transactions. Checked reward delivery precedes acknowledgement. Owned-purchase queries support restoration and retry failed acknowledgements on a later query.

## Export checklist

Android builds require matching Godot export templates, an Android SDK/JDK, the Gradle build template, and local signing configuration. Keep test ads enabled for development. Before distribution, review application IDs, signing, network permissions, export filters, and the product catalog. Exclude development addons and tests from production exports. iOS export and native-service acceptance are not yet validated.

## Unsigned release preparation

The existing `Android` preset remains the development APK workflow. The separate
`Android Release AAB` preset uses a release template, AAB output, explicit min SDK
24 / target SDK 36, arm64, and the same package identity and network permissions.
Signing is deliberately disabled; its unsigned, test-ad output is not a Play upload.
No credentials belong in `export_presets.cfg`, which is currently tracked despite
its ignore rule. Godot stores local signing credentials separately under `.godot/`.

Release exclusions cover `test/`, GUT, documentation, build tools, Android generated
content and export output. The isolated Android directory also has `.gdignore` to
prevent rescanning generated assets on repeated exports.
AdMob/Billing runtime scripts, plugin export hooks and native libraries remain available.
Legal notices already handle an absent GUT resource. Production ad settings remain unset.

`tools/prepare_android_release.ps1` copies runtime sources and installed 4.6.3
templates to a new, ignored `export/release-smoke/project` workspace. It refuses an
existing workspace and private ad config. It never copies `.godot/` credentials or
changes the development Android template. Import this workspace before exporting:

```powershell
./tools/prepare_android_release.ps1
& $godotConsole --headless --path ./export/release-smoke/project --editor --import
& $godotConsole --headless --path ./export/release-smoke/project --export-release 'Android Release AAB' --quit
```

`$godotConsole` must point to the matching Godot 4.6.3 console executable. Output is
`export/release-smoke/project/export/nospace_arena-release-unsigned.aab`.

Godot 4.6.3 ships AGP 8.6.1, while Android documents AGP 8.9.1 as the API 36 minimum.
Gradle 8.11.1 already meets AGP 8.9's requirement; no wrapper upgrade is needed.
The preparation script patches only the isolated release template to AGP 8.9.1.
A complete unsigned export with Godot 4.6.3, AdMob 5.1.0 / ads-mobile-sdk 1.4.0
and Billing 3.3.0 / billing-ktx 9.1.0 succeeded with this combination. The development
template remains stock. Use the isolated workspace for this verified release toolchain;
exporting directly from the source project's preset still uses the local development template.
Sources: [Godot template](https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/java/app/config.gradle),
[Android API/AGP matrix](https://developer.android.com/build/releases/about-agp#api-level-support).

Inspect the final bundle manifest, packaged resources and all native ELF load
segments, plus the bundle's native-library page-alignment configuration. Build success
alone does not establish 16 KB compatibility; generated APK alignment and 16 KB
device/emulator execution remain separate checks. Signing and production-ad activation
require later explicit configuration; this preparation supplies neither.

R1 artifact inspection: min/target SDK 24/36, version 1 / 0.1.0, package
`com.tugrahek.nospace`, arm64 only, no signatures, and no test/GUT/docs/tools assets.
All LOAD segments in `libc++_shared.so` and `libgodot_android.so` have 16,384-byte
alignment with congruent file offsets / virtual addresses; bundletool reports
`PAGE_ALIGNMENT_16K`. These are artifact checks, not physical-device acceptance.
The merged manifest retains the SDK-added ad ID, basic phone state, Billing,
wake-lock, foreground-service and dynamic-receiver permissions already present in
the development build. Review them in the later privacy/disclosure step; no SDK or
Billing functionality is removed here.

The initial repeat-export failure came from six generated Godot import sidecars:
`android/build/res/{mipmap,mipmap-hdpi-v4,mipmap-mdpi-v4,mipmap-xhdpi-v4,mipmap-xxhdpi-v4,mipmap-xxxhdpi-v4}/icon.webp.import`.
Their remap data referenced generated Android icons, and they were created before
the Android `.gdignore` existed. They are ignored build artifacts, not required
source resources. Gradle rejects these sidecars in Android resource directories.
The preparation script creates `.gdignore` before the first scan, and `android/*`
is excluded from the release export. Preserve old evidence and prepare a clean
workspace with `./tools/prepare_android_release.ps1 -WorkspaceName release-smoke-clean`;
then substitute `export/release-smoke-clean/project` in the commands above.
No source icons or import sidecars need deletion.

Verified on 2026-10-21 in the clean workspace: import and unsigned release export
both exited 0. The final 42,256,389-byte AAB passed the manifest, exclusions,
unsigned-status and native alignment checks described above; Android resource
directories contained no `.import` sidecars after import or export. Its SHA-256 is
`938dbab33085ec2ee280486177c9b829ccb150642bf3a5adf9b700605b3ab7f4`.
