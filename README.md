# NoSpace: Arena

2D mobile territory capture arcade game built with Godot 4.6.

**Core mechanic:** Move along the arena border, enter the field, draw a line, close the shape to capture territory — don't let enemies touch your active line.

**Genre root:** Qix/Volfied, with three differentiating hooks:
1. **Living Territory** — captured regions have active effects (fire, slow, energy)
2. **Daily Seed + Ghost + Leaderboard** — everyone plays the same daily arena; your best run's ghost faces you
3. **Roguelite draft** — *(v1.1, post-launch)*

**Platform:** Android + iOS  
**Engine:** Godot 4.6.x (GDScript, statically typed)

**AdMob boundary (Step 23B):** Poing Studios plugin **5.1.0**, pinned to the
[stable release](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0).
Packages: `poing-godot-admob-v5.1.0.zip` and `android-template-v4.6.3.zip`.
SHA-256: `8c53ff52719edf6a81cc7d32a9cdaad2d9e11693c85faca25008a1c19355726f`
and `f7fdf644d50c0e231d8f02ae044057e489d0bcafcf50e908a4858477e7ee05ee`, respectively.
Install the template's `ads/` and `package.gd` into `addons/admob/android/bin/`;
native binaries and local export/signing settings remain excluded from Git.
Android uses the Godot 4.6.3 Gradle build template, arm64, and network permissions.
Enable `Use Gradle Build` in the local Android preset; no manual plugin ProGuard rules.
UMP updates each session and presents any required form before AdsService may
initialize/load. Privacy choices appear in Settings only when UMP requires them.
`monetization/ads/use_test_ads=true` and the plugin Android App ID use Google's
official test configuration; production rewarded ID is empty. Configure both App ID
and rewarded unit before deliberately disabling test mode. Editor uses no-op ads.
Results coin rewards and claim/save integration remain Step 23C.

**Android billing foundation (Step 24D.1):** official
[GodotGooglePlayBilling 3.3.0](https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0),
with Google Play Billing Library **9.1.0**, under `addons/GodotGooglePlayBilling/`.
The required GDScript/export files, MIT notice and debug/release AARs are vendored.
Release ZIP SHA-256: `20d75623d6f337f08d8283c83098b73678d5f575e39247af5a8eb80588b18568`.
The editor plugin adds the variant-specific AAR and pinned Maven dependency to
the existing Android Gradle export; it does not initialize a billing client or
connect to PurchaseService. No products or purchase flow are configured.
Vendor GDScript trailing whitespace is normalized; behavior is unchanged.

**Android purchase backend (Step 24D.2):** PurchaseService selects the Google Play
adapter only when the Android native singleton is available; desktop remains no-op.
Approved product definitions can be supplied to the adapter; its default catalog
is empty. Native v1 behavior supports non-consumables with one purchase offer.
Google supplies localized metadata/prices. Immutable request callbacks and opaque
flow-attribution markers correlate live updates; purchase tokens identify durable
transactions. Economy's existing checked delivery completes before acknowledgement.
Connection/reconnection and restore query owned purchases through the same dedupe
path. A failed acknowledgement is retried on a later owned query, without a timer.
No product definitions, consumable rewards, subscriptions or server validation are configured.

---

*Source code is publicly visible for portfolio and reference purposes only.*  
*See [LICENSE](LICENSE) for terms.*
