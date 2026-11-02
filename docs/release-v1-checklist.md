# NoSpace: Arena — permanent v1 release tracker

Last reviewed: **2026-11-02**. Status: **BLOCKED — mandatory v1 IAP is incomplete**.
Keep this file current in every release-related step. A checked preparation item
does not mean signing, account approval, device acceptance or publication passed.
Attach evidence/date to newly completed items; account-dependent entries stay open
until the publisher verifies them. No Play Console access/approval is inferred.

## Completed preparation

- [x] R1 / Step 25 (`2776728`): separate unsigned release AAB and retained development
  APK workflow; isolated Godot 4.6.3/AGP preparation and artifact/16 KB checks.
- [x] R2 / Step 26 (`39f2bc0`): production-ad fail-closed configuration, test default,
  UMP integration audit and privacy/Data Safety drafts. Production remains disabled.
- [x] R3 / Steps 27–28 (`eb95d26`, `06c634c`): approved branding/feature graphics,
  EN/TR authentic rendered screenshots, upload order, launcher/adaptive integration
  and listing drafts. Screenshots are desktop renders, not device acceptance.
- [x] R4 / Step 30 (`725dcfc`): credential-safe upload-key preflight/post-export
  signer and negative tests; unsigned AAB smoke. Owner-key positive signing pending.
- [x] Step 29 (`81f9b8b`): floating hold-to-move D-Pad with focused input/HUD tests.
- [x] Step 31 (`2ae8563`): Daily replay/recording removed, historical scores retained,
  README and store/privacy copy cleaned. Daily seeds and scoring unchanged.
- [x] Step 32: typed `coins_500/1500/4000` definitions, exact amounts, validation
  tests, explicit disabled native-purchase gate and [secure IAP design](iap-v1-architecture.md).

## Mandatory v1 IAP — release blockers

- [ ] **Decide account identity and wallet recovery**: login/linking, reinstall and
  device loss/switch, account switching, deletion/support and offline behavior.
- [ ] Decide authoritative paid-wallet/spend model and safe migration/merge of
  existing local earned coins. Preserve approved economy balance; review separately.
- [ ] Deploy authenticated Play verification service for the expected package,
  SKU, owner, state, quantity and environment; server credentials stay outside Git/APK.
- [ ] Implement durable unique-token ledger, atomic wallet credit and consumption
  outbox with retry/backoff, deadlines, monitoring, audit and backups.
- [ ] Implement versioned wallet projection/idempotent client delivery; never grant
  from an unverified callback or repeat `earn` on retries.
- [ ] Extend the currently non-consumable native adapter for approved consumable
  metadata/offers, pending handling and reconnect/recovery; validate plugin support.
- [ ] Implement server consumption after durable fulfillment; handle duplicates,
  already-consumed responses and pending-to-purchased transitions without double credit.
- [ ] Implement RTDN/reconciliation and Voided Purchases polling, partial refund
  policy, spent-coin reversal/support process and operational alerts.
- [ ] Configure the three exact products as consumable one-time products in Play
  Console; approved regional prices/availability/taxes and single-quantity policy.
  Show Google-localized prices only; define missing/stale-offer UI behavior later.
- [ ] Connect purchase actions to the existing Store in a separately scoped step;
  no Store/Settings redesign is included here. Do not route through the local stub
  that marks consumables delivered without coin credit.
- [ ] Validate sandbox/license-tester paths: success, cancel, pending/declined,
  duplicate token/concurrent devices, mismatch/replay, offline/crash at each phase,
  persistence failure, reinstall/account recovery, consume timeout and refund.
- [ ] Approve end-to-end evidence with a signed Play-delivered build and trusted
  verification/delivery in operation; only then review flipping
  `PurchaseService.REAL_PURCHASES_ENABLED` and installing the live catalog.

IAP is **mandatory for this v1 plan**. The unchecked work is not silently deferred
or replaced by a local receipt check. Remove-ads, cosmetics, subscriptions or
additional products are not approved by this foundation step.

## Play Console and merchant ownership

- [ ] Confirm publisher/legal identity, country, developer account type/date,
  verification, app ownership and package `com.tugrahek.nospace` availability.
- [ ] Complete applicable payments/merchant profile, bank/tax/identity setup and
  monetization agreements; confirm supported selling regions/currencies.
- [ ] Grant least-privilege Play Developer API/backend access, set up authenticated
  notification delivery and keep credentials out of the repo/client/logs.
- [ ] Configure license testers/testing accounts and product activation on the
  appropriate testing track. Console/merchant readiness is account-dependent.

## AdMob, UMP and privacy

- [ ] Supply/verify owned production AdMob App ID and rewarded unit, app association,
  readiness and app-ads.txt. Keep test defaults until separately approved activation.
- [ ] Publish/review UMP messages for intended regions/ages; confirm consent gating,
  privacy-options availability, revoke/change choices, offline/error and return flows.
- [ ] Confirm target audience/child-directed/under-age decisions and SDK configuration.
- [ ] Complete publisher/contact/retention/deletion/recipient/transfer details in the
  [privacy draft](privacy-policy.draft.md) and [Data Safety worksheet](data-safety-worksheet.md).
- [ ] Update disclosures for the future account/wallet/verification backend, tokens
  and operational services; confirm actual SDK behavior and final artifact inventory.
- [ ] Publish approved public HTTPS policy, bind it through the documented Legal
  integration point without redesigning frozen Settings, and complete Console
  Data Safety/ads/audience declarations.

## Upload signing and final production AAB

- [ ] Owner supplies external upload key/alias and secret-manager process variables;
  approve certificate pin and positively validate [R4 signing](android-upload-signing.md).
- [ ] Confirm Play App Signing/upload-certificate association and secure backup/recovery.
- [ ] Prepare a fresh final release workspace with approved runtime configuration;
  preserve development APK and unsigned smoke paths. Review production activation
  separately; unsigned test-ad artifacts are not production releases.
- [ ] Select versionName and increasing versionCode; verify current Play SDK/ABI and
  policy requirements, package/permissions, asset exclusions and non-debuggable manifest.
- [ ] Inspect final AAB/assets/native ELF and generated APK 16 KB zip alignment;
  verify on a 16 KB-capable environment/device and review Play validation results.
- [ ] Sign the exact reviewed AAB hash, verify pinned signature and archive artifact,
  checksums, version, configuration and acceptance evidence without credentials.

## Physical Android acceptance — exported/Play builds

- [ ] Install/update on representative real phones and portrait ratios; confirm
  launcher/adaptive/themed masks, safe areas, text/languages, touch and performance.
- [ ] D-Pad at center/edges: all directions/reversal, dead-zone stop, owner release,
  extra fingers, HUD/Pause exclusion, scheme switching, background/resume, no stuck input.
- [ ] Daily: deterministic arena selection, old score-save upgrade, no replay marker,
  best/history persistence and pause clock; normal run/capture/collision behavior unchanged.
- [ ] Rewarded ads/UMP: unavailable/offline/pending consent, close/return/revoke and
  exactly-once rewards. No production ads used for routine development testing.
- [ ] IAP: complete the signed-device/test-account cases above with server and wallet
  logs reconciled; no real-money activation while any security/recovery blocker remains.
- [ ] Verify audio/haptics, battery/resume interruptions, back navigation and crash/ANR
  observations; record device/OS/build and owner acceptance.

## Store listing, testing and publication

- [ ] Approve final EN/TR listing/metadata, correct current feature claims, content
  rating, policy/contact URLs, regions, pricing and screenshots `02 → 01 → Mode Select`.
- [ ] Compare authentic store renders with final phone behavior; retain native capture
  provenance. Approved graphics do not imply approval of later monetization claims.
- [ ] Upload to the chosen internal/closed track only with explicit publisher approval;
  complete pre-launch/security/policy warnings and reviewer access instructions.
- [ ] Determine account-specific closed-testing eligibility. Current Google guidance
  requires qualifying newer personal accounts to retain at least 12 opted-in testers
  continuously for 14 days before applying for production access; account applicability
  and final requirements must be checked in Console, not assumed complete.
  [Official testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465)
- [ ] Complete required testing, fix blocking issues, submit production-access request
  if applicable, obtain approval, then explicitly approve release/rollout and monitoring.
- [ ] Re-check this tracker and retain rollback/support/incident ownership before launch.

## Deferred scope

- [ ] iOS signing/device acceptance, StoreKit/server verification, App Store accounts,
  store assets/privacy and App Review: deferred, not Android v1 evidence.
- [ ] v1.1 roguelite draft/deeper content and separately approved enhancements:
  deferred. No additional IAP products or gameplay/economy changes inferred.

Evidence starts in [Android integration notes](android-integrations.md),
[store asset package](play-store/README.md), [R4 signing](android-upload-signing.md)
and the [IAP architecture](iap-v1-architecture.md). Revalidate changing platform
requirements at the actual release date; historical preparation checks stay historical.
