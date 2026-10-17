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

## Google Play billing

- The project vendors [GodotGooglePlayBilling 3.3.0](https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0) with Google Play Billing Library 9.1.0 under `addons/GodotGooglePlayBilling/`, including its MIT notice and debug/release AARs.
- Release ZIP SHA-256: `20d75623d6f337f08d8283c83098b73678d5f575e39247af5a8eb80588b18568`.
- The editor plugin adds the variant-specific AAR and pinned Maven dependency to Android Gradle exports. `PurchaseService` selects the Android adapter only when the native singleton is available; desktop remains a no-op.
- The adapter supports non-consumables with one purchase offer and uses Google-provided localized product metadata. The default catalog is empty: no products, consumables, subscriptions, or server-side receipt validation are configured.
- Purchase callbacks are correlated with immutable request data and opaque flow markers; purchase tokens identify durable transactions. Checked reward delivery precedes acknowledgement. Owned-purchase queries support restoration and retry failed acknowledgements on a later query.

## Export checklist

Android builds require matching Godot export templates, an Android SDK/JDK, the Gradle build template, and local signing configuration. Keep test ads enabled for development. Before distribution, review application IDs, signing, network permissions, export filters, and the product catalog. Exclude development addons and tests from production exports. iOS export and native-service acceptance are not yet validated.
