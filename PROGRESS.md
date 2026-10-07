## Step 24D.1 — Google Play Billing Plugin Foundation — Implemented (2026-10-07)
- Son güncelleme: 2026-10-07
- Tamamlanan Steps: [x] Step 24D.1 implemented on `step/24d1-google-play-billing-plugin`, from clean main `5cea6e8b1b31f7bd43a7afe80e3c28390ccb8281`. No commit/push/merge.
- Önemli Kararlar: Official GodotGooglePlayBilling 3.3.0 release ZIP checksum verified (`20d75623d6f337f08d8283c83098b73678d5f575e39247af5a8eb80588b18568`). Only required vendor GDScript/export/config/license and debug/release AARs installed; generated script UIDs retained. Google Play Billing Library 9.1.0 is supplied through the upstream export plugin's pinned Maven dependency. Vendor GDScript trailing whitespace normalized; otherwise release contents unchanged. Editor plugin enabled; no BillingClient instance/autoload, PurchaseService adapter, product configuration, purchase flow, subscription integration, Economy/save changes or server work.
- Üretilen Sonuçlar: Billing addon, project editor-plugin entry, README version/checksum, credits and exported MIT notice using the existing legal resource. Godot 4.6.3 editor/parser and project-load probe PASS; PurchaseService remains unavailable with empty catalog and its no-op backend. One Android debug export PASS; `export/nospace_arena_24d1_debug.apk` signature verified. APK manifest has native billing registration, BILLING permission and PBL 9.1.0 alongside AdMob rewarded/UMP registrations; APK dex contains billing/client and AdMob rewarded/UMP classes. Existing AdMob build.gradle, config.gradle and package.gd hashes unchanged; local Android preset unchanged. Required vendor files checked against release bytes (source differs only by trailing whitespace). ZIP in TEMP, probes/logs/cache in .godot, and APK under export are excluded from intended changes. No GUT or Play purchase tests. git diff --check PASS.
- Açık Sorunlar: Android runtime plugin loading and Play purchases need future device/account validation. Existing Gradle compileSdk/manifest warnings are environmental/template warnings, not new integration errors. This step proves native packaging; it does not validate Play purchase behavior.
- Sonraki Step: Step 24D.2 — Android backend adapter behind PurchaseService (requires separate scope/approval).

## Step 24C — Durable Purchase Delivery — Implemented (2026-10-07)
- Son güncelleme: 2026-10-07
- Tamamlanan Steps: [x] Step 24C implemented on `step/24c-purchase-delivery`, from clean main `98beebe401934a9644e09d63d48f024c27d40f6a`. No commit/push/merge.
- Önemli Kararlar: SaveData adds `iap_transactions` (transaction identity + product/kind/status) and `iap_entitlements`. Existing profiles default empty. Trusted PurchaseService autoload delegates backend transaction context to Economy's internal delivery entry; purchase success emits only after a checked durable result. Economy first persists pending transaction, then persists delivered state with non-consumable entitlement in one candidate profile write. A failed second write leaves the first pending record durable for deterministic sorted recovery; failed first write reports no delivery. Entitlement is emitted only when it is newly persisted. Consumable transaction identity is tracked without assigning a reward. No native acknowledgement/consume behavior, product IDs, prices, reward mapping or SaveStore redesign.
- Üretilen Sonuçlar: SaveData schema serialization/migration defaults, Economy checked two-phase delivery and recovery/entitlement/status APIs, PurchaseService durable success boundary + pending-delivery signal, purchase delivery tests. Focused GUT 57/57 PASS, 285 assertions across purchase delivery, PurchaseService, SaveData and rewarded mission persistence (user:// writes permitted). Parser/editor registered changed scripts/autoload without project script errors; environmental certificate/editor settings warnings unchanged. git diff --check PASS. No full GUT/build/screenshot.
- Açık Sorunlar: Native verification, acknowledgement, server validation and actual consumable reward mapping remain later scopes.
- Sonraki Step: Step 24D — native billing integration (separate approval/scope).

## Step 24B — Purchase Service Foundation — Implemented (2026-10-07)
### Full-suite failure diagnosis (2026-10-07)
- Full GUT finalization attempt ran once: 575/597 tests, 7968/8025 assertions; no commit/push/merge. All 22 failures reproduced across isolated Daily Reward (11/13, 788/798 assertions), rewarded mission bonus (4/16, 42/73), Results rewarded (14/19, 60/68), Settings (9/12, 144/152) runs under the same sandbox. Failed assertions concern persisted values or claims gated by successful saves.
- Exact IO evidence: workspace WRITE opens successfully (error 0); user://24b_io_probe.tmp in AppData cannot open for WRITE (error 12). SaveStore returns false/default reload; SettingsStore silently skips failed open and reloads defaults. PurchaseService startup probe: UNAVAILABLE, active token 0, next token 1, empty products/transaction history. New service only connects its own backend; per-test fake service instances are autofreed; affected autoloads/tests/pre-run hook do not reference PurchaseService.
- Minimal grouped comparison, unchanged code: PurchaseService + rewarded mission bonus under sandbox 20/32 tests, 147/178 assertions; with authorized temporary user:// writes permitted, 32/32 tests and 178 assertions PASS. Decision B: environment fixture-write restriction, no demonstrated 24B state/order regression. Production and test implementation unchanged; diagnostic configs/logs/probe are ignored .godot artifacts. git diff --check PASS. Another full GUT is justified only with permitted routine user:// test writes; not rerun during diagnosis. Existing certificate/editor warnings were not investigated.

- Son güncelleme: 2026-10-07
- Tamamlanan Steps: [x] Step 24B finalized on `step/24b-purchase-service`; commit `98beebe401934a9644e09d63d48f024c27d40f6a` pushed and ff-only merged/pushed to main.
- Önemli Kararlar: PurchaseService autoload with platform-neutral backend contract, unavailable no-op and manual deterministic fake. Empty metadata catalog supports consumable/non-consumable; no live IDs, prices, grants or entitlements. One active request with monotonic tokens; pending retains its token and blocks new work. Restore streams queried non-consumable metadata transactions and explicit completion. Duplicate/stale callbacks cannot emit duplicate success; transaction IDs deduplicated across operations within this service instance only. Success describes backend reporting, not verified or durable delivery authorization. No native SDK, Store UI, Economy delivery, save changes, subscriptions or server work.
- Üretilen Sonuçlar: project.godot autoload entry; purchase_service, purchase_backend, noop_purchase_backend, fake_purchase_backend, purchase_product, purchase_catalog; test_purchase_service and generated .uid files. Focused GUT 16/16 PASS, 105 assertions. Coverage includes initialization/retry, metadata query/snapshots, rejection/single-active, success/cancel/failure/pending, restore/empty/failure, duplicate/stale callbacks, transaction replay and synchronous/reentrant listeners. Godot 4.6.3 parser/editor registered new classes and autoload without project script errors; sandbox emitted Windows certificate-store and editor-settings write errors. git diff --check PASS. No full GUT, build or screenshot.
- Açık Sorunlar: Durable transaction deduplication/delivery, validation, native acknowledgement, reconnect recovery and refund/entitlement reconciliation remain future implementation; foundation performs no rewards. Product decisions remain unapproved. Existing Step 23E physical-device acceptance remains deferred.
- Sonraki Step: Step 24C — durable transaction delivery (complete).

## Step 23D — Rewarded Ad Lifecycle Hardening — Finalized (2026-10-07)
- Son güncelleme: 2026-10-07
- Tamamlanan Steps: [x] Step 23D on `step/23d-rewarded-lifecycle`, from clean main containing finalized 23C.2 `d523f65`; commit `018d12d` pushed and ff-only merged/pushed to main.
- Step 23 status: 23A COMPLETE; 23B COMPLETE; 23C COMPLETE; 23D COMPLETE; 23E DEFERRED — requires physical Android hardware.
- Final verification: Full GUT once PASS, 581/581 tests and 7920 assertions; git diff --check PASS. main/origin/main/feature equal `018d12d33cd2a1973934ad77c46a6eda5f82bb67`, ahead/behind 0/0, working tree clean. Implementation unchanged during finalization.
- Önemli Kararlar: Two reproduced Results defects: hiding/reopening Results retained its reward authorization; a queue_free-pending HUD could claim during deferred callback delivery before actual destruction. ResultsRewardedBonus now retires an active request when effective visibility disappears and checks pending deletion throughout its ancestor hierarchy before show/reward matching. AdsService remains authoritative for single-active requests/tokens; only its matching reward-earned handler calls the existing claim path. No Economy/save, native SDK/UMP, UI redesign, retry loop or timer changes.
- Üretilen Sonuçlar: Only results_rewarded_bonus.gd and test_results_rewarded_bonus.gd changed. Six new lifecycle tests reproduce hidden/reopened Results and pending deletion, simulate background/foreground while loading/showing, and reject old tokens across new runs and new Results scenes. Existing coverage retains reward/close/failure/no-fill, duplicates, freed scenes, synchronous callbacks, repeated tap and navigation behavior. Before hardening: 57/59 tests passed, two reproduced defects. Focused: 59/59 PASS, 261 assertions across three explicitly selected Results/AdsService/native-adapter test files. Final full GUT once: 581/581 PASS, 7920 assertions. Parser/editor and focused HUD scene instantiation PASS; git diff --check PASS. No screenshots or native-device acceptance.
- Açık Sorunlar: Physical Android hardware is currently unavailable. Emulator, headless and native-build validation do NOT count as real-device AdMob/UMP acceptance.
- Sonraki Step: Step 23E physical-device acceptance when Android hardware is available.

## Step 23C.2 — Results Rewarded Bonus UI — Finalized (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] Step 23C.2 implemented on `step/23c2-results-rewarded-ui`, from clean main `9b185b0`; commit `d523f65` pushed and ff-only merged/pushed to main.
- Önemli Kararlar: Results offer is a 56px Secondary action below existing navigation with centralized EN/TR exact bonus text. game.gd explicitly finalizes the offer after mission payout and Campaign bookkeeping. New scene-local ResultsRewardedBonus component queries existing Economy eligibility and AdsService availability, makes a best-effort preload without blocking normal results, locks immediately and attempts one show. Only the matching AdsService.reward_earned handler may pass verified completion to the existing durable claim API; scene/request/economy context validation and pre-claim consumption reject stale/duplicate/reentrant callbacks. Deferred signal delivery handles even synchronous show reward/close/failure callbacks. Close without reward, cancellation/failure and scene disappearance do not claim; currency updates through existing Economy.currency_changed. No Economy/save-schema/AdsService/native/UMP changes.
- Üretilen Sonuçlar: HUD scene and finalization hook, results_rewarded_bonus.gd, localized translation resources and test_results_rewarded_bonus.gd. Focused tests 74/74 PASS, 316 assertions across 5 files. Full GUT once for finalization: 575/575 PASS, 7899 assertions. Parser/editor and HUD scene instantiation PASS; git diff --check PASS. Cold Godot 4.6.3 editor startup confirmed earlier AdsService identifier reports were stale autoload cache; no code/config fix was needed. No screenshots or native build. main/origin/main/feature refs match; ahead/behind 0/0, working tree clean.
- Açık Sorunlar: Physical-device ad/consent verification remains a later step.
- Sonraki Step: Step 23D lifecycle hardening (complete).

## Step 23C.1 — Rewarded Bonus Persistence — Finalized (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] Step 23C.1 eligibility, pre-Coin-Bonus calculation and daily exactly-once durable claim on `step/23c1-rewarded-bonus-persistence`, based on clean main `93531c8`; commit `9b185b0` pushed and ff-only merged/pushed to main.
- Önemli Kararlar: Economy captures only newly claimed mission payout at finished-run evaluation, before Coin Bonus multiplication. In-memory context ID changes on GameState.game_started; terminal-state, context, canonical SeedManager.today_epoch(), verification and persisted day checks reject stale/duplicate claims. Bonus uses floor(base × 0.50). SaveData.rewarded_mission_bonus_epoch_day defaults to -1 for old saves. One SaveStore.save_to call writes a candidate profile containing both coins and claim marker to the same canonical user://save.json; Economy publishes the candidate only after the writer reports successful flush. SaveStore now returns write success; existing callers remain unchanged. Verified completion is an explicit trusted-caller requirement; SDK/Results wiring belongs to 23C.2. No AdsService, Daily Reward, Extra Life or normal mission/Coin Bonus payout changes.
- Üretilen Sonuçlar: Economy API prepare_rewarded_mission_bonus, rewarded_mission_bonus_status, rewarded_mission_bonus_amount and claim_rewarded_mission_bonus; one game.gd payout-context hook; minimal SaveData field and SaveStore success result. New focused tests 16/16 PASS; together with existing SaveData, boosts, login streak, audio settings, Daily Reward and Settings regressions: 85/85 PASS, 1139 assertions across exactly 7 files. Final full GUT once: 562/562 PASS, 7848 assertions. Parser/editor PASS; git diff --check PASS. All test/profile/log/config outputs use isolated user:// fixtures or ignored .godot paths. main/origin/main/feature refs match; ahead/behind 0/0, working tree clean.
- Açık Sorunlar: None in this scope. UI/ad-button/verified AdsService completion integration is deferred; old finished-run contexts are intentionally not restored across restart.
- Sonraki Step: Step 23C.2 Results UI and AdsService callback wiring (complete).

## Step 23B — AdMob SDK + Android Gradle + UMP — Complete (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] Step 23B implementation, validation and Git finalization on `step/23b-admob-sdk-consent`, based on clean main `5844e0e`; commit `ddd25c8` pushed and ff-only merged/pushed to main.
- Önemli Kararlar: Official stable Poing 5.1.0 pinned, with checksum-verified `poing-godot-admob-v5.1.0.zip` and `android-template-v4.6.3.zip` (source/release URLs and SHA-256 in README). Existing Godot 4.6.3 Android template retained. Local preset changes only Gradle enabled and INTERNET/ACCESS_NETWORK_STATE enabled; identity, arm64, orientation and release/signing settings preserved. SDK bridge + NativeAdsBackend behind AdsService, no new autoload. UMP session update and required form gate initialization/load; Google-documented NOT_REQUIRED/OBTAINED equivalence used because Poing 5.1 exposes status rather than canRequestAds. Privacy choices only for Google's REQUIRED state; stale/duplicate consent and rewarded callbacks rejected. No retry loop, Economy or claim/save integration.
- Üretilen Sonuçlar: Native adapter/bridge/consent coordinator, explicit official Google test configuration, localized conditional Settings privacy entry, plugin MIT notice. Focused GUT 52/52 tests, 345 assertions PASS; full GUT exactly once 546/546 tests, 7,775 assertions PASS. Editor/parser and native bridge compilation PASS; `git diff --check` PASS. Final Gradle TEST debug APK `export/nospace_arena_23b_test.apk` produced; APK signature, package `com.tugrahek.nospace`, arm64 and native rewarded/UMP manifest registration verified. Plugin's installer also automatically downloaded its pinned optional iOS binaries; iOS remains disabled and native bin/download output remains Git-excluded.
- Açık Sorunlar: Export completes and produces a valid signed APK, but Godot's console process remains open even with --quit; only the task-owned completed export process was closed. No build/code blocker. Direct bridge check-only exit emits existing shutdown ObjectDB/2-resource notices; full GUT and Android export have no project errors. No physical-device test or actual ad/consent network acceptance performed; Step 23E owns that. AdMob Privacy & messaging account setup is needed for device consent testing with the eventual configured app.
- Sonraki Step: Step 23C rewarded mission bonus (complete).

## Step 23A — Ads Service Boundary — Finalized (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] Step 23A committed as `5844e0e` (`feat: add ads service boundary`) on `step/23a-ads-service-boundary`, ff-only merged and pushed to `main`.
- Önemli Kararlar: AdsService autoload owns a small token-based rewarded lifecycle; reusable AdsBackend contract, no-op default, deterministic fake backend. No native types or UI references. Network-capable backends require an explicit requests-allowed gate, default false. Reward and close are independent; closed/failed/stale tokens cannot earn, duplicates are consumed once. An already-open ad retains its valid reward/close sequence after request permission is revoked. No Economy or persistence calls.
- Üretilen Sonuçlar: `project.godot`, four monetization scripts and `test/test_ads_service.gd` (+ Godot-generated .uid files). Full GUT: 525/525 tests, 7,669 assertions PASS. Godot 4.6.3 parser/editor and SDK-free project boot PASS; `git diff --check` PASS. `.godot/ads_service_focused.json` excluded. AGENTS/CLAUDE retain only the previously approved implementation-approval workflow addition; unrelated 23A monetization-policy text removed.
- Açık Sorunlar: Physical-device AdMob/UMP acceptance is deferred to Step 23E.
- Sonraki Step: Step 23B — Native AdMob SDK and consent work (complete).

## Final UI Consistency Sweep + Persistence Environment — Finalized (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] Approved LevelSelect BackButton minimum height changed from 56 to 64 px on `step/ui-final-consistency-sweep`, based on clean main `376d4ba`.
- Önemli Kararlar: Single scene-property adjustment aligns the 300 px Back button with ModeSelect/Leaderboard. Settings 42 px and Credits 36 px titles intentionally retained. User accepted sweep scope and waived screenshots. Persistence failures were execution-environment-only: sandbox denies `FileAccess.open(user://..., WRITE)` with error 12, both writers silently return, and reload reads defaults/stale data. The same temporary probe succeeds with authorized AppData access. No production persistence or test assertions changed; runtime semantics and reward table remain canonical.
- Üretilen Sonuçlar: Narrow reproduction used an ignored config with `dirs: []` and exactly two explicit test files: 19/24 PASS under sandbox; authorized user:// access yielded 24/24 PASS, 939 assertions. Related SaveData/AudioSettings/LoginStreak tests: 30/30 PASS, 75 assertions. Full GUT once after environment correction: 505/505 PASS, 7567 assertions, exit 0. LevelSelect parser/scene instantiate PASS; `git diff --check` PASS. Temporary probe and runner configs/logs are under ignored `.godot/`. Only tracked change is LevelSelect BackButton 300×56→300×64.
- Açık Sorunlar: Run persistence verification with authorized routine Godot AppData/user:// write access; a workspace log alone does not grant save-file access. Earlier premature full-suite run remains an acknowledged workflow error; root cause now resolved. No screenshots required.
- Git Finalization: Commit `2ceb63af2bab08d4adf9bd125d6199cff88a9d10` (`fix: restore ui persistence and finalize consistency sweep`) contains only `scenes/ui/LevelSelect.tscn`. Feature pushed; main safely fetched/updated and ff-only merged; main pushed. main/origin/main/local+remote feature refs match, ahead/behind 0/0, working tree clean. No stash mutation, squash/rebase/amend/force/merge commit/branch deletion.
- Sonraki Step: Step 23 — AdMob.

## MainMenu + Daily Reward Micro-Polish — Finalized (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] Tier-A menu spacing and reward timing pass, committed as `376d4ba`.
- Önemli Kararlar: MainMenu 2×2 hub shifts down 12 px after container layout completes. Daily Reward claimed hold changes from 1.0 s to 0.7 s; claim, economy and persistence behavior remain unchanged.
- Üretilen Sonuçlar: Parser/editor PASS; runtime layout probe confirms +12 px; focused Daily Reward GUT 13/13 PASS, 798 assertions; `git diff --check` PASS. Feature pushed and ff-only merged/pushed to main.
- Açık Sorunlar: Godot reports a Windows root certificate store error and shutdown resource warnings in this environment; parser and focused test runs completed successfully.
- Sonraki Step: Continue with the next approved UI task.
# PROGRESS.md — NoSpace: Arena

## Missions Variety — Verified, Git Finalization Blocked (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] Approved mission-family expansion, stateless date rotation and final capture-cell polish implemented and verified. Git publication pending.
- Önemli Kararlar: 14→21 definitions, 4→7 families. Stage 2/4/6 rewards 90/140/200 reuse win 1/2/3 tiers. Survival 30/60 seconds rewards 40/70 reuse areas_8/percent_80 tiers; thresholds approximate two/four perimeter traversals on the 64×110 reference grid at 0.045 seconds/cell (~15.5 seconds/lap). Completed runs 2/4 rewards 40/70 reuse those same easy/medium tiers; losses count, wins remain separate. Stage is one-based Endless only; survival is best existing game-time clock value per run. No new gameplay counter, reward amount, save schema or DailySeed arena algorithm.
- Üretilen Sonuçlar: Bounded date-seeded candidate selection on intervening epoch-days avoids both adjacent seeded anchor sets, prioritizing exact-set repeats, family-composition repeats and same-slot repeats without within-day category quotas. Tiny pools use a cyclic fallback. 370-day tests cover calendar boundaries, family coverage and same-day area+percent combinations. Captured neighboring area cells now merge visually and magenta frontier follows the actual captured boundary; percentage/Win designs retained. Focused GUT 32/32 PASS, 3418 assertions; full GUT ONCE 505/505 PASS, 7564 assertions; editor/parser, screenshot and diff-check PASS. Screenshot `.godot/missions_capture-polish-tr.png` (720×1280). Only existing Windows certificate-store/editor shutdown messages; no new project-caused errors.
- Açık Sorunlar: Automatic approval review rejected `git commit -m "feat: expand daily mission variety"`, citing earlier NO-commit instructions and no trusted visible user authorization for this exact commit. Explicit attachment approval was not accepted by the reviewer. 23 reviewed files remain staged; no commit, push, merge or stash mutation occurred.
- Sonraki Step: Obtain direct visible authorization for the blocked Git finalization on `step/ui-missions-native-progress`, then commit→feature push→safe main update→ff-only merge→main push. No code/test reruns needed absent new changes. HEAD/main/origin/main remain `e430fdd`.

## E5 Redirection — Finalized (2026-10-06)
- Son güncelleme: 2026-10-06
- Tamamlanan Steps: [x] UI Pass E5 — Settings-owned Legal reader and balanced MainMenu hub finalized.
- Önemli Kararlar: Legal notices remain under Settings. MainMenu hub destinations are Store, Missions, Leaderboard and How to Play; the corner help shortcut is removed. Daily Reward utility group shifted 75 px left; footer label removed.
- Üretilen Sonuçlar: Localized copyright footer and scrollable MIT/OFL/engine notices; Legal Back preserves the same Settings instance. Godot 4.6.3 project/editor scene scan completed; single 720×1280 MainMenu capture confirms the utility alignment. `git diff --check` passed. Commit `e430fdd fix: refine main menu utility alignment` pushed on `step/ui-e5-credits-polish`, ff-only merged to main and pushed. Main, origin/main and feature refs are equal; working tree clean.
- Açık Sorunlar: Android hardware Back/safe-area behavior remains for device verification. Godot reported a Windows root certificate store error during headless/runtime checks; the scene scan and explicit-log-file screenshot probe completed successfully.
- Sonraki Step: Step 23 — AdMob (per existing roadmap; plugin/export setup remains Tuğra-owned).

## E4 Visual Follow-Up Current Status (2026-10-05)
Commit `ba03b4f fix: scale daily reward hero presentation` was pushed on `fix/e4-reward-hero-scale`, ff-only merged to `main`, then main was pushed. Local/remote fix and main refs all equal `ba03b4faafba1906bc3e66a8366a0d3dbc14b274`, ahead/behind 0/0; working tree clean. Coin and all three canonical Store boost identities share a centered 128×128 hero slot, a large +amount/1× row and a 28 px localized reward name. Checkpoint tooltips removed; route status uses Day X/7 or Preview · Day Y/7. Economy/reward table, eligibility, persistence, cycle and current-day claim targeting are unchanged. Regression coverage includes stable hero/route layout across coin and boost previews, preview return, localized names, and no tooltip or Economy mutation. Godot 4.6.3 editor/parser boot PASS; focused Daily Reward GUT **13/13 tests, 798 assertions PASS**; full GUT **494/494 tests, 4134 assertions PASS**; final verification logs 0 warnings/errors. Real-render 720×1280 screenshots exist for Day 4 coin, Day 3 Slow Start, Day 5 Coin Bonus, Day 7 Extra Life, and preview state in TR/EN; popup content stays inside the viewport and the player profile fixture is unchanged. `git diff --check` PASS. AGENTS.md and matching CLAUDE.md routine Godot validation write policy updated locally; both remain excluded local-only work files. No history rewrite or stash mutation.

## E4 Current Status (2026-10-05)
Final publication: **`b236f0b feat: rework daily reward experience`** pushed to `step/ui-e4-daily-reward-polish`, ff-only merged to main, main pushed. Local main/origin/main/feature remote all equal; clean working tree, ahead/behind 0/0. No merge commit, force/squash/rebase/branch deletion or stash mutation. E4 complete; balance and existing UI accepted by user.
UI Pass E4 — Daily Reward System Rework, `step/ui-e4-daily-reward-polish`, baseline main/origin `924658a`. User approved the exact replacement schedule: **Day 1 50 coins; Day 2 75 coins; Day 3 1× Slow Start; Day 4 180 coins; Day 5 1× Coin Bonus; Day 6 225 coins; Day 7 1× Extra Life**. Boost-only days grant zero coins. Existing canonical boost IDs and charge persistence are reused; no conversion system or save migration. Eligibility, local epoch-day, missed/clock-back reset, Day 7→1 cycle and manual idempotent claim remain unchanged. MainMenu compact LEFT coin + n/7 entry, seven-node route, sticky today claim context, read-only past/future preview, same-day claimed reopen, claim animation and visible hold preserved. Final full GUT **493/493 PASS, 4013/4013 assertions, 0 failures/warnings/errors**; parser/editor, TR/EN, MainMenu/reward instantiate and diff-check PASS. Actual Economy bundle claims are tested against a separate fixture save for all seven days, boost increments/no extra coins, double claim, persistence, next-day/cycle/missed-day and non-mutating localized previews. Real 720×1280 coin/boost renders use only an in-memory profile. Balance approval resolved; final Git publication pending.

## E4 Initial Popup Snapshot (2026-10-05, superseded by system rework above)
UI Pass E4 — Daily Reward / Reward Popup Rework, `step/ui-e4-daily-reward-polish`, based on clean main/origin `924658a`. Canonical flow remains MANUAL CLAIM: Economy evaluates epoch-day/streak and persists currency/streak once on successful claim. Economy/LoginStreak/SaveStore unchanged. Removed the large Glass panel; popup presents production coin visual, real dominant +amount, localized coin/day text and clear Claim. Entrance 0.20 s; Claim disables immediately, consumes the actual Economy return once, pulses the coin 0.22 s, holds claimed feedback 1.0 s, then safely fades 0.16 s without freeing its signal owner. MainMenu currency refreshes from actual Economy balance; underlying menu context is subdued during the overlay and restored on dismissal, when the logo intro begins. Existing JuicyButton UI SFX/haptic reused. Full GUT **485/485 PASS, 3354 assertions, 0 failures/warnings/errors**; parser/editor boot and diff-check PASS. Tests cover manual presentation/no auto-claim, eligibility/same-day/next-day, duplicate taps, persistence fixture, visible hold/deferred dismissal, repeated lifecycle, TR/EN, real MainMenu currency refresh/context restore. Real-render Turkish 720×1280 screenshots `.godot/e4_reward_before_tr_720x1280.png` and `.godot/e4_reward_claimed_tr_720x1280.png` use an in-memory Day 4 / 125 reward fixture from the canonical table; no player save mutation. **MANUAL VISUAL ACCEPTANCE PENDING — no commit/push.**

## E3 Final Status (2026-10-05)
UI Pass E3 Settings Interaction Rework, `step/ui-e3-settings-polish`, manual visual acceptance PASS. Controls are three visible touch targets with procedural Swipe/Tap/D-pad icons and captured cyan selection; Mute has a clear compact ON/OFF target; Language is a single row opening a scrollable Auto/English/Türkçe list, with a synthetic ten-entry layout/scroll regression. All settings semantics, values/defaults, persistence, locale update, and MainMenu/Pause returns are preserved. Language Back returns to Settings, repeated opening retains one selector and one signal. Full GUT **481/481 PASS, 3308 assertions, 0 warnings/errors**; parser/editor, MainMenu runtime round-trip, Pause/lifecycle, TR/EN fit and diff-check PASS. Screenshots: `.godot/e3_interaction_settings_tr_720x1280.png`, `.godot/e3_interaction_language_tr_720x1280.png`. Commit `924658a feat: rework settings presentation` pushed to feature branch, ff-only merged to main, and main pushed; no merge commit.

## E3 Route-Selector Attempt (2026-10-05, visually rejected)
UI Pass E3 — Settings Visual Rework, `step/ui-e3-settings-polish`: the first clean-form attempt was visually rejected. Current uncommitted presentation is a compact NoSpace control console: three 10 px VOID/cyan captured-volume tracks with real percentage labels, magenta frontier and diamond handle; full-row inline mute state without a pill; Controls/Language use unenclosed route selectors with selected diamonds. AudioManager keys/defaults, volume/mute/control/language semantics, persistence, MainMenu/Pause return, fonts and global theme remain unchanged. Real Turkish 720×1280 screenshot: `.godot/e3_rework_settings_tr_720x1280.png` (local/ignored; language set only in memory for capture). Final full GUT **479/479 PASS, 3273 assertions, 0 warnings/errors**; parser/editor boot, MainMenu → Settings → Back runtime smoke, repeated paused Settings round-trip, TR/EN fit, and `git diff --check` PASS. **REWORK MANUAL VISUAL ACCEPTANCE PENDING — no commit/push.**

## E3 Initial Attempt (2026-10-04, visually rejected)
UI Pass E3 — Settings Polish, `step/ui-e3-settings-polish`: Settings presentation now uses one clean surface with restrained Audio/Controls/Language sections, VOID/cyan sliders with small diamond handles, a compact localized mute state, and shared segmented control/language choices. Existing AudioManager settings keys/defaults, volume/mute/control/language persistence, and MainMenu/Pause return behavior are unchanged. Added only presentation-local scripts and three minimal localization keys for Audio and On/Off. MainMenu → Settings → Back runtime navigation PASS; repeated Pause → Settings → Back remains paused. Full GUT **479/479 PASS, 3246 assertions, 0 warnings/errors**; parser/editor boot and `git diff --check` PASS. Turkish 720×1280 runtime screenshot: `.godot/e3_settings_tr_720x1280.png` (local/ignored; language was set in memory for the screenshot, no save mutation). **MANUAL VISUAL ACCEPTANCE PENDING — no commit/push.** Current main/origin baseline is `2b5c7f7` (E2 completed and merged); older E2 pending text below is a historical snapshot.

## E2 Final Status (2026-10-04)
UI Pass E2 Pause Redesign + Gameplay Mission HUD Cleanup was manually accepted and committed as `2b5c7f7 feat: rework pause and mission HUD`; the feature branch was pushed, ff-only merged to main, and main was pushed. Gameplay HUD shows only the procedural frontier/diamond icon and completed/active count. Pause preserves dimmed gameplay, primary Continue, and compact read-only real mission rows: partial = VOID/cyan track + magenta frontier/diamond; complete = one thin full cyan line; zero = VOID track only. Mission logic, rewards, economy, save, gameplay and core scripts did not change. Final E2 verification: **474/474 PASS, 3153 assertions, 0 warnings/errors**; parser/editor boot and diff-check PASS. Local screenshots: `.godot/e2_final_partial.png`, `.godot/e2_final_complete.png`.

## E1 Current Status (2026-10-04)
UI Pass E1 Results Screen Rework is complete and visually accepted. The compact 320x64 motif uses independent real 0-100 positions: cyan rectangular fill and diamond at achieved capture percentage, vertical magenta target marker at target percentage, VOID for the remainder. It preserves 32/50 and 74/70 semantics; win never invents 100%. Score remains numeric-first and stars/new-best/Next remain conditional real state. Endless results show the reached stage: authoritative `_current_stage` is zero-based and changes only when `_start_stage` begins the next stage, so presentation uses `_current_stage + 1` (first stage = 1; after transition = 2). Added localized `RESULT_STAGE_REACHED` (EN `Stage %d`, TR `Aşama %d`); Free, Daily and Campaign do not show it. Result/gameplay progression, save schema, navigation, and existing result actions are unchanged. Final GUT: 466/466, 3079 assertions, 0 warnings/errors; parser/editor boot and diff-check PASS. Screenshots: `.godot/e1_screenshots/results-progress-loss-32-50-tr.png` and `.godot/e1_screenshots/results-progress-win-74-70-tr.png`. Commit `22f838d` was pushed on `step/ui-e1-results-polish`, ff-only merged to main, and main was pushed.

## D3 Current Status (2026-10-03)
UI Pass D3 final readability/completion polish is implemented on `step/ui-d3-level-select-polish`; manual visual acceptance PASS. Completed checkpoints use a brighter muted captured-cyan fill; current remains dark with the strongest cyan frontier; locked remains muted. Metadata is 21 px, full localized descriptions are preserved, and final Level 8 is reachable above the fixed Back footer. Route geometry/order, unlocks, stars, persistence, navigation, and localization content are unchanged. Full GUT: 455/455, 3013 assertions; parser/editor boot and diff-check PASS. Screenshots: `.godot/d3_screenshots/level-select-final-start-tr.png` and `.godot/d3_screenshots/level-select-final-level8-tr.png`. Commit/push pending.

## Proje Bilgisi
- **Proje:** NoSpace: Arena — 2D mobil arcade (territory capture)
- **Motor:** Godot 4.6.x (GDScript, statik tipli)
- **Hedef:** Android + iOS yayın (Google Play & App Store)
- **Kanca:** Yaşayan Bölge + Günlük Seed/Ghost + estetik UI + ekonomi (draft → v1.1)
- **Başlangıç:** [STEP 01 TAMAMLANDIĞINDA DOLDUR]

## Son Güncelleme
2026-10-06 (**UI Pass E5 — Credits / Attributions Polish**, `step/ui-e5-credits-polish`, base `ba03b4f`, commit/push `e7e7ec3`):
Credits ekranı DynaPuff wordmark, Rubik bölüm başlıkları, Nunito Sans gövde metni ve küçük prosedürel cyan/magenta frontier motifiyle yapılandırıldı. Godot/GUT, font yazarları ve OFL/MIT atıfları, geliştirici/telif ve özgün ses bilgisi iki dilde gösteriliyor; 720×1280’de kaydırmasız, Back erişilebilir. MainMenu→Credits→MainMenu runtime smoke PASS; focused GUT **3/3, 38 assert**, full GUT **497/497, 4205 assert**, editor/parser ve diff-check PASS; final loglarda **0 warning/error**. Gerçek-render TR ekran `.godot/e5_credits_top.png`; içerik kısa olduğundan alt/scroll ekranı yok. **ATTRIBUTION REVIEW REQUIRED:** Godot Engine MIT metni/linki projede bulunmuyor; mevcut Credits yalnız lisans adını söylüyor. Yayın öncesi değerlendirilecek, bu pass'te hukuki metin uydurulmadı. Manuel görsel kabul bekliyor; feature branch push edildi, main'e merge edilmedi.

2026-10-05 (**E4 Visual Follow-Up — Reward Hero Scale**, `fix/e4-reward-hero-scale`, commit `ba03b4f`):
Shared 128×128 reward hero gives coin and boost awards equal space with a prominent `+amount`/`1×` and localized name. Tooltip removed; preview/day status and current claim target verified. **494/494 GUT, 4134 assertions; editor/parser, TR/EN 720×1280 renders, and diff-check PASS; 0 warnings/errors.** Branch pushed and ff-only merged; main pushed. AGENTS/CLAUDE validation permission updated locally and stay excluded. No history rewrite.

2026-10-05 (**UI Pass E4 — Approved Mixed Rewards / Final Verification**):
Exact approved Day 1–7 schedule activated; boost-only days grant no coins, real boost charges persist without schema changes. Today remains the claim target during previews; double claim/reopen and visible hold preserved. **493/493 PASS, 4013 assertions, 0 warning/error**, parser/editor and diff-check PASS. PROGRESS remains local-only; publication authorized by user.

2026-10-05 (**UI Pass E4 — Daily Reward System Rework**, `step/ui-e4-daily-reward-polish`, commit/push YOK):
Kompakt MainMenu coin+n/7 girişi, yedi checkpoint rotası, gerçek ödül önizlemesi ve aynı gün claim sonrası salt-okunur tekrar açma eklendi. Ödüller 50/75/100/125/150/200/300 coin; balance, eligibility/day boundary, cycle/missed-day, Economy ve save değişmedi. Claim tek kez; coin/ring/amount feedback, captured checkpoint ve gerçek currency refresh sonrası görünür hold korundu. **489/489 PASS, 3634 assertions, 0 warning/error**, parser/editor ve diff-check PASS. Beş Türkçe 720×1280 gerçek-render screenshot local/ignored; kullanıcı save'ine yazılmadı. **MANUEL KABUL BEKLİYOR.**

2026-10-05 (**UI Pass E4 — Daily Reward System / Balance Gate**, `step/ui-e4-daily-reward-polish`, commit/push YOK):
Sticky current-day claim targeting survives past/future previews; mixed reward specs can present real coin/boost data and apply a bundle atomically using existing boost/save fields. Empty boost and default coin overrides preserve current rewards. Full GUT **491/491 PASS, 3888 assertions, 0 warning/error**, parser/editor and diff-check PASS. Boost reward mix has no approved economy conversion; current coin table is untouched and commit/push awaits balance decision.

2026-10-05 (**UI Pass E4 — Daily Reward Popup**, `step/ui-e4-daily-reward-polish`, commit/push YOK):
Manual Claim korundu; generic Glass panel kaldırıldı. Gerçek coin/amount, restrained claim pulse, 1.0 s alındı beklemesi ve ertelenmiş fade-dismissal eklendi. Double tap input/state guard ile tek claim; Economy/save/day/streak semantics değişmedi. **485/485 PASS, 3354 assertion, 0 warning/error**, parser/editor ve diff-check PASS. İki gerçek-render Türkçe screenshot local/ignored fixture ile üretildi; kullanıcı save'ine yazılmadı. **MANUEL KABUL BEKLİYOR.**

2026-10-05 (**UI Pass E3 — Settings Interaction Rework**, `step/ui-e3-settings-polish`, commit/push/ff-only merge tamamlandı):
Kontrol yöntemleri açıklayıcı prosedürel ikonlarla kompakt seçim hedeflerine dönüştürüldü. Sessiz durumu görünür ON/OFF kontrolü; dil seçimi tek satırdan açılan scrollable liste. Yalnız mevcut üç dil production'da; synthetic 10-entry test scroll ve son satır erişimini doğruluyor. Audio/control/locale/persistence ve Pause/MainMenu return davranışı korundu. Manual visual acceptance PASS. **481/481 PASS, 3308 assertion, 0 warning/error**, parser/editor, runtime navigation ve diff-check PASS.

2026-10-05 (**UI Pass E3 — Settings Visual Rework**, `step/ui-e3-settings-polish`, commit/push YOK):
İlk generic settings-form görseli reddedildi; mevcut aday capture-style gerçek yüzdeli ses track'leri, magenta frontier/diamond, pill'siz inline mute ve kutusuz Controls/Language rota seçicileriyle yeniden kuruldu. Settings davranışı/persistence değişmedi. Full GUT **479/479 PASS, 3273 assertion, 0 warning/error**; parser/editör, MainMenu ve Pause dönüşleri, TR/EN containment, diff-check PASS. Türkçe 720×1280 ekran görüntüsü `.godot/e3_rework_settings_tr_720x1280.png`. **MANUEL GÖRSEL KABUL BEKLİYOR.**

2026-10-04 (**UI Pass E3 — Settings Polish**, `step/ui-e3-settings-polish`, commit/push YOK):
Tek yüzeyli Audio/Controls/Language hierarchy; cyan/VOID diamond sliders, compact localized mute, segmented choices. AudioManager/persistence/navigation semantics unchanged. Full GUT **479/479 PASS, 3246 assertions, 0 warning/error**; parser/editor boot, MainMenu → Settings → Back smoke, repeated paused round-trip and diff-check PASS. Türkçe 720×1280 screenshot `.godot/e3_settings_tr_720x1280.png`. **MANUAL VISUAL ACCEPTANCE BEKLİYOR.**

2026-10-04 (**UI Pass E2 — Pause Redesign + Mission HUD Cleanup**, `step/ui-e2-pause-mission-hud`, commit/push YOK):
HUD mission sentences removed in favor of a 65–80 px count; real objective/progress/completion moved into compact Pause presentation. Completed missions show an exact progress value and ✓ above a single thin full-width cyan line; partial keeps its magenta frontier/diamond, zero uses muted VOID only. Continue and Menu retain accepted sizes. Pause/Settings/Retry/Menu semantics and mission behavior unchanged. GUT **474/474, 3153 asserts, 0 warning/error**, editor boot and diff-check clean. Manual acceptance received; commit/merge now authorized.

2026-10-03 (**UI Pass D3 — LevelSelect Polish**, `step/ui-d3-level-select-polish`, commit/push YOK):
Mevcut 12-level winding Campaign route, level sırası, stars/unlock/save ve navigation korunarak
yalnız presentation katmanı düzenlendi. Node'lar 220×108'den 194×92'ye kompaktlaştı; seviye ve yıldız
tek satıra, açıklama ikinci satıra alındı. Completed node'lar sakin, sıradaki oynanabilir node cyan
frontier, locked node'lar muted görünür. Route connector'ları artık node merkezine kadar gitmez;
node yüzeyinden önce kesilir, daha ince ve düşük alpha ile secondary kalır. Level count/order,
path-node mapping, locked/completed/frontier hierarchy, scroll bounds ve TR/EN smoke için odaklı
regression eklendi. Türkçe 720×1280 mixed-state örneği `.godot/d3_screenshots/level-select-tr.png`
(local/ignored; kullanıcı save'ine yazılmadı). Full GUT **454/454 PASS, 2927 assert, 0 warning/error**;
parser/editor boot ve diff-check PASS. **MANUAL VISUAL ACCEPTANCE BEKLİYOR — commit/push YOK.**

2026-10-03 (**UI Pass D2 — all-time date-format correction**, `step/ui-d2-leaderboard-polish`, commit/push YOK):
Leaderboard tarihleri artık mevcut `YYYYMMDD` anahtarından her kayıt için tam yıl ile gösterilir:
TR `22 Haz 2026`, EN `Jun 22, 2026`. Bugün/Dün metinleri tarih yerine geçmez; gerçek bugünkü
kaydın diamond işareti korunur. Persistence/model ve skor sıralaması değişmedi. Aynı yıl,
önceki yıl, 31 Ara → 1 Oca sınırı ve TR/EN tam tarih-skor çakışmaması (720×1280) test edildi.
Full GUT **450/450 PASS, 2850 assert, 0 warning/error**; parser/editor boot ve diff-check PASS.
Manual visual acceptance **PASS**. Güncel D2 kuralı bu paragraftır; aşağıdaki kısa tarih/Bugün-Dün
anlatımı önceki çalışma snapshot'ıdır. Final commit/merge bu paragraftan sonra tamamlanacak.

2026-10-03 (**UI Pass D2 — Leaderboard Polish** — `step/ui-d2-leaderboard-polish`, commit/push YOK):
Daily leaderboard'ın score/date verisi, score-desc/date-desc sıralaması, `MAX_ROWS`, `best_ever`,
`LeaderboardStore` ve persistence korunarak yalnız view hiyerarşisi yenilendi. Önceki bütün satırlara
uygulanan cyan bordered rounded card kaldırıldı: gerçek #1 kaydı tek restrained gold-rail yüzeyi,
#2/#3 daha güçlü rank/score tipografisi, kalan kayıtlar flat liste. Mevcut "Tüm zamanların rekoru"
aynı gerçek `best_ever` verisiyle podium grubuna taşındı; bugün diamond'ı yalnız gerçek date==today
kaydı varsa çizilir. Boş state sahte kayıt üretmez. TR/EN 720×1280 yerleşim, score/date binding,
top3, tie-break, marker ve Back runtime hedefi doğrulandı. Türkçe gerçek-render 720×1280 örnek veri
görüntüsü `.godot/d2_screenshots/leaderboard-tr-fixture.png` (local/ignored; kullanıcı save'ine yazmadı).
Date-format edge case audit: `Leaderboard` key'i `YYYYMMDD` tam tarihi `to_dict()` içinde string olarak
saklıyor ve `from_dict()` ile geri yüklüyor; migration gerekmedi. Presentation artık current local
day/year (`SeedManager.compute_today`) ile karşılaştırıp EN `Jun 22` / `Jun 22, 2025`, TR `22 Haz` /
`22 Haz 2025` biçimini kullanır; Today/Yesterday yıl dönümü davranışı korunur. TR/EN previous-year
date column 720×1280'de score ile çakışmıyor; gerçek-render örnek görüntü
`.godot/d2_screenshots/leaderboard-tr-previous-year.png` (local/ignored). Same-year, previous-year,
Dec 31 → Jan 1 boundary ve date-column fit testleri eklendi. Final full GUT **455/455 PASS,
2846 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS.
**MANUAL VISUAL ACCEPTANCE BEKLİYOR — commit/push YOK.**

2026-10-03 (**UI Pass D1 — HowToPlay Final Polish** — `step/ui-d1-how-to-play-rework`):
Kabul edilmiş dört sayfalı Container düzeni korunarak capture freeze-frame'ine mevcut güvenli alandan
ayrışan daha açık cyan yeni ele geçirilen bölge eklendi; magenta U-trail, reconnect ipucu, diamond ve
kalan VOID görünür kaldı. Enemies sayfasında production daire/üçgen/döndürülmüş kare silüetleri korunup
yalnız o sayfadaki boyut/yerleşim iyileştirildi; tek canonical `HOWTO_ENEMIES_BODY` metni aynen kaldı.
Body satır aralığı ve Container minimum alanı TR/EN sayfalar arası art/progress sıçramasını azalttı;
Move ve Stay Alive kompozisyonları değiştirilmedi. Dört gerçek Türkçe 720×1280 PNG yenilendi
(`.godot/d1_screenshots/`, local/ignored). Yeni semantic-art, düşman ayrıklığı, body/close containment
ve yumuşak vertical-stability regressions ile full GUT **446/446, 2746 assert, 0 fail/warning/error**;
parser/editor boot ve diff-check PASS. Dört Türkçe sayfanın **MANUAL VISUAL ACCEPTANCE: PASS**.
Final verification aynı sonuçlarla tekrarlandı. Commit **e51687a feat: rework how-to-play tutorial**
feature branch'e normal push edildi, main'e ff-only merge edilip origin/main'e pushlandı;
üç ref aynı commit'te, working tree clean, ahead/behind 0/0. Merge commit/squash/rebase/force/branch
deletion yok; önceki stash'e dokunulmadı. PROGRESS local-only kalır.

2026-10-01 (**UI Pass D1 — HowToPlay Final Hard Reset** — `step/ui-d1-how-to-play-rework`, commit/push YOK):
İki reddedilen sunumun kök nedeni runtime ölçümüyle doğrulandı: önceki Art `0×350`, progress `0×34` idi;
ikisinin de horizontal SHRINK_CENTER flag'i vardı fakat minimum genişliği sıfırdı. Önceki visual subtree
tamamen değiştirildi: tek SafeMargin/MainVBox, küçük context, büyük Rubik page title, `540×350` art canvas
(`500×310` arena), azami 520 px copy, 220×28 native trail/diamond progress, ilişkili Back/Next row.
Tek `HowToPageArt` dört static gameplay freeze-frame çizer: capture'da cyan safe territory + kapanmaya
yaklaşan U-trail + diamond; move'da player/path/four-direction cues; enemies'te Bouncer circle, Chaser
triangle, captured edge Sparx square; lives'ta active trail'e değen enemy ve integrated hearts. Art geometry
her çizimde gerçek local `size` üzerinden hesaplanır. Dört gerçek Türkçe 720×1280 PNG Godot pencere
renderer'ından alındı ve görsel olarak kontrol edildi (`.godot/d1_screenshots/`, local/ignored).
TR/EN tüm sayfalar için art/progress minimum boyutu, 4 step, containment, vertical order ve non-overlap
regression eklendi. Got it ve X'in MainMenu hedefine gidişi runtime smoke ile doğrulandı. Localization
content, gameplay, controls, enemies, lives, economy/save, global theme/font/palette değişmedi.
Full GUT **446/446, 2718 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS.
**DÖRT TÜRKÇE SAYFA MANUAL VISUAL ACCEPTANCE BEKLİYOR — commit/push YOK.**

2026-09-30 (**UI Polish P1 — MainMenu Logo Trail One-Shot Animation** — `step/ui-p1-logo-trail-animation`, commit/push YOK):
Kabul edilmiş logo geometri/palette/stroke/placement değişmeden, `logo.gd` içinde local one-shot trail reveal
ekli: top-center → center → canonical diamond endpoint tam L yolu path-length bazlı 1.20 s Quad ease-out ile
çizilir; diamond aktif ucu iki segment boyunca kesintisiz izler. Finalde 0.18 s %7 settle ve kısa moving-tip /
diamond glow vardır; static finalde glow sıfırlanır. Logo artık kendi ready'sinde başlamaz: MainMenu popup yoksa
başlatır, Daily Reward varsa gerçek claim/dismiss path'inden sonra bir kez başlatır. Aynı Logo instance'ında
restart/loop yok; fresh MainMenu scene yeniden oluşursa bir kez tekrar oynar. Input/mouse_filter, navigation,
theme ve gameplay değişmedi. Regression final trail progress, full L continuity ve one-shot semantics'i kapsar.
Static final diamond halo guard'ı eklendi: intro tamamlanınca glow ve scale canonical olarak zorla sıfırlanır;
static draw path'i glow çizmez. Glow yalnız active magenta trail'in kısa afterimage segmentindedir; diamond'a
halo/aura/light-disc uygulanmaz. Full GUT **445/445, 2575 assert, 0 fail/warning/error**; parser/editor boot ve
diff-check PASS. **MANUAL VISUAL ACCEPTANCE BEKLİYOR — commit/push YOK.**

2026-09-30 (**UI Pass C2 — Store Rework** — `step/ui-c2-store-rework`, commit/push YOK):
Store'un tek uzun 9-offer listesi view-local focus sahibi showcase + 3-item selector mimarisine ayrıldı.
Her selector, preview/label/padding'i kapsayan tek flat hit target'tır; focus persist edilmez ve
Economy/SaveData/gameplay mutate etmez. Karakterlerde ortak beyaz player-diamond ile Pulse push, Drag slow-ring,
Halt freeze-ray motifleri hem showcase hem selector'da eşleşir. Arena preview'leri Void 64×110, Ember 56×120,
Frost 80×96 gerçek grid oranlarını uniform-fit korur; captured fill inner alt sınıra kadar gider, border en
son çizilir. Boost showcase/owned-count/repeat Buy grammar'ı korunur. Store refresh'i Economy signal emission
stack'i sonrasına `call_deferred` + pending flag ile ertelenir; böylece emitting Buy control/ancestor free edilmez.
Economy.purchase/buy_boost, selection IDs, persistence, prices, resources ve localization content değişmedi.
Store UI regression coverage category/focus/hit target/character motif/arena aspect/deferred refresh/localization
davranışını kapsar. Full GUT **443/443, 2564 assert, 0 fail/warning/error**; parser/editor boot PASS.
**TÜRKÇE MANUAL VISUAL + Buy lifecycle acceptance BEKLİYOR — commit/push YOK.**

2026-09-30 (**UI Pass C1 — Missions Rework FINAL** — `step/ui-c1-missions-rework`, commit/push YOK):
Accepted wide rounded territory geometry korunarak yalnız presentation polish yapıldı: bütün partial ve
complete state'lerde `current / goal` texti patch'in sabit merkezinde; fill/frontier oranına göre artık
yer değiştirmiyor. Reward coin 24→27 px, completion check 22→25 px oldu; reward amount fontu değişmedi.
List container'ın ilk grup mesafesi korunurken grup aralığı 76→96 px ile üçüncü mission aşağıya dengeli
dağıtıldı; Back, runtime mission behavior, localization, reward/claim, deterministic selection ve global
theme değişmedi. Stock ProgressBar tabanlı satırlar NoSpace territory-progress presentation ile değişti;
önceki runtime layout/autowrap overflow sorunu Container-owned strip lifecycle ile kapandı. Mission/meta/
economy behavior, automatic reward, deterministic catalog, save schema ve localization content değişmedi.
Full GUT **433/433, 2511 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS.
**MANUAL VISUAL ACCEPTANCE: PASS.** Commit `55e84f1 feat: rework missions progress UI` feature branch'e
normal push edildi, ardından main'e ff-only merge edilip origin/main'e pushlandı; branch korunuyor.

2026-09-30 (**UI Pass C1 Wide Rounded Layout Restore** — `step/ui-c1-missions-rework`, commit/push YOK):
Tall/square mini-arena experiment manual olarak reddedildi ve önceki wide rounded territory surface yönü
explicit ölçülerle geri yüklendi: 510×108 px, 20 px radius, title→ilk grup 74 px, grup arası 76 px.
Objective/reward/progress readable sizing ile korunur (22/20/18 px); 0/partial/complete görünümü,
localized runtime data binding, automatic claim/reward ve no-overlap lifecycle değişmedi. Full GUT
**433/433, 2511 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS. **Yeni TR 720×1280
screenshot hazır — MANUAL VISUAL ACCEPTANCE BEKLİYOR.**

2026-09-30 (**UI Pass C1 Use Real NoSpace Arena Grammar** — `step/ui-c1-missions-rework`, commit/push YOK):
Production `ArenaController` çizimi incelendi: tall rectangular void arena, cyan captured territory,
magenta active trail, bright head ve cyan polyline border. Mission presentation yalnız bu görsel grameri
miniature ölçekte yeniden kullanacak şekilde düzeltildi; önceki yatay/rounded patch kaldırıldı. Partial
mission ratio, hem width hem height büyüten sqrt-area fill ile görselleşir; active L trail + diamond ve
complete iç-check yalnız presentation’dır. Mission semantics, deterministic selection, reward/claim,
persistence, localization ve typography families korunur. Full GUT **433/433, 2511 assert, 0
fail/warning/error**; parser/editor boot ve diff-check PASS. **Yeni TR 720×1280 screenshot hazır —
MANUAL VISUAL ACCEPTANCE BEKLİYOR.**

2026-09-30 (**UI Pass C1 Final Visual Direction Correction** — `step/ui-c1-missions-rework`, commit/push YOK):
Arbitrary stepped territory silhouette kaldırıldı. Mission patch artık accepted NoSpace logo ailesiyle uyumlu
rounded mini-arena’dır: dark VOID interior, restrained cyan outer boundary; partial state sqrt-area mapping
ile hem X hem Y’de gerçek alan büyütür, kısa orthogonal L frontier + diamond içeride kalır. Complete state
tam cyan rounded arena ve iç check gösterir. Missions-local font hierarchy objective 24 px, reward 22 px,
progress 20 px olarak büyütüldü; production font aileleri/global theme değişmedi. Full GUT **433/433,
2511 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS. **Yeni TR 720×1280 screenshot
hazır — MANUAL VISUAL ACCEPTANCE BEKLİYOR.**

2026-09-30 (**UI Pass C1 Visual Direction Reset** — `step/ui-c1-missions-rework`, commit/push YOK):
Önceki yatay territory-strip yönü manual olarak reddedildi. Presentation yalnız yeniden kuruldu: her
mission container-owned header altında genuinely 2D, sabit authored arena silüeti kullanır. Partial
capture diagonal area clipping ile hem X hem Y boyunca büyür; frontier + diamond arena içindedir.
Complete state aynı silüeti tam cyan doldurur ve check arena içinde kalır. Üç obje spacing ile
lower-middle’a dağıtıldı; fake content/card eklenmedi. Mission behavior, deterministic selection,
reward/claim, save ve localization content değişmedi. Area coverage monotonic regression eklendi.
Full GUT **433/433, 2511 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS.
**Yeni TR 720×1280 screenshot hazır — MANUAL VISUAL ACCEPTANCE BEKLİYOR.**

2026-09-29 (**UI Pass C1 — Missions Rework** — `step/ui-c1-missions-rework`, commit/push YOK):
Missions ekranındaki runtime `Label + ProgressBar` satırları, günlük deterministic MissionService akışı
korunarak üç adet `MissionProgressStrip` ile değiştirildi. Her strip mevcut localized objective’i,
gerçek `current / goal`, reward ve completion state’ini gösterir: 0’da yalnız VOID; partial’da oranlı
cyan capture + magenta frontier + diamond; tamamlandığında full cyan + restrained check (manual claim
ima edilmez). MissionDef, selection/seed, advance/claim, automatic Economy reward, MissionStore ve
save schema değişmedi. List, üç real strip’e meaningful yükseklik vermek için genişletildi; card/glow
dashboard eklenmedi. 0/partial/complete binding, TR/EN template, reward ve üç runtime strip regression
ile full GUT **429/429, 2489 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS.
**MANUAL VISUAL ACCEPTANCE BEKLİYOR** — TR 720×1280 Missions screenshot istenecek.

**C1 Attempt 2 — diagnosed layout fix + territory patch:** İlk sürümün manual FAIL’i data değil,
strip parent width almadan yapılan wrapped-label layout’unun 258–316 px minimum height üretip sibling
strip’lere taşmasıydı. `MissionProgressStrip` artık Container-owned objective/reward header ile gerçek
width sonrası layout alır; focused regression, üç runtime strip’te objective/reward/patch containment,
sibling overlap yokluğu, resize ve uzun TR objective’i kapsar. Uzun 600×42 bar kaldırıldı: görünür cell
border’ı olmayan deterministic 6×3 serpentine traversal, 470×84 bounded 2D territory patch içinde
contiguous cyan capture, partial frontier+diamond, complete check ve exact numeric progress gösterir.
Mission behavior korunur. Full GUT **432/432, 2505 assert, 0 fail/warning/error**; parser/editor boot
ve diff-check PASS. **Yeni MANUAL VISUAL ACCEPTANCE BEKLİYOR**.

**C1 Territory Patch Visual Correction:** Görünür logical-cell/traversal çizgileri tamamen kaldırıldı.
Güncel patch, tüm görevlerde ortak kalan sabit asimetrik stepped 2D arena silüetidir; partial fill, gerçek
oranı polygon alanına göre bisection ile doldurur. Böylece tek parça cyan captured bölge, tek magenta
aktif boundary ve diamond görünür; complete state aynı silüetin tamamını cyan doldurur, frontier/diamond
göstermez. Exact `current / goal`, aktif boundary'nin ters tarafında konumlanır. Behavior, Mission data ve
reward/claim akışı değişmedi. Gerçek runtime **TR 720×1280** screenshot üretildi (bir partial, iki complete
state). Full GUT **432/432, 2505 assert, 0 fail/warning/error**; parser/editor boot ve diff-check PASS.
**MANUAL VISUAL ACCEPTANCE BEKLİYOR**.

2026-09-29 (**UI Pass B2 — ModeSelect Redesign** — commit `ed1b2fe`,
`step/ui-b2-mode-select-redesign` → **main ff-only merge + origin push**):
ModeSelect’in dört tekrar eden satırı, mevcut Daily / Free / Level-Endless / Campaign handler ve
SeedManager akışı korunarak tek 2×2 prosedürel seçim yüzeyine taşındı. B1 hub’ı tekrar
edilmedi: shared rounded boundary yalnız kesik ayraçlarla kullanılır; Daily L-route+diamond,
Free cyan captured frontier, Level escalating coral/magenta marks ve Campaign node path motifleri
ayrı `ModeSelectTileArt` presentation-only renderer’ında çizilir. UI’daki kanonik etiketler
**UI Pass B2 Endless Label Micro-Fix:** Level-Endless davranışını Campaign progression’dan açıkça
ayırmak için aynı mevcut `MENU_LEVEL` localization anahtarı EN `Endless`, TR `Sonsuz` oldu; mevcut
`Escalating difficulty` / `Gittikçe zorlaşır` açıklaması, `_start(SeedManager.Mode.LEVEL_ENDLESS)` ve
tile art/geometry/interactions değişmedi. Daily / Free / Campaign etiketleri aynen korundu.
BoostStrip owned detection, gizli-empty davranış, BoostIcon/count, arm toggle ve Economy wiring’i
korundu; hidden/owned presentation regression’ı eklendi. Full GUT **424/424, 2469 assert, 0
fail/warning/error**; parser/editor boot ve diff-check PASS. **MANUAL VISUAL ACCEPTANCE: PASS** —
2×2 surface, distinct mode motifs, secondary boost treatment ve Endless/Sonsuz semantics kabul edildi.

2026-09-29 (**UI Pass B1.1 — MainMenu Polish** — `step/ui-b1-main-menu-redesign`, commit/push YOK):
Mevcut top-right currency pill’e `BoostIcon`ın mevcut procedural gold coin çizimi küçük, input
almayan bir sol ikon olarak eklendi; mevcut localized currency label ve runtime balance kaynağı
korundu. Yeni container yalnız pill içi yerleşim içindir, ikinci bir currency panel değildir.
Merkez MainMenu compositing alanının üst margin’i 72 px yapılarak accepted hub yaklaşık 36 px aşağı
alındı; hub geometry/ikonları, Play CTA, logo, typography, footer ve navigation wiring değişmedi.
Currency TR/EN smoke ve navigation regression dahil full GUT **421/421, 2431 assert, 0
fail/warning/error**; parser/editor boot ve diff-check PASS. **MANUAL VISUAL ACCEPTANCE: PASS** —
coin pill, vertical rebalance ve uncluttered final MainMenu kabul edildi.

2026-09-28 (**UI Pass B1 — MainMenu Redesign** — `step/ui-b1-main-menu-redesign`, commit/push YOK):
MainMenu’daki dört ayrı Secondary button, mevcut `StoreButton` / `MissionsButton` /
`LeaderboardButton` / `CreditsButton` kimlikleri ve scene-change wiring’i korunarak tek, shared
rounded arena navigation hub’a taşındı. Her quadrant düz/şeffaf `JuicyButton` hit target’ı;
procedural Store coin, Missions L-frontier, Leaderboard rank-bars+diamond ve Credits info ikonuna
sahip. Global theme, palette, logo, A2 typography, gameplay, RNG ve destination screen’ler
değişmedi. A2 body/action-label rolüne uygun olarak hub etiketleri Nunito Sans’tır. Kısa menu
anahtarı `MENU_MISSIONS_SHORT` eklendi (EN `Missions`, TR `Görevler`); diğer mevcut anahtarlar
korundu. Parser/editor boot PASS; destination smoke + localization + touch-area regression dahil
full GUT **420/420, 2426 assert, 0 fail/warning/error**; diff-check temiz. TR/EN 720×1280
MainMenu görsel kabulü B1.1 ile birlikte **PASS**; final tekrar doğrulaması **421/421, 2431 assert,
0 fail/warning/error**.

2026-09-28 (**UI Pass A2 — Typography Finalization** — commit `91c61d2`,
`step/ui-a2-typography-proof` → **main ff-only merge + origin push**): DynaPuff yalnız NoSpace
brand wordmark (`wght≈600`), Rubik UI heading (`wght≈500`) ve Nunito Sans body/button/number
rolleri production’da kabul edildi. Store `MENU_STORE` ile yerelleştirildi (TR `Mağaza`, EN
`Store`). Final verification **417/417, 2377 assert, 0 warning/error**; manual + technical
acceptance PASS.

**Aşağıdaki A2 araştırma/proof notları tarihsel ara snapshot’tır; yukarıdaki final kayıt geçerlidir.**

2026-09-28 (**UI Pass A2 — Typography Finalization** — `step/ui-a2-typography-proof`, commit/push YOK):
manual comparison Candidate B (`Fredoka` + `Nunito Sans`) seçti; A/C reddedildi. Final
production integration **BLOCKED:** gerçek GUT `Font.has_char()` gate'i, indirilen resmi Fredoka
variable dosyasında `Ğ İ Ş ğ ş` glyphlerinin bulunmadığını kanıtladı (417 test: 416 pass, 1 fail;
2286/2291 assert). Dolayısıyla Godot fallback ile görünen metin production-safe kabul edilmez;
farklı font/asset kararını Tuğra vermeden B commit edilmez. Proof switch/code ve rejected assets
finalization sırasında kaldırıldı; tema B için hazırlanmış ancak test kırmızı olduğundan manual final
acceptance/commit bekliyor. **Recovery audit:** Google Fonts canonical variable dosyası ile
metadata'nın işaret ettiği resmi upstream `35c584f` commit'indeki Regular/Medium/SemiBold/Bold/Light
static TTF'lerinin tamamı aynı beş glyphi eksik. **Fredoka official builds do not satisfy Turkish
production glyph gate.** Fallback, başka aile veya test gevşetme uygulanmadı; typography kararı
yeniden açılmalı. Recovery proof: resmi Google Fonts Quicksand, Rubik ve Nunito variable
dosyaları gerçek `Font.has_char()` Türkçe/UI glyph gate'ini geçti. `TypographyDisplayProof`
yalnız MainMenu/Missions/Store Display/Heading rollerine D/E/F selector uygular; body/button/
numbers Nunito Sans olarak kalır. Full GUT **416/416, 2374 assert, 0 warning/error**;
parser/editor boot ve diff-check temiz. **Manual D/E/F screenshot comparison PENDING**;
final seçim yok, commit/push yok. Localization micro-fix: Store başlığı sahnede hardcoded
`Store` olduğu ve `store.gd` yalnız geri düğmesini yerelleştirdiği için Türkçede yanlış kalıyordu;
mevcut `MENU_STORE` anahtarına bağlandı (EN `Store`, TR `Mağaza`). Rubik (E) aktif aday olarak
geri seçildi. Full GUT **416/416, 2376 assert, 0 warning/error**; Store runtime smoke,
parser/editor boot ve diff-check temiz. Final Türkçe MainMenu/Missions/Store görsel kabulü
bekliyor; commit/push yok. Rubik weight tune: `NoSpace` variable `wght=600`; semantic
`Title` ve `Heading` rolleri `wght=500`; `Display`/ARENA ince secondary treatment olarak
değişmeden kaldı. Nunito Sans body/button/number rolleri, boyut, yerleşim, renk ve geometry
değişmedi. Full GUT yeniden **416/416, 2376 assert, 0 warning/error**; parser/editor boot,
MainMenu/Missions/Store instantiate ve diff-check temiz. Wordmark micro-proof: `NoSpace` Rubik
`wght=600` korunarak 9 px düşük-opaklıklı cyan outline kaldırıldı; solid cyan fill ve outline'sız
treatment benimsendi. ARENA, ikon, layout ve diğer typography rollerine dokunulmadı. Parser/editor
boot ve diff-check temiz. Wordmark brand-font micro-proof: yalnız `NoSpace`, resmi Google Fonts
DynaPuff variable asseti (`wght=600`) ile override edildi; solid cyan, outline/glow yok. Rubik
screen heading ve Nunito Sans body/button/number rollerine dokunulmadı. DynaPuff OFL + credits
eklendi; MainMenu headless instantiate PASS. **MANUAL TYPOGRAPHY ACCEPTANCE: PASS.** Final
production roles: DynaPuff yalnız `NoSpace` brand wordmark (`wght=600`); Rubik screen/section
headings (Title/Heading) ve korunan ince/spaced `ARENA` Display treatment; Nunito Sans body,
button ve number. Fredoka, resmi build'lerin Türkçe glyph gate'ini geçememesi nedeniyle reddedildi;
Quicksand ve Nunito display alternatifleri görsel proof sonrası reddedildi. Selector, proof code,
Quicksand/Nunito proof assets ve lisans/credits kayıtları kaldırıldı; production Rubik/DynaPuff/
Nunito Sans assets + OFL kayıtları korundu. Store localization `MENU_STORE` üzerinden (TR `Mağaza`,
EN `Store`) ve regression kapsamı korundu. Final GUT **417/417, 2377 assert, 0 warning/error**;
parser/editor boot, MainMenu/Missions/Store instantiate ve diff-check PASS. Final technical
acceptance/commit/push bekliyor.

2026-09-27 (**UI Pass A1 — Visual Foundation + Full Territory Logo** — commit `a70c1c9`,
`step/ui-a1-visual-foundation` → **main ff-only merge + origin push**): `ui_theme.tres` içine mevcut default
Button/Panel/PanelContainer/Label/ProgressBar stillerine dokunmadan opt-in semantic
`Passive` / `Frontier` / `Captured` / `Overlay` PanelContainer variation'ları eklendi.
Mevcut ekranlar henüz bu variation'lara migrate edilmedi; cross-screen redesign yok.
Procedural `logo.gd` Full Territory yönüne güncellendi: cyan ve coral captured alanlar
rounded arena'nın iç kenarlarını sampled quarter-circle arc ile takip eder; cyan'ın sağ
kenarı vertical frontier ile tam hizalıdır. Fills border altına ölçek-bağlı küçük overlap
ile girer ve border en son çizilir; seam yoktur. Magenta frontier, top-center → center → diamond
tek L-active trail'ine sadeleştirildi; small-menu okunabilirliği için magenta trail hafif
brightened ve stroke çok az kalınlaştırıldı; ikinci manual contrast ayarıyla bir kademe
daha belirginleştirildi. Void ve active-tip diamond saklandı.
Typography açıkça ERTELENDİ;
font/asset eklenmedi. Capture/grid/seed/ghost/economy/progression/gameplay değişmedi.
Headless MainMenu/logo/theme boot PASS; full GUT **414/414, 2110 assert, 0 warning**;
diff-check temiz. **Manual visual acceptance PASS:** cyan bottom-left ve coral top-right captured
territory temiz/tam dolu; top-left ile bottom-right VOID, L-shaped active trail ve diamond,
rounded silhouette korunuyor; seam veya A1 kaynaklı MainMenu layout değişikliği yok.

2026-09-26 (**Fix-Pass #29 — Project Settings Default Canonicalization** — commit `092b986`,
`fix/29-project-settings-canonicalization` → **main ff-only merge + origin push**): Godot 4.6
varsayılanlarıyla birebir aynı olan `audio/buses/default_bus_layout` ve
`internationalization/locale/fallback` redundant kayıtlardan kaldırıldı. Özel
`default_bus_layout.tres` (Master/SFX/Music) ve EN/TR translations korunur; `LocaleUtil.DEFAULT=en`
değişmedi. Canonical dosya ikinci headless editor açılışında değişmedi. Geçici runtime probe:
`ProjectSettings.save()=OK`, AudioServer Master/SFX/Music indexleri `0/1/2`; save sonrası diff değişmedi.
**414/414, 2110 assert, 0 warning; parser/boot ve diff-check temiz.**

2026-09-25 (**Fix-Pass #28 — Enemy Stuck Test Cleanup** — commit `082b580`,
`fix/28-enemy-stuck-test-cleanup` → **main ff-only merge + origin push**): `test_enemy_stuck_states.gd` containment testleri manual
`_physics_process()` akışında dört transient `CaptureBurst` sibling'ını test root'unda bırakıyordu;
production runtime leak kanıtı yok. Test-only `after_each()` bu `CPUParticles2D` node'larını explicit
temizler. Isolated GUT **18/18, 144 assert, 0 warning**; full GUT **414/414, 2110 assert, 0 warning**;
headless parser/boot ve `git diff --check` temiz. Production enemy/capture/movement kodu değişmedi.
**Assertion notu:** #28 öncesi temiz `2e90d8e` full-suite log'u da 2110 assert gösterir; #26'daki 2109
raporu stale'dir, cleanup diff'i assertion eklemez.

2026-09-25 (**Fix-Pass #27 — Godot Comment Indentation Normalization** — commit `2e90d8e`,
`fix/27-arena-comment-indentation` → **main ff-only merge + origin push**): Tekrarlayan `arena_controller.gd` dirty-tree farkı
Godot 4.6.3 headless editor açılışıyla deterministik olarak üretildi. Yalnız wrapped comment satırlarında
leading spaces → tabs normalizasyonu var; yorum metni ve gameplay code değişmedi. Normalized dosya ile ikinci
headless editor açılışı yeni bir diff üretmedi; parser/boot ve `git diff --check` temiz.

2026-09-25 (**Fix-Pass #26 — Free Near-Total Completion** — commit `4f437ed`,
`fix/26-free-mode-full-capture` → **main ff-only merge + origin push**): Eski Free hedefleri ArenaData'dan gelen Void 75 / Ember 70 /
Frost 80 idi; Daily ile shared oldukları için değiştirilmedi. Literal 100 danger-seed invariant nedeniyle
güvenilir değil. `BalanceConfig.free_completion_percent = 99.0` yalnız `Mode.FREE` için uygulanır;
CaptureGrid, Daily seed, ghost, Campaign ve Endless değişmez. **414/414, 2109 assert passed.**
**MANUAL ACCEPTED:** Frost run ~98% capture'a kadar doğrulandı ve near-total progression pratik bulundu;
exact 99% result-screen manual observation yapılmadı (boundary otomatik testte doğrulandı). Son küçük FREE
pocket'ta Sparx disappearance gözlendi; ayrı non-blocking observation, bu fix-pass'te enemy behavior değişmedi.

2026-09-25 (**Fix-Pass #25 — Endless late-curve test baseline** — commit `bca86c5`,
`fix/25-stage-plan-test-baseline` → **main ff-only merge + origin push**): Production progression bug
değildi: HUD Stage 9 correct count **5** ve Stage 8 baseline roster'ını korur. Monotonic test
`previous_count=0` ile yanlış başlıyordu; Stage 8 baseline initialization ile düzeltildi. Production
files değişmedi. **401/401, 2035 assert passed.**

2026-09-25 (**Fix-Pass #24 — Trail / Player Visual Sync** — `fix/24-trail-player-visual-sync`
branch'inde kodlandı, commit/push YOK): Gerçek CPU hitch kanıtlanmadı; logical trail'in visual Player'dan
yaklaşık bir hücre önde render edildiği CONFIRMED. Gameplay trail timing değişmedi; presentation-only
`TrailHeadLayer` forward/retract endpoint'ini çiziyor. CaptureGrid, determinism ve ghost değişmedi.
Yeni geometry/fallback testleri **8/8 passed**; #25 test-only baseline correction sonrası full GUT
**409/409, 2095 assert passed.** Manual acceptance **PASS**; hızlı uzun Swipe hissi kullanıcı tarafından iyi bulundu.

2026-09-25 (**Fix-Pass #23 — Capture Hitstop Tuning** — commit `7c2a5ce`,
`fix/23-capture-hitstop-tuning` → **main ff-only merge + origin push**): PC profiling büyük gerçek CPU hitch kanıtlamadı; capture pause'ın önemli kısmı intentional
60 ms hitstop olarak değerlendirildi. 40 ms ve 50 ms manual karşılaştırıldı; kullanıcı final olarak
**45 ms** tercih etti. Capture-only `HitStop.capture_duration` **0.06 → 0.045**; `scale_during=0.02`
değişmedi. Capture/grid, seed, ghost, progression ve enemy behavior değişmedi. **401/401, 2036 assert
passed. Manual acceptance PASS.**

2026-09-25 (**Fix-Pass #22 — Endless progression curve** — commit `167abc6`,
`fix/22-endless-progression-curve` → **main ff-only merge + origin push**): Eski Level-Endless eğrisinde Stage 2→3 arena + Chaser/Sparx + enemy bonus +
speed + target baskılarını tek geçişte yığıyordu. Çözüm: yalnız LEVEL_ENDLESS için data-driven **B1-R**;
Stage 1–8 authored, Stage 9+ Stage 8 baseline'ından relative anchored ramp. Arena `speed_mult`, yalnız
Endless enemy pace ekseninde normalize edilir; Free/Daily/Campaign mevcut davranışını korur. Late roster
ekleri Bouncer→Sparx, cap 2: maksimum 7 enemy. Capture/grid, seed, ghost, leaderboard, enemy behavior ve
#21 grace değişmedi. Yeni golden/handoff/cap/offset/determinizm testleriyle **401/401, 2036 assert passed**.
**MANUAL PARTIAL PASS / EARLY CURVE ACCEPTED:** Stage 1–6 oynandı; erken curve doğal bulundu, eski Stage 2→3
difficulty wall gözlenmedi; Stage 3 Chaser, Stage 4 Sparx ve Stage 6 Adaptive kabul edildi. **Stage 7–9 ve
high-stage progression DEFERRED** — later long-run / Android acceptance; count=7 performansı Android'de ayrıca
test edilecek. A4 Stage 5→6 bu yeni curve üzerinde yeniden denenmeli.

2026-09-25 (**Fix-Pass #21 — Endless stage start-grace** — commit `a4864fc`,
`fix/21-endless-stage-start-grace` → **main ff-only merge + origin push**): Acceptance sırasında varsayılan Void rotasyonunda Level-Endless **Stage 3 Frost**
başlangıcında oyuncu hiç hareket etmeden Sparx spawn-kill bulundu. Kök: `_advance_stage()` → `_start_stage()`
Player.setup ile oyuncuyu yeniden park `(0,0)` durumuna alıyor, fakat #18 start-grace yalnız run başlangıcı/
respawn'da rearm ediliyordu; önceki stage'in `_awaiting_first_move=false` durumu sızıyordu. Fix:
`_advance_stage()` içinde yeni stage kurulmadan HEMEN ÖNCE mevcut `_begin_grace(start_grace_duration)` rearm.
Sparx spawn/TELEGRAPH/PATROL/Chebyshev catch, capture/grid, seed/ghost, StagePlan ve balance resource
DEĞİŞMEDİ. Yeni GUT lifecycle regressions: Endless transition armed + gerçek hit can götürmez; ilk gerçek
grid adımı sonrası normal tehlike döner; tekrarlı transition eski state'i sızdırmaz. **395/395, 1817 assert
passed.** **Manuel kabul PASS:** Stage 3 Frost başlangıcında oyuncu hareketsizken Sparx artık can götürmüyor.
**A4 Stage 5→6** testi, ayrı progression balance bulgusu nedeniyle şimdilik ertelendi. Açık bulgu:
**Endless progression erken stage'lerde aşırı sıçramalı** — Stage 2→3'te arena + roster + enemy count + speed +
target aynı anda yükseliyor; ayrı bir balance pass planlanacak.)

2026-09-23 (**Codex'e devir öncesi son kontrol** — main @ 6250db3, origin senkron, working tree temiz,
açık/merge edilmemiş branch yok; #18/#19/#20 main'de ama hiçbiri henüz Tuğra tarafından oynanarak test
edilmedi):
- `AGENTS.md` oluşturuldu — CLAUDE.md'nin TAM (birebir) kopyası; Codex bundan sonra bu dosyayı okuyacak.
- **DÜZELTME (aynı oturum içinde):** Önce yanlışlıkla "CLAUDE.md/PROGRESS.md gerçek `.gitignore`'da değil,
  bu bir hijyen açığı" diye `.gitignore`'a üç dosyayı ekledim — **YANLIŞTI**. Tuğra düzeltti: bu BİLİNÇLİ
  bir tasarım. `.gitignore`'un KENDİSİ commit'lenir ve public repoda görünür; CLAUDE.md/PROGRESS.md'nin
  ADI bile orada listelenirse "gizli çalışma dosyası var" bilgisi public'e sızar. Doğru mekanizma
  `.git/info/exclude` — git'in kendisi tarafından hiç senkronize edilmeyen, yalnız lokal `.git/` klasöründe
  duran dosya; hem içerik hem isim tamamen gizli kalır. `.gitignore`'daki eklemem GERİ ALINDI;
  `.git/info/exclude`'a CLAUDE.md + AGENTS.md + PROGRESS.md + `.claude/settings.local.json` (ayrıca bu da
  aynı sebeple `.gitignore`'dan taşındı) eklendi. `git check-ignore -v` ile dördü de artık
  `.git/info/exclude`'dan çözümleniyor, teyit edildi. CLAUDE.md'nin "Bu Dosya Hakkında"/"İzin Politikası"/
  "Klasör Yapısı"/"Asla Commit Edilmeyecek Dosyalar" bölümleri bu doğru mekanizmayı anlatacak şekilde
  güncellendi (AGENTS.md yeniden senkronlandı — hâlâ birebir kopya). **Ders:** taze bir clone'da
  `.git/info/exclude` boş gelir — bu 4 satır manuel eklenmeli, `.gitignore`'a DEĞİL.
  **Commit + push edildi:** `6250db3` `chore: stop listing settings.local.json in the tracked gitignore`
  — tek dosyalık chore, branch'siz doğrudan main'e (CLAUDE.md kuralına uygun). origin senkron (0/0).
  GitHub'da `.gitignore` diff'i yalnızca 3 satır silme gösteriyor; CLAUDE.md/AGENTS.md/PROGRESS.md/
  settings.local.json adları hiçbir committed dosyada geçmiyor.
- "Aktif"/"Sırada" bölümleri netleştirildi (aşağıda): #18/#19/#20 durumu + açık denge/B4/Mobil Doğrulama
  soruları + olası #21 (Free skor avı) notu tek yerde toplandı.

Önceki: 2026-09-16 (**molasonrası durum tespiti + project.godot temizliği** — main @ 6dd75a7 `chore(export): enable
etc2/astc for android` (**push EDİLDİ** 2026-09-16, e46f7a0..6dd75a7 ff, force yok — origin senkron 0/0).
- Durum tespiti: #15/#16/gitignore hijyeni main'de teyit edildi; working tree'de editörün export sırasında
  yaptığı project.godot yeniden-yazımı vardı → düzeltildi: `import_etc2_astc=true` TUTULDU (Android export
  şartı), editörün sildiği `[audio] buses/default_bus_layout` + `locale/fallback="en"` açık yazılı GERİ KONDU.
  Commit diff'i = yalnız ETC2 satırı (+1). **334/334, 1506 assert.** Tree temiz; export artıkları
  (export_presets.cfg / android/ / export/ / NoSpace) ignored + untracked.
- Mobil doğrulama TODO netleştirildi (aşağıda, 5 test) — AÇIK, kullanıcı cihaz testi bekliyor.
- **#17 Feel-Pass P1 MAIN'DE** (a89c73f; step/feel-pass-p1 push → ff-only → main push, origin 0/0): feel P1-7
  düşman canlılığı + P1-11 unlock kutlaması + P1-12 kombo eskalasyonu — salt görsel, determinizm-değişmez
  testli. **349/349, 1580 assert.**

Önceki: 2026-07-21 (**#15 + #16 + gitignore hijyeni MAIN'DE** — main @ e46f7a0, origin senkron, lineer ff-only:
454b7ae perf(core) çekirdek flood → 8d67336 fix(mobile) → e46f7a0 chore(gitignore). **334/334 test.**
- **#15 ✅ VALİDE** (algoritma-sonuç sabit; 10/10 diferansiyel + bekçi; flood 40.6→3.7 / largest 54.5→4.3 ms).
- **#16 ⚠️ MAIN'DE ama MOBİL DOĞRULAMA BEKLİYOR** (valide iş güvene alındı; emülatör teyidi ertelendi —
  vakit yok). Kök KANITLANMADI: (a) slider drag mobilde çalışıyor mu — root IGNORE yetti mi yoksa
  `emulate_touch_from_mouse` A/B mi gerekli; (b) capture tık gitti mi — flash aktif-kama yetti mi yoksa
  `play()` akış-birleştirme mi gerekli. Zararsız hijyen + doğru yön; kesin çözüm teyide muhtaç.
- Export hijyeni: `export_presets.cfg`/`android/`/`/NoSpace` gitignore + CLAUDE.md'ye eklendi
  (keystore-şifre sızıntı riski, public repo). project.godot editör yeniden-yazımı geri alındı.
Sonraki: **Mobil Doğrulama** (aşağıda) → doğrulanınca #16 kapanır → cihaz checkpoint → Step 23 AdMob.)

### ⚠️ Mobil Doğrulama — BEKLİYOR (kullanıcı cihaz testi yapacak)
> **Bu bölüm KAPATILMAZ** — Tuğra cihaz/emülatör testini yapıp sonuçları getirene kadar açık kalır.
> Sonuçlar gelince her TEST'in yanına ✅/❌ + not düşülür; ❌ olanın hazır fix'i PLAN+onay ile uygulanır.

**Bağlam:** #16 (8d67336 — root mouse_filter IGNORE + flash aktif-kama) **main'de AMA kök KANITLANMADI** —
cihaz/emülatör teyidi bekliyor. #16 ancak TEST 1 + TEST 3 geçince kapanır.

**Kurulum (önkoşul):**
- **Export build ŞART** — editör önizlemesi GEÇMEZ (dokunma/perf/render yanıltıcı).
- Seçenek A: emülatör → Software graphics ile aç ("terminated" takılmasını aşmak için).
- Seçenek B: gerçek telefon → USB debug (one-click deploy) VEYA kablosuz APK kurulumu.

**TEST 1 — Ses slider (#16 BUG1):** Settings ▸ master/sfx/music barlarını PARMAKLA sürükle.
- ✅ Bar parmağı takip ediyor, ses değişiyor → root-IGNORE yetti → #16 BUG1 kapanır.
- ❌ Sürüklenmiyor / sadece tık → fix HAZIR: `input_devices/pointing/emulate_touch_from_mouse` OFF
  (platform-ayrımlı: masaüstünde açık, mobilde kapalı).

**TEST 2 — Her ekranda dokunma:** Store / ModeSelect / LevelSelect / HowToPlay (+ MainMenu, Missions,
Leaderboard, Credits) butonlarına dokun.
- ✅ Her buton ilk dokunuşta tepki veriyor (pop/haptic), ölü bölge yok, scroll'lu listeler kayıyor.
- ❌ Hangi ekran/buton tepkisiz → not düş (root IGNORE sonrası regresyon şüphesi).

**TEST 3 — Capture tık (#16 BUG2):** büyük kapatmalar yap — Void (büyük tek kapatma) + Frost/c06 (Sparx'lı).
- ✅ Kapatma anında takılma/"tık" yok → flash aktif-kama yetti → #16 BUG2 kapanır.
- ❌ Tık sürüyor → fix HAZIR: FlashLayer `play()` Dictionary gruplamasını kaldır + akış-birleştir
  (~14→~2 ms emülatör tahmini; salt görsel, invariant korunur).

**TEST 4 — Self-touch (adil ölüm):** swipe ile alana gir, çizerken kendi trail'ine bilerek değ.
- ✅ Ölüm tutarlı ve "haklı" hissettiriyor (değdiğin an, görünür temas); yanlışlıkla/erken ölüm yok.
- ❌ Değmeden ölüm, gecikmeli ölüm veya swipe yanlış yön → hangi kontrol şeması + ne oldu not düş.

**CİHAZ BULGULARI — 2026-09-16 (gerçek Android; TEŞHİS yapıldı, düzeltme YOK):**
> ⚠️ Önkoşul belirsiz: diskteki tek APK `export/nospace_arena.apk` **2026-07-08** (#15/#16 ve feel P1'den ÖNCE).
> Telefondaki build one-click deploy değilse #16 teyidi GEÇERSİZ — hangi build olduğu teyit edilmeli.
- **KESİN (2026-09-16, git A/B):** main 6dd75a7 worktree vs P1 çalışma ağacı — aynı deterministik harness
  (LivingTerritory'nin birebir aynası, Pulse efekti, 60 Hz) → **DIGEST BİREBİR AYNI** (70212baf…); P1 ağacında
  görsel `_process` koşuyor, HEAD'de yok. **İki bug da P1 ÖNCESİ main'de YENİDEN ÜRETİLDİ → P1 SUÇSUZ.**
  - Sparx: oyuncu çerçeve KÖŞE hücresinde (0,109) → Sparx (1,108)'den geçer, merkez 14.1 px (çizimler
    örtüşür: 9+8=17 px) ama Manhattan min=2 → **0 catch**. Kenar hücresinde (0,102) → Manhattan 1 → 1 catch.
    Köşe hücresi (ve Sparx'ın yalnız çapraz geçtiği her dışbükey köşe) **catch'e bağışık**.
  - Chaser: captured duvar arkasındaki oyuncuyla aynı sütundayken 180 karede **net 3.3 px** (yol 415 px =
    yerinde titreme); oyuncu sola gidince duvar boyunca x 20→5 takip; açık alanda hizalı kovalamada takılma
    YOK (300 px ilerledi) → takılmanın şartı hizalanma + ARADA captured bölge.
> **B1/B2/B3 → #18'de DÜZELTİLDİ ve MAIN'DE (9d61221, 2026-09-22): cihazda TEYİT BEKLİYOR.**
> B4 (capture tık) hâlâ AÇIK — ölçüm yapılmadı.
- **B1 Sparx öldürmedi:** P1 ilgisiz (catch mantığı `_grid_cell` + `_last_player_pos` okur; P1 yalnız çizim).
  Kök adayları: (a) catch = hücre **Manhattan ≤1** (çapraz komşu SAYILMAZ) + iki taraf da gecikmeli hücre
  okur (Sparx varılan hücre, oyuncu lerp'li pozisyon) — çizim ~2 hücre geniş (kare 18px, elmas 16px; hücre
  8-10px) → görsel temas ≠ hitbox; (b) `death_grace` sırasında yok sayılan catch yine `_catch_cd` 1.0s
  başlatır → grace bitince bitişik Sparx ~1s öldüremez; (c) TELEGRAPH 0.4s ölümsüz. Yön: hitbox'ı görselle
  hizala (Chebyshev ≤1 / `_step_to` + oyuncu `_grid_pos`) VEYA çizimi küçült; cd'yi yalnız kabul edilen
  catch'te başlat. Denge etkiler → onay gerekir.
- **B2 Chaser takıldı:** P1 ilgisiz. Homing exposed'da çalışıyor (LivingTerritory → decide). Kök: açgözlü
  düz-çizgi homing'in yerel minimumu — oyuncu captured duvarın arkasındaysa chaser duvara yapışıp
  teğet kayar (peel yalnız 0.18s; dik ayak noktasında teğet=0 → sekme/geri-homing döngüsü). 19a'nın
  tekrarı DEĞİL, bilinen sınır. İkincil: grace sırasında trail'e değen düşman `_advance` false → trail
  üzerinde DONAR. Yön: görüş-hattı yoksa roam/flow-field; grace'te trail'i duvar gibi yansıt.
- **B3 Pause-HUD çakışması:** yapısal (çözünürlükten bağımsız, 720 genişlik canvas_items). PauseButton
  sağ-üst x[W-84,W-16] y[16,84]; TopBar tam genişlik y[16,56], ScoreLabel sağa yaslı → aynı köşe.
  DailyLabel (y60-84 sağa yaslı) da altında. Yön: TopBar/DailyLabel offset_right ≈ -100 (buton+boşluk).
- **B4 Capture tık kalıntısı:** TEST 3 kısmen ❌. Adaylar (önem sırası): (1) Sparx arenalarında Sparx başına
  Dictionary `_flood_free_set(cols*rows)` — #15 DOKUNMADI, masaüstü 2-Sparx karesi 46.9 ms ölçülmüştü;
  (2) **tasarım gereği 60 ms hitstop** (`capture_duration`) cihazda "tık" okunabilir; (3) base `_draw`
  tam tarama; (4) FlashLayer `play()` Dictionary bucketing (hazır fix, muhtemelen en küçük kalem).
  Yön: önce ÖLÇ (Sparx'sız vs Sparx'lı arena; hitstop=0 A/B) → sonra en büyük kaleme fix.

**PC BULGULARI — 2026-09-22 (Tuğra, #19 working tree; TEŞHİS yapıldı, düzeltme YOK):**
> Kararlaştırıcı git A/B: aynı deterministik harness **a89c73f (#17) / 9d61221 (#18) / #19 working tree**
> üzerinde koşuldu. **Üçü de #17/#18/#19'dan GELMİYOR (H3'ün bir varyantı hariç).**
- **B5 (EN CİDDİ) — düşman CAPTURED alanın içinde kalıyor:** ÜÇ SÜRÜMDE DE BİREBİR (kök #17 öncesi).
  Zincir: (1) düşman TRAIL hücresine değer → `_advance` `hit_trail.emit()` + **`return false` → o kare HİÇ
  hareket etmez**; (2) oyun grace'teyse (`death_grace` veya #18 başlangıç grace'i) vuruş yok sayılır → düşman
  trail üstünde **her kare donar** (ölçüm: 60 karede 60 hit, **0.00 px** hareket); (3) oyuncu ilmeği kapatır →
  `close_and_capture` ÖNCE tüm TRAIL'i CAPTURED yapar, SONRA seed'leri süzer (`cell_at == FREE` olmayan seed
  DÜŞER) → donmuş düşmanın seed'i **düşer** → bölge seed'siz kalır → **düşman içinde kalarak dolar**
  (ölçüm: `seed_dropped=true`, `enemy_cell_state=CAPTURED`, **değişmez ihlali=1**). Kontrol: düşman trail'in
  YANINDA (FREE) iken seed korunuyor, ihlal yok.
  **Soluk renk = `_steered`** (efekt aktif, `lightened(0.5)`) — kapatma sonrası ölçümle doğrulandı
  (`steered=true`); "frozen" (Halt, neredeyse beyaz) veya #19 trail-hunt tint'i (trail rengine ısınma) DEĞİL.
  **#18 etkisi = SIKLIK:** start grace ilk adıma kadar TUTULDUĞU için pencere artık dalışın başına denk
  geliyor (#17'de death_grace ölüm anından itibaren sayıyordu, dalışta çoktan bitmişti). Kök değil, tetikleyici.
  **BEKÇİ DEĞİŞMEZ ÖNERİSİ:** "Hiçbir capture sonrasında hiçbir aktif düşman CAPTURED hücrede olamaz."
  **Yön:** (a) grace'te düşman trail'de donmasın — trail'i duvar gibi yansıtsın; (b) güvenlik ağı: seed
  hücresi FREE değilse en yakın FREE hücre seed yapılsın (orchestration; capture algoritması değişmez);
  (c) son çare: capture sonrası CAPTURED'da kalan düşmanı en yakın FREE hücreye taşı.
- **B6 — Sparx dar sütun cebinde kalıyor (c09):** kök = **trap kontrolü OLAY-TABANLI**. `on_capture_event`
  yalnız (i) bir capture olduğunda ve (ii) Sparx **PATROL** iken çalışır. Ölçümler: TELEGRAPH sırasında
  `wants_capture_events=false` → o capture Sparx'ı **ATLAR**; bağlantılı (tek hücre boşluklu) cepten
  duvar-takipçisi kendi kendine **çıkıyor** (`escaped=true`); sütun tek FREE bileşen olduğunda ve bir capture
  olayı geldiğinde `trap_pocket_max_cells=400` güvenliği **çalışıyor** (`trapped=true`, 191 hücre).
  Yani boşlukta kalan durum: **capture'lar arasında** cebe giren Sparx — yeni bir capture olmadan hiçbir şey
  yeniden bakmıyor; dar-döngü dedektörü de `loop_min_cells=24`'ü aşıyor (ölçüm: **191–344 farklı hücre**) →
  asla tetiklenmiyor. **Yön:** periyodik trap yeniden-kontrolü (ör. N saniyede bir) VEYA dar-döngü eşiğini
  "bölge ≤ trap_pocket_max_cells" ile birleştirip hücre eşiğini yükseltmek.
- **B7 — Chaser'lar captured kenarda gidip geliyor:** `reflect` büyüklüğü koruduğu için **donma YOK**
  (ölçüm: `min_speed=150.0` sabit). Eksen-kilidi: roam son hızı korur, hız eksene hizalı kaldıkça iki duvar
  arasında sonsuz sekme (ölçüm: 600 karenin **250'sinde** eksen-hizalı, x-aralığı 177 px).
  **Oyuncu GÜVENDEYKEN bu davranış üç sürümde de AYNI** (kök #17 öncesi).
  **Oyuncu ÇİZERKEN ve duvar arkasındayken** ise #17'de Chaser duvara yapışıyordu (x-aralığı **5.5 px**),
  #18/#19'da sekiyor (**177 px**) → bu varyant **#18'in bilinçli takası** (B2 fix'i: görüş yoksa roam).
  **Yön:** roam'a girerken hızı `base_speed`e normalize et + eksenle açı eşiğin altındaysa `_variation`'dan
  türetilen deterministik bir diyagonale çevir (RNG yok).

**TEST 5 — TR metin taşması:** Settings ▸ dil = Türkçe; tüm ekranları + HUD + sonuç paneli + popup'ları gez.
- ✅ Hiçbir metin buton/panel dışına taşmıyor, kesilmiyor, üst üste binmiyor.
- ❌ Taşan ekran + metin anahtarı/ekran görüntüsü not düş.

---

## Yol Haritası (Fazlar & Steps)

### Faz 0 — Temel
- [x] Step 01 — Proje kurulumu, klasör yapısı, git, test framework (GUT) (2026-06-14)

### Faz 1 — Çekirdek Mekanik
- [x] Step 02 — Arena & sınır hareketi (tek-parmak kontrol) (2026-06-15)
- [x] Step 03 — Çizgi çizme & alan kapatma algoritması (2026-06-15)
- [x] Step 03.1 — Seçilebilir kontrol sistemi + trail donma fix (2026-06-15)
- [x] Step 04 — Düşman & can sistemi (2026-06-15)
- [x] Step 05 — Skor, kombo & oyun döngüsü (2026-06-15)
- [x] Step 05.1 — Trail geri sarma + hareketsiz başlangıç (2026-06-15)

### Faz 2 — Kanca
- [x] Step 06 — "Yaşayan Bölge" mekaniği (Push efekti) (2026-06-15)
- [x] Step 07 — Karakter sistemi (Pulse/Drag/Halt) (2026-06-16)
- [x] Step 08 — Arena çeşitliliği & tema sistemi (Void/Ember/Frost) (2026-06-16)
- [x] Step 09 — Düşman türleri (Bouncer/Chaser, pluggable) (2026-06-16)
- [x] Step 10 — Günlük Seed sistemi (deterministik) (2026-06-16)
- [x] Step 11 — Ghost/replay + skor & yerel liderlik (2026-06-17)

### Faz 3 — Meta & Ekonomi
- [x] Step 12 — Kayıt/yükleme & ekonomi (soft currency) (2026-06-17)
- [x] Step 13 — Daily mission sistemi (2026-06-17)
- [x] Step 14 — Store & menü akışı (karakter/arena açma) (2026-06-17)
- [x] Step 14.1 — Günlük giriş ödülü (streak) (2026-06-17)
- [x] Step 14.2 — Run-içi pause + mission paneli (2026-06-17)

### Faz 4 — Cila & His
- [x] Step 15 — Art direction uygulaması (void-neon UI) (2026-06-17)
- [x] Step 16 — Juice & game feel (shake, hitstop, partikül) (2026-06-18)
- [x] Step 17 — Ses & müzik & haptic (2026-06-19)

### Faz 5 — Oynanış Derinliği
- [x] Step 18 — Level-Endless (stage ramp; Daily/Free tek-arena) (2026-06-19)
- [x] Step 19 — Düşman çeşitliliği & sertlik (Chaser overlap + Sparx) (2026-06-23)
- [x] Step 20 — Boost / power-up (coin sink: Extra Life / Coin Bonus / Slow Start) (2026-06-23)
- [x] Step 21 — Level-Campaign (sonlu level + unlock + seç UI) (2026-07-02)

### Faz 6 — Lokalizasyon & Monetizasyon
- [x] Step 22 — Lokalizasyon altyapısı (tüm string'ler key'li, TAM TR, dil seçici) (2026-07-04)
- [ ] Step 23 — AdMob entegrasyonu (rewarded + interstitial)
- [ ] Step 24 — IAP entegrasyonu (remove ads, currency, kozmetik)

### Faz 7 — Yayın
- [ ] Step 25 — Android export & cihaz testi
- [ ] Step 26 — Çeviri pass'i (10 dil)
- [ ] Step 27 — iOS export & App Store hazırlık
- [ ] Step 28 — Mağaza listeleme & yayın (çok-dilli; ASO, gizlilik, submission)

---

## Step Detayları

### Step 01 — Proje kurulumu
**Durum:** TAMAMLANDI — 2026-06-14 — commit 5dd13eb
**İçerik:**
- Godot 4.6.x ile yeni proje, dikey (portrait) mobil ayarı
- CLAUDE.md'deki klasör yapısını birebir oluştur (boş `.gdkeep` ile)
- Git init, `.gitignore` (CLAUDE.md, PROGRESS.md, `.godot/`, export/, keystore, ad_ids)
- README.md başlangıç + LICENSE (all-rights-reserved / proprietary —
  telif: Tuğra Hekimoğlu, 2026; repo PUBLIC olduğu için açık lisans DEĞİL)
- GUT addon kurulumu, örnek bir geçen test
- Autoload iskeletleri (boş): GameState, Economy, AudioManager, SeedManager
- İlk commit (CLAUDE.md ve PROGRESS.md OLMADAN)
- Remote bağla + ilk push (Tuğra onayıyla):
  `git remote add origin https://github.com/tugrahek/nospace_arena.git`
  → `git branch -M main` → `git push -u origin main`

**Doğrulama:**
- Proje hatasız açılıyor, boş sahne çalışıyor
- `git ls-files` çıktısında CLAUDE.md / PROGRESS.md YOK
- GUT örnek testi geçiyor
- Klasör yapısı CLAUDE.md ile birebir eşleşiyor
- `origin` doğru repoya bağlı, `main` push edildi, GitHub'da görünüyor
- GitHub'da gizli dosya YOK (CLAUDE.md, PROGRESS.md, keystore, ID dosyaları)

### Step 02 — Arena & sınır hareketi
**Durum:** TAMAMLANDI — 2026-06-15 — commit c480b5e
**İçerik:**
- `BorderMath` (scripts/core/border_math.gd): t∈[0,1) parametrik sınır matematiği — position_at, nearest_t, advance, perimeter
- `ArenaController` (scripts/gameplay/arena_controller.gd): void arka plan + neon çerçeve _draw() ile
- `Player` (scripts/gameplay/player.gd): tek-parmak dokunma (sol/sağ yarı) + klavye (A/D/ok) yön kontrolü
- `game.gd` (scripts/core/game.gd): Arena → Player.setup() bağlantısı, Camera2D 360×640 merkezli
- `Game.tscn` (scenes/main/), `Arena.tscn` + `Player.tscn` (scenes/gameplay/)
- project.godot: main_scene ve void clear color (derin indigo) eklendi
- GUT: 12/12 test geçti (BorderMath)

**Doğrulama:**
- GUT headless: 12/12 passed
- Tuğra editörde F5 ile oynar, aşağıdaki Test Listesi'ni uygular

### Step 03 — Çizgi çizme & alan kapatma algoritması
**Durum:** TAMAMLANDI — 2026-06-15
**İçerik:**
- `CaptureGrid` (scripts/core/capture_grid.gd, RefCounted): saf grid mantığı —
  init_frame, add_trail_cell/lay_trail, close_and_capture (4-komşuluk flood-fill),
  captured_percent, world_to_cell/cell_to_world. Hücre: FREE/CAPTURED/TRAIL.
- `CaptureResult` (scripts/core/capture_result.gd): kapatma sonucu datası.
- Kapatma kuralı: trail iç alanı böler; tehlike (düşman/Step 04) içermeyen bölge
  ele geçirilir. Düşman yokken: en büyük boş bileşen "tehlike tarafı", gerisi alınır.
- `ArenaController`: grid'i sahiplenir, captured/trail/çerçeveyi _draw ile render eder
  (satır-run birleştirme). `area_captured`/`capture_failed` sinyalleri.
- `Player`: grid hareketi + çizim + kapanma tetikleme (Step 02'den evrim).

**Doğrulama (GUT):** 12/12 capture testi geçti — bilinen şekil yüzdeleri, çoklu
bölge, açık seed komplementi, self-intersection reddi, dejenere durum, %100,
determinizm (aynı girdi → aynı sonuç), yüzde sınırları.

### Step 03.1 — Seçilebilir kontrol sistemi + trail donma fix
**Durum:** TAMAMLANDI — 2026-06-15
**İçerik:**
- Pluggable kontrol mimarisi: `ControlScheme` (temel) + 3 şema (TapTurn/Swipe/Dpad).
  Girdi ↔ hareket ayrı; tek hareket mantığı, şema sadece "istenen yön" üretir.
  `auto_advance` bayrağı iki modeli kapsar (boşta auto=devam, hold=dur).
- Klavye daima hold ve öncelikli. `1/2/3` dev toggle ile runtime şema değişimi.
- `emulate_touch_from_mouse=true` → masaüstünde fareyle touch testi.
- `DpadView` (scripts/ui): d-pad neon görseli, sadece d-pad aktifken.
- Trail/sınır engelinde yön korunur → donma yok, anında steer (ölüm Step 04).
- Varsayılanlar (playtest sonrası): move_interval=0.04 (~250 px/s), control_scheme=SWIPE.

**Doğrulama (GUT):** 9/9 kontrol testi (saf eşleme: rotate, vector_to_dir,
pos_to_dir, dpad center). Toplam 33/33 test geçiyor, headless boot temiz.

### Step 04 — Düşman & can sistemi
**Durum:** TAMAMLANDI — 2026-06-15
**İçerik:**
- `Enemy` (scripts/gameplay/enemy.gd): void'de sürekli-uzay sekme; CAPTURED/sınır
  duvar (yansıma), TRAIL ölümcül (`hit_trail`). Alt-adımlı hareket → tünelleme yok.
- `EnemyMotion` (saf): eksen-bazlı yansıma + deterministik başlangıç hızı (RNG yok).
- `GameState`: can/durum mantığı (start_run, lose_life, is_playing, reset);
  mevcut sinyaller korundu (game_started, game_over, life_lost).
- `BalanceConfig` + `config/balance.tres`: start_lives=3, enemy_speed=180, enemy_count=1.
- Capture entegrasyonu: Player `loop_closed` yayar → Game düşman hücrelerini
  `close_capture(enemy_cells)`'e geçirir (düşman bölgesi serbest kalır).
- Can kaybı akışı: fail_trail + player.respawn (güvenli hücreye) + lose_life;
  0'da game over (donma + placeholder etiket). Dev `R` ile restart.

**Doğrulama (GUT):** 7 enemy (yansıma, deterministik hız) + 5 game_state (can
azalma, 0-altı koruma, game_over, reset). Toplam 45/45, headless boot temiz.

### Step 05 — Skor, kombo & oyun döngüsü
**Durum:** TAMAMLANDI — 2026-06-15
**İçerik:**
- `ScoreKeeper` (scripts/meta/score_keeper.gd, RefCounted): saf skor mantığı —
  combo_window içinde ardışık kapatma → combo artar (x2, x3…); pencere kaçarsa 0 reset.
  Zaman dışarıdan enjekte edilir (test deterministik, runtime Time.get_ticks_msec).
- `GameState` genişletti: WON durumu, `register_capture`/`win_run`/`get_score`/`get_combo`;
  sinyaller: `run_won(final_score)`, `score_changed(score, combo)`. lose_life artık gerçek
  skoru game_over sinyaline ekliyor. start_run base_points + combo_window alıyor.
- `BalanceConfig` + `config/balance.tres`: target_percent=75, base_points=10, combo_window=2.0.
- `HUD` (scenes/ui/HUD.tscn + scripts/ui/hud.gd, CanvasLayer, layer=2):
  - Üst bar: Can / % / Skor (tr() anahtarlarıyla)
  - ComboLabel: combo > 0 iken "Kombo xN" gösterir
  - ResultPanel: koyu overlay + KAZANDIN!/OYUN BİTTİ başlığı + skor + TEKRAR butonu
  - Tüm güncellemeler GameState sinyalleriyle (sinyal tabanlı, gevşek bağlı)
- `locale/translations.csv`: CSV tabanlı tr() anahtarları (HUD_LIVES, HUD_SCORE, HUD_COMBO,
  RESULT_WIN, RESULT_LOSE, RESULT_RETRY). Not: .po yerine CSV tercih edildi — çalışma
  zamanında fragile değil, headless import ile düzgün yükleniyor.
- `game.gd`: _on_area_captured → HUD.update_percent + GameState.register_capture + win kontrol;
  TEKRAR → reload_current_scene (R dev kısayolu korundu). _game_over_label kaldırıldı.
- project.godot: [internationalization] bölümü eklendi.

**Doğrulama (GUT):** 54/54 passed (önceki 45 + 5 ScoreKeeper + 4 GameState).

### Step 06 — "Yaşayan Bölge" mekaniği
**Durum:** TAMAMLANDI — 2026-06-15 (efekt = PUSH, proximity tabanlı)
**İçerik:**
- `TerritoryEffect` (scripts/core/territory_effect.gd, Resource base): no-op sanal
  `compute_velocity`. Karakterler (Step 07) ve diğer efektler alt-sınıflar.
- `PushEffect` (scripts/core/push_effect.gd, path-extends base, class_name): ele geçirilen
  iç bölgeye `push_radius` içinde yaklaşan düşmanı uzağa saptırır. **Hız büyüklüğü korunur,
  sadece yön döner** → mevcut bounce invaryantı bozulmaz. @export push_radius, push_max_turn_deg.
- `PushMotion` (scripts/gameplay/push_motion.gd, RefCounted, SAF): strength_for (gradient
  0..1) + steer (büyüklük-koruyan yön döndürme). EnemyMotion gibi izole → GUT testable.
- `LivingTerritory` (scripts/gameplay/living_territory.gd, Node): arena + enemy listesini
  bilir (gevşek bağlı; tersi değil). process_priority=-10 → düşmandan ÖNCE çalışır.
  _physics_process'te her düşmana effect uygular. effect/arena null → no-op.
- `config/default_territory.tres`: PushEffect, push_radius=80, push_max_turn_deg=8 (güçlü).
- `ArenaController.is_player_captured(cell)`: CAPTURED **ve** dış halkada değil. **Dış-çerçeve
  tuzağını çözer** — efekt sadece oyuncunun kapattığı iç bölgeden yayılır, başlangıç sınırından değil.
- `Enemy`: apply_territory (kendi velocity'sini günceller, kapsülleme korunur) + _steered bayrağı
  + GEÇİCİ debug tint (efekt aktifken açık ton — Step 16'te kalkacak).
- `game.gd`: _spawn_enemies sonrası _living_territory.setup(arena, enemies).

**Doğrulama (GUT):** 9 push_motion testi (strength gradient kenar/orta/radius/guard;
steer büyüklük-koruma, zero-strength, yön, zero-velocity). Toplam 64/64, headless boot
temiz (ana sahne 40 frame hatasız, @export effect PushEffect'i kabul etti).

### Step 07 — Karakter sistemi
**Durum:** TAMAMLANDI — 2026-06-16
**İçerik:**
- TerritoryEffect arayüzü **iki-hook'a genelleştirildi**: `steer` (kalıcı yön) +
  `speed_scale` (geçici hız çarpanı). Slow'un compounding bug'ını (hız her kare
  çürür) bu ayrım çözer. Push davranışı değişmedi (compute_velocity → steer).
- 3 etki (hepsi proximity, deterministik, ortak `nearest_player_captured`):
  - `PushEffect` (steer dışa) — Pulse karakteri
  - `SlowEffect` (speed_scale gradient) — Drag karakteri
  - `StasisEffect` (TEMAS tetikleyici) — Halt karakteri. Yakınlık alanı/dwell YOK:
    düşman PLAYER-captured bölgeye çarpıp bounce'ladığı AN donar (freeze_duration=0.12s,
    playtest'te kısa tutuldu — kıstırma exploit'i yok), sonra freeze_cooldown=0.5s re-freeze
    engeli (boundary jitter perma-lock'u önler).
    `contact_freeze_duration`/`contact_freeze_cooldown` hook'ları. Düşman freeze sonrası
    bounce'layıp uzaklaşır. Üç eksen: Push=yön, Drag=hız, Halt=zaman(temas).
  - `SlowEffect` (Drag): slow_factor=0.55 (çekirdek ~0.45x) + min_scale=0.40 TABAN +
    slow_radius=55 (alan daraltıldı, yavaşlama yakında başlar). slow_scale=maxf(scale_for,min_scale).
- `TerritoryMotion` (eski PushMotion rename): saf math — strength_for, scale_for,
  steer (target_dir genelleştirildi), is_frozen (stasis ritmi). EnemyMotion gibi
  izole, GUT testable. (tangent/aligned_tangent Orbit ile birlikte kaldırıldı.)
- Temas modeli: `speed_scale(world_pos, arena)` (dwell kaldırıldı) + `contact_freeze_duration/
  cooldown`. Enemy `_freeze_timer` (sabit fizik adımı azalımı) bounce anında set edilir,
  yalnız `is_player_captured` hücrede (border'da değil → boş arenada efekt YOK). Ghost-safe.
- `CharacterData` (Resource): id, display_name_key (locale), accent_color, effect,
  unlock_cost (Step 14 için rezerve, 0=ücretsiz). 3 .tres: char_pulse/drag/orbit.
- `ArenaController.nearest_player_captured`: ortak proximity tarama (push_effect'ten
  çıkarıldı, 3 etki paylaşır). is_player_captured (dış-halka dışla) korunur.
- `GameState.selected_character_index` (int, scene reload'da korunur; yeni autoload YOK).
- `game.gd`: 3 karakteri preload eder; `_apply_character` etkisini + accent glow rengini
  uygular; dev tuşu `C` döngüsel canlı geçiş (UI Step 14).
- `Enemy.apply_territory`: iki hook + `_speed_scale` (move'da çarpılır) + debug tint.
- **Radius-aware bounce** (enemy.gd): CAPTURED çarpışması gövdenin ÖN KENARINI
  (merkez + radius*yön) yoklar ve `EnemyMotion.clamp_to_wall` ile merkezi duvar
  yüzünden en az `radius` uzakta tutar → gövde captured glow'una HİÇ binmez.
  TRAIL ölümcüllüğü merkez tabanlı kaldı (zorluk değişmedi). Halt radius 80→45.
- **Oyun dili İngilizce yapıldı**: locale CSV İngilizce'ye çevrildi (Lives/Score/Combo,
  YOU WIN!/GAME OVER/RETRY, Pulse/Drag/Halt), fallback "en". Türkçe altyapı kalıyor.

**Doğrulama (GUT):** territory_motion (strength/scale gradient, steer büyüklük-koruma+yön,
slow_scale floor), enemy_motion (reflect + clamp_to_wall radius-aware bounce), territory_effects
(contact_freeze: Push/Drag=0, Halt=0.12 via .tres load). Toplam 82/82. Geçici locale testi
tr()→İngilizce + CHAR_HALT doğrulandı (silindi). Ana sahne temiz boot.

**Tuned değerler (config/*_territory.tres, playtest sonrası):**
- Pulse (default_territory.tres): push_radius=80, push_max_turn_deg=8 (script default).
- Drag (slow_territory.tres): slow_radius=55, slow_factor=0.55, min_scale=0.40.
  → GÜNCELLEME (2026-07-03, 0cf9099 "softer Drag slow"): slow_factor=**0.4**, min_scale=**0.6**
  (güncel kaynak: config/slow_territory.tres — buradaki eski sayılar tarihsel kayıt).
- Halt (stasis_territory.tres): freeze_duration=0.12, freeze_cooldown=0.5.
- Not: editör .tres'lerden script-default'una eşit değerleri çıkarır (dosyada görünmez ama etkin).

### Step 08 — Arena çeşitliliği & tema sistemi
**Durum:** TAMAMLANDI — 2026-06-16
**İçerik:**
- `ArenaData` (scripts/meta/arena_data.gd, Resource): mantıksal grid (cols/rows),
  ThemeData ref, zorluk (enemy_count, enemy_speed_cells [GRID-bazlı, cells/s],
  target_percent), unlock_cost (Step 14 rezerve). İçerik = .tres, kod değil.
- `ThemeData` (scripts/meta/theme_data.gd, Resource): palet (void/border/trail/enemy/
  captured_base + border_width). Saf `color_contrast` (luminance). Karakter accent
  glow tema ÜSTÜNE biner (kompoze): tema ortamı, karakter kimliği.
- `ArenaCatalog` (scripts/meta/arena_catalog.gd, RefCounted, SAF): `select(count,seed)=
  posmod(seed,count)` (deterministik, RNG yok) + `compute_fit(cols,rows,play_rect)`
  (fit-to-rect: en büyük tam cell_size, ortalı). Dev döngü + Step 10 seed aynı yol.
- `ArenaController.configure(data, play_rect)`: fit-to-rect boyutlandırma + tema renkleri
  + grid rebuild. `_ready` yalnız configure edilmemişse default kurar (fallback).
- 3 arena (resources/arenas): Void (64×110, 1 düşman 18 c/s, %75), Ember (56×120 dar-uzun,
  2 düşman 16 c/s, %70), Frost (80×96 geniş-kaba, 1 düşman 22 c/s, %80). 3 tema eşli.
- `game.gd`: ARENAS preload + PLAY_RECT sabit; `_apply_arena` (catalog→configure, _ready
  ilk iş, player'dan ÖNCE); enemy px/s = enemy_speed_cells × cell_size; düşman rengi
  temadan; win arena target_percent'i. Dev tuşu `V` arena döngüsü (reload — boyut değişir).
- `GameState.selected_arena_index` + `set_arena` (yeni autoload YOK; reload'da korunur).
- BalanceConfig sadece global (start_lives, base_points, combo_window); enemy/target arenadan.

**Doğrulama (GUT):** arena_catalog (select determinizm/modulo/negatif/guard + compute_fit
default/ortalama/sığma), theme_readability (color_contrast + 3 tema enemy/trail/border ve
3 karakter glow'u void'e karşı eşik>0.25 kontrast), arena_data (3 arena load/geçerli/distinct).
Toplam 95/95. Ana sahne temiz boot (Arena: Void uygulanıyor).

### Step 09 — Düşman Türleri (pluggable, deterministik)
**Durum:** TAMAMLANDI — 2026-06-16
**İçerik:**
- Strateji pattern (ControlScheme/TerritoryEffect ile tutarlı): `EnemyBehavior` (Resource,
  base=identity) + `BouncerBehavior` (heading korur, bounce S04) + `ChaserBehavior`
  (DURUM-FARKINDA stalker: oyuncu YALNIZ exposed iken (free'de trail çizerken) homing
  yapar; güvenliyken roam eder — bouncer gibi). decide(…, player_exposed: bool, …) saf,
  RNG yok. Kök çözüm: hedef açık alandayken duvar-kampı imkânsız (eski orbit/SLIDE silindi).
- `EnemyType` (Resource): behavior ref + base_speed_cells + shape (CIRCLE/TRIANGLE
  placeholder — renk arena temasından). config/behaviors/{bouncer,chaser}.tres +
  resources/enemies/type_{bouncer,chaser}.tres.
- **Pipeline SIRA düzeltmesi:** behavior.decide → effect.steer → speed_scale →
  collision/contact-freeze. Efektler tüm türlere otomatik uygulanır. LivingTerritory
  orkestratör (player ref alır, prio -10): her frame base=enemy.decide_velocity(player_pos),
  sonra enemy.apply_territory(effect, arena, base). steer/speed_scale mantığı KORUNDU.
- `ArenaData`: flat enemy_count/enemy_speed_cells → `enemies: Array[EnemyType]`
  (instance-listesi) + `speed_mult`. Final cells/s = type.base_speed_cells × speed_mult,
  px/s = ×cell_size. Void=[bouncer], Ember=[bouncer,bouncer], Frost=[chaser].
- `Enemy`: behavior + base_speed + decide_velocity + shape; _draw daire/üçgen.
- `Player.is_exposed()` (= _is_drawing) → living_territory her frame decide'a `player_exposed`
  geçirir. Geçiş: güvenli→exposed homing başlar, exposed→güvenli roam. Tüm collision REFLECT
  (orbit/SLIDE kaldırıldı — state-aware kök çözümle gereksiz).
- **Halt × Chaser fix (güvenlik ağı):** post-freeze recovery penceresi (recovery_time=0.18s,
  EnemyMotion.is_behavior_suppressed) — donma sonrası kısa süre decide bastırılır, reflected
  hızla açılır. State-aware ile kamp zaten imkânsız; recovery savunma amaçlı kaldı.
- `BalanceConfig` sadeleşti: enemy_speed/enemy_count/target_percent kaldırıldı (arenadan).
- **Regresyon:** Bouncer × Push/Drag/Halt eskisiyle birebir aynı (base=identity → steer(base)
  = eski steer(_velocity)); yeni davranış yalnız Chaser. Patroller ertelendi (mimari hazır).

**Doğrulama (GUT):** enemy_behavior (base identity, bouncer player-state'i yok sayar, chaser
exposed=true homing yön/büyüklük & exposed=false roam, same-pos guard, determinizm),
arena_data (kompozisyon load/geçerli/behavior null değil), enemy_motion (is_behavior_suppressed
freeze/recovery). Toplam 104/104. Ana sahne temiz boot.

- **Not (2026-07-03, audit P0 / P1-7 kararı):** Territory efektleri (Push/Drag/Halt) **Sparx'a
  İŞLEMEZ — BİLİNÇLİ tasarım.** Sparx grid-kilitli kenar yürüyücüsüdür; itme/yavaşlatma/dondurma
  serbest-uzay hareketine aittir, edge-follow doğasına aykırıdır. Yukarıdaki "efektler tüm türlere
  otomatik uygulanır" ifadesi ALAN düşmanları (Bouncer/Chaser) için geçerlidir; Sparx muaf.
  How-to metni (HOWTO_ENEMIES_BODY) bu istisnayı oyuncuya da söyler.

### Step 10 — Günlük Seed sistemi
**Durum:** TAMAMLANDI — 2026-06-16
**İçerik:**
- `DailySeed` (scripts/meta/daily_seed.gd, SAF): `seed_for_date(y,m,d)` (YYYYMMDD),
  `derive(seed,salt)` (32-bit MASKELİ integer hash — cross-platform/sürüm tutarlı,
  overflow/işaret yok), `to_index(seed,salt,count)`, `dir_index(seed,enemy_index)`.
  RNG YOK; Godot RNG kullanılmadı (platform-bağımsız + test edilebilir).
- `SeedManager` (mevcut autoload dolduruldu — YENİ autoload yok): `daily_seed`, `is_daily`,
  `compute_today()` (Time.get_date_dict_from_system → seed_for_date; tek impure nokta),
  `enter/exit/toggle_daily`, `daily_seed_ready` sinyali (Step 11 ghost/leaderboard için hazır).
- Daily mod: arena + **karakter** + düşman ilk yönleri **seed'den** (herkese aynı; karakter
  unlock'tan bağımsız sağlanır). Pozisyonlar merkez sabit. Free-play: oyuncu indeksleri (C/V).
  game.gd `_apply_arena/_apply_character` `persist` parametresiyle daily'de free-play
  seçimini EZMEZ. Dev tuşu `G` daily toggle (reload); daily modda C/V devre dışı.
- `EnemyMotion.start_velocity_seeded(dir_index, speed)` (seed-seçili yön; free-play start_velocity korunur).
- **HUD DAILY rozeti** (minimal): daily modda "DAILY • YYYY-MM-DD" (DailySeed.date_string, locale
  HUD_DAILY), üst marjda sağ-hizalı (arena sınırına binmez), free-play'de gizli. Step 14 tam ekran.
- **DEV gün önizleme:** SeedManager.day_offset (0=gerçek bugün) + advance_day(); dev tuşu `H`
  daily modda sonraki günün challenge'ı (offset'li tarih unix ile, ay/yıl rollover doğru).
  Badge tarihi offset'i yansıtır → gün-gün varyasyon önizlenebilir. Determinizm korunur (saf hash).

**Doğrulama (GUT):** daily_seed (seed_for_date golden=20260616, derive determinizm/salt-farkı/
32-bit, to_index aralık+guard+determinizm, dir_index aralık+determinizm, farklı tarih→farklı seed,
**golden regresyon**: seed 20260616 → arena 0 / char 0 / dir0 2 / dir1 0; date_string golden).
Toplam 116/116, temiz boot. HUD_DAILY locale çözümü geçici testle doğrulandı.

### Step 11 — Ghost/replay + skor & yerel liderlik
**Durum:** TAMAMLANDI — 2026-06-17
**İçerik:**
- `GhostTrack` (scripts/meta, SAF): kare-başına player pozisyon örneği; position_at_frame
  (clamp), to_array/from_array (JSON için düz). Ghost = KAYITLI-YOL (resimülasyon değil).
- `Leaderboard` (scripts/meta, SAF): gün(date/seed) → {best score, ghost track}. submit
  (strictly-greater → yeni best), best_score/-1, best_track, **prune_tracks(keep_recent)**
  (eski günlerin track'i budanır, skor kalır → sınırsız büyüme yok), to_dict/from_dict.
- `LeaderboardStore` (scripts/meta, IO ince): user://leaderboard.json yükle/kaydet; bozuk/
  eksik JSON → boş Leaderboard (güvenli). Kaydederken prune_tracks(KEEP=5). Yeni autoload YOK.
- `Ghost` (scripts/gameplay, Node2D): yarı-saydam, etkileşimsiz; kare-indeksli oynatma,
  bitince gizlenir. Kod-spawn (Game.tscn değişmez).
- Entegrasyon (game.gd, YALNIZ daily): run başı leaderboard yükle + bugünün best_track'i
  varsa Ghost oynat + BEST göster; her fizik karesi player pozisyonu kaydet; run bitişi
  (run_won/game_over) submit → yeni best ise persist + BEST güncelle. Free-play: kayıt/ghost/persist YOK.
- HUD: daily modda "BEST: N" (sol üst marj; locale HUD_BEST).

**Doğrulama (GUT):** ghost_track (empty, add/length, clamp ±, array round-trip), leaderboard
(ilk best, düşük red, yüksek günceller, eşit red, -1 bilinmeyen, best_track, date bağımsız,
prune eski-track-boş/skor-kalır, dict round-trip). Toplam 129/129, temiz boot. (IO impure →
test edilmez; serileştirme saf test edilir.) HUD_BEST locale geçici testle doğrulandı.

### Step 12 — Kayıt/yükleme & ekonomi
**Durum:** TAMAMLANDI — 2026-06-17
**İçerik:**
- `SaveData` (scripts/meta, SAF): currency + unlocked {kind→[id]}. earn (negatif yok),
  spend (yetersiz/negatif → false, **negatif bakiye imkânsız**), can_afford, unlock
  (idempotent), is_unlocked, new_default (Pulse+Void açık), to_dict/from_dict.
- `SaveStore` (scripts/meta, IO ince): user://save.json yükle/kaydet; yok/bozuk →
  new_default (güvenli). Step 11 store deseni.
- `Economy` (mevcut autoload DOLDURULDU — yeni autoload yok): SaveData'yı sahiplenir,
  _ready'de yükler, her mutasyonda otomatik kaydeder; balance/earn/spend/can_afford +
  is_unlocked/unlock; currency_changed + unlocks_changed sinyalleri.
- Run ödülü (PLACEHOLDER): run bitişinde `Economy.earn(score / RUN_REWARD_DIVISOR)` (=100,
  game.gd sabiti — magic number yok); gerçek ekonomi Step 13 mission'lar. Free-play + daily.
- Dev bakiye göstergesi: HUD sol-alt "Coins: N" (Economy.currency_changed; locale HUD_CURRENCY).
  Gerçek currency UI Step 13/14.
- GATING YOK: is_unlocked/unlock veri modeli hazır; selection/satın-alma Step 13. Daily
  unlock-bağımsız (Step 10) korunur. Leaderboard (Step 11) ayrı dosya, dokunulmadı.

**Doğrulama (GUT):** save_data (new_default açıkları, earn/negatif-yok, spend başarı/yetersiz/
negatif-red, can_afford, unlock idempotent+is_unlocked, round-trip currency+unlocks). Toplam
138/138, temiz boot. HUD_CURRENCY locale doğrulandı. (IO impure → test edilmez.)

### Step 13 — Daily mission sistemi
**Durum:** TAMAMLANDI — 2026-06-17
**İçerik:**
- `MissionDef` (scripts/meta, Resource): id, description_key (locale template), goal_type
  (REACH_SCORE/REACH_PERCENT/TOTAL_AREAS/WIN_RUNS), goal_amount, reward. Havuz: 14 .tres
  (çeşitli eşik/değer → günler arası çeşitlilik; aynı gün herkese aynı 3).
- `Mission` (scripts/meta, SAF): def + progress + claimed. advance(stats) — REACH_*→max,
  TOTAL_AREAS/WIN_RUNS→kümülatif; **progress goal_amount'a clamp** (display 3/3, 5/3 yok);
  is_complete; **claim() idempotent (çift ödül YOK)**; to_dict/apply_dict.
- `MissionCatalog` (scripts/meta, SAF): pick_daily(pool, seed, count) — DailySeed ile
  deterministik distinct indeksler (herkese aynı 3 günlük mission).
- `MissionStore` (scripts/meta, IO ince): user://missions.json {date, progress}; farklı
  tarih → boş (yenilendi); bozuk → boş (güvenli); yalnız bugünün ilerlemesi (eski budanır).
- Entegrasyon (game.gd): _setup_missions (compute_today seed → 3 mission + kayıtlı ilerleme;
  her run sayılır — free-play + daily). Run sonu _update_missions: advance(stats:
  score/percent/areas/won) → yeni tamamlananlar claim → Economy.earn (bir kez) → kaydet.
  Placeholder run-ödülü (score/RUN_REWARD_DIVISOR) KALDIRILDI — missions tek kaynak.
- Minimal HUD: bugünün 3 mission'ı "desc  progress/goal ✓" (sol üst, placeholder; locale
  MISSION_* template %d/%%). Tam panel Step 14.

**Doğrulama (GUT):** mission (advance her goal_type max/kümülatif, **progress goal'a clamp**,
is_complete, claim bir-kez+incomplete=0, dict round-trip), mission_catalog (count/distinct/
range/determinizm/clamp/boş). Toplam 152/152, temiz boot. Mission locale format ("Capture 80%")
doğrulandı. (IO impure → test edilmez.)

### Step 14 — Store & menü akışı
**Durum:** TAMAMLANDI — 2026-06-17
**İçerik:**
- `MainMenu.tscn` (yeni main_scene): Oyna (free-play), Günlük (enter_daily), Store, Künye.
  Aktif loadout + Coins + bugünün 3 mission'ı (read-only) gösterir.
- `Store.tscn`: karakter+arena listesi (kod-üretimli satırlar). Açık+seçili="Selected";
  açık="Seç"→Economy.set_selected; kilitli="Satın Al (cost)"→Economy.purchase (yeterli
  para → spend+unlock; yetersiz → disabled). currency/unlocks sinyalleriyle anında yenilenir.
- `Credits.tscn`: künye (telif + lisans notu; docs/credits.md iskelet).
- `ContentCatalog` (yeni, merkezi): CHARACTERS/ARENAS/MISSIONS + id→index (game/store/menü paylaşır).
- `MissionService.build` (saf): pool+seed+saved → today's missions (game + menü ortak).
- `Storefront.can_purchase` (saf): kilitli+affordable. `Economy.purchase` (spend+unlock) +
  selected_character/arena id (SaveData'da kalıcı) + getter/setter.
- `SaveData`: selected_character_id/selected_arena_id (default pulse/void) + round-trip.
- game.gd: free-play loadout **Economy.selected**'ten (yalnız açık olan); result panel'e
  Menü butonu. Dev tuşları (C/V/G/H/R) **OS.is_debug_build() guard'ı** (release'de kapalı).
  *(Not 2026-07-04: player.gd 1/2/3 şema tuşları o zaman guard'sız kalmıştı — audit P0 paketinde
  (Fix-Pass #9 / P1-9) aynı guard'a alındı; iddia artık tüm dev tuşları için doğru.)*
  GameState'ten selected_*_index/set_* KALDIRILDI (Economy/SaveData kaynak).
- İlk-pas maliyetler: Pulse/Void 0; Drag 300, Halt 400; Ember 500, Frost 700. (Tuğra dengeler.)

**Doğrulama (GUT):** storefront (can_purchase: kilitli+affordable/exact/açık/yetersiz/negatif),
save_data (default+round-trip selection). Toplam 159/159. MainMenu boot + **4 sahne instantiate**
(MainMenu/Store/Credits/Game @onready+_ready) geçici testle doğrulandı (bir tip-uyuşmazlığı
yakalanıp düzeltildi: MissionService.build → Array[Mission]).

### Step 14.1 — Günlük Giriş Ödülü (Streak)
**Durum:** TAMAMLANDI — 2026-06-17
**İçerik:**
- `EpochDay` (scripts/meta, SAF): `from_date(y,m,d)` → epoch-day (1970'ten gün sayısı,
  proleptik Gregoryen). Streak'in "ardışık gün"ü için DOĞRU (YYYYMMDD +1 ay/yıl sınırında
  bozuk; epoch-day değil). Golden + ay/yıl/leap sınır testleri.
- `LoginStreak` (scripts/meta, SAF): `evaluate(today_epoch, last_epoch, streak, table)` →
  {claimable, reward, new_streak}. İlk giriş→1; aynı gün→claimable false (çift claim yok);
  ardışık→++ (7→loop 1); kaçırma/saat-geri→1. Tam testable.
- `SaveData`: last_claim_epoch_day(-1) + streak_day(0) + round-trip.
- `SeedManager.today_epoch()`: epoch-day + dev day_offset (H ile streak test edilir).
- `Economy`: LOGIN_REWARDS [50,75,100,125,150,200,300] + login_reward_status() +
  claim_login_reward() (idempotent: aynı gün 2. çağrı 0) + login_reward_claimed sinyali.
- `MainMenu`: girişte claimable ise "Daily Reward — Day X/7  +N" popup + Claim → earn.
  Fonksiyonel scaffold; cila Step 15. Roadmap: decimal 14.1 (renumber yok).

**Doğrulama (GUT):** epoch_day (anchor 1970-01-01=0, ardışık fark=1, ay/yıl/leap/non-leap
sınırı), login_streak (ilk/aynı-gün/ardışık/kaçırma/7-loop/reward-lookup/saat-geri), save_data
(streak default+round-trip), reward locale ("Day 3/7  +100"). Toplam 175/175, 4-sahne
instantiate (popup dahil) + boot temiz.

### Step 14.2 — Run-içi Pause + Mission Paneli
**Durum:** TAMAMLANDI — 2026-06-17
**İçerik:**
- `PauseOverlay` (scenes/ui + script, CanvasLayer, **process_mode=ALWAYS**): sağ-üst pause
  butonu (≥64px) + overlay (Devam/Yeniden/Menüye Dön). Esc **çift yönlü toggle** (ALWAYS
  node → hem duraklat hem devam). `get_tree().paused` ile durdurma. pause() yalnız
  is_playing() iken (result-panel/zaten-pause'da no-op). restart→reload, menu→MainMenu.
- **Auto-pause:** `_notification` APPLICATION_PAUSED + WM_WINDOW_FOCUS_OUT → pause (resume
  MANUEL; daily'de sen bakmazken run ilerlemesin). game.gd PauseOverlay sinyallerini bağlar.
- **Menüye Dön (mid-run)** = run TERK: submit/earn YOK; paused=false sahne değişiminde garanti.
- **Determinizm:** pause fizik karelerini dondurur → game._physics_process (ghost kaydı) durur
  → resume aynı state'ten; ghost/daily bozulmaz (kare-sayım testiyle doğrulandı).
- `Missions.tscn` + script: MainMenu→Missions butonu; 3 günlük mission read-only (açıklama +
  ProgressBar + ödül + ✓; MissionService ortak). Auto-claim (Step 13) korunur; HUD mini-liste kalır.
- Fonksiyonel scaffold; görsel cila Step 15 (bu ekranları da stiller).

**Doğrulama (GUT):** pause (overlay toggle çift yönlü; **pause'da ghost kaydı durur** =
determinizm), 6-sahne instantiate (PauseOverlay/Missions + güncel Game/MainMenu, @onready+
_ready). Toplam 177/177, temiz boot. (Auto-pause/his/APPLICATION_PAUSED → Tuğra playtest.)

### Step 15 — Art direction uygulaması (void-neon UI)
**Durum:** TAMAMLANDI (scaffold) — 2026-06-17 — Tuğra his/görsel ayarı bekliyor
**İçerik:**
- `PaletteData` (scripts/meta) + `config/palette.tres`: merkezi void-neon renkler (void/panel/
  border/accent-cyan/accent_alt-magenta/text/coin/danger/success). Kod-çizimli için tek kaynak.
- `theme/ui_theme.tres` (Godot Theme, **gui/theme/custom**): StyleBoxFlat neon butonlar
  (koyu cam + cyan kenar + köşe, hover/pressed/disabled), glass Panel/PanelContainer, neon
  ProgressBar, Label tip-varyasyonları (Title/Heading/Accent/Coins/Muted). Tüm Control'ler
  otomatik stillenir. clear_color paletten.
- **Sahte glow** (gl_compatibility'de KAL — bloom YOK): parlak accent + derin void +
  StyleBox neon kenar/köşe. Gerçek bloom v1.1.
- Restyle: MainMenu/Store/Missions/Credits (Title varyasyonu + bg void), Store header'lar
  Heading varyasyonu, Pause/Result/RewardPopup glass PanelContainer, HUD Coins varyasyonu +
  sonuç başlığı win=success/lose=danger (koddan). In-game: player neon cyan; arena/düşman
  renkleri zaten per-arena tema (Step 08), clear_color palet void.
- Font: varsayılan (Tuğra CC0 font ekleyince temaya bağlanacak — künyeye girer).
- **Feel-loop revizyonu (2026-06-17):** yön void-neon → "dostane-parlak". A/B: void-neon
  `config/palette_voidneon.tres` olarak YEDEK (silinmedi); aktif `palette.tres` dostane
  (derin indigo/erik zemin + canlı cyan/pembe + sıcak coral/altın). ui_theme yuvarlatıldı
  (köşe 18/24, yumuşak kenar). PaletteData'ya `warm` eklendi. Tek referansla A/B geri dönüş.
  **Font bağlama ERTELENDİ** (assets/fonts boş — .ttf yok; eksik path tema'yı kırardı):
  DynaPuff (Title/Heading) + Nunito (gövde/sayı) dosyaları + OFL.txt eklenince bağlanacak
  (credits.md'de künye + not hazır).
- **MainMenu amblem/wordmark (2026-06-18):** `scripts/ui/logo.gd` — motoriçi `_draw` amblem
  (yuvarlak-kare arena kenarı + 3 çok-renkli kapılmış bölge [cyan/pembe/coral] + kenarda
  oyuncu elması), tümü PALETTEN (PNG/AI yok, kare format = ileride app ikonu). Lockup:
  amblem üstte + "NoSpace" (Title) + "A R E N A" (Accent) altta, üst-orta; butonlar altta.
  Font DynaPuff eklenince başlık ona geçer.
- **MainMenu hiyerarşi/craft (feel-loop #2, 2026-06-18):** "generic" hissini kıran düzen.
  ui_theme'e `HeroButton` (dolu cyan + StyleBoxFlat shadow ile sahte glow, büyük) →
  PLAY tek kahraman; `Secondary` (sönük/küçük/muted) → Daily/Store/Missions/Credits geri
  çekilir. Amblem: 2x2 dengeli (cyan/magenta/coral + 1 boş kadran), elmas sınıra oturdu +
  içeri kesen iz ("kapma" okunur). Wordmark sahte-glow (TitleGlow/SubtitleGlow katmanlı-alpha),
  ARENA daha parlak magenta. VBox yukarı + sıkı ritim; Coins sönük pill panel; altta sönük
  versiyon metni. Palet/font/yön DEĞİŞMEDİ.
- **MainMenu feel-loop #3 (2026-06-18):** (1) wordmark glow hayaleti kaldırıldı — temiz tek
  "NoSpace" (TitleGlow/SubtitleGlow silindi), ARENA temiz+parlak magenta. (2) buton aralığı
  açıldı (separation 26 + Play altına spacer) → nefes alıyor. (3) amblem yeniden: mekanizmayı
  gösteriyor — sol duvara yaslı dolu kazanılmış bölge (cyan) + elmas arena İÇİNDE + arkasında
  iz (frontier'dan dönerek bölge çevreliyor, magenta). Çalışan korundu (Hero/Coins/footer/palet).
- **MainMenu feel-loop #4 (2026-06-18):** amblem rengi geri (hikâye korunarak) — 2 kapılmış
  bölge (sol cyan + sağ-üst köşe coral), iz magenta, elmas parlak beyaz-cyan (iz≠oyuncu net).
  Dikey kompozisyon: içerik bloğu (amblem→wordmark→butonlar) 1280'de ortalandı (244→~1040),
  footer korundu → alt-void dengelendi. Wordmark'a çok hafif cyan outline glow (offset/hayalet
  yok). Palet/font/yön sabit.
- **MainMenu feel-loop #5 (2026-06-18):** amblemde iz "+"/çapraz kesimi olarak uzatıldı —
  cyan (sol-alt) ve coral (sağ-üst) bölgeleri artık iz-segmenti + arena kenarıyla çevrili
  (havada blok yok); elmas izin canlı ucunda, içeride. Kompozisyon: tüm içerik (emblem→
  wordmark→butonlar) tek `Center` VBoxContainer'a alındı (alignment=center) → her çözünürlükte
  dikey ortalı, üst-alt boşluk eşit. Footer korundu. Palet/font/yön sabit; node yolları
  `$Center/Buttons/*` olarak güncellendi.
- **MainMenu feel-loop #6 (2026-06-18):** amblem kilitli; sadece kompozisyon — `Center`
  merkezleme alanı alttan kısıldı (offset_bottom -120) → içerik bir tık yukarı, üst-alt boşluk
  algısı dengelendi (footer alttaki payı dolduruyor).

**Doğrulama (GUT):** test_palette (palette yüklenir + accent/text/coin void'e karşı kontrast
eşik üstü). 6-sahne instantiate (tema + glass + varyasyonlar) + temiz boot. Toplam 179/179.
**His/görsel = Tuğra Test Listesi esas (otomatik test edilemez).** 3 çözünürlük + neon his Tuğra'da.

### Step 16 — Juice & game feel
**Durum:** TAMAMLANDI — main'de (16a/16b=87e2d7a + 16c=72ab12a); Tuğra his ayarı bekliyor
**Bölme:** 16a = kapatma juice'u · 16b = tehlike/UI hissi · 16c = geniş UI pop

**16a — Kapatma juice'u (2026-06-18, kodlandı):**
- `scripts/fx/juice_math.gd` (saf: trauma decay + shake²) → `test/test_juice_math.gd` (5 test)
- `scripts/fx/camera_shake.gd` (Camera2D, trauma² shake, @export max_offset/roll/decay/trauma_capture)
- `scripts/fx/hit_stop.gd` (Engine.time_scale dip, ignore-time-scale+process-always timer; @export
  capture_duration/scale_during; is_active()) — time_scale'in TEK sahibi (16b near-miss arbitre edecek)
- `scenes/fx/CaptureBurst.tscn` (CPUParticles2D one-shot, `one_shot_particles.gd` self-free)
- `scenes/fx/FloatingScore.tscn` ("+N" punch+rise+fade, `floating_score.gd`, @export rise/duration/punch)
- HUD: skor label punch (pivot ortalı, @export `score_punch`)
- `game.gd`: `_on_area_captured` → shake + hitstop + burst + "+N" (kapanış = cells world centroid,
  boşsa player.pos; renk = arena captured/trail). `_ready`'de `Engine.time_scale=1.0` (retry güvenliği).
  Ghost kaydı hitstop sırasında gate'lendi (örnek kümelenmesi yok; determinizm değişmez).
- Etkilenen sahne: Game.tscn + (HUD kod-only) = bütçe içinde. **Ses YOK** (assets/audio boş — hook'lar hazır).
- **Doğrulama:** 184/184 GUT (179+5), boot temiz, Game/FX instantiate, time_scale=1.0. His = Tuğra'da.

**16b — Tehlike & UI hissi (2026-06-19, kodlandı):**
- `scripts/fx/time_control.gd` — `Engine.time_scale`'in TEK arbiteri (min-aktif-ölçek, key+gen
  token, her istek ignore-time-scale timer, hiç kalmayınca 1.0). hitstop + near-miss buradan.
- `hit_stop.gd` → TimeControl'e devredildi (game `_ready`'de `time_control` inject; @export korundu).
- `scripts/fx/near_miss.gd` — oyuncu çizerken (is_exposed) düşman↔TRAIL nokta-segment mesafesi
  (`juice_math.min_distance_to_polyline`) radius altı + cooldown → `near_miss`. @export radius/
  slow_scale/slow_duration/cooldown. Player'a `trail_world_points()` (sıralı) eklendi.
- `scenes/fx/JuiceOverlay.tscn` + `juice_overlay.gd` — tek flaş (`flash`) + vignette nabzı
  (`pulse_vignette`); `assets/shaders/vignette.gdshader` (gl_compatibility canvas). @export dozlar.
- `game.gd`: near-miss → TimeControl slow + vignette; can-kaybı → tek flaş + ağır shake
  (`trauma_life_loss`). Ghost gate `_hitstop` → `_time_control.is_active()` (near-miss slow da kapsanır).
- `scripts/ui/juicy_button.gd` (Button) — press scale-pop + `vibrate_handheld`; @export pop_scale/
  haptic_ms. Bağlandı: MainMenu Play + HUD Result(Retry/Menu) + Pause(Resume/Restart/Menu) = **3 sahne**.
- `juice_math`: `min_distance_to_polyline` + segment mesafe eklendi → +5 test.
- **Doğrulama:** 189/189 GUT (184+5), boot temiz (shader sorunsuz), Game/Overlay/buton instantiate,
  time_scale=1.0. His = Tuğra'da.

**16b feel-tune (2026-06-19):** tehlike vignette'i artık SÜREKLİ proximity-sürüşlü (tek nabız değil).
`near_miss` iki bağımsız kanal: `danger_changed(level)` her frame (0..1, `vignette_radius`'a göre
`JuiceMath.danger_from_distance` smoothstep) → overlay'e; `near_miss()` discrete slow-mo (cooldown,
`radius`). Overlay `set_danger` + `_process` lerp (`vignette_smooth`/`vignette_max_intensity`) →
titremesiz belirip koyulaşır/söner; çizmiyorken 0. Slow-mo (TimeControl) dokunulmadı. Vignette saf
görsel → determinizm/gate etkilenmez. +4 danger testi (189→193).

**16c — UI pop geniş yayılım (2026-06-19, kodlandı):** tunlanmış juicy_button kalan tüm menü
butonlarına bağlandı (yeni mantık/dosya yok). MainMenu Daily/Store/Missions/Credits + Pause'un
PauseButton'u + Store/Missions/Credits BackButton (tscn script). Store Buy/Select kod-üretimli →
`JuicyButton.new()` (IS-A Button; text/size/pressed/disabled mantığı aynı). Uniform pop (pop_scale/
haptic_ms tutarlı). Saf UI → determinizm/ghost/seed etkilenmez. Doğrulama: 4 menü instantiate +
Store dinamik JuicyButton testi; 193/193 korunur, boot temiz. COMMIT YOK.

### Step 17 — Ses & müzik & haptic
**Durum:** TAMAMLANDI — main'de (17a=2a0f845 + 17b-i=fef3587 + 17b-ii=a6790ab + menu music=978e749)
**Bölme:** 17a = ses sistemi (asset'siz, sessiz) · 17b = ayar UI + gerçek CC0 ses + künye

**17a — Ses sistemi iskeleti (2026-06-19, kodlandı):**
- `AudioManager` (mevcut autoload dolduruldu): `play_sfx`/`play_music`/`stop_music`, round-robin
  SFX havuzu (@export `sfx_pool_size`), linear→dB bus volume + Master mute, `_ready`'de settings
  yükle+uygula (ilk çalmadan önce). Boş/bilinmeyen key → sessiz no-op (crash yok).
- `default_bus_layout.tres` (Master→SFX/Music) + project.godot `[audio]` bağlama.
- `scripts/meta/sound_bank.gd` + `config/sound_bank.tres` (boş; event→AudioStream, 17b'de atanır).
- `scripts/meta/audio_settings.gd` (pure: clamp/mute/linear→dB/to_dict) + `settings_store.gd`
  (`user://settings.json`). → `test_audio_settings` (7 test).
- Wiring: capture→`play_sfx("capture")`+haptic, life_loss→+haptic, near_miss→sfx; UI tap
  `juicy_button._on_down`'da merkezî; menü müziği `main_menu._ready`, oyun müziği `game._ready`.
- Gameplay haptic @export (`capture_haptic_ms`/`life_loss_haptic_ms`, hafif).
- **Asset dürüstlüğü:** SESSİZ, placeholder yok; CC0 ses + künye 17b'de.
- **Doğrulama:** 200/200 GUT (193+7), boot temiz, SFX/Music bus var, no-op güvenli, Game/MainMenu
  instantiate. Duyum = Tuğra (asset gelince).

**17b-i — Ses ayar UI (2026-06-19, kodlandı):** `Settings.tscn` + `settings_panel.gd` — master/sfx/
music slider (neon-fill) + tek master mute, dostane-bright tema. Slider değişimi → `AudioManager.
apply_*` (canlı, save'siz), drag_ended → `commit_settings` (debounce); mute → `set_muted` (anında
save). Açılışta `AudioManager.settings()`'ten doldurulur. Erişim: MainMenu sol-üst motoriçi mixer
ikonu (`settings_icon.gd` _draw, paletten, ≥64px, Coins simetriği). ui_theme'e HSlider neon-fill
stylebox (slider/grabber_area/highlight). locale `SETTINGS_*`. AudioManager set_* → apply_*/
commit_settings ayrımı (debounce). Doğrulama: 203/203 (200+3), boot temiz, panel instantiate +
slider→AudioManager wiring + locale. COMMIT YOK.

**17b-ii — Ses asset bağlama (2026-06-19, kodlandı):** Tuğra'nın 5 WAV'ı bağlandı.
- `sound_bank.tres`: capture/life_loss/near_miss/ui_tap → sfx/*.wav, music_menu → menu_music.wav (uid+path).
- Müzik wiring: MainMenu→`play_music("menu")` (menüler arası sürekli, idempotent); Game→`stop_music()`
  (oyun-içi sessiz, menüye dönünce devam). Mix: `@export music_volume_db = -6` (müzik SFX altı).
- **Loop quirk:** headless/export WAV importer hand-edit `edit/loop_mode=1`'i güvenilir uygulamıyor;
  AudioManager `play_music` müzik WAV'ında loop'u RUNTIME zorluyor (SFX one-shot kalır). `.import`=1
  (editör için doğru) + runtime guard (her ortam). Künye: `docs/credits.md` (original/synthesized, 3.parti yok).
- **Doğrulama:** 207/207 (203+4 `test_sound_bank`: key'ler null değil, bilinmeyen null, menü loop), boot temiz.
  Duyum/mix = Tuğra (oynayıp dinler).
- **Fix (2026-06-19): menü müziği sessizdi** — runtime loop guard `loop_mode=FORWARD` yapıyordu ama
  `loop_end=0` (import) → sıfır-uzunluk loop → ilk frame'den sessizlik. AudioManager `play_music`
  artık loop'u zorlarken `loop_begin=0`, `loop_end=int(get_length()*mix_rate)` ayarlıyor (geçerli
  tam-dosya loop). `test_sound_bank` loop_end>begin doğrular. 216/216, boot temiz.

## FAZ — Oynanış Derinliği (monetization'dan ÖNCE)

> Karar (2026-06-19, düz şema 2026-06-23): Çekirdeği derinleştir, sonra sat. **DÜZ numara şeması**
> (ondalık YOK): 18 Level-Endless ✅ · 19 Enemies ✅ · 20 Boost ✅ · 21 Campaign · 22 Lokalizasyon ·
> 23 AdMob · 24 IAP · 25 Android+cihaz · 26 Çeviri (10 dil) · 27 iOS · 28 Store. Tamamlanan ≤17 +
> shipped decimal'ler (03.1/05.1/14.1/14.2 — gerçek remote branch'lere bağlı, tarihsel kayıt)
> DOKUNULMADI. v1.1 backlog (aşağıda) launch'ı BLOKLAMAZ — sağlam çekirdekle çık, güncellemelerle besle.

### Mod Yapısı (2026-06-19 revize)
Stage sistemi yalnız **Level** modlarına ait; **Daily + Free tek-arena**.
- **Daily:** tek arena + karakter, bugünün tohumu (seed→arena/char deterministik), TAM ghost +
  leaderboard. (Çok-stage daily GERİ ALINDI — adalet/ghost tek-arena ile net.)
- **Free** (eski "Play"): tek arena, oyuncu loadout seçer, casual; ghost/leaderboard yok.
- **Level-Endless** (Step 18): stage'ler ölene dek sertleşir (arena cycle + ramp); kişisel skor,
  daily-ghost yok.
- **Level-Campaign** (Step 21): sonlu level dizisi + unlock persistence + level-seç UI.

### Step 18 — Level-Endless (progression & zorluk eğrisi)
**Durum:** TAMAMLANDI — main'de (18a=8d66c54 + mode select=29bd179 + 18b=bdf87ae)

**18a redirect (2026-06-19, kodlandı):** `SeedManager`'a `Mode {DAILY, FREE, LEVEL_ENDLESS}` enum'u
(+ `enter_free`/`enter_level_endless`; `is_daily` = mode==DAILY mirror; yeni autoload yok).
`game.gd` `_on_area_captured`: target%'te → **LEVEL_ENDLESS = advance** (deferred), **Daily/Free =
`win_run`** (tek arena). Daily tek-arena → seed→arena/char + TAM ghost/leaderboard eski haline döndü.
MainMenu'ye **Level** butonu (→ Level-Endless; Campaign Step 21). locale `MENU_LEVEL`. Doğrulama: 216/216,
boot temiz, mode helper'ları + Free-game stage-0 + menü Level butonu testli.

**18a — Stage çekirdeği (2026-06-19, kodlandı):**
- `progression_config.gd` + `config/progression.tres`: daily_stage_count, speed_ramp/cap,
  enemy_add_every/cap_bonus, target_ramp/cap (@export, magic number yok).
- `stage_plan.gd` (pure): `(daily,seed,base_arena,stage,count,config)` → {arena_index, speed_scale,
  enemy_bonus, target_bonus, stage_seed}. Daily seed-deterministik (stage 0 = mevcut günlük arena
  draw, ARENA_SALT mirror); free-play arena cycle + ramp. → `test_stage_plan` (9 test, determinizm/
  ramp/cap/cycle).
- `game.gd`: sinyaller bir kez bağlanır; `_start_stage(n)` (arena configure + player reset +
  scaled enemy respawn + living/near-miss re-point; lives/scorer KORUNUR), `_advance_stage`
  (deferred — capture-signal içinde arena rebuild yok). `_on_area_captured`: `_stage_target`'e
  ulaşınca win_run YERİNE advance. Daily N tamam → win_run; free-play endless; ölüm → game_over.
  Win, game-over ile AYNI submit yolundan geçer (atlama yok).
- Capture/seed/grid algoritması DEĞİŞMEDİ (sadece orchestration). Enemy stage geçişinde queue_free.
- **Doğrulama:** 216/216 (207+9), boot temiz, Game stage-0 instantiate (enemy spawn + target).
  His/akış (zorluk eğrisi, stage-clear, retry) = Tuğra. HUD 3-kalp + flourish = 18b.

**MainMenu restructure (2026-06-19, kodlandı):** Ana menü sadeleşti — ayrı Daily/Free/Level
butonları kaldırıldı; tek **Play (hero) → `ModeSelect.tscn`**. MainMenu = Play + Store + Missions +
Credits (+ gear/coins). `ModeSelect`: Daily (üstte, Accent açıklama) / Free / Level + Back, her biri
`SeedManager.enter_*` + Game; Campaign 4. slot'a hazır. Akış: Retry = aynı mod (mode SeedManager'da
kalıcı), Result→Menu = MainMenu. locale `MENU_FREE`/`MODE_SELECT_TITLE`/`MODE_*_DESC`. mode-set
mantığı değişmedi (sadece IA). Doğrulama: 216/216, boot temiz, MainMenu(Level/Daily yok)+ModeSelect testli.

**18b — 3-kalp HUD + stage flourish (2026-06-20, kodlandı):**
- `hearts_hud.gd` (Control `_draw`, 2 daire + üçgen kalp, paletten): `set_max`/`set_current`; can
  kaybında kaybedilen kalp **sönük slot'a fade + scale-punch** (kalan can okunur). @export
  boyut/aralık/sönme. HUD.tscn `LivesLabel` → `Hearts` (TÜM modlar). `hud.gd`: setup→set_max,
  `_on_life_lost`→set_current. 16b can-kaybı flaş/shake ile birleşir.
- Stage flourish (Level-Endless): `game._advance_stage` → `hud.show_stage_banner(n)` ("Stage N"
  scale-in+fade banner) + iri partikül (amount×2) + güçlü camera punch + `play_sfx("stage_clear")`.
  Daily/Free'de yok. SoundBank `stage_clear` key + `stage_clear.wav` bağlandı. locale `HUD_STAGE`.
- Fix: `hearts_hud._draw` set_max'tan önce çağrılınca out-of-bounds → `_ready` init + guard.
- **Doğrulama:** 219/219 (+3 `test_hud_hearts`: kalp life_lost'u yansıtıyor, banner method, stage_clear
  bound), boot temiz. Görsel/his = Tuğra. (Ghost build işi yok — Daily redirect'te tek-arena tam ghost.)
**Hedef:** Tek düz endless run'ı, sense-of-progress + tırmanan zorlukla değiştir.
**D1 kararı = A (stage/level omurga):** arenanın `target_percent`'ini kapat → sonraki stage
(daha sert); skor/kombo taşınır. In-stage ramp (C) → v1.1.
**Tasarım notları:**
- Arenalar HEM döner HEM sertleşir: her stage arena döndürür (mevcut 3: A→B→C cycle) +
  stage no'suyla artan zorluk çarpanı (düşman hız/sayı, target %). Daha fazla arena = v1.1.
- Görünür can HUD'u: 3 KALP; can kaybında kalp rengi söner/solar (+ küçük fade/kırılma juice).
  Motoriçi çizilir (palet renkli, dış asset yok). Mevcut can-kaybı flaş/shake ile birleşir
  (flaş = an, sönen kalp = kalıcı gösterge).
- Planda çözülecek: can/skor stage'ler arası taşıma; daily framing ("bugünün tohumuyla N stage");
  fail/retry granülerliği (run mu, stage mi baştan).

### Step 21 — Level-Campaign
**Durum:** 21a main branch'e commit'li (955c3e4, step/21-campaign); 21b = ba05768 ile main'de → **Step 21 TAMAM**
**Model (onaylı):** Level-seç (gauntlet değil). Her level = tek arena challenge (kompozisyon + target% +
can + boost-flag). Seç → oyna → target'e ulaş → yıldız + sonraki unlock → seçime dön. Ölüm → fail → retry.
Free'nin tek-arena `win_run` yolu reuse. **v1 = basit grid UI** (harita v1.1). **Alt-hedef v1.1.**

**21a — Mantık katmanı (2026-07-01, UI yok):**
- **LevelData** (`.tres` class_name): id, arena:ArenaData, enemies:Array[EnemyType] (açık kompozisyon),
  target_percent, lives, boosts_allowed, speed_mult, star2_score, star3_percent.
- **`ContentCatalog.LEVELS`** = 12 level, **elle tasarlanmış zorluk eğrisi**: c01-02 bouncer tanıt →
  c03-04 chaser girer → c05-06 sparx girer → c07 ilk kombo → c08 boost-yasak kombo → c09 nefes →
  c10 ağır → c11 düşük-can (2) → c12 finale (tüm tipler, boost-yasak). `level_at(index)`.
- **`SeedManager.Mode += CAMPAIGN`** + `campaign_level:int` + `enter_campaign(index)` (enter_* deseni; yeni autoload yok).
- **`BoostPolicy.boosts_allowed(mode, campaign_allows:=true)`** — CAMPAIGN → level bayrağı; DAILY → false
  (değişmez); FREE/ENDLESS/bilinmeyen → true.
- **`CampaignStars` (saf):** `star_for(reached, score, percent, level)` — 1★ bitir, +1 score≥star2, +1
  percent≥star3 (sum, cap 3, eşik 0=kapalı); `is_unlocked(index, levels, stars)` — N açık ⇔ N-1 ≥1★ (ilk hep açık).
- **SaveData:** `campaign_stars` (id→best 0-3) + `set_campaign_star` (max tutar) + to_dict/from_dict.
- **Economy:** `campaign_star` / `record_campaign_result` (max, flush+signal) / `is_level_unlocked` + `campaign_changed`.
- Determinizm: sabit kompozisyon + spawn deterministik (RNG yok); ghost yok, personal stars.
- Test: yıldız (0/1/2/3 + eşik-kapalı), unlock türetme, policy CAMPAIGN dalı, campaign_stars round-trip/max,
  12-level catalog geçerli. **297/297 (+11).**
**21b — UI + entegrasyon (2026-07-01):**
- **LevelSelect** (`level_select.gd` + `.tscn`): 12 level grid (3 sütun, scroll). Her kart = tek buton
  "Level N\n★★☆" (unlocked) / "Level N\nLocked" (disabled). `Economy.is_level_unlocked` (N-1≥1★) gate +
  `campaign_star` yıldız. Kart → `SeedManager.enter_campaign(index)` → Game. Back → ModeSelect.
  `campaign_changed` sinyali → yeniden kur (kazanınca yeni unlock/yıldız yansır).
- **ModeSelect:** 4. slot **Campaign** butonu (rezerveydi) → LevelSelect'e gider (level seçmeden run yok).
- **game.gd CAMPAIGN branch:** `_ready` mode==CAMPAIGN → `_level = level_at(campaign_level)`. `_start_stage`
  → `_apply_campaign_level` (arena=level.arena, kompozisyon=level.enemies via `_spawn_stage_enemies`
  override_types, target=level.target%, lives=level.lives, speed=level.speed_mult). `_on_area_captured`
  target'te → **win_run** (tek level, oto-advance yok, LEVEL_ENDLESS değil). `_on_run_ended` (win) →
  `CampaignStars.star_for` → `Economy.record_campaign_result` (max + unlock) → `_hud.show_campaign_stars`.
  Ölüm → game_over (retry aynı level). Menu → **LevelSelect** (campaign) / MainMenu (diğer).
- **Boost gate:** `_resolve_boosts` → `BoostEffects.resolve(..., campaign_allows=level.boosts_allowed)`;
  boost-yasak level'da (c08/c12) armed olsa bile uygulanmaz + charge korunur.
- **Result:** HUD.tscn `StarsLabel` + `show_campaign_stars(stars, improved)` (★/☆ + "New best!" if arttı).
- **locale:** MENU_CAMPAIGN / MODE_CAMPAIGN_DESC / LEVELSELECT_TITLE / LEVEL_LABEL / LEVEL_LOCKED / RESULT_NEW_BEST.
- capture/seed/grid DEĞİŞMEDİ (yalnız orchestration). Yeni autoload yok. Etkilenen sahne: LevelSelect +
  ModeSelect + Game + HUD.
- Test: campaign boost-off resolve; LevelSelect instantiate; **game CAMPAIGN configure** (c01 → arena void /
  1 enemy / target 50 / lives 3, gerçek Game sahnesi instantiate). **300/300.**
- **Tuğra'da kalan (his/cihaz):** haritadan seç → oyna → yıldız kazan → sonraki açılır; boost-yasak
  level'ı hisset; zorluk eğrisi + yıldız eşikleri (star2/star3) ayarı.

**21b iterasyon (2026-07-01, Tuğra feedback):**
- **Result taşma fix:** "New best!" yıldız satırından ayrıldı → `StarsLabel` yalnız ★/☆ (40px);
  ayrı `NewBestLabel` (20px) yalnız rekor artınca. Glass/VBox büyütüldü (taşma yok).
- **Next butonu:** Campaign win + sonraki level açıksa → `_on_next` (`enter_campaign(+1)` + reload).
  Sıra Next(HeroButton) · Retry · Menu; kayıp/son-level/diğer modlarda gizli. `has_next` game'de hesaplanır.
- **Level menüsü → zigzag PATİKA:** düz grid kaldırıldı. `path_canvas.gd` (motoriçi bağlantı çizgisi,
  accent) + `level_select.gd` düğümleri zigzag (sıra sola/sağa, `X_OFFSET`) dikey yerleştirir, scroll.
  Düğüm = "Level N / ★★☆ / alt-başlık" (kilitli → "Locked", disabled).
- **Level açıklaması:** `LevelData += description_key`; 12 `.tres` + 12 locale (`LEVEL_C0N_DESC`,
  kompozisyon+amaç). Düğüm alt-başlığında gösterilir.
- **CAMPAIGN stalker overlap fix:** variation ataması pozisyon (`i % types.size()`) yerine **gerçek
  EnemyType**'a göre gruplanır → campaign'in açık kompozisyonu (`[chaser, chaser]`) aynı tipi doğru
  sayar → index-eşit variation → üst üste binmez. Arena roster'ları etkilenmez (tek-tip-slot aynı sonuç).
  Level-Endless + Campaign **aynı spawn yolu** (çift mantık yok). Deterministik.
- Test: campaign boost-off resolve; LevelSelect instantiate (patika); game CAMPAIGN configure; catalog
  description_key dolu. **300/300.**
- **Yıldız modeli fix (2026-07-01):** 3★ = capture% ≥ star3_percent İMKANSIZDI (run target'te bitiyor →
  final % ≈ target < star3_percent). Yeni model (Tuğra seçimi): **1★** bitir · **2★** = skor≥star2_score
  **VEYA** cansız · **3★** = skor≥star2_score **VE** cansız (no-death). `star_for(reached, score,
  lives_lost, level)`; game `_lives_lost` sayacı (`_on_trail_failed`'de artar) → win'de geçirilir.
  `star3_percent` kullanılmıyor (rezerve). 301/301.
- **Result layout fix (2026-07-02):** Next gelince panel sıkışıyordu → **NextButton tam genişlik**
  (üst satır, HeroButton) + **Retry|Menu `ButtonRow` (HBox) yan yana** (3 buton-satırı yerine 2) →
  ~1 buton yüksekliği kazanıldı; VBox separation 14→18. `hud.gd` Retry/Menu yolları
  `VBox/ButtonRow/*`. Boot + 301/301 (Game.tscn instantiate testi yeni ağacı doğruladı).

### Step 19 — Düşman çeşitliliği & sertlik
**Durum:** 19a/19b-1/19b-2/19b-3 TÜMÜ main'de (19b-3 = 58d0208) — **Step 19 TAMAM**
**Hedef:** `EnemyBehavior` strategy deseni üstüne yeni tip(ler) + per-enemy varyasyon.

**19a — Chaser overlap fix + variation altyapısı (2026-06-22, kodlandı):** `decide()`'a `variation`
param (default 0 geriye uyumlu); `enemy._variation` setup'ta atanır → `decide_velocity`'ye; spawner
tip-içi **eşit dağılım** (`EnemyMotion.even_spread`); `ChaserBehavior` homing'i `variation*spread_rad`
döner (@export). Index-tabanlı (RNG yok) → daily/ghost reproduce. Fix-Pass #6 burada kapandı.
247/247 (+6). Capture/seed/grid değişmedi.
- **Boundary-pin bütünsel fix (2026-06-22):** düşman HİÇBİR sınıra yapışmasın. Kök: recovery
  (peel-off) yalnız Halt-freeze sonrası set ediliyordu; normal bounce'ta homing her frame duvara
  geri yönelip reflect↔home salınımı (pin) + Pulse'u eziyordu. Fix: `enemy._advance` HER reflect'te
  `_recovery_timer = recovery_time` → reflected (dışa) heading kalır, peel eder; Pulse üstüne güvenle
  iter. Bouncer (decide=identity) ve Drag/Halt etkilenmez; Halt-freeze ayrı yol korunur. Çözer: (1)
  2-chaser park, (2) Pulse-stick (aynı kök). RNG yok → determinizm korunur. 247/247, regresyon yok.

**19b-1 — Sparx wall-follow hareketi (2026-06-22, kodlandı):** Sparx = `edge_follow` hareket modu —
yakalanmış bölgenin/duvarın çevresini **sağ-el wall-follow** ile yürür (grid OKUMA, capture algoritması
değişmez). `EnemyType.edge_follow`; `type_sparx.tres` (shape=SQUARE, base_speed @export); Enemy
`_edge_process` (grid-step + lerp, `_grid_cell/_heading`), engulf'ta en yakın FREE perimeter'a
re-projection (deterministik); `EnemyMotion.wall_follow_turn` (sağ→ileri→sol→geri, pure/testli) +
turn_right/left. Frost roster = chaser + sparx. Spawn: perimeter (col 1, DOWN) deterministik.
Enemy._draw + how-to `enemy_glyphs` SQUARE. **Tehdit = SADECE trail teması (a)** — player-cell (b) +
metin açıklamaları (HOWTO_ENEMIES_BODY/ARENA_FROST_DESC) **19b-2**. Bouncer/Chaser/Drag/Halt/19a
regresyon yok. RNG yok → daily/ghost reproduce. 255/255 (+8).

**19b-2 — Sparx tehdit (b) + metinler (2026-06-22, ✅ main'de 659db4b):** Sparx artık **player-cell tehdidi** —
oyuncu hücresine komşu/üstünde olunca (kenarda **güvende bile**) yakalar → border'da oyalanma = ölüm
(klasik Qix Sparx). `decide_velocity` player pos'u cache'ler (LivingTerritory önce çalışır); `_edge_process`
catch + **cooldown** (`edge_catch_cooldown=1s`, respawn chain-kill yok). Trail tehdidi (a) korunur.
how-to "Enemies" + `ARENA_FROST_DESC` Sparx'ı anlatır. 257/257 (+2). RNG yok → determinizm korunur.
- **How-to Enemies legend (2026-06-22):** her şeklin altına isim etiketi — daire→Bouncer, üçgen→
  Stalker, kare→Sparx (3 sütun: glyph + Muted ad, ortalı, aralıklı). `enemy_glyphs` tek-şekil
  (`kind`) oldu; locale `ENEMY_*_NAME`. Açıklama cümlesi aynen. Şekil↔isim↔davranış net.

**19b-3 — Sparx trap → contain → re-emerge (2026-06-22, kodlandı):** Sparx tuzaklanınca contain
(inert+görünmez `contain_duration` 5s @export) → süre dolunca re-emerge + telegraph
(`emerge_telegraph` 0.4s @export, çıkışta blink, **NON-LETHAL**) → aktif+lethal. Geçiş:
contained→telegraph→active, uyarısız lethal frame yok. Skor ödülü yok = taktik nefes.
  - **KÖK NEDEN (kritik):** ilk taslak engulf tetiği `cell_state(_grid_cell)==CAPTURED` idi ama
    `close_and_capture` **düşman FREE bölgesini danger-seed olarak KORUR** (asla kapatmaz) → sarılan
    Sparx hücresi hiç CAPTURED olmaz → contain hiç tetiklenmez, Sparx küçülen cepte takılı kalır
    ("çıkmıyor"). **Düzeltme:** tetik artık **cep boyutu** — her capture'da `game._on_area_captured`
    → `enemy.on_capture_event()` → Sparx'ın 4-bağlı FREE region'ı `contain_pocket_cells` (120 @export,
    early-exit flood) eşiğinin altındaysa contain. (Eski CAPTURED-cell kontrolü emniyet olarak kalır.)
  - **Re-emerge ana alana:** `_reproject(ref)` artık **oyuncu hücresine** en yakın FREE perimeter'ı
    seçer (cebe geri dönmesin) — `_last_player_pos` yoksa kendi hücresi. Deterministik
    (Manhattan + row-major). Timer'lar fixed-delta → frame-deterministik (RNG yok → daily/ghost).
  - **"Hapis kalma" düzeltmesi (2026-06-22):** ikinci/daha sıkı tuzakta re-emerge cebin İÇİNE
    düşüyordu (oyuncu cebin yanında → en yakın perimeter = cep duvarı) → Sparx aynı minik cepte
    "hapis", ancak sonraki capture grid'i değiştirince çıkıyordu. **Kök:** `_reproject` cebi hariç
    tutmuyordu. **Düzeltme:** re-emerge artık Sparx'ın kendi cebini (`_flood_free_set(_grid_cell,
    contain_pocket_cells)`) **HARİÇ TUTAR** → cep-dışı en yakın FREE perimeter. Re-emerge
    **timer-expiry'de DAİMA** olur (capture beklemez — test capture'sız doğrular).
  - **Konsolide fix (2026-06-22) — hapis + "yerinde dönme":** cep-hariç hâlâ yetmiyordu (cep duvarı
    yine en yakın olabiliyor) + re-emerge **degenere/duvarsız hücreye** koyunca Sparx yerinde DÖNÜP
    duruyordu. **Kök 2:** wall-follow duvarsız açık hücrede her adım sağa döner → daire çizer.
    **Düzeltme (decisive):** (1) re-emerge artık **oyuncunun FREE bölgesinden** (ref'ten flood,
    `_flood_free_set(ref, cols*rows)`) seçer → izole pocket başka bileşen, **otomatik dışlanır**;
    (2) hedef **yürünebilir kenar** olmalı — `_is_walkable_border` = FREE + ≥1 CAPTURED komşu +
    ≥2 açık komşu (izole/çıkmaz spur değil) → `_nearest_walkable_border` (row-major deterministik,
    bölge yoksa global); (3) re-emerge'de **geçerli heading** atanır (`_wall_follow_start_heading`:
    önü açık + sağı duvar) → ilk adımdan yürür; (4) `_next_edge_heading` duvarsız hücrede **düz git**
    (sağa-daire değil). Hiç yürünebilir kenar yoksa zarif no-op. Deterministik → daily/ghost.
  - **Edge-lock regresyon fix (2026-06-22):** (4)'teki "duvarsız hücrede düz git" + "en yakın kenara
    yürü" mantığı Sparx'ı **iç FREE alandan yürütüyordu** → normal düşman gibi içeride dolaşıyor,
    edge-walker kimliği bozuluyordu. **Kesin kural geri geldi:** Sparx HER adımı **border-komşu**
    (CAPTURED/wall'a komşu) bir FREE hücreye atar, **açık iç alana ASLA**. `_next_edge_heading`
    yeniden: right-hand tercih sırası [right, front, left, back] ama her aday **open + border-adjacent**
    filtreli; hiçbiri yoksa `ZERO` → `_edge_process` **yerinde tutar** (iç alana kaçmaz). No-wall
    "düz git" guard'ı KALDIRILDI. Re-emerge = **snap** (teleport, iç-alan traversali yok); hedef
    `_is_walkable_border`. Invariant test: 150 adım boyunca Sparx hep border-komşu. 265/265 (+9).
  - **Contain trigger ayarı (2026-06-22):** pocket-trap algılaması (`on_capture_event` → FREE flood
    ≤ eşik → contain) zaten vardı ama eşik (120) playtest pocket'leri için **çok küçüktü** → Sparx
    pocket'i dönüp duruyordu, contain tetiklenmiyordu. `contain_pocket_cells` → **`trap_pocket_max_cells`
    @export** (default 120→**400**, Tuğra tune eder). `_grid_cell` FREE değilse boş-set yanlış-pozitif
    contain'i engellemek için `not region.is_empty()` koruması. Trigger = **engulf (per-frame CAPTURED)
    VEYA bölge ≤ eşik** (OR). capture/seed/grid sadece OKUNUR (flood-fill). Deterministik → daily/ghost.
  - **(ara) "farewell lap" modeli (2026-06-23):** size-threshold tuzak + bir tur + dışarı respawn.
    4 turdur symptom-yaması olduğu için NİHAİ state-machine ile değiştirildi (aşağı).
  - **KESİN ÇÖZÜM — Sparx lifecycle state machine (2026-06-23, NİHAİ):** dağınık flag'ler tek enum'a:
    **PATROL → CONTAINED → TELEGRAPH → PATROL** (`_sparx_state`, `_edge_process` match-dispatch).
    **Trigger = CONNECTIVITY (boyut değil):** `on_capture_event` (her capture'da, grid değişince) →
    `_is_trapped` = (Sparx hücresi CAPTURED = engulf/pocket-0) VEYA (Sparx'ın FREE bileşeni **en büyük
    FREE bölge DEĞİL** — oyuncu onu ana alandan kopardı). `grid._largest_free_component_seed()` (read-only,
    deterministik) ana bölgeyi verir; Sparx flood'u onu içermiyorsa trapped. Ek güvenlik: `trap_pocket_max_cells`
    (>0 ise küçük pocket de trapped). **CONTAINED:** görünmez+inert, `contain_duration` (5s @export) sabit
    physics-step'te azalır, **grid'den bağımsız** → süre dolunca DAİMA re-emerge (ekstra capture GEREKMEZ,
    kalıcı hapis imkânsız). **Re-emerge hedefi = ANA bölgenin yürünebilir perimeter'ı** (`_reproject_to_main`:
    main_seed'den flood → `_nearest_walkable_border` ref=oyuncu, deterministik) + geçerli `_wall_follow_start_heading`
    → snap (iç-alan traversali yok). **TELEGRAPH:** `emerge_telegraph` (0.4s) non-lethal blink → PATROL.
    **Invariant'lar:** EDGE-LOCK (`_next_edge_heading` border-adjacent filtre; iç alana asla); NO-SPIN
    (heading ZERO/degenere → `_begin_telegraph` relocate, yerinde dönmez); NO-PERMANENT-TRAP (timer DAİMA
    expire). Debug trace `OS.is_debug_build()` ile. `contain_duration`/`emerge_telegraph`/`trap_pocket_max_cells`
    @export. capture/seed/grid sadece OKUNUR. Deterministik (RNG yok, sabit tarama + sabit step) → daily/ghost.
    Testler: connectivity contain (size kapalı), engulf contain, saf-timer re-emerge ana-bölgede, re-emerge
    sonrası patrol, edge-lock invariant (150 adım), telegraph non-lethal. 264/264.
  - **Re-emerge güvenli konum + wall-follow tam-tur (2026-06-23):** trap/contain'e dokunulmadı; 2 fix.
    **BUG 1 (oyuncunun üstünde doğup öldürme):** re-emerge `_nearest_walkable_border ref=oyuncu` (= oyuncuya
    EN YAKIN) seçiyordu → haksız ölüm. `_reproject_to_main` yeniden: ana bölgenin yürünebilir kenarında,
    oyuncudan **≥ `safe_emerge_distance` (7 @export, Manhattan)** UZAK + aktif trail'e komşu OLMAYAN; bunlar
    arasında contained pozisyona en yakın (deterministik). Güvenli hücre yoksa oyuncudan EN UZAK (deterministik
    fallback) → asla bitişikte doğmaz. `_has_trail_neighbor` eklendi. **BUG 2 (wall-follow yarıda U-dönüş):**
    `_next_edge_heading`'in border-adjacency filtresi dışbükey köşede meşru sağa-dönüşü (hücre duvara sadece
    çapraz komşu) reddedip erken reverse veriyordu. Klasik `EnemyMotion.wall_follow_turn`'a (sağ→ileri→sol→geri,
    reverse YALNIZ gerçek çıkmazda) dönüldü → kapalı kenarda TAM TUR, erken U-dönüş yok. `_patrol`: dört taraf
    duvarsa (izole) `_begin_telegraph` ile relocate (spin/wall-step yok). Testler: re-emerge ≥safe-distance +
    asla bitişik; tam-tur reverse-yok + başlangıca dönüş. Edge-lock/NO-SPIN/determinizm korunur. 266/266.
  - **Dar-döngü hapis fix (2026-06-30):** trap/contain/respawn'a dokunulmadı; ek yakalama. **Belirti:**
    Sparx ana FREE bölgenin İÇİNDEKİ küçük bir captured **ada/nub** etrafındaki kapalı döngüye kilitlenip
    sonsuza dek sarıyordu. **Kök:** connectivity tetiği (`_is_trapped`) bunu kaçırır (Sparx hâlâ ana
    bölgede + sadece capture olayında çalışır); per-frame guard'lar (engulf/boxed) da tetiklenmez —
    geçerli kenarda yürüyor. **Düzeltme:** `_is_stuck_in_loop` (her arrival'da) — `loop_check_steps` (64
    @export) penceresinde ziyaret edilen DISTINCT hücre `loop_min_cells` (24 @export) altındaysa VE
    erişilebilir FREE alan bu döngüden çok daha büyükse (flood gate, thrash önler) → degenere döngü →
    `_begin_telegraph` (mevcut güvenli-mesafe relocate yolu). `_reset_loop_tracker` setup/contain/telegraph'ta.
    Edge-lock/NO-SPIN/determinizm korunur (RNG yok). Test: büyük bölgede tiny-cycle yakalanır; tiny bölge
    (near-win) yakalanmaz (thrash yok); gerçek tur yanlış-pozitif değil. 283/283 (+3).

### Step 20 — Boost / power-up
**Durum:** 20a (e0672cd) + 20b (7eea3ae) main'de — **Step 20 TAMAM**
**Hedef:** Pre-run consumable boost (coin sink, pay-to-win değil). **MVP set:** Extra Life (+1 kalp) +
Slow Start (ilk N sn düşmanlar ~%50 yavaş). In-run buton YOK; Daily'de policy ile KAPALI.

**20a — Boost veri+policy+economy+save (2026-06-23, UI yok):**
- **BoostData** (`.tres` class_name): id/display/desc/cost/effect{EXTRA_LIFE,SLOW_START}/magnitude/duration.
  `resources/boosts/extra_life.tres` (cost 150, +1 kalp) + `slow_start.tres` (cost 120, scale 0.5, 5s).
  `ContentCatalog.BOOSTS` + `boost_by_id`.
- **BoostPolicy** (saf, merkezi tek kanca): `boosts_allowed(mode)` → DAILY=false (leaderboard adaleti +
  ghost determinizmi), FREE/LEVEL_ENDLESS=true, **bilinmeyen/gelecek mode (Campaign) = default true**
  (kanca hazır; Campaign = Step 21 level flag'i ileride refine eder).
- **BoostEffects.resolve** (saf): (mode, boosts, armed, counts) → {extra_lives, slow_scale, slow_duration,
  consume[]}. Policy off → boş (etki yok, charge tükenmez). RNG yok → daily/ghost reproduce.
- **SaveData:** `boost_charges` (id→count) + `armed_boosts` + add/consume/arm + to_dict/from_dict.
- **Economy:** `buy_boost`/`boost_count`/`consume_boost`/`set_boost_armed`/`is_boost_armed`/`armed_boosts`
  + `boosts_changed` sinyali. Yeni autoload YOK.
- **locale:** BOOST_*_NAME/DESC + STORE_BOOSTS/OWNED + BOOST_ARM/ARMED (20b için).
- Test: policy (daily off / free-endless on / unknown→on), catalog, resolve (armed+owned / daily-nothing /
  unowned-unarmed skip), SaveData charges/arm/round-trip. **276/276 (+10).**
**20b — Boost UI + run-start entegrasyon (2026-06-23):**
- **Store "Boosts" bölümü:** `ContentCatalog.BOOSTS` satırları — isim + açıklama + **Owned: N** + Buy(fiyat)
  (coin yetmezse pasif). `Economy.buy_boost` → `boosts_changed` ile refresh. Char/Arena deseniyle tutarlı.
- **ModeSelect arm şeridi:** sahip olunan boost'lar için arm/disarm toggle (adet gösterir);
  `Economy.set_boost_armed`. Hiç boost yoksa şerit gizli. Not: instant-launch akışı korundu (mode
  butonu = anında başlat); şerit her zaman görünür + "Free/Level" notu (Daily'yi policy run-start'ta
  zaten eler) — per-mode hide istenirse selection+start eklenebilir.
- **game.gd run-start:** `_resolve_boosts` → `BoostEffects.resolve(_mode, …)` → policy izinliyse armed+owned
  uygulanır + `Economy.consume_boost` ile charge tükenir; DAILY'de etki yok + charge korunur. Extra Life →
  `start_lives += magnitude`; Slow Start → `_slow_start_timer`/`_slow_start_scale`, spawn'da enemy
  `run_speed_scale` set, `_physics_process` fixed-step azalır, dolunca 1.0'a döner.
- **3. boost — Coin Bonus (pasif, ekonomi ekseni):** `effect += COIN_BONUS`; `resolve` → `coin_multiplier`
  (1+magnitude); `_update_missions` run-sonu coin ödülünü `× _coin_multiplier` (int round) uygular.
  **Skor/leaderboard'a DOKUNMAZ** (sadece coin) → adalet korunur. `coin_bonus.tres` (magnitude 0.5 → ×1.5).
- **enemy.gd:** `run_speed_scale` (var) `_move` + `_patrol` interval'ında uygulanır (RNG yok).
- **Boost ikonları (`boost_icon.gd`):** effect'e göre ayrı motoriçi glyph — Extra Life→kalp (kırmızı),
  Coin Bonus→coin (altın), Slow Start→saat (mavi). Store + arm şeridi aynı swatch yerine bunu kullanır.
- **Tune:** Slow Start duration 5→**3s**; fiyatlar **Extra Life 250 > Coin Bonus 200 > Slow Start 180**.
- Test: run_speed_scale travel'i yarıya indirir; Coin Bonus resolve ×1.5 (Daily'de 1.0); catalog 3 boost +
  fiyatlar; Store + ModeSelect sahneleri runtime'da temiz (smoke). **280/280.** Determinizm: DAILY'de policy
  off → leaderboard/ghost + daily coin akışı birebir aynı.
- **Not (Daily arm şeridi):** instant-launch korundu; şerit her zaman görünür + "Free/Level" notu (Daily'yi
  policy run-start'ta eler). Strict per-mode hide isterse selection+Start akışı eklenecek (Tuğra kararı).
- **Tuğra'da kalan (his/cihaz):** Store'dan al → arm et → Free/Endless'ta etkiyi hisset (kalp/yavaşlık/coin);
  Daily'de uygulanmadığını + charge korunduğunu doğrula; fiyat/doz (250/200/180, slow 0.5×/3s, coin +%50) ayarı.

> Not: **Fire boost** (aktif ateş) bilinçli olarak ELE ALINMADI → "Launch Sonrası / v1.1 Backlog"
> bölümünde kayıtlı (kendi PLAN'ı/step'i gerektirir; kategorik olarak farklı).

> İleri-not: Step 21 (Campaign) sonrası, Step 23 (AdMob) öncesi → debug cihaz testi checkpoint'i —
> derinlik çekirdeği cihazda doğrulanır, sonra lokalizasyon + monetization'a geçilir.

### Step 22 — Lokalizasyon altyapısı
**Durum:** TAMAMLANDI — 2026-07-04 — ✅ main'de (22a=515b6bb + 22b=6d6a9ac, branch
`step/22-localization`, ff-only merge; Tuğra TR review + playtest onaylı)

**22b — Settings dil seçici + otomatik algılama + persistence (2026-07-04):**
- **`AudioSettings += language`** ("" = auto/cihaz; `set_language` bilinmeyen kodu auto'ya normalize
  eder — bozuk save bilinmeyen locale pinleyemez) + dict round-trip + legacy-save default testi.
- **AudioManager:** `_ready` ilk iş `_apply_language()` — `TranslationServer.set_locale(
  LocaleUtil.resolve(saved, OS.get_locale_language()))` (impure OS girişi TEK burada; çözümleme saf).
  `set_language(lang)`: kaydet + anında uygula + `language_changed` sinyali. Autoload sırası gereği
  locale TÜM sahnelerden önce set edilir.
- **Settings UI:** LanguageRow segmenti (Auto/English/Türkçe — dil adları endonym, her locale'de aynı;
  Controls segment deseni + ayrı ButtonGroup). Panel metin kurulumu `_apply_texts()`'e çıkarıldı →
  dil değişince panel KENDİNİ yerinde yeniler (ucuz-hibrit); diğer ekranlar sahne girişinde zaten
  yeniden kurulur. locale: SETTINGS_LANGUAGE/LANG_AUTO/LANG_EN/LANG_TR (+4 key, EN+TR).
- Test: **+2** — language sanitize/round-trip/legacy-default; panel dil basışı locale'i değiştirir +
  panel kendini "Ayarlar" olarak yeniden etiketler (gerçek sahne, tercih+locale restore'lu).
  **323/323, 1368 assert, temiz boot.** Etkilenen sahne: yalnız Settings.tscn.

**22a — Altyapı + string süpürme + P2-13 temizliği + TR sütunu (2026-07-04, UI yok):**
- **Mekanizma:** yerleşik TranslationServer + CSV genişletildi (custom sistem YOK). CSV'ye `tr`
  sütunu → üretilen `translations.tr.translation` project.godot'a kaydedildi (ÜRETİLEN dosya,
  CSV değil — Step 07 tuzağı). `fallback="en"` korunur. TR sütunu **TAM dolu** (~117 key —
  iskelet değil; Tuğra TR review yapacak). Kalan 8 dil Step 26.
- **BULUNAN GERÇEK BUG (süpürme bonusu):** 3 EN değeri quote'lanmamış virgül içeriyordu →
  Godot CSV import'u virgülde kesiyordu — `HOWTO_GOAL_BODY` ("Leave the safe border"de kırpık!),
  `LEVEL_C12_DESC`, `ARENA_EMBER_DESC`. Quote'lanarak düzeltildi + regresyon testi pinliyor.
- **Süpürme:** leaderboard tarih helper'ı locale'e bağlandı (`LEADERBOARD_TODAY`/`_YESTERDAY` +
  `MONTHS_SHORT` tek virgüllü liste; statik fonksiyonda `TranslationServer.translate` — ISO
  anahtarlar DEĞİŞMEZ); HowToPlay **Prev** butonu kodda hiç set edilmiyordu → `SETTINGS_BACK`
  bağlandı; Credits gövdesi `CREDITS_BODY` (çok satırlı quoted CSV; © satırı ortak);
  mode_select "%s / %s" birleştirme → `BOOST_APPLY_NOTE` (Campaign-dahil/Daily-hariç doğru metin).
  Bilinçli key'siz: wordmark/footer (marka), "II" glifi, sayı/sembol formatları, runtime-ezilen
  .tscn placeholder'ları (HowTo caption'ları dahil — hepsi `_apply_texts`'te eziliyor, doğrulandı).
- **P2-13 temizliği:** `HOWTO_PREV`, `MENU_LOADOUT`, `HUD_LIVES`, `GAME_TITLE` ölü key'leri SİLİNDİ.
  `HOWTO_LIVES_BODY` yeniden yazıldı (sabit "3 lives" kalktı; değişken can + self-touch ölümü).
- **`LocaleUtil` (saf, 22b zemini):** `resolve(saved, device_language)` — kayıtlı desteklenen dil >
  cihaz dili (destekleniyorsa) > "en". SUPPORTED=[en,tr] (Step 26 genişletir). OS çağrısı YOK
  (impure girdiler 22b'de AudioManager'dan geçecek).
- **GUT pre-run hook (`test/pre_run_hook.gd` + .gutconfig):** koşu EN'e sabitlenir — TR kayıtlıyken
  Godot açılışta OS locale'ini seçer; TR Windows'ta EN-metin assert'leri patlamasın diye ZORUNLU.
  Locale değiştiren testler `after_each`'te EN'e döner.
- Test: **+5** (`test_locale`): katalog EN+TR tam & 3-sütun & key benzersiz (süpürme bekçisi,
  FileAccess.get_csv_line ile quote-farkındalıklı); locale round-trip (tr→Oyna/en→Play);
  bilinmeyen key görünür fallback; resolver zinciri; virgül-kırpılma regresyonu. **321/321,
  1344 assert, temiz boot** (ilk import'ta tr.translation "cannot open" hatası NORMAL — dosya o
  koşuda üretiliyor; ikinci boot temiz, doğrulandı).
- Etkilenen: translations.csv (tam yeniden yazım) + project.godot + leaderboard_view/mode_select/
  how_to_play/credits (kod key bağlama) + locale_util.gd + .gutconfig/pre_run_hook. Sahne DEĞİŞMEDİ.
- Determinizm/gameplay: sıfır dokunuş (yalnız metin katmanı; DailySeed.date_string ISO kalır).

**22b (tarihsel plan; tamamlandı — 2026-07-04, 6d6a9ac):** Settings dil segmenti (Auto/English/Türkçe), `AudioSettings.language` persistence,
boot'ta `LocaleUtil.resolve(saved, OS.get_locale_language())` → `set_locale` (AudioManager._ready),
ucuz-hibrit canlı yenileme (Settings kendini yeniler; ekranlar sahne girişinde zaten kurar), GUT.
**İçerik:**
- Çok-dil iskeleti: tüm UI string'leri locale key'li (hard-code YOK), `tr()` üzerinden — büyük
  kısmı zaten key'li; kalan/eksikleri tara + tamamla.
- Dil seçici (Settings) + cihaz dilini varsayılan algılama; eksik çeviri → İngilizce fallback.
- CSV→`.translation` pipeline (mevcut desen) çok-dil için ölçeklenir; sayı/tarih biçimi gözden geçir.
- **Bu step = ALTYAPI** (1 dil tam çalışır kalır); gerçek 10-dil çeviri içeriği Step 26.

**Doğrulama:**
- Dil değiştirince tüm ekranlar çevrilir; eksik key fallback'e düşer (crash yok).
- Yeni dil eklemek = yalnız CSV sütunu (kod değişmez).

### Step 23 — AdMob entegrasyonu
**Durum:** 23A COMPLETE; 23B COMPLETE; 23C COMPLETE; 23D COMPLETE; 23E DEFERRED — physical Android device required (2026-10-07).
**İçerik:**
- 23A: AdsService autoload + AdsBackend/no-op/fake; benzersiz token, ayrı reward/close, duplicate/stale koruması, varsayılan kapalı privacy gate. SDK bağımlılığı yok.
- Onaylı ayarlanabilir v1: yalnız Results rewarded; yeni mission payout'u varsa temel PRE-Coin-Bonus payout'a +%50, ayrı eklenir/boost ile çarpılmaz; yerel gün başına en fazla 1 başarılı bonus.
- V1'de revive/Daily Reward reklamı/banner/interstitial/app-open/rewarded-interstitial yok.
- 23B: Poing stable 5.1.0 + Godot 4.6.3 Android paketi, Gradle, UMP/session consent ve koşullu Settings privacy entry complete; test debug APK ve 52/52 odaklı + 546/546 full GUT PASS; commit `ddd25c8` main'e ff-only merge/push edildi.
- 23C: PRE-Coin-Bonus temel görev ödemesinin %50 tabanlı, yerel gün başına tek kalıcı claim'i; Results ikincil reklam eylemi ve matching AdsService reward-earned callback bağlantısı complete. 23C.1/23C.2 main'e merge/push edildi.
- 23D: Results/reward lifecycle ve eski/duplicate callback dayanıklılığı complete; commit `018d12d`, full GUT 581/581 PASS.
- 23E: DEFERRED — fiziksel Android cihaz şu anda yok. Emulator/headless/native-build validation real-device AdMob/UMP acceptance SAYILMAZ.

**Step 23E fiziksel cihaz doğrulama listesi (henüz yapılmadı):**
- UMP consent akışı
- Gerekli olduğunda privacy-options girişi
- Google test rewarded ad load/show
- Reward-earned callback
- Ödülsüz kapatma
- Results bonus'unun tam bir kez verilmesi
- Reklam yaşam döngüsü sırasında uygulamayı background/foreground yapma

### Step 24 — IAP entegrasyonu
**Durum:** Bekliyor (Claude entegrasyon kodunu kurar; Tuğra mağaza ürün/test ayarı yapar)
**İçerik:**
- "Reklamları kaldır" (tek seferlik), currency paketi, kozmetik paket
- Satın alma doğrulama + restore purchases
- IAP wrapper'ı soyutlanmış; **rekabet gücü satılmıyor** (sadece kolaylık/kozmetik)

**Doğrulama:**
- Test satın alma çalışıyor, restore çalışıyor
- "Remove ads" kalıcı, reklam çağrılarını doğru kapatıyor

### Step 25 — Android export & cihaz testi
**Durum:** Bekliyor (Tuğra öncelikli — export ayarları)
**İçerik:**
- Android export preset, keystore (gizli), AAB üretimi
- Gerçek cihazda performans/dokunma/reklam testi (production build)
- İkon, splash, izinler, sürüm kodu

**Doğrulama:**
- AAB sorunsuz çalışıyor, FPS hedefi tutuyor
- Tüm akışlar (oyna/store/mission/reklam/IAP) cihazda doğrulandı

### Step 26 — Çeviri pass'i (10 dil)
**Durum:** Bekliyor (Step 22 altyapısı üstüne; Android'den sonra, içerik kilitlenmişken)
**İçerik:**
- ~10 dile çeviri (CSV sütunları): metinler son haline yakınken yapılır (yeniden-çeviri israfı yok).
- Diller (taslak): EN, TR, ES, PT-BR, DE, FR, RU, JA, KO, ZH (mağaza erişimine göre netleşir).
- Çeviri kalite/uzunluk kontrolü (UI taşması), mağaza metadata dilleriyle hizalı.

**Doğrulama:**
- Her dilde ana ekranlar taşmadan okunur; eksik key fallback'e düşer.

### Step 27 — iOS export & App Store hazırlık
**Durum:** Bekliyor (Tuğra öncelikli — Xcode/sertifika; Mac erişimi gerekir)
**İçerik:**
- iOS export, Xcode projesi, imzalama, ATT izin akışı
- AdMob iOS tarafı doğrulama
- Apple Developer hesabı, App Store Connect kaydı

**Doğrulama:**
- iOS cihaz/simülatörde çalışıyor, ATT akışı doğru
- App Store Connect'te uygulama kaydı hazır

### Step 28 — Mağaza listeleme & yayın (çok-dilli)
**Durum:** Bekliyor
**İçerik:**
- ASO: başlık, açıklama, anahtar kelimeler, ekran görüntüleri, tanıtım (çok-dilli metadata)
- Gizlilik politikası (zorunlu), veri güvenliği formu, içerik derecelendirme
- Her iki mağazaya build gönderimi, review süreci
- Yayın sonrası: temel analytics + crash takibi

**Doğrulama:**
- Her iki mağaza review'dan geçti, uygulama canlı
- Gizlilik politikası ve store metadata eksiksiz

### Launch Sonrası / v1.1 Backlog (launch'ı BLOKLAMAZ)
**Durum:** Ertelendi — sağlam çekirdekle çık, güncellemelerle besle. (Tüm "sonraya" maddeleri BURADA
toplanır; dağıtma.)

**İçerik & mod genişlemesi**
- **Ekstra arena + karakter** (mevcut 3 arena / sidegrade karakter üstüne içerik genişlemesi).
- **Roguelite draft / gelişmiş Campaign hedefleri** (zone-capture, fog, boss-level).
- **Tema / event varyasyonları** (sezonsal, özel günlük modlar).

**Boost & düşman çeşitliliği**
- **Fire boost (aktif ateş etme):** pygame sürümünde vardı. Diğer boost'lardan KATEGORİK farklı
  (in-run kontrol + projectile + düşman-isabet modeli) → tek-satır tune DEĞİL, **kendi PLAN'ı + step'i**.
  "Düşman öldürülemez" felsefesini etkileyebilir (dikkatli tasarım). v1.1 adayı.
- **Gelişmiş düşman tipleri:** Patroller, hızlı-avcı Chaser varyantı, **in-stage ramp** (D1 A→C evrimi).

**Skor & sosyal**
- **Online/global leaderboard** (şu an yalnız yerel daily best-per-day).
- **Level-Endless kişisel high-score persistence** (SaveData alanı + submit → leaderboard'a Endless sekmesi).

**Platform & teknik**
- **Apple/iOS yayını** (Mac erişimi gerektiğinde) + **Apple Sign In**.
- **Gerçek bloom/glow için renderer upgrade** (gl_compatibility → Forward+/Mobile; şu an fake-glow).

## Fix-Pass Kuyruğu (sıralı — paralel YOK)

Cila/eksik/bug maddeleri. Her madde ayrı **PLAN → ONAY → KODLA → RAPOR**; sırayla işlenir.

1. **Kontrol şeması seçici** — ✅ main'de (commit c56d6aa). Settings'e
   "Controls" segment (Swipe/Tap/D-Pad, ButtonGroup radyo, seçili=accent); `audio_settings`'e
   `control_scheme` + `AudioManager.set_control_scheme` (save); Game `_ready` player'a uygular →
   D-pad seçiliyse DpadView görünür. locale `SETTINGS_CONTROLS`/`CONTROL_*`. 220/220 (+control_scheme
   round-trip/clamp). *(şemalar + DpadView zaten vardı; eklenen = seçici + persist.)*
   **Ek (2026-06-20):** Pause→Settings — `PauseOverlay`'e Settings butonu, `Settings.tscn` overlay
   olarak açılır (`embedded`, process_mode ALWAYS; Back/Esc kapatır, MainMenu'den `change_scene`
   korunur). Canlı uygula: `AudioManager.control_scheme_changed` sinyali → `game` → `player.set_scheme`
   (mid-run anında + DpadView güncellenir); ses zaten bus'tan canlı.
2. **Leaderboard görünüm ekranı** — ✅ main'de (commit dce5200). `Leaderboard.tscn`
   + `leaderboard_view.gd`: yerel daily best-per-day (tarih-desc, bugün vurgulu, son 60), "All-time
   best: N" header, empty-state. `Leaderboard.gd`'ye `scores()`/`best_ever()` (pure). MainMenu
   "Leaderboard" butonu. locale `MENU_LEADERBOARD`/`LEADERBOARD_*`. 222/222 (+scores/best_ever +view).
   *(Free/Level-Endless high-score persistence yok → v1.1.)*
   **Görsel + tarih (2026-06-21):** kart satırlar (StyleBoxFlat cam+neon+yuvarlak), skor-desc +
   rank #N (top-3 altın/gümüş/bronz), skor büyük+altın/tarih muted, bugün accent kenar+glow.
   Dostane tarih (`format_date` pure: Today/Yesterday[epoch-day]/Jun 19/Jun 19, 2025) — ISO
   anahtar DEĞİŞMEZ. 228/228 (+kart render +6 date helper).
3. **How-to-play + açıklamalar** — ✅ main'de (commit c83ba57). `HowToPlay.tscn`
   4-sayfa carousel (Amaç/Kontroller[seçili şema]/Düşmanlar[Bouncer-Stalker]/Canlar; nokta + İleri-Geri,
   son "Got it"). MainMenu sol-üst motoriçi **"?"** ikonu + ilk-açılışta otomatik 1 kez
   (`SaveData.tutorial_seen`, entry'de set; Economy getter/setter). Arena/Karakter `.tres`'e
   `description_key` (data-driven) → Store satırında isim altında açıklama. locale `HOWTO_*`/
   `ARENA_*_DESC`/`CHAR_*_DESC`. 232/232 (+tutorial round-trip +howto nav/desc). *(Bouncer=void/ember,
   Stalker=frost teyit.)*
   **İterasyon (2026-06-21):** her sayfada motoriçi **X** (erken menüye dönüş, herhangi sayfadan);
   Kontroller sayfası artık **3 şemayı da** anlatır (seçiliye bağlı değil) — her biri mini glyph
   (swipe oku/tap halka/d-pad artı). **Görseller (motoriçi):** Amaç=capture diyagramı (logo reuse),
   Düşmanlar=Bouncer daire+Stalker üçgen, Canlar=3 kalp (hearts reuse). **Store:** karakter effect
   ikonu (push/slow/freeze) + arena tema swatch. 233/233.
4. **Skor modeli** — ✅ main'de (commit 0d8de40; his/tune Tuğra'da). `score = capture(area×base×
   combo) + exposed-bonus − life-penalty`. ScoreKeeper: `register_capture(...,exposed_seconds=0)` +
   `floor(min(exposed,cap)×rate)`, `apply_life_penalty()` (floor 0); 2-arg geriye uyumlu. game
   `_exposed_time` (is_exposed iken += delta; safe/duvar=0; kapatma+fail'de sıfır). GameState
   start_run knob'ları + lose_life ceza. BalanceConfig `exposed_points_per_sec=10`/`exposed_cap_sec=10`/
   `life_loss_penalty=400` (TUNE). Skor sadece çıktı (seed/ghost etkilenmez); mission REACH_SCORE aynı
   toplam. 241/241 (+8). Geriye uyum: eski leaderboard kayıtları eski modelle (migration yok).
5. **Polish: Result panel buton casing** — ✅ main'de (commit 52e39d5). `RESULT_RETRY` "RETRY"→"Retry" (Title Case);
   tüm butonlar Title Case (Retry/Menu/Resume/Back…) tutarlı. Result başlıkları (YOU WIN!/GAME OVER)
   bilerek UPPER (başlık). HUD.tscn placeholder'ları da güncellendi. 241/241.
6. **BUG: Stalker üst-üste binme** — ✅ main'de (Step 19a / commit 44de747; #6 fold). Chaser homing'i per-enemy
   `variation` ([-1,1], tip-içi eşit dağılım) × `spread_rad` kadar döner → farklı açıdan yaklaşır,
   üst üste binmez. `decide()` variation param (default 0 geriye uyumlu), `EnemyMotion.even_spread`,
   `ChaserBehavior.spread_rad` @export. Index-tabanlı (RNG yok) → daily/ghost reproduce korunur.
7. **Oyuncu self-touch → can kaybı** — ✅ main'de (commit c007b8c). `player.gd:_try_step` TRAIL dalı:
   **non-adjacent kendi trail'ine adım** (gerçek self-cross) artık **blok YERİNE can kaybı** (yeni
   `self_hit` sinyali) — Qix/Volfied standardı; eski "blocked, keep heading" takılma/hapsi bitti.
   **Backtrack** (bir önceki TRAIL hücresi → geri-sar) ve **tek-hücre backtrack-cancel** ve
   **CAPTURED'a dönüş = loop_closed (kapatma)** KORUNDU (ölüm değil). Ölüm pipeline ENEMY ile birebir
   aynı: `game._on_enemy_hit_trail` → jenerik **`_on_trail_failed`** rename; `enemy.hit_trail` +
   `player.self_hit` ikisi de buna bağlı (flash+shake+sfx+haptic + `fail_trail` + `respawn` +
   `lose_life`). Telegraph yok (mevcut life-loss juice). **Auto-advance ADALET (kanıt):** adım hücre-
   hücre (`move_interval` başına 1) + her adımda intent poll → oyuncu çizgiye VARMADAN dönebilir; ayrıca
   **boxed olsa bile reverse=backtrack güvenli** (ölüm değil) → self-cross asla kaçınılmaz değil
   (tolerans-hücresi EKLENMEDİ, kural net). capture/seed/grid DEĞİŞMEDİ (yalnız player.gd else dalı);
   grid-seviye self-intersection testi dokunulmadı. Yeni `test_player_self_cross` (self-cross emit /
   backtrack güvenli / captured-kapatma ölüm değil). 286/286 (+3). Deterministik (input-driven) →
   daily/ghost korunur.
8. **Chaser exposed-homing regression fix (19a recovery)** — ✅ main'de (commit 24a56ee, branch
   `step/fix-enemy-behavior`; not: planlanan ad `step/fix-chaser-homing` idi, gerçek branch adı bu). **Kök:** `decide_velocity`, `_recovery_timer>0` iken homing'i KÖR bastırıyordu; 19a her
   captured-sekmede recovery set ettiğinden, exposed oyuncu captured kenara bitişik çizince chaser
   sürekli sekip recovery kesintisiz → homing hiç gelmiyor, kenarda peel-off dönmesi (Drag amplifier:
   slow→dwell↑). **Fix (A yönsel):** recovery artık homing'i kesmez; `_peel_adjust` yalnız **az
   çarpılan duvara doğru bileşeni** siler (`_recovery_normal` = dış normal, `_advance`'te set), teğet+dışa
   homing serbest → kenarda kaymayı sürdürür, düz duvara homing YOK (anti-pin korunur). Freeze yolu
   (Halt) aynen tam-bastırma. **(C tetik-daraltma UYGULANMADI:** A'yı yaptıktan sonra gereksiz + arena
   çerçevesi sekmelerinde recovery'yi kaldırmak frame-pin'i geri getirir → 19a faydası bozulurdu; rapor
   edildi.) Bouncer/Sparx/Halt/Pulse/Drag davranışı değişmez. Deterministik. Genel enemy fix (Campaign'e
   özgü değil). Test: `_peel_adjust` (into→peel / teğet-kayar / dışa-serbest) + chaser recovery'de homing
   (kenarda dönmez). 305/305 (+4).
   - **Spawn üst-üste-binme fix (2026-07-03):** variation yalnız homing AÇISINI ayırıyordu; non-edge
     düşmanlar hâlâ arena MERKEZİNDE aynı noktada spawn olup üst üste biniyordu. `EnemyMotion.spawn_offset`
     (index/count → ring; 2 düşman = zıt taraflar, RNG yok) ile spawn pozisyonu yayıldı (`center + offset`,
     radius `cell_size*3`). Deterministik → daily/ghost. 308/308 (+3).
   - **Level içerik tune (c06):** 2 Sparx (edge-walker tek başına iç-tehdit yok = anlamsız/basit) →
     **2 Sparx + Bouncer, target 65%** (bouncer iç baskı + yüksek hedef → sparx kenar cezası anlam kazanır).
   - **Çift-can bug fix (2026-07-03):** aynı ölüm anında birden çok `hit_trail` (iki bitişik Sparx / respawn'da
     yeniden yakalanma) her biri ayrı `lose_life` çağırıyordu → 1 çarpmada 2 can. **Fix:** ölüm sonrası
     **dokunulmazlık penceresi** — `game.death_grace` (1.0s @export); `_on_trail_failed` başında
     `_death_grace_timer>0` ise hit YOK SAYILIR (+ oyuncu blink). 1 ölüm = tam 1 can, respawn-chain-kill biter.
     `_lives_lost` (flawless star) da tek sayar. Test: çift `_on_trail_failed` → 1 can. 311/311.

9. **Audit P0 paketi** — ✅ main'de (commit 1473265, branch `step/audit-p0`; 2026-07-04 merge).
   Geriye dönük audit raporunun P0 bulguları + küçük hardening:
   - **P0-1 (BUG):** CONTAINED (görünmez/inert) Sparx artık capture **danger-seed DEĞİL**
     (`game._enemy_cells` filtresi) ve **near-miss taramasına GİRMEZ** (`near_miss.gd`) →
     hapsedildiği cep contain sırasında KAPATILABİLİR (onaylı tasarım kararı: görünmez düşman
     alan bloke etmez), hayalet vignette/slow-mo yok. Yeni `Enemy.is_contained()` (yalnız
     CONTAINED true; TELEGRAPH/PATROL aktif sayılır). capture/seed/grid algoritmasına
     DOKUNULMADI (yalnız orchestration filtresi).
   - **P0-2 (ADALET):** Kombo penceresi wall-clock'tan (`Time.get_ticks_msec`) **fizik-zamana**
     taşındı — `game._run_time` (fixed-step birikimli, yalnız is_playing'de) `register_capture`'a
     geçer. Pause kombo penceresini artık YEMEZ; slow-mo/hitstop pencereyi oyun-zamanı cinsinden
     kısaltmaz. ScoreKeeper imzası/testleri DEĞİŞMEDİ (zaman zaten enjekteliydi; yalnız kaynak).
   - **P0-3 (SIZINTI):** `AudioManager.control_scheme_changed` bağlantısı lambda → named method
     (`_on_scheme_setting_changed`) + `_exit_tree`'de disconnect → her Game reload'unda autoload
     üstünde bağlantı birikmez, freed-sahne lambda'sı kalmaz.
   - **P1-9 (GUARD):** player.gd KEY_1/2/3 şema toggle artık `OS.is_debug_build()` guard'lı
     (game.gd dev tuşlarıyla tutarlı; release'de klavyeyle Settings tercihi bypass edilemez).
   - **P2-18 (PRINT):** game.gd'nin 5 guard'sız print'i (daily/arena/karakter/stage/campaign)
     debug-guard'landı; daily print'teki yanıltıcı "stages=%d" ibaresi kaldırıldı (çok-stage
     daily zaten geri alınmıştı — ölü knob temizliği ayrıca P1-4, bu pakette DEĞİL).
   - **P1-7 (BELGELEME):** Sparx territory-efekt muafiyeti bilinçli karar olarak Step 09 notuna +
     `HOWTO_ENEMIES_BODY`'ye ("ignores your territory's power") işlendi. Kod değişikliği yok.
   - Test: **+4** — `test_sparx` (is_contained yalnız CONTAINED'de; contained ≠ danger-seed
     [gerçek Game sahnesi]; contained near-miss tetiklemez / PATROL tetikler) + `test_pause`
     (pause kombo saatini dondurur). **315/315, 847 assert, temiz koşu.** Determinizm korunur
     (RNG yok; P0-2 skor zamanlamasını oyun-zamanı determinizmine İYİLEŞTİRİR).
   - Etkilenen dosyalar: `enemy.gd` (+is_contained), `game.gd` (filtre + _run_time + named
     connect/disconnect + print guard), `near_miss.gd` (filtre), `player.gd` (guard),
     `locale/translations.csv` (1 satır), test ×2. Sahne dosyası DEĞİŞMEDİ.

10. **Sparx trap → cep otomatik capture (ödül mekaniği)** — ✅ main'de (commit d6fe0f2, branch
    `step/10-sparx-pocket-capture`; 2026-07-04 merge). **P0-1 ÖN KOŞUL** (contained Sparx seed
    değil → cep seed'siz kalır → mevcut mekanizma alır).
    - **Mekanik (çekirdek REUSE, yeni flood YOK):** `enemy.on_capture_event() -> bool` (yalnız
      PATROL→CONTAINED geçişinde true). `game._on_area_captured`: enemy döngüsünden sonra herhangi
      bir Sparx YENİ contain olduysa → `_arena.close_capture(_enemy_cells())` bir kez daha (**SYNC**,
      aynı capture sinyali içinde — o anda oyuncu kesin çizmiyor, aktif trail yutulamaz). Cep =
      seed'siz izole FREE bölge → `close_and_capture` sözleşmesi gereği otomatik dolar. %, skor,
      kombo (tetikleyen x1 + cep x2 zinciri), mission area, capture juice, win/advance → hepsi
      fill'in KENDİ `area_captured` emisyonundan, normal pipeline'la akar.
    - **Fork kararları:** SYNC (1-A) · tam sayım + SINIRSIZ (2-i; Claude kararı — doğal üst sınır
      var: contain tetiği "ana-olmayan bileşen" olduğundan otomatik dolan bölge DAİMA kalan FREE'nin
      en büyüğü DEĞİL, yani <%50'si; ayrıca ana bölge aktif düşman içerdikçe seed'li → asla dolmaz) ·
      tam juice + `cells.is_empty()` guard'ı (3): boş capture (engulf cep=0 / seed'li cep fill'i)
      area/skor/juice EKLEMEZ (genel boş-capture hardening).
    - **BELGELİ DAVRANIŞ (Fork 5):** cepte AKTİF (görünür) düşman varsa (bouncer/chaser) cep DOLMAZ —
      aktif düşman seed olarak alanı tutar (P0-1 semantiğiyle tutarlı: yalnız görünmez düşman alan
      tutamaz). Sparx yine contain olur, main'e re-emerge eder; cep manuel kapatılabilir kalır.
      Re-emerge değişmedi (`_reproject_to_main` zaten ana bölgeyi hedefler; cep captured = dönüş
      sorunu kökten yok). Çoklu Sparx / çoklu cep: tek fill hepsini kapsar.
    - **Determinizm:** cep = grid connectivity (RNG yok), seed'ler = deterministik düşman hücreleri,
      SYNC aynı fizik karesi → daily/ghost reproduce. capture ÇEKİRDEĞİ değişmedi (yalnız çağrıldı).
      Re-entrancy güvenli: contained Sparx ikinci event'te false döner (fill tekrarı yok), iç
      emisyonun win/advance'i mevcut `is_playing`/`_advancing` guard'larıyla çakışmaz.
    - Test: **+4** — `on_capture_event` yalnız ilk geçişte true; uçtan-uca cep dolumu (gerçek Game:
      CAPTURED + %↑ + ana bölge FREE kalır + kombo x2 + terminasyon); aktif-düşmanlı cep dolmaz +
      boş fill area eklemez; boş capture event skor/area/crash yok. **319/319, 862 assert.**
    - Etkilenen: `enemy.gd` (~5 satır), `game.gd` (~15 satır), `test_sparx.gd`. Sahne DEĞİŞMEDİ,
      yeni autoload YOK.

11. **Audit temizlik paketi (ölü kod + PROGRESS senkron)** — ✅ main'de (commit d76f31a, branch
    `step/audit-cleanup`; 2026-07-04 merge). **DAVRANIŞ DEĞİŞMEDİ** — yalnız ölü kod silme + doküman:
    - **P1-4 (çok-stage Daily kalıntıları):** `game._advance_stage` ölü daily-gauntlet dalı,
      `daily_stage_count` knob'u (progression_config.gd + .tres) ve `stage_plan.gd` daily stage>0
      salt-shift yolu (+ STAGE_STRIDE/STAGE_SEED_SALT sabitleri) KALDIRILDI. Daily = tek-arena,
      yalnız stage 0 istenir (grep + canlı-yol analiziyle doğrulandı: dal hiç çağrılmıyordu).
      `test_stage_plan` ramp testleri gerçek sahibi olan endless yoluna çevrildi (9 test korundu);
      daily stage-0 golden testleri aynen.
    - **P1-6:** `EnemyMotion.is_behavior_suppressed` (directional peel almıştı yerini; grep: yalnız
      test kullanıyordu) + onu pinleyen 3 ölü test SİLİNDİ.
    - **P2-11 (karar: SİLME değil REZERVE):** `player.trail_started/returned_to_safe` (juice
      haritasındaki "çizerken yükselen gerilim" sesi için hazır kanca) + `arena.capture_failed`
      (area_captured'ın fail ikizi) RESERVED yorumuyla işaretlendi; `GameState.reset` test-temizlik
      API'ı olarak yorumlandı (onlarca test kullanıyor — ölü değil). `.tscn` bağlantısı grep'le tarandı: yok.
    - **P2-12 (karar: KALDIR):** `LevelData.star3_percent` alanı + 12 level .tres'indeki değerler
      SİLİNDİ (yeni yıldız modeli skor+cansız; alan hiçbir yerden okunmuyordu — tune yanıltmasın).
      `test_campaign._level` helper'ı sadeleşti; CampaignStars docstring'i güncel modele çekildi.
    - **P2-14:** enemy.gd `_steered/_frozen` tint'leri KALICI efekt-geribildirimi olarak benimsendi,
      TEMP etiketleri kalktı (Açık Sorunlar Step 06 maddesi kapandı; zengin VFX v1.1).
    - **P2-17:** hud.gd "DEV/placeholder Step 13/14" + mode_select.gd "Step 18.1" stale yorumları güncellendi.
    - **PROGRESS senkron:** header; roadmap Step 21 [x]; Fix-Pass #8 → main'de 24a56ee (gerçek branch
      `step/fix-enemy-behavior`); "Sonraki Step" → Step 22; Üretilen Sonuçlar tablosuna Step 16-21;
      Step 07 Drag tune güncellemesi (0.4/0.6, 0cf9099); Açık Sorunlar Step 04 (death_grace) +
      Step 06 (tint) kapanışı; Step 14 dev-tuş notu.
    - Test: **316/316, 860 assert** (319 − 3 ölü test; davranış testi eklenmedi — silme+doküman paketi).

12. **Feel-Pass P0 (görsel/his cilası — 5 madde)** — ✅ main'de (commit 31815d7 fx + arena görselleri
    b67226b içinde; 2026-07-07 merge). Kaynak: oynanış-hissi/polish audit'inin P0 quick-win'leri.
    **TÜMÜ SALT GÖRSEL/ÇİZİM katmanı** — capture/seed/grid/gameplay timing SIFIR dokunuş;
    determinizm/daily/ghost aynen (görsel saat/tween gameplay tarafından OKUNMAZ). Tüm dozlar @export.
    - **P0-1 Capture parlama-sönme:** `arena_controller` — yeni captured hücreler ilk kare parlak
      overlay ile boyanır, `flash_duration`(0.25s)'de captured rengine söner (`_flash_cells` +
      `_process` yalnız flash aktifken). **KRİTİK invariant:** grid durumu İLK KAREDEN tam CAPTURED —
      boyama gecikir, durum gecikmez (testle pinli). Aynı karedeki cep-dolumu (#10) flash'e MERGE edilir.
    - **P0-2 HUD hedef göstergesi:** "%.0f / %.0f%%" ("62 / 75%") — hedef artık ekranda (UX boşluğuydu);
      hedefin `near_target_ratio`(0.9)'una gelince accent renk + mini pulse. `set_target` stage/level
      başında game'den (Endless ramp'te stage başına güncellenir).
    - **P0-3 Poof'lar (CaptureBurst REUSE, yeni sahne yok):** oyuncu ölüm NOKTASINDA palet-danger burst
      (game._on_trail_failed); Sparx contain'de sıkı içe-puf + re-emerge/relocate'te dışa mini-pop
      (enemy `_spawn_poof`, `poof_scale` @export, 0=kapalı; logic-only testler için is_inside_tree guard).
    - **P0-4 Result + yıldız reveal:** panel scale-in (0.9→1 BACK + fade, `result_pop_time`); Campaign
      yıldızları TEK TEK (`star_stagger` 0.15s, punch + `play_sfx("star")` hook'u — asset sonra);
      "New best!" en sonda pop.
    - **P0-5 Trail glow + baş + exposed oyuncu:** trail çift-geçiş (altta `glow_width`/`glow_alpha`
      geniş soluk halo — gl_compat fake glow), en yeni trail hücresi `head_brightness` ile parlak
      (arena `_trail_head`, backtrack'te güvenli sıfırlanır); oyuncu elması çizerken `exposed_pulse_scale`
      (%8) büyür + parlar, güvende söner (lerp, `_visual` null-guard'lı — logic-only Player testleri kırılmaz).
    - Dokunulmayanlar: time_control/hitstop, near-miss vignette, hearts, stage banner, juicy_button,
      trauma² shake, floating score, MainMenu amblem, pause (audit "dokunma listesi" aynen korundu).
    - Test: **+4** (`test_feel_pass`): flash paint-only invariant (hücre ilk kare CAPTURED + flash
      decay temizliği); HUD "62 / 75%" + hedef takibi; contain poof spawn; yıldız stagger reveal
      (boş başlar → "★★☆" + New-best sonda). **327/327, 1381 assert, temiz boot.**
    - Etkilenen: arena_controller / hud / player / enemy / game (+test). Sahne dosyası DEĞİŞMEDİ.

13. **Campaign eğri revizyonu + oyuncu hızı + dolma dalgası** — ✅ main'de (eğri+hız commit d1ac670;
    dalga b67226b içinde; 2026-07-07 merge).
    - **Campaign zorluk eğrisi (LevelData verisi — kod değil):** c09 "nefes" KALDIRILDI → gerçek
      basamak oldu (void, [bouncer,bouncer,chaser,sparx], %65, sm 1.2; locale desc "Rising swarm").
      Eğri artık DÜZ ARTAN: speed_mult 1.0→1.3 kademeli (c03'ten itibaren her 2 level +0.05),
      target %50→%75, kompozisyon 1→6 düşman — hiçbir eksen geri düşmez. star2_score yeni zorluğa
      göre yükseltildi (c05+ kademeli, c12=2000). Değişen: c03-c12 .tres (c01/c02 tanıtım aynen).
      **Bekçi test:** `test_campaign_curve_monotonic_no_breather` — speed/target/düşman-sayısı
      non-decreasing + finale doruk; "nefes yok" kararı DATA invariant'ı olarak pinli.
    - **Oyuncu hızı:** `move_interval` 0.04 → **0.045** (~%12 yavaş; ~250→~222 px/s eşdeğeri).
      Ghost etkisi TEYİT: ghost kayıtlı-POZİSYON oynatımı (resimülasyon değil) → eski ghost'lar
      bozulmaz, kendi kayıtlı hızlarıyla oynar (yalnız kozmetik fark). Deterministik (sabit interval).
    - **Dolma dalgası (P1-6, P0-1 üstüne):** flash artık kapanış CENTROID'inden dışa mesafe-gecikmeli
      pulse dalgası (`wave_delay_per_cell` 0.012 @export; hücre pulse'ı varışta parlar,
      `flash_duration`'da söner). **Invariant KORUNUR:** captured taban dolgusu İLK KAREDEN çizili —
      dalga yalnız parlaklık katmanı; ard arda capture'lar ortak saate offset'le merge olur.
      Test: paint-only invariant güncellendi + `test_capture_wave_spreads_from_centroid`
      (centroid önce, uzak hücre sonra). Poof'ların test-sonu temizliği (`after_each` sweep —
      GUT unfreed-children uyarıları giderildi).
    - **329/329 test, 1434 assert, temiz koşu.** capture/seed/grid DEĞİŞMEDİ; determinizm aynen.

14. **Perf-Pass — capture kasma düzeltmesi** — ✅ main'de (commit b67226b; 2026-07-07 merge).
    Kaynak: ÖLÇÜLMÜŞ teşhis (Tuğra'nın makinesinde mikro-bench). Capture
    ÇEKİRDEK algoritması DEĞİŞMEDİ; tümü görsel/orchestration katmanı. **Ölçülen kazanımlar:**
    - **(1) `_draw` taraması:** `cell_at()` çağrıları yerine `grid.cells()` (YENİ read-only
      PackedByteArray erişimi — capture_grid'e isim-düzeyi ek, mantık sıfır; P2-15 ailesi işaretli)
      + yerel indeksleme → **63.1 ms → 3.6 ms / redraw (17.7×)**. Aynı hücreler/renkler
      (`test_cells_accessor_matches_cell_at` tam-grid eşitlik invariant'ı).
    - **(2) Taban cache + ayrı katman:** flash dalgası artık kod-üretimli child **FlashLayer**
      node'unda (`scripts/fx/capture_flash_layer.gd`, sahne dosyası değişmedi) — dalga penceresi
      (0.25-0.8s) boyunca taban dolgusu HİÇ yeniden taranmaz; taban yalnız grid değişince çizilir.
      Not: pulse artık border çizgisinin üstünde (child render sırası) — kenar hücrelerde 0.25s'lik
      önemsiz görsel fark.
    - **(3) Flash merge:** pulse başlangıçları `wave_quantize`(1/30s @export)'a kuantalanıp satır-run
      birleştirme → yarım-board'da **3286 tekil rect → 845 merged rect** (kare başına aktif alt-küme
      ~⅓'ü); kurulum 3.4 ms tek seferlik. Kapsama invariant'ı: merged run'lar TAM OLARAK yeni
      hücreleri örter (test).
    - **(4) Sparx trap flood paylaşımı:** ana-bölge seed'i capture başına **1 kez** game'de hesaplanıp
      tüm devriye Sparx'lara parametre geçer (`on_capture_event(main_seed)`, sentinel'li geriye-uyumlu;
      `wants_capture_events()` ile Sparx'sız arenalarda flood tamamen atlanır) → 2-Sparx karesi
      **93.7 → 46.9 ms**. Karar eşitliği testli (`test_shared_main_seed_same_trap_decision`).
    - **Kalanlar (bilinçli):** capture çekirdek flood'u ~22-36 ms (tek seferlik, hitstop arkasında;
      #5 PackedByteArray-visited çekirdek optimizasyonu REDDEDİLDİ-kayıtlı = Onay Gerektiren Karar);
      Sparx başına ÜYELİK flood'u hâlâ ayrı (paylaşım kapsam dışıydı — gerekirse sonraki tur).
      → GÜNCELLEME (2026-07-08): #5 emülatör teşhisiyle AÇILDI ve uygulandı — bkz. Fix-Pass #15
      (Onay Gerektiren Karar onaylı; PC'de "değmez" gerekçesi mobil hedefte geçersizleşti).
    - Test: **+2, 331/331, 1444 assert.** Determinizm aynen (aynı hücreler/kararlar, sadece hızlı).
    - **Dalga hız tune'u (2026-07-07 ek):** `wave_delay_per_cell` 0.012→**0.007** + YENİ
      **`wave_max_duration`** (0.4s @export) — süpürme toplam süresi cap'li: küçük alan doğal
      per-cell hızda, cap'i aşacak büyük alanda gecikmeler normalize edilir (delay = dist/max_dist
      × cap) → dev capture'lar da ~0.4s'de süpürülür, sürünme yok. Salt görsel; invariant aynen.
      Test: cap bağlayınca ~0.1s'e sıkışma + cap altında per-cell hız değişmez. **332/332.**

15. **Perf #5 — çekirdek flood Dictionary → PackedByteArray** — ✅ main'de (commit 454b7ae,
    branch `step/perf-core-flood`; 2026-07-21 ff-merge). **ONAY GEREKTİREN KARAR (capture
    çekirdeği) — Tuğra onaylı, VALİDE.** Gerekçe: emülatör teşhisi — her capture'da ~70-180 ms tek-kare
    spike (hitstop 50-80 ms'i aşıyor); kök = `_flood_free`/`_largest_free_component_seed`'in
    Dictionary(Vector2i) visited yapısı. **ALGORİTMA/SONUÇ SABİT — yalnız iç veri temsili:**
    mask=PackedByteArray (y*cols+x) + PackedInt32Array int-stack; LIFO + komşu sırası
    (RIGHT/LEFT/DOWN/UP) + dış row-major tarama + strictly-greater tie-break AYNEN; satır-sarma
    guard'ları cell_at OOB≡CAPTURED'ın birebir eşdeğeri ("ring garantisine güvenilmedi").
    API/CaptureResult/public yüzey değişmedi; enemy._flood_free_set dokunulmadı.
    - **Diferansiyel eşdeğerlik (geçici harness, silindi):** eski gövdelerin verbatim kopyası vs
      yeni — 10 senaryo (boş/yarım-board/çift-cep/tek-hücre/near-full/L/spiral/seedless-fallback/
      dupe-seed/captured+OOB-seed) → **flood kümesi + largest seed + newly listesi (SIRA dahil)
      10/10 ÖZDEŞ.**
    - **Bench (aynı yük, Tuğra makinesi):** flood **40.6 → 3.7 ms (11×)**, largest **54.5 → 4.3 ms
      (12.7×)**. Emülatör tahmini (×3-5): capture çekirdeği ~12-18 ms → hitstop'un rahat arkasında.
    - **Kalıcı bekçi:** `test_capture_matches_reference_reachability` — test-içi bağımsız naif BFS
      referansına karşı 3 authored board (gelecek her çekirdek dokunuşunun bekçisi).
    - Test: **334/334, 1506 assert** — 13 capture golden + determinizm + seed golden SAPMASIZ geçti
      (DUR gerekmedi). Determinizm/daily/ghost birebir (dict zaten yalnız .has()/.size() idi).
    - **Saha teyidi:** capture "tık"ı kaybı emülatörde ayrıca doğrulanacak (mobil TODO ile birlikte).

**Aktif:** Fix-Pass #9-#20 + Step 22 **TÜMÜ MAIN'DE** (main @ 6250db3, origin senkron, lineer ff-only).

- **#17 Feel-Pass P1** (a89c73f, `step/feel-pass-p1`, 2026-09-16): düşman canlılığı + unlock kutlaması +
  kombo eskalasyonu, salt görsel. **349/349 test.**
- **#18** (9d61221, `step/enemy-hitbox-chaser-layout`, 2026-09-22): B1 Sparx Chebyshev + grace tek-sahip +
  B2 Chaser görüş-hattı + B3 pause layout + başlangıç grace. **363/363 test.**
- **#19 Adaptive Chaser** (293aa8b, `fix/19-adaptive-chaser`, 2026-09-22 — yeni `fix/NN-` isim kuralının
  İLK örneği): Campaign c09–c12 + Level-Endless stage 6+'da Chaser en yakın tehdidi (kafa/trail) avlar.
  **374/374 test.**
- **#20 Düşman sıkışma durumları** (f9e581e, `fix/20-enemy-stuck-states`, 2026-09-23): B5 (grace-bounce +
  seed-düzeltme + tahliye güvenlik ağı) + B6 (periyodik sınırlı trap kontrolü) + B7 (roam eksen-kilidi) +
  kalıcı bekçi değişmez. **392/392 test.** Ölçüm: B6 sızan cep artık 76. karede contained (öncesi: 2000
  karede hiç); B7 eksen-kilitli kare 250/600→0/600, x-yayılımı 177→591 px.
- **#21 Endless stage start-grace** (2026-09-25, `fix/21-endless-stage-start-grace` → main, commit
  `a4864fc`): **TAMAMLANDI, origin/main senkron.** Stage 3 Frost spawn-kill kökü: stage transition Player.setup reseti + grace rearm eksikliği.
  `_advance_stage()` yeni stage'den ÖNCE mevcut start-grace'i rearm eder; Sparx/hitbox/spawn/capture/grid
  değişmez. **395/395, 1817 assert. Manuel Stage 3 kabul PASS:** oyuncu park hâlindeyken spawn-kill yok.
  A4 Stage 5→6, #22 curve manuel acceptance'ında yeniden denenmeli.
- **#22 Endless progression curve** (2026-09-25, `fix/22-endless-progression-curve` → main, commit
  `167abc6`): **TAMAMLANDI, origin/main senkron.** B1-R authored Stage 1–8 + Stage 8'e anchored procedural Stage 9+; Endless-only pace
  normalization; final roster explicit spawn override ile, cap 7 (late Bouncer→Sparx). Free/Daily/Campaign,
  capture/seed/ghost ve enemy behavior değişmez. **401/401, 2036 assert. MANUAL PARTIAL PASS / EARLY CURVE
  ACCEPTED:** Stage 1–6 doğal bulundu; eski Stage 2→3 wall yok, Chaser/Sparx/Adaptive kabul. Stage 7–9 ve
  high-stage progression deferred; count=7 performansı Android acceptance'ta ayrıca test edilecek.
- **#23 Capture Hitstop Tuning** (2026-09-25, `fix/23-capture-hitstop-tuning` → main, commit
  `7c2a5ce`): **TAMAMLANDI, origin/main senkron.** Baseline
  60 ms; 40 ms ve 50 ms manual karşılaştırıldı, kullanıcı final olarak **45 ms** tercih etti. Capture-only
  `HitStop.capture_duration` 60 ms→45 ms; `scale_during=0.02`, near-miss, life-loss, shake, particles,
  haptic ve SFX değişmez. Capture/grid/determinism değişmez. **401/401, 2036 assert; manual acceptance PASS.**
- **#29 Project Settings Default Canonicalization** (2026-09-26, commit `092b986`,
  `fix/29-project-settings-canonicalization` → **main ff-only merge + origin push**): Redundant
  `default_bus_layout` ve `locale/fallback=en` kayıtları kaldırıldı; custom bus resource ve translations
  korunur. Headless editor ve `ProjectSettings.save()` canonical hâli değiştirmedi; runtime bus indexleri
  Master/SFX/Music = `0/1/2`; **414/414, 2110 assert, 0 warning**.
- **#28 Enemy Stuck Test Cleanup** (2026-09-25, commit `082b580`,
  `fix/28-enemy-stuck-test-cleanup` → **main ff-only merge + origin push**): Test root'unda kalan dört transient `CaptureBurst` `CPUParticles2D`, test-only
  `after_each()` ile explicit temizlenir. Isolated **18/18, 144 assert, 0 warning**; full GUT
  **414/414, 2110 assert, 0 warning**. Production code değişmedi.
- **#27 Godot Comment Indentation Normalization** (2026-09-25, commit `2e90d8e`,
  `fix/27-arena-comment-indentation` → **main ff-only merge + origin push**): Godot 4.6.3 headless editor yalnız `arena_controller.gd` içindeki
  wrapped comment leading indentation'ını spaces → tabs normalize ediyor; executable code değişmiyor ve ikinci
  editor açılışı yeni diff üretmiyor.
- **#26 Free Near-Total Completion** (2026-09-25, commit `4f437ed`,
  `fix/26-free-mode-full-capture` → **main ff-only merge + origin push**): Free-only `BalanceConfig.free_completion_percent=99.0`; ArenaData'nın shared
  Void 75 / Ember 70 / Frost 80 hedefleri Daily için korunur. Literal 100 danger-seed invariant nedeniyle
  kullanılmaz. CaptureGrid, Daily seed, ghost, Campaign ve Endless değişmez. **414/414, 2109 assert passed.**
  **MANUAL ACCEPTED:** Frost run ~98% capture'a kadar doğrulandı ve near-total progression pratik bulundu;
  exact 99% result-screen manual observation yapılmadı (boundary otomatik testte doğrulandı). Son küçük FREE
  pocket'ta Sparx disappearance gözlendi; ayrı non-blocking observation, bu fix-pass'te enemy behavior değişmedi.
- **#25 Endless late-curve test baseline** (2026-09-25, `fix/25-stage-plan-test-baseline` → main, commit
  `bca86c5`): **TAMAMLANDI, origin/main senkron.** Production progression bug değildi: Stage 9 correct
  count=5, Stage 8 baseline roster korunur. Monotonic assertion `previous_count=0` ile yanlış başlıyor;
  Stage 8 baseline initialization ile düzeltildi. Production files değişmez. **401/401, 2035 assert.**
- **#24 Trail / Player Visual Sync** (2026-09-25, `fix/24-trail-player-visual-sync` → main, commit
  `04453f0`): **TAMAMLANDI, origin/main senkron.** Logical trail timing değişmeden presentation-only `TrailHeadLayer` son forward
  segmenti Player visual position'ına clip'ler; retract transient çizilir. CaptureGrid/determinism/ghost
  değişmez. Yeni testler **8/8 passed**; #25 test-only baseline correction sonrası full GUT
  **409/409, 2095 assert passed.** Manual acceptance **PASS**; hızlı uzun Swipe hissi kullanıcı tarafından iyi bulundu.

**KODLANDI ama HENÜZ TEST EDİLMEDİ (Tuğra):** #18/#19/#20 main'de, otomatik testler yeşil, ama henüz
PC'de/telefonda OYNANARAK doğrulanmadı. Açık iki his/ölçüm sorusu:
1. **Denge hissi** — #18 (Sparx Chebyshev sertliği, Chaser görüş-hattı kaybı), #19 (Adaptive Chaser
   `trail_bias`/eşik/hangi level'lar), #20 (grace-bounce/Sparx cep/roam çeşitliliği "canlı" hissediyor mu).
2. **B4 — capture kasması** hâlâ ölçülmedi (mobil TODO'dan; Sparx'lı vs Sparx'sız arena A/B, hitstop=0 A/B).

**Açık manuel kabul:** #22 B1-R için Stage 7–9 (özellikle Stage 8→9 handoff) later long-run / Android
acceptance'a ertelendi. High-stage count=7 okunabilirlik ve performans da Android acceptance'ta ayrıca test edilecek.

Ayrı, bağımsız açık konu: **Mobil Doğrulama — BEKLİYOR** (Son Güncelleme altında, 5 test; #16'nın kabul
kriteri, cihaz gerektirir).

**Sırada:** Tuğra'nın #23 capture hitstop 40 ms A/B hissini doğrulaması; ardından #22 Stage 7–9 + high-stage/Android
acceptance, #18/#19/#20 denge hissi + B4 ölçümü + Mobil Doğrulama. A4 Stage 5→6 ise #22 curve üzerinde yeniden ele alınacak. Sonrasında olası **Free skor avı** (zincir/kombo YOK, kapatma %100'e kadar) —
henüz PLANLANMADI, yalnız sıradaki aday olarak not düşüldü; test geri bildirimine göre kesinleşecek.
Bağımsız: **Step 23 — AdMob** (mobil doğrulama + cihaz checkpoint sonrası).

16. **Mobil bug fix — ekran-kökü pointer STOP'ları + flash aktif-kama** — main'de (commit 8d67336,
    branch `step/mobile-input-perf`; 2026-07-21 ff-merge) **AMA ⚠️ MOBİL DOĞRULAMA BEKLİYOR** (bkz.
    Son Güncelleme'deki MOBİL DOĞRULAMA TODO — kök kanıtlanmadı, valide iş güvene alındı).
    - **BUG1 (slider input):** İstenen "_HotkeyCatcher" TARAMA sonucu kodda YOK (grep boş). Gerçek
      eşdeğer desen: **9 ekranın kök Control'ü tam-ekran DEFAULT(STOP)** (Settings/MainMenu/Store/
      ModeSelect/Credits/HowToPlay/Leaderboard/LevelSelect/Missions) → hepsine `mouse_filter = 2`
      (IGNORE). Bilinçli DOKUNULMAYAN modal'lar: PauseOverlay/Overlay, HUD/ResultPanel, RewardPopup
      (STOP = tasarım). Klavye/shortcut yolları etkilenmez (_input tabanlı).
      **DÜRÜSTLÜK NOTU:** kök-STOP'un slider drag'ini kesin öldürdüğü KANITLANMADI — emülatör teyidi
      negatif çıkarsa sıradaki şüpheli `project.godot pointing/emulate_touch_from_mouse=true`'nun
      Android'de çift-emülasyon etkisi (platform-ayrımlı kapatma önerisi hazır, onay bekler).
    - **BUG2 (flash redraw):** FlashLayer artık pulse start'a göre SIRALI + `_lo` aktif-kama
      penceresi — tamamlanan run'lar kalıcı atlanır, başlamamışlara hiç girilmez. Görsel birebir
      (kapsama/cap/dalga testleri aynen). Bench: kare-başı iterasyon 0.056→0.027 ms (2×; per-frame
      zaten küçüktü — capture KARESİ toplamı [çekirdek+redraw+dalga kurulumu] ana aday olmayı
      sürdürüyor; play() akış-birleştirme önerisi AÇIK, gerekirse sonraki tur).
    - Test: **+1 (aktif-kama penceresi), 334/334, 1506 assert.** capture/seed/grid dokunulmadı.
    - ASIL kabul: Tuğra emülatörde (1) her ekranda slider/buton, (2) capture tık'ı.

17. **Feel-Pass P1 — düşman canlılığı + unlock kutlaması + kombo eskalasyonu** — ✅ main'de (commit a89c73f,
    branch `step/feel-pass-p1`; 2026-09-16 ff-merge, doz mevcut haliyle Tuğra onaylı). Kaynak: feel-audit P1.
    Telefon bug'ları (Sparx köşe / Chaser eksen) için git A/B ile **SUÇSUZ** kanıtlandı (bkz. Mobil Doğrulama).
    *Numara notu:* "feel P1-7" ≠ audit-P0 paketindeki P1-7 (#9, Sparx efekt-muafiyeti belgelemesi).
    **TÜMÜ SALT GÖRSEL** — capture/seed/grid/gameplay-timing/`radius`/`_velocity`/node transform'a YAZMA YOK;
    görsel saat `_process`/tween (fizik adımına girmez); gl_compatibility (bloom yok). Yeni autoload/`.tscn` YOK.
    - **feel P1-7 düşman canlılığı (`enemy.gd`):** yeni `_process` yalnız `_velocity`/`_heading` OKUR.
      Chaser üçgeni hız yönüne döner (`draw_set_transform` — `Node2D.rotation` 0 kalır), `JuiceMath.turn_toward`
      (kare-hız bağımsız üstel, ±PI en kısa yol, wrap'li). Sparx karesi köşelerde yuvarlanır (`sparx_roll`;
      90° simetri → düz giderken nötr); setup + re-emerge'de açı anında oturur. Bouncer nefesi yalnız ÇİZİM
      yarıçapı (±`breath_amount` 0.06; faz `_variation`'dan, RNG yok). CONTAINED (görünmez) erken çıkar.
      Knob'lar: `turn_rate` 14, `sparx_roll` true, `breath_amount` 0.06, `breath_speed` 3.0.
    - **feel P1-11 unlock kutlaması:** `CampaignStars.frontier()` + `newly_unlocked()` (saf, keeps-best);
      `Economy.record_campaign_result` frontier büyürse bellekte `_pending_unlock` atar (kayıt formatı
      DEĞİŞMEDİ; app-kill'de kaybı zararsız); `consume_pending_unlock()` bir-kez. `level_select.gd`: `_ready`
      tüketir → `unlock_delay` 0.25 → `ensure_control_visible` → scale-pop 0.6→1 BACK (`unlock_pop_time` 0.35)
      + accent glow (tema StyleBoxFlat kopyası: accent kenar + `shadow_size` 14, alfa `unlock_glow_time` 0.9'da
      söner, sonra override kalkar) + `play_sfx("unlock")` kanca (sessiz). Basışta kutlama tween'i öldürülür
      → JuicyButton pop'u tek sahip. Next edge case kabul (harita ilk gösterimde kutlar; game.gd unlock'a dokunmaz).
    - **feel P1-12 kombo eskalasyonu:** `JuiceMath.combo_punch` (x1=1, x2=base, monoton, kırpık) +
      `combo_heat` (x3 altı 0, x3≈⅓, x5=1). HUD kombo etiketi: zincir BÜYÜDÜĞÜNDE punch (aynı kombo yeniden
      emit → punch yok) + renk accent→coin (knob: base 1.25/step 0.12/max 1.8/heat 3..5). "+N" popup
      (`floating_score.gd`): `show_value(value, color, mult=1)` — punch 1.5+0.15/çarpan (max 2.2), renk
      trail→coin; **x1 birebir eski**. `game.gd` +1 satır (`get_combo()+1`). Skor etiketi punch SABİT (1.3).
    - Test: **+15** (`test_feel_pass_p1.gd`): turn_toward (yakınsama/±PI kısa yol+wrap/dt=0/snap), combo_punch +
      combo_heat; **ENEMY DETERMİNİZM DEĞİŞMEZİ** (Chaser+Sparx çiftleri 240 fizik adımı, biri düzensiz
      `_process` serpiştirmeli → position/_velocity/_heading BİREBİR + rotation==0 + radius sabit); Bouncer
      nefes yalnız çizim; frontier (boş/-1, ilerlemesiz 0, zincir, son); newly_unlocked (ilk clear açar,
      fail/iyileşme/tekrar açmaz, girdi saf); consume bir-kez; LevelSelect pending tüketir + doğru index /
      pending yoksa kutlama yok; **basış çakışması** (custom_step ile deterministik: glow uygulanmış → basış →
      tween ölü + glow temiz + JuicyButton 1.0'a oturur); HUD x5>x2 punch + accent→coin + aynı kombo re-punch
      yok; popup x1 birebir + x5 büyük/altın. **349/349, 1580 assert.** capture/seed/grid golden AYNEN.
    - Etkilenen: enemy.gd, juice_math.gd, campaign_stars.gd, Economy.gd, level_select.gd, hud.gd,
      floating_score.gd, game.gd (+1), test (yeni). Sahneler: Game + LevelSelect (2).
    - ASIL kabul: Tuğra PC'de oynar (his/doz) — cihaz gerekmez.

18. **Düşman hitbox + Chaser görüş-hattı + başlangıç grace + pause layout (cihaz bug paketi B1/B2/B3)** —
    ✅ main'de (commit 9d61221, branch `step/enemy-hitbox-chaser-layout`; 2026-09-22 ff-merge, origin
    senkron). Kaynak: gerçek Android testi
    (CİHAZ BULGULARI). **Feel-pass P1 SUÇSUZ kanıtlıydı** (git A/B, digest birebir) — bu paket asıl kökler.
    **capture/seed/grid ALGORİTMASI DEĞİŞMEDİ** (yalnız salt-okuma `grid.cells()` kullanımı + docstring).
    **DENGE bilinçli değişti (Tuğra onaylı).**
    - **B1 Sparx yakalama (`enemy.gd _patrol`):** Manhattan ≤1 → **Chebyshev ≤1** (çapraz dahil) ve Sparx
      tarafı `_grid_cell` → **`world_to_cell(position)`** (çizilen hücre; adım gecikmesi kalktı). Oyuncu
      tarafı lerp'li pozisyon AYNEN ("gördüğün öldürür"; API/imza değişmedi). Köşe bağışıklığı bitti:
      duvar-takipçisi köşeyi yalnız ÇAPRAZ döndüğü için köşe hücresindeki oyuncu ölümsüzdü.
    - **Grace tek sahip:** Sparx-yerel `_catch_cd` + `edge_catch_cooldown` **KALDIRILDI** → ölüm sonrası
      dokunulmazlığın tek sahibi `game.death_grace` (#8). Eski hata: grace'te YOK SAYILAN yakalama yine
      1 sn cooldown başlatıyordu → grace bitince bitişik Sparx ~1 sn öldüremiyordu.
    - **B2 Chaser görüş-hattı:** `EnemyMotion.line_of_sight(cells, cols, from, to, blocked)` (saf, tam sayı
      Bresenham, uç hücreler engel değil) + `EnemyBehavior.needs_line_of_sight()` (taban false) +
      `ChaserBehavior.requires_line_of_sight` (@export, **true**; false = eski kör homing birebir).
      `Enemy.decide_velocity` görüş kapısı: görüş yoksa exposed=false → **roam** (son hız korunur, sekerek
      gezer, görüş açılınca tekrar takip). TRAIL engel DEĞİL (hedefin kendisi). `_peel_adjust` korundu.
      Perf: yalnız exposed + isteyen davranış; ≤~120 hücre/fizik-karesi; **capture karesine yük YOK, flood YOK**.
    - **B3 Pause layout (`HUD.tscn`, TEK sahne):** `TopBar.offset_right` ve `DailyLabel.offset_right`
      −16 → **−100** (pause butonu 68 px + 16 boşluk). `PauseOverlay.tscn` ve sola yaslı `BestLabel` dokunulmadı.
    - **Ölçüm (teşhis harness'ı, aynı senaryolar):** Sparx köşe **0 → 3 catch** (kenar 1→9: yerel cooldown
      yok, gerçek oyunda grace yutar); Chaser duvar-arkası hizalı 180 karede net **3.3 → 147.5 px**
      (çakılma yok, duvardan ayrılıp geziyor); **açık alan homing DEĞİŞMEDİ** (300 px, eski değerle aynı).
    - Test: **+11 (`test_enemy_hitbox_los.gd`) ve test_sparx cooldown testi yeniden yazıldı** (artık
      "her karede ölümcül, zinciri death_grace engeller"): köşe catch bekçisi, çapraz ölür/2-hücre ölmez,
      çizilen-hücre kuralı, grace biter bitmez yeniden ölümcül, line_of_sight saf (açık/duvar/boşluk/komşu/
      hedef-hücre), trail engel değil, Chaser kör→roam & açık→homing, **çakılma regresyonu**, knob=false
      eski davranış, Bouncer etkilenmez, HUD/pause rect kesişmez. **360/360, 1607 assert**, temiz boot.
    - Etkilenen: enemy.gd, enemy_motion.gd, enemy_behavior.gd, chaser_behavior.gd, capture_grid.gd
      (yalnız docstring), HUD.tscn, test ×2. Yeni autoload YOK.
    - **EK — Başlangıç grace (2026-09-22, Chebyshev'in yan etkisi):** oyuncu spawn'ı `(0,0)` **çerçeve
      köşesi**; köşe bağışıklığı kalkınca oradan geçen Sparx **ilk karede** can alıyordu (tepki şansı yok).
      Fix: `game.start_grace_duration` (@export, 1.0s) run başında VE her respawn'da kurulur, **oyuncu ilk
      adımını atana kadar DONDURULUR** (`player.has_moved()`; `_try_step`'te set, `setup`/`respawn`'da sıfır).
      Tek sahip korunur: `_begin_grace()` hem başlangıç hem ölüm sonrası i-frame'leri kurar ve tüm ölümcül
      yollar (Sparx catch / trail / self-hit) `_on_trail_failed`'den geçtiği için **tüm düşman türleri**
      kapsanır. Oyuncu yanıp sönerek dokunulmazlığı gösterir. Determinizm: sabit süre + input, RNG yok.
      **Kabul edilen takas:** hiç hareket etmeyen oyuncu süresiz dokunulmaz kalır (skor da üretmez).
    - Test (EK): +3 — park hâlinde 2 sn fizik + hit → can gitmez & timer donuk; ilk adımdan sonra grace
      sayar ve biter → yeniden ölümcül; respawn sonrası grace yeniden kurulur. Mevcut `death_grace`
      testleri (test_campaign + bu dosya) start-grace'i açıkça düşüren yardımcıyla güncellendi.
      **363/363, 1612 assert**, temiz boot.
    - ASIL kabul: Tuğra PC'de + telefonda denge hissi (Sparx fazla ölümcül mü / Chaser fazla kaçırıyor mu)
      + Sparx'lı level'da ilk karede ölmeme.

19. **Adaptive Chaser — zor bölümlerde en yakın tehdidi avlar** — ✅ main'de (commit 293aa8b, branch
    `fix/19-adaptive-chaser`; 2026-09-22 ff-merge, origin senkron — **yeni `fix/NN-` isim kuralının ilk
    uygulaması**). Tuğra denge testi (c09–c12 / Endless stage 6+) bekliyor.
    **capture/seed/grid ALGORİTMASI DEĞİŞMEDİ.** Yeni autoload YOK, **`.tscn` değişikliği YOK**.
    Kural KAPALIYKEN Chaser davranışı **birebir eski** (regresyon testiyle pinli). Sparx/Bouncer etkilenmez.
    - **Hedef seçimi (`enemy._hunt_target`):** kural açık + oyuncu çiziyor + davranış `hunts_player()` ise
      `JuiceMath.closest_point_on_polyline` (YENİ saf fonksiyon; `_distance_to_segment` ile ortak
      `_closest_on_segment` tabanına oturtuldu) ile trail'in en yakın NOKTASI bulunur.
      Seçim: `head_dist <= trail_dist * trail_bias` → kafa, değilse trail noktası.
      `ChaserBehavior.trail_bias` @export **1.0 (nötr/saf mesafe)**; >1 kafayı, <1 çizgiyi kayırır.
      `EnemyBehavior`'a iki sanal eklendi: `hunts_player()` (taban false) + `target_bias()` (taban 1.0).
    - **Politika (`ChaserPolicy`, saf, BoostPolicy deseni):** `hunts_nearest(mode, campaign_flag, stage,
      endless_from_stage)`. Campaign → `LevelData.chaser_hunts_nearest` (**c09–c12 = true**, c01–c08 false);
      Level-Endless → `ProgressionConfig.chaser_hunts_nearest_stage` (**5**, 0 tabanlı = HUD Stage 6+;
      negatif = tamamen kapalı); **Free/Daily/bilinmeyen = daima false**. `game._hunts_nearest(stage)`
      stage/level başında BİR KEZ çözer → `_living_territory.set_hunt_nearest(...)`.
    - **KRİTİK — paylaşılan Resource tuzağı:** bayrak `type_chaser.tres`/ChaserBehavior'a **ASLA yazılmaz**
      (motor cache'i onları paylaşıyor; yazılsa Free/Daily'ye sızardı). Kare başına parametre olarak
      `decide_velocity(player_pos, exposed, trail, hunt_nearest)` ile iner. **Sızıntı bekçi testi zorunlu
      olarak var** (hunting frame → sonra Free frame → yine kafa hedefi).
    - **Görüş hattı (#18 ile etkileşim):** önce hedef seçilir, **#18 LOS SEÇİLEN hedefe** uygulanır;
      görünmüyorsa mevcut dolaşma yolu. Duvara çakılma regresyonu testle kapalı.
    - **İpucu:** P1 dönüşü zaten hedefe bakar + çizgiyi avlarken gövde trail rengine doğru ısınır
      (`trail_hunt_tint` @export 0.35, 0 = kapalı). Salt görsel, steered/frozen tint'lerinin yanında üçüncü durum.
    - **Perf (izole ölçüm, bu makine):** kare başına 1 trail kurulumu (LivingTerritory'de, tüm Chaser'lar
      paylaşır) + Chaser başına O(trail) tarama. 50 hücre **0.096 ms** · 200 hücre **0.357 ms** · 600 hücre
      **0.951 ms** (2 Chaser dahil). Kural kapalı / oyuncu güvende → trail HİÇ kurulmaz, maliyet 0.
      **Capture karesine ek yük yok** (kapatmada trail zaten tükeniyor). Throttle EKLENMEDİ (gerek görülmedi).
    - **Determinizm:** saf mesafe + sabit kural, RNG yok; Daily'de kapalı → ghost/leaderboard etkilenmez.
      Aynı kurulum → aynı yörünge (test).
    - **Anlatım:** `HOWTO_ENEMIES_BODY`'ye bir cümle + `LEVEL_C09_DESC` güncellendi (EN+TR, virgüllü
      alanlar quote'landı — CSV kesilme tuzağı).
    - Test: **+12 (`test_adaptive_chaser.gd`), 374/374, 1663 assert**: closest_point (boş/tek/projeksiyon/
      iki uç kelepçe/çok segment/mesafe-tutarlılık), politika (Free/Daily/bilinmeyen/Campaign flag/Endless
      eşik/negatif), katalog bekçisi (c09–c12 açık, c01–c08 kapalı, eşik=5), KAPALI→birebir, AÇIK→yakın olan
      hedef + tint, `trail_bias` iki yönlü, Bouncer etkilenmez, LOS seçilen hedefe, **sızıntı bekçisi**,
      determinizm, uçtan-uca (c09 açık / c01 kapalı / Free kapalı gerçek Game sahnesinde).
    - Etkilenen: chaser_policy.gd (yeni), juice_math.gd, enemy.gd, enemy_behavior.gd, chaser_behavior.gd,
      living_territory.gd, level_data.gd, progression_config.gd, game.gd, c09–c12.tres, progression.tres,
      translations.csv, test (yeni).
    - ASIL kabul: Tuğra c09–c12 + Endless stage 6+ oynar; "adil mi, uzun çizgi ne kadar riskli olmalı"
      geri bildirimine göre `trail_bias` / eşik / hangi level'lar ayarlanır.

20. **Düşman sıkışma durumları (B5/B6/B7) + kalıcı bekçi değişmez** — ✅ main'de (commit f9e581e,
    branch `fix/20-enemy-stuck-states`; 2026-09-23 ff-merge, origin senkron). Kaynak: "PC BULGULARI"
    teşhisi (üçü de
    #17/#18/#19 kaynaklı DEĞİL, git A/B ile kanıtlanmıştı). **capture/seed/grid ALGORİTMASI DEĞİŞMEDİ**
    (yalnız orchestration: hangi hücre seed/tahliye hedefi olarak kullanılıyor). Yeni autoload YOK,
    `.tscn` değişikliği YOK. RNG yok → determinizm/daily/ghost korunur.
    - **B5 — kök (`enemy._advance`):** `hit_trail.emit()` **senkron**; emit dönünce hücre hâlâ TRAIL ise
      vuruş yok sayılmış (grace) demektir — bu bilgiyi game'den taşımaya GEREK YOK, düşman kendi kendine
      senkronize okuyor. Artık donmak yerine duvar gibi **yansır** (reflect + `_recovery_timer`, CAPTURED
      bounce'la aynı desen); hücre artık FREE ise (ölüm gerçekleşti, trail temizlendi) normal geçer.
      **Fork 1 tek başına embedded-korider senaryosunu kurtaramıyor** (saf eksen hızı, korider her iki
      yönde de trail ise reflect sadece işaret çeviriyor, `moved_px=0.00` kalıyor — matematiksel olarak
      beklenen, ölçümle doğrulandı) — bu yüzden Fork 2 zorunlu.
    - **B5 güvenlik ağı (`game.gd`, `arena_controller.gd`):** `ArenaController.nearest_free_cell(from,
      max_radius)` (saf, genişleyen Chebyshev-halka taraması, deterministik). `_enemy_cells()`: hücresi
      FREE olmayan düşman için en yakın FREE hücre seed olur (`STUCK_ENEMY_SEARCH_RADIUS`=12).
      `_evacuate_enemies_from_captured_cells()`: her capture'dan sonra (`_on_area_captured` başında)
      hâlâ CAPTURED hücrede olan aktif, **edge-follow OLMAYAN** düşman en yakın FREE hücreye deterministik
      taşınır (debug log). **Sparx hariç** — kendi engulf-check'i (`_patrol` başı) zaten kendi kendini
      iyileştiriyor; körlemesine teleport `_grid_cell/_step_from/_step_to` senkronunu bozardı
      (`Enemy.is_edge_follow()` yeni erişimci).
    - **B6 — periyodik sınırlı trap kontrolü (`enemy._patrol`):** `trap_recheck_steps` (@export, 32) PATROL
      adımında bir `_is_trapped_bounded()` çalışır — **yalnız boyut sınırı** (`trap_pocket_max_cells`),
      tam bağlantı kontrolü (`_is_trapped`, tam-grid flood gerektirir) DEĞİL; bilinçli — periyodik tam
      flood kasma sorununu geri getirirdi. **`close_capture` ASLA çağırmaz** (yalnız `_enter_contain()`) —
      mid-draw canlı bir trail'i yanlışlıkla sonlandırmaz; bu yüzden pocket-fill ödülü (#10) periyodik
      yoldan TETİKLENMEZ, yalnız gerçek capture olaylarına bağlı kalır (bilinçli takas). 0 = kapalı.
    - **B7 — roam eksen-kilidi (`enemy_motion.unstick_axis` + `enemy.decide_velocity`):** Saf
      `EnemyMotion.unstick_axis(velocity, base_speed, variation, axis_lock_ratio)` — eksene kilitli
      (bir bileşen oran altında) hızı `_variation`'dan türetilen deterministik diyagonale çevirir +
      `base_speed`'e normalize eder; zaten diyagonal ise dokunmaz. **Roam tespiti `exposed` bayrağından**
      (davranışın kendi dalladığı KOŞUL) yapılır, **eşitlik karşılaştırmasından DEĞİL** — ilk denemede
      eşitlik tabanlı sezgi, hedefin rastlantısal olarak mevcut hız yönünde olduğu GERÇEK takip
      durumlarını (#19 testlerinde yakalandı) roam sanıp yanlışlıkla saptırıyordu; düzeltildi.
      `axis_lock_ratio` (@export, 0.08). Bouncer etkilenmez (`hunts_player()` taban false).
    - **Test-yan-etkisi (bilinçli, gerekçeli):** İki #18/#19 testi (`test_enemy_hitbox_los.gd`,
      `test_adaptive_chaser.gd`) eksen-hizalı `(0,-150)` yerine diyagonal başlangıç hızı kullanacak
      şekilde güncellendi (`_chaser()` yardımcılarına opsiyonel `velocity` parametresi) — B7'nin kendisi
      roam+eksen-kilit durumunu KASITLI değiştiriyor; testler artık test ettikleri şeyi (roam hız
      korunumu / LOS) B7'den izole ediyor. Davranış assertion'ları AYNEN korundu.
    - **Ölçüm (aynı teşhis harness'ı, #19 vs #20):**
      | Senaryo | #19 (önce) | #20 (sonra) |
      |---|---|---|
      | B6: capture olayı olmadan sızan cep | 2000 karede hiç contain | **76. karede contained** |
      | B7: eksen-kilitli kare (600 karede) | 250 | **0** |
      | B7: x-yayılımı | 177 px | **591 px** |
      | B5: embedded-korider (Fork 1 tek başına) | moved_px 0.00 | moved_px 0.00 (beklenen; Fork 2 kurtarıyor) |
    - **Perf:** B6 periyodik kontrol +0.0136 ms/fizik-karesi/Sparx (32-adım periyotta, `trap_recheck_steps=0`
      0.0178→`=32` 0.0314 ms); B5 tahliye normal yolda (sıkışma yokken) 0.00265 ms/çağrı. İkisi de
      16.7 ms kare bütçesine göre ihmal edilebilir; kasma konusuna (B4, hâlâ açık) katkı YOK.
    - Test: **+18 (`test_enemy_stuck_states.gd`), 392/392, 1807 assert**: `nearest_free_cell` saf (itself/
      düzeltme/menzil-dışı/deterministik), B5 dışarıdan-yaklaşma yansıması + trail-temizlenince-geçiş,
      **bekçi değişmez** (gerçek `game._enemy_cells`/`_evacuate_enemies_from_captured_cells` ile uçtan
      uca), seed-düzeltme, tahliye, Sparx kendi-kendini-iyileştirme, B6 periyodik yakalama + devre-dışı +
      yanlış-pozitif-yok + **canlı trail'e dokunmuyor** (güvenlik), `unstick_axis` saf, roam saptırma +
      **rastlantısal-eşitlik yanlış-pozitifi yok** (regresyon bekçisi), Bouncer etkilenmez, knob kapalı,
      eksen-sekme regresyonu. Mevcut chaser/sparx/adaptive-chaser/capture/seed/grid golden'ları AYNEN.
    - Etkilenen: enemy.gd, enemy_motion.gd, arena_controller.gd, game.gd, test ×3 (2 güncelleme + 1 yeni).
    - ASIL kabul: Tuğra PC'de + telefonda — grace sırasında düşman artık sekiyor mu (donmuyor mu),
      Sparx cepleri kendiliğinden çözülüyor mu, Chaser kenarda artık çeşitlilik gösteriyor mu.

---

## Önemli Kararlar

> 2026-10-04 (UI Pass E2): Görev ownership'ı `game.gd`/MissionService'te kalır; HUD yalnız sayar ve Game.tscn signal bağlantısıyla gerçek Mission nesnelerini Pause'a iletir. Pause satır node'ları refresh sırasında yeniden kullanılır, free/duplicate callback riski yaratılmaz. Görevsiz durumda bölüm tamamen collapse olur.

[Her step sonunda güncellenir. Format: tarih + step + karar + gerekçe]

> 2026-06-17 (Step 14.2): Pause-toggle node process_mode=ALWAYS → Esc HEM duraklatır HEM
>   devam ettirir (pausable node pause'da input almaz). Auto-pause arka plan/odak kaybında
>   (resume manuel → yanlışlıkla can kaybı yok). Mid-run Menü = run terk (ödül yok). Pause
>   kare üretmez → ghost/daily determinizmi korunur (kare-sayım testiyle doğrulandı).
> 2026-06-17 (Step 14.1): Streak için epoch-day (saf, 1970'ten gün) — YYYYMMDD +1 ay/yıl
>   sınırında yanlış. DailySeed(YYYYMMDD)=seçim; EpochDay=ardışıklık (ayrı amaç). 7-gün loop.
>   "Bugün" SeedManager.day_offset'i respect eder (dev H ile test). Roadmap decimal 14.1 (renumber yok).
> 2026-06-17 (Step 14): İçerik tek kaynak ContentCatalog (game/store/menü paylaşır). Seçim
>   SaveData'da kalıcı (Economy.selected_*); GameState selection API'ı kaldırıldı. Free-play
>   yalnız açık loadout; daily seed-driven (gating yok). Dev tuşları OS.is_debug_build() guard'ı
>   → release'de hile yok. UI fonksiyonel scaffold; void-neon cila Step 15. main_scene→MainMenu.
> 2026-06-17 (Step 14): Sahne-instantiate testi (geçici) Game.tscn'de runtime tip-uyuşmazlığı
>   yakaladı (MissionService.build Array→Array[Mission]). Ders: yeni .tscn'ler için @onready+_ready
>   doğrulaması GUT pure testlerden ayrı gerekir (boot yalnız main_scene'i kapsar).
> 2026-06-17 (Step 13): Mission değerlendirme RUN-SONU (canlı per-event değil): basit +
>   deterministik; stats {score/percent/areas/won}. REACH_*→max, TOTAL/WIN→kümülatif.
>   Günlük seçim seed-türevli (herkese aynı 3). Her run sayılır (free-play+daily). claim
>   idempotent → çift ödül imkânsız. Placeholder run-ödülü kaldırıldı; missions tek currency
>   kaynağı. Ödül sayıları İLK PAS — gerçek denge Step 14'te unlock_cost ile kilitlenecek.
> 2026-06-17 (Step 12): Save iki ayrı dosya: save.json (currency+unlocks, Economy) +
>   leaderboard.json (Step 11, dokunulmadı). Gerekçe: odaklı, migration churn yok, Step 11
>   kırılmaz. Economy autoload SaveData'yı sahiplenir (yeni autoload yok), mutasyonda auto-save.
>   Negatif bakiye imkânsız (spend guard). Run ödülü score/RUN_REWARD_DIVISOR(=100) PLACEHOLDER → Step 13 gerçek.
> 2026-06-17 (Step 11): Ghost = KAYITLI-YOL oynatma (input-resimülasyon değil). Gerekçe:
>   resimülasyon frame-timing/kontrol/float'a bağımlı kırılgan; kayıtlı yol her zaman aynı
>   yolu izler + determinizm tuzağı yok. Seed arena/düşman/karakteri sabitlediği için bağlam adil.
> 2026-06-17 (Step 11): Yerel liderlik minimal user://leaderboard.json (Step 12 birleşik
>   save'e migrate edebilir). Gün-başına best (date/seed anahtarlı). Ghost YALNIZ daily.
>   Track'ler son KEEP=5 güne budanır (skorlar kalır) → dosya sınırsız büyümez. Tie strictly-greater.
> 2026-06-16 (Step 10): Günlük seed kendi SAF integer hash'i (Godot RNG değil). Her adım
>   32-bit maskeli (& 0xFFFFFFFF) → overflow/işaret belirsizliği yok, cross-platform/sürüm
>   tutarlı (global liderlik adaleti için kritik). Golden-value regresyon testi determinizmi pinler.
> 2026-06-16 (Step 10): Daily mod arena + KARAKTER + düşman ilk yönleri seed'den (fork 1:
>   karakter de sabit, unlock'tan bağımsız). Pozisyon merkez sabit (rastgele spawn riski yok).
>   Free-play seçimi (GameState index) daily'de EZİLMEZ (persist=false). G toggle, daily'de C/V kapalı.
> 2026-06-16 (Step 09): Düşman türleri strateji-pattern (EnemyBehavior Resource +
>   Bouncer/Chaser). Behavior istenen hızı verir; ÜSTÜNE efekt (steer/speed_scale) +
>   collision/contact-freeze biner → efektler tüm türlere otomatik. Pipeline SIRA düzeltmesi
>   (behavior→effect→collision); steer/speed_scale mantığı korundu. Bouncer regresyonsuz
>   (base=identity). Patroller ertelendi (dinamik kenar pathing karmaşık; mimari ucuz ekler).
> 2026-06-16 (Step 09): enemy_speed tür-tabanı (base_speed_cells) × arena speed_mult ×
>   cell_size. ArenaData enemy_count/enemy_speed_cells → enemies: Array[EnemyType]. Chaser
>   DURUM-FARKINDA stalker: yalnız oyuncu EXPOSED (free'de trail çizerken) iken homing;
>   güvenliyken roam (bouncer). Kök çözüm: hedef açık alandayken duvar-kampı imkânsız —
>   orbit/SLIDE workaround'ları silindi. Saf (pos + player_exposed input'tan, RNG yok) → ghost-safe.
> 2026-06-16 (Step 09): ROADMAP RENUMBER — yeni Düşman Türleri step'i 09'a sokuldu; eski
>   09+ tümü +1 kaydı (Günlük Seed 09→10 ... Mağaza 21→22, toplam 22). Decimal-label yerine
>   renumber (branch step/09 ile uyum; decimal'ler intra-branch refinement için). Tüm
>   ### başlıklar + checklist + sonuç tablosu + inline cross-ref'ler kaydırıldı, grep ile doğrulandı.
> 2026-06-16 (Step 08): enemy_speed GRID-bazlı (cells/s), px/s değil. Gerekçe: fit-to-rect
>   cell_size'ı arenaya göre değiştiriyor; player grid-zamanlı (sabit cells/s). Enemy px/s
>   kalsa küçük hücreli arenada grid'e göre hızlanıp zorluk kayardı. px/s = cells/s × cell_size
>   configure sonrası. Arena başına farklı cells/s ile bilinçli zorluk hâlâ mümkün.
> 2026-06-16 (Step 08): Portrait-fit = fit-to-rect ölçek (sabit-cell+margin değil). Sabit
>   PLAY_RECT, ArenaData mantıksal cols/rows verir, compute_fit en büyük tam cell_size'ı
>   bulup grid'i ortalar. Her grid boyutu garanti sığar, ekran kullanımı tutarlı.
> 2026-06-16 (Step 08): Tema BAĞIMSIZ (ArenaData→ThemeData ref, paylaşılabilir), 1:1 değil.
>   Renk sahipliği: tema = void/border/trail/enemy ortamı; karakter = captured glow (accent).
>   Kompoze; çakışma yok (arena teması önce, karakter accent sonra uygulanır).
> 2026-06-16 (Step 08): DENGE — arenalar farklı zorlukta (boyut/düşman/hedef). Adalet:
>   günlük seed herkese AYNI arenayı verir → liderlik adil. Serbest oyunda arena seçim
>   (sidegrade), pay-to-win değil. Engeller ertelendi (seam: percent zaten iç-alan üzerinden).
> 2026-06-16 (Step 07): Orbit (Deflect/teğetsel) ELENDİ, yerine Halt (Stasis) geldi.
>   Gerekçe: kapatılan bölgeler hep kenara yapışık şerit olduğundan teğetsel efekt
>   "duvar boyunca kaydır"a düşüyordu (şekle bağımlı, buggy salınım). Üç efekt ekseni
>   netleşti: Push=YÖN, Drag=HIZ, Halt=ZAMAN (ritimle tam durdurma, şekilden bağımsız).
>   Tüm tangent/aligned_tangent/deflect kodu + testleri kaldırıldı.
> 2026-06-16 (Step 07): Stasis GLOBAL ritim → PER-ENEMY dwell → TEMAS tetikleyici (iki adımda).
>   Son model: yakınlık alanı/dwell tamamen kaldırıldı; düşman PLAYER-captured'a çarpıp
>   bounce'ladığı AN donar (havada değil, temasta). freeze_duration=0.3, freeze_cooldown=0.5
>   (perma-lock yok). is_player_captured ile border hariç → boş arenada efekt YOK korunur.
>   Determinizm: _freeze_timer sabit fizik-adımı azalımı. is_frozen/dwell/influence_radius silindi.
> 2026-06-16 (Step 07): Drag güçlendirildi (çok az yavaşlatıyordu): slow_factor 0.55,
>   min_scale 0.40 taban. Taban düşmanın kenarda sıfır hıza sürünüp glow'a binmesini önler.
> 2026-06-16 (Step 07): Radius-aware bounce — düşman gövdesi (merkez ± radius) captured'a
>   biniyordu (merkez doğru sekiyordu ama daire kenarı taşıyordu). Çözüm: çarpışma öngörücü
>   (ön kenar yoklaması) + clamp_to_wall ile merkez duvardan >= radius uzakta. TRAIL merkez
>   tabanlı kaldı (zorluk sabit). Halt radius 80→45 (düşman havada değil kenara yakın donar).
> 2026-06-16 (Step 07): DENGE NOTU — 3 karakterin etkisi de savunma/crowd-control
>   sidegrade'i (uzaklaştır/yavaşlat/kenarda tut); hiçbiri doğrudan skor artırmaz. Ama
>   hayatta kalmayı kolaylaştırdıkları için dolaylı skora etki ederler → günlük liderlik
>   adaleti için kabaca EŞİT güçte olmalılar. Sürekli gözlem; sayısal ayar playtest'le.
>   Pay-to-win YASAK: karakterler parayla açılınca rekabet avantajı SATMAMALI.
> 2026-06-16 (Step 07): TerritoryEffect iki-hook (steer kalıcı + speed_scale geçici).
>   Gerekçe: yön değişimi kalıcı saklanmalı, hız değişimi geçici olmalı (yoksa compounding
>   ile hız sıfıra çürür). Tek compute_velocity arayüzü ikisini birden temiz çözemiyordu.
> 2026-06-16 (Step 07): Oyun dili İngilizce (varsayılan). Locale altyapısı korunuyor,
>   Türkçe sonra ek sütun olarak gelebilir. Kod/yorum/commit Türkçe kalır.
> 2026-06-16 (Step 07): KRİTİK locale fix — project.godot translations CSV'yi gösteriyordu;
>   TranslationServer yüklemiyordu (tr() ham anahtar dönüyordu, Step 05'ten beri). Üretilen
>   .translation dosyası gösterilince düzeldi. GUT ile doğrulandı.
> 2026-06-15 (Step 06): Yaşayan Bölge efekti = PUSH (proximity), slow değil. Gerekçe: imza
>   mekanik için görünürlük; void temasıyla "kuvvet alanı" uyumu; mevcut velocity sistemine
>   yeni sahne gerektirmeden oturur. Tuğra kararı. Slow/shoot Step 07'de karakter-bazlı alt-sınıf.
> 2026-06-15 (Step 06): KRİTİK fix — efekt "düşman CAPTURED içindeyse" olamaz çünkü düşman
>   CAPTURED'a çarpıp sekiyor (hep FREE'de). Proximity'ye çevrildi. Ayrıca dış-çerçeve tuzağı:
>   init_frame dış halkayı baştan CAPTURED yapıyor → efekt başlangıçta hep açık olurdu. Çözüm:
>   is_player_captured dış halkayı dışlar; efekt sadece kapatılan iç bölgeden yayılır.
> 2026-06-15 (Step 06): Push hız YÖNÜNÜ döndürür, büyüklüğü korur (steer). Böylece sabit-hız
>   bounce invaryantı bozulmaz; push ile bounce aynı yöne çalışır (çatışmaz, pekiştirir).
> 2026-06-15 (Step 05.1): Trail backtracking için Player'da _trail_path eklendi (ordered
>   Array[Vector2i]). size-2 index ile anlık önceki hücre tespiti; cancel için size==1 +
>   target==_safe_cell özel hali. CaptureGrid.remove_trail_cell tek hücre geri alır.
>   Auto-advance şemalarda hareketsiz başlangıç: setup/respawn'da _direction=ZERO override.
>   TapTurnControl.rotate() zaten ZERO→RIGHT guard'ına sahipti — değişiklik gerekmedi.
> 2026-06-15 (Step 05): Skor locale için .po yerine CSV kullanıldı. Gerekçe: .po header
>   fragile, Godot 4 CSV import headless'da güvenilir. Çoklu dil gerektiğinde CSV ek sütun.
> 2026-06-15 (Step 05): HUD game.gd'den gevşek bağlı; yalnızca GameState sinyallerini
>   dinliyor. game.gd sadece update_percent() ve setup(lives) doğrudan çağırıyor (area_captured
>   sinyali ArenaController'da, GameState'e eklenmedi — gereksiz coupling önlendi).
> 2026-06-15 (Step 04): Düşman sürekli-uzayda (grid-kilitli değil) seker; seed için
>   hücresi türetilir. Alt-adımlı hareket ile 1-hücrelik çizgi tünellenmez.
> 2026-06-15 (Step 04): Düşman hareketi deterministik (sabit başlangıç, RNG yok) —
>   Step 10 günlük seed'e hazır. Capture'a düşman hücreleri seed olarak besleniyor;
>   algoritma değişmedi (Step 03'te hazırlanmıştı).
> 2026-06-15 (Step 04): Can/oyun durumu mevcut GameState autoload'a eklendi (yeni
>   autoload YOK). Player↔Enemy gevşek bağlı (loop_closed sinyali, koordinatör Game).
> 2026-06-15 (Step 03): Alan kapatma = grid + 4-komşuluk flood-fill (polygon DEĞİL).
>   Gerekçe: deterministik, integer, test edilebilir; düzensiz/çoklu bölgeyi otomatik
>   çözer; seed determinizmiyle uyumlu. cell_size=10 → 64×110 grid.
> 2026-06-15 (Step 03): Kapatma kuralı tehlike-seed tabanlı. Düşman yokken en büyük
>   boş bileşen tehlike sayılır, gerisi alınır. Step 04'te tek değişiklik: seed=düşman.
> 2026-06-15 (Step 03): Determinizm için "en büyük bileşen" eşitlik bozma row-major-ilk.
> 2026-06-15 (Step 03): Runtime class_name çözümü için yeni class_name dosyaları editör
>   dışı oluşturulunca `godot --headless --import` ile global class cache yenilenmeli
>   (yoksa boot'ta "Could not find type" hatası). GUT izole yükleyici için ayrıca
>   test'te preload / şema alt-sınıflarında path-extends kullanıldı.
> 2026-06-15 (Step 03.1): Kontrol şeması pluggable + seçilebilir (yarış oyunu gibi).
>   Gerekçe: tek şemaya kilitlenmemek; oyuncu seçsin. Şimdilik @export + dev toggle.
> 2026-06-15 (Step 02): GUT test dosyasında class_name türler için `preload` zorunlu.
>   Godot 4 headless modda GUT kendi loader'ı ile parse ederken global class_name
>   kayıtları henüz tamamlanmamış olabiliyor. Çözüm: test dosyasının başına
>   `const BorderMath = preload("res://scripts/core/border_math.gd")` eklendi.
>   Bu kural tüm gelecek GUT testleri için geçerli.
> 2026-06-15 (Step 02): touch kontrolü: sol yarı = saat tersi, sağ yarı = saat yönü;
>   parmak kaldırınca dur. `InputEventScreenDrag` ile parmak ekranda sürüklenince
>   yön değişir. Tek parmak takibi (_touch_finger_id) ile multi-touch izolasyonu.
> 2026-06-14 (Plan): Kanca = Yaşayan Bölge + Günlük Seed/Ghost; roguelite draft
> v1.1'e ertelendi. Gerekçe: MVP'yi dar tutup hızlı yayınlamak; sıralı çalışma.
> 2026-06-14 (Plan): Karakterler dengeli sidegrade olacak. Gerekçe: parayla erken
> açmanın rekabet avantajı yaratmaması, günlük liderliğin adil kalması.
> 2026-06-14 (Step 01): .gitattributes ile eol=lf zorunlu kılındı. Gerekçe: Windows
> geliştirme + Android/iOS hedef — tutarsız satır sonu sorunlarını önlemek.
> 2026-06-14 (Step 01): GUT v9.6.0 addons/gut altına commit edildi (pure GDScript,
> sır yok). Gerekçe: her geliştirici ortamında aynı test versiyonunu garanti etmek.
> 2026-06-14 (Step 01): Autoload script'lerde class_name kullanılmayacak. Gerekçe:
> Godot 4'te singleton adı ile class_name aynı olamaz — parse hatası verir. Autoload'lar
> zaten global singleton adıyla erişilebilir; class_name gereksiz ve kırıcı.

---

## Üretilen Sonuçlar

2026-10-04 (UI Pass E2): `PauseOverlay.tscn`, `HUD.tscn`, iki küçük procedural UI scripti, `PAUSE_TITLE` EN/TR çevirisi ve `test_pause_mission_ui.gd`; tam cyan completion line sonrası sonuç 474/474 GUT, 3153 assertions. Oyun/core görev algoritması değişmedi.

[Step bazında eklenen sistemler/dosyalar buraya]

| Faz | Step | Sistem | Durum |
|-----|------|--------|-------|
| 0 | 01 | Proje iskeleti + GUT | ✓ 2026-06-14 |
| 1 | 02 | Arena + sınır hareketi | ✓ 2026-06-15 |
| 1 | 03 | Alan kapatma algoritması (CaptureGrid) | ✓ 2026-06-15 |
| 1 | 03.1 | Seçilebilir kontrol sistemi | ✓ 2026-06-15 |
| 1 | 04 | Düşman + can sistemi (GameState) | ✓ 2026-06-15 |
| 1 | 05 | Skor + kombo + HUD + oyun döngüsü | ✓ 2026-06-15 |
| 2 | 06 | Yaşayan Bölge (Push efekti + TerritoryEffect mimarisi) | ✓ 2026-06-15 |
| 2 | 07 | Karakter sistemi (Pulse/Drag/Halt + 2-hook etki) | ✓ 2026-06-16 |
| 2 | 08 | Arena çeşitliliği + tema (ArenaData/ThemeData/Catalog) | ✓ 2026-06-16 |
| 2 | 09 | Düşman türleri (EnemyBehavior: Bouncer/Chaser) | ✓ 2026-06-16 |
| 2 | 10 | Günlük Seed (DailySeed saf hash + SeedManager) | ✓ 2026-06-16 |
| 2 | 11 | Ghost/replay + yerel liderlik (GhostTrack/Leaderboard) | ✓ 2026-06-17 |
| 3 | 12 | Kayıt/yükleme & ekonomi (SaveData/SaveStore/Economy) | ✓ 2026-06-17 |
| 3 | 13 | Daily mission sistemi (Mission/Catalog/Store) | ✓ 2026-06-17 |
| 3 | 14 | Store & menü (MainMenu/Store/Credits + ContentCatalog) | ✓ 2026-06-17 |
| 3 | 14.1 | Günlük giriş ödülü (EpochDay/LoginStreak) | ✓ 2026-06-17 |
| 3 | 14.2 | Run-içi pause + mission paneli | ✓ 2026-06-17 |
| 4 | 15 | Art direction (PaletteData + ui_theme; void-neon) | ✓ 2026-06-17 |
| 4 | 16 | Juice & game feel (shake/hitstop/partikül/TimeControl/near-miss) | ✓ 2026-06-19 |
| 4 | 17 | Ses & müzik & haptic (AudioManager + SoundBank + Settings) | ✓ 2026-06-19 |
| 5 | 18 | Level-Endless (StagePlan + ramp + ModeSelect + 3-kalp HUD) | ✓ 2026-06-20 |
| 5 | 19 | Düşman çeşitliliği (Chaser variation + Sparx lifecycle) | ✓ 2026-06-23 |
| 5 | 20 | Boost sistemi (BoostData/Policy/Effects + Store/arm UI) | ✓ 2026-06-23 |
| 5 | 21 | Level-Campaign (LevelData + yıldız/unlock + LevelSelect patika) | ✓ 2026-07-02 |
| 6 | 22 | Lokalizasyon (TAM TR + dil seçici + LocaleUtil + süpürme) | ✓ 2026-07-04 |

---

## Açık Sorunlar

> [UI Pass E2] Türkçe 720×1280 gerçek oynanış ve Pause görsel/etkileşim kabulü Tuğra'dan bekleniyor; commit/push yapılmadı. Production tüm modlarda üç görev üretiyor; görevsiz UI davranışı boş dizi regresyonuyla doğrulandı, aktif görevsiz mod gözlemi yok.

[Çözülmemiş / sonraya bırakılan şeyler ve geçici çözümler]

> [Step 01] — GUT plugin editörde henüz enable edilmedi. Tuğra, Godot editöründe
> Project → Project Settings → Plugins → GUT → Enable adımını yapmalı.
>   → GÜNCELLEME: project.godot'ta [editor_plugins] eklenerek enable edildi (2026-06-14).
> [Step 01] — GUT için .gutconfig.json eksikti; "no directories set" hatasına yol açıyordu.
>   Düzeltme: .gutconfig.json oluşturuldu, headless test doğrulandı (1/1 passed).
> [Step 01] — Autoload script'lerde class_name autoload adıyla çakışıyordu (Godot 4 kısıtı:
>   singleton adı ile class_name aynı olamaz). class_name kaldırıldı; 4 autoload düzeltildi.
> [Step 01] — main_scene boş: Step 02'de çözüldü (Game.tscn).
> [Step 03.1] — Oyuncuya açık kontrol ayar menüsü + kalıcı kayıt YOK. Şimdilik
>   @export + dev toggle (1/2/3). Menü step'inde (Step 14) UI'a bağlanacak.
> [Step 03] — Görsel grid-bloklu (köşeli). Kenar yumuşatma (marching-squares) Step 15.
> [Step 03] — Bölge dolma juice'u yok (Step 16); kazanma/bitiş yok (Step 05).
> [Step 04] — GameOver "OYUN BİTTİ" placeholder → Step 05'te HUD + locale ile çözüldü. ✓
> [Step 04] — Respawn anı dokunulmazlığı yok; gerekirse his ayarında eklenecek.
>   → ÇÖZÜLDÜ (2026-07-03, commit 24a56ee): `game.death_grace` (1.0s @export) i-frame penceresi +
>   oyuncu blink — 1 ölüm = tam 1 can, respawn chain-kill yok.
> [Step 06] — Enemy._draw geçici debug tint (push efekti aktifken açık ton). Step 16
>   (juice) gerçek VFX ile değiştirilecek; `# TEMP` yorumu kodda işaretli.
>   → KAPANDI (2026-07-04, audit-cleanup): tint KALICI hafif efekt-geribildirimi olarak benimsendi,
>   TEMP etiketleri kaldırıldı. Zengin VFX (gerçek bloom) = v1.1 renderer upgrade maddesi.
> [Step 04] — Düşman görseli sade daire; juice/iz Step 16.
> [Step 11] — Online liderlik: Şimdilik yerel. v1.1'de backend eklenecek.
> [Fix-Pass #17 / feel P1] — **Satır limiti ihlali (400, CLAUDE.md):** `enemy.gd` 639 (P1 öncesi 601),
>   `game.gd` 578 satır. Bu adımda refactor YAPILMADI (salt-görsel adım; saf matematik JuiceMath'e alındı,
>   ekleme minimal). Öneri: Sparx kenar-yürüyücü mantığı (patrol/contain/telegraph/reproject/flood) ayrı
>   dosyaya (`sparx_walker.gd` vb.) — audit P1-5 ile birleştirilecek; game.gd orchestration bölünmesi ayrı iş.
> [Fix-Pass #17] — `--quit-after` headless boot çıkışında "1 resource still in use" (menu_music.wav
>   AudioStreamPlayback): menü müziği çalarken zorla çıkış artefaktı, AudioManager kaynaklı, P1'den BAĞIMSIZ.
>   Oyun içi etkisi yok; ileride AudioManager `_exit_tree`'de music stop ile susturulabilir.

---

## Mimari Sapmalar

[CLAUDE.md'deki kurallardan/plandan sapmalar buraya. Format: tarih + step + ne değişti + neden]

> 2026-06-30 (Step 19b-3 / 20a / 20b): Bu 3 commit (58d0208/e0672cd/7eea3ae) step-branch açılmadan
>   **doğrudan main'e** işlendi — CLAUDE.md "her step kendi branch'inde" kuralından sapma. Karar:
>   geçmiş KURCALANMAZ (geri-dönük ref-branch açılmadı — main'de + origin ile senkron + lineer
>   history sağlam, kozmetik gereksiz). İLERİYE düzeltildi: CLAUDE.md "Permanent Git Kuralları"na
>   açık standing rule eklendi; **Step 21+ yeniden step-branch akışıyla** işlenecek.
> 2026-09-22 (Branch'siz main commit'leri — TAM ENVANTER, düzeltme GEREKMİYOR): yukarıdaki 19b-3/20a/20b
>   dışında şu commit'ler de branch açılmadan doğrudan main'e işlendi:
>   **34d8dda** fix(enemy) Sparx dar döngü · **c007b8c** fix(player) kendi trail'ine değme = can (Fix-Pass #7)
>   · **e46f7a0** chore gitignore export artıkları · **6dd75a7** chore(export) ETC2/ASTC.
>   Hepsi main'de, origin ile senkron ve lineer (sonraki branch'ler bunların üstünden dallandığı için
>   `git branch --contains` çıktısında görünürler — tersi değil). Karar: **geçmiş KURCALANMAZ**, geri-dönük
>   branch açılmaz. İleriye dönük kural CLAUDE.md'ye yazıldı: son iki chore zaten yeni kuralın "tek dosyalık
>   chore doğrudan main" istisnasına uyar; 34d8dda ve c007b8c bugünkü kurala göre `fix/NN-` branch'i isterdi.
> 2026-09-22 (Branch isimlendirme — İLERİYE dönük): fix-pass'ler artık `fix/NN-isim`, roadmap step'leri
>   `step/NN-isim`. Sebep: iki ayrı sayaç aynı öneki paylaşınca karışıyordu (`step/10-sparx-pocket-capture`
>   = Fix-Pass #10, Step 10 — Günlük Seed DEĞİL). Eski branch'ler AYNEN kalır (silme/rename YOK);
>   kural yalnız yeni açılacak branch'leri bağlar. #18 (`step/enemy-hitbox-chaser-layout`) eski isimle
>   kapandı; bir sonraki fix-pass ilk `fix/NN-` örneği olacak.
> 2026-06-30 (Roadmap): Shipped ondalık step'ler (03.1/05.1/14.1/14.2) düz numaraya ÇEKİLMEDİ —
>   gerçek remote branch'lere bağlı (`step/14.1-login-streak` vb.); renumber git geçmişiyle desync
>   yaratırdı. Tarihsel kayıt korunur. Yalnız ileri-roadmap düzleştirildi (18.1 Campaign → 21).

> 2026-06-15 (Step 03/03.1): Step 02 kontrol şeması grid + seçilebilir modele taşındı.
>   Step 02'deki parametrik dikdörtgen-perimetre hareketi (border_t) yalnızca başlangıç
>   durumunun özel hâliydi; ilk kapatmadan sonra güvenli sınır dikdörtgen değil. Bu yüzden
>   tek doğruluk kaynağı grid yapıldı; hareket grid hücrelerinde, kontrol pluggable şema
>   ile. `border_math.gd` korunuyor (testli, başlangıç çerçevesi eşlemesinde yardımcı).

---

## Sonraki Step
**Step 23A–23D complete (2026-10-07).**
**Step 23E — DEFERRED:** physical Android hardware is unavailable.
Emulator, headless and native-build validation do NOT count as real-device AdMob/UMP acceptance.
When a physical Android device is available, verify: UMP consent flow; privacy-options entry when
required; Google test rewarded ad load/show; reward-earned callback; close without reward; Results
bonus granted exactly once; and app background/foreground around the ad lifecycle.

---

## v1.1 Backlog (Yayın Sonrası)
→ **Tek kaynak:** yukarıdaki **"Launch Sonrası / v1.1 Backlog"** bölümü (Fire boost, ekstra
arena/karakter, online leaderboard, Level-Endless high-score, gelişmiş düşman/boost + in-stage ramp,
roguelite/Campaign+, iOS+Apple Sign In, renderer upgrade, tema/event). Burada tekrar TUTULMAZ (dağıtma).
*(Not: Patroller/Sparx ARTIK TAMAM — Step 19; eski backlog maddesi düştü.)*

---

2026-10-03 (UI Pass D3 - LevelSelect Polish recovery + targeted polish, `step/ui-d3-level-select-polish`, commit/push YOK):
Reddedilen compact D3 node geometrisi baseline'a geri alÄ±ndÄ±. Winding route, level sÄ±rasÄ±, stars/unlock/save ve navigation korunuyor.
Baseline 220x108 node / 140 satÄ±r geometrisi korundu; connector'lar node sÄ±nÄ±rÄ±nda kesildi, sÄ±radaki oynanabilir node'a hafif frontier outline eklendi,
scrollbar muted edildi ve TR/EN aÃ§Ä±klamalarÄ± iki kompakt satÄ±rda tutuldu. Gameplay/progression davranÄ±ÅŸÄ± deÄŸiÅŸmedi.
TÃ¼rkÃ§e 720x1280 mixed-state Ã¶rneÄŸi `.godot/d3_screenshots/level-select-tr-final.png` (local/ignored). Full GUT **454/454 PASS, 2941 assert, 0 warning/error**;
parser/editor boot ve diff-check PASS. **MANUAL VISUAL ACCEPTANCE BEKLÄ°YOR - commit/push YOK.**

2026-10-03 (UI Pass D3 - LevelSelect visual rework, `step/ui-d3-level-select-polish`, commit/push YOK):
Kart tabanlÄ± sunum compact checkpoint + route-dÄ±ÅŸÄ± metadata olarak yeniden kuruldu. Winding route topology,
level order, unlock/stars/save, navigation ve localization content korunuyor. Current checkpoint cyan frontier
ile vurgulanÄ±yor; completed checkpoint'ler sakin, locked checkpoint'ler metadata'sÄ± sade ve muted. GerÃ§ek
level description verileri iki satÄ±ra sÄ±ÄŸacak ÅŸekilde gÃ¶steriliyor; path checkpoint yÃ¼zeyinde kesiliyor.
Scroll viewport Back footer Ã¼stÃ¼nde bitiyor ve final level alt padding ile eriÅŸilebilir. TÃ¼rkÃ§e 720x1280
baÅŸlangÄ±Ã§/final screenshot'larÄ± `.godot/d3_screenshots/level-select-map-start-tr.png` ve
`.godot/d3_screenshots/level-select-map-final-tr.png` (local/ignored). Full GUT **454/454 PASS, 2957 assert**;
parser/editor boot ve diff-check PASS. **MANUAL VISUAL ACCEPTANCE BEKLÄ°YOR - commit/push YOK.**

2026-10-03 (UI Pass D3 - Final visual polish, `step/ui-d3-level-select-polish`, commit/push YOK):
OnaylÄ± compact checkpoint + winding route korunarak yalnÄ±z final okunabilirlik/state polish uygulandÄ±.
Metadata 14 px'ten 18 px'e Ã§Ä±karÄ±ldÄ±; Level + stars, objective/target ve Locked metinleri route/checkpoint
koridoruna girmeden iki/Ã¼Ã§ satÄ±rda eksiksiz gÃ¶rÃ¼nÃ¼yor. Completed checkpoint'ler muted captured cyan fill,
current checkpoint dark interior + en parlak cyan frontier, locked checkpoint'ler dark/muted kalÄ±yor.
Final level scroll iÃ§inde Back footer Ã¼stÃ¼nde eriÅŸilebilir. TÃ¼rkÃ§e 720x1280 screenshot'larÄ±
`.godot/d3_screenshots/level-select-polish-start-tr.png` ve
`.godot/d3_screenshots/level-select-polish-final-tr.png` (local/ignored). Full GUT **455/455 PASS,
3010 assert**; parser/editor boot ve diff-check PASS. **MANUAL VISUAL ACCEPTANCE BEKLÄ°YOR - commit/push YOK.**

2026-10-03 (UI Pass D3 - Final readability + completion polish, `step/ui-d3-level-select-polish`, commit/push YOK):
OnaylÄ± checkpoint/route geometrisi korunarak completed checkpoint captured fill'i orta parlaklÄ±ÄŸa
Ã§Ä±karÄ±ldÄ±; current checkpoint dark interior + en parlak frontier, locked checkpoint dark/muted kaldÄ±.
Metadata 18 px'ten 21 px'e yÃ¼kseltildi; tam localized objective/target metni clipping olmadan gÃ¶rÃ¼nÃ¼r.
YapÄ±sal regression final checkpoint'in fixed Back footer Ã¼stÃ¼ne tamamen scroll edilebildiÄŸini doÄŸruluyor.
TÃ¼rkÃ§e 720x1280 baÅŸlangÄ±Ã§ ve Level 8 screenshot'larÄ± `.godot/d3_screenshots/level-select-final-start-tr.png`
ve `.godot/d3_screenshots/level-select-final-level8-tr.png` (local/ignored). Full GUT **455/455 PASS,
3013 assert**; parser/editor boot ve diff-check PASS. **MANUAL VISUAL ACCEPTANCE BEKLÄ°YOR - commit/push YOK.**

## Referans Notlar
- Motor: Godot 4.6.x stable (4.7 beta aşamasında; stable'da kal)
- AdMob plugin: poingstudios `godot-admob-plugin` (monorepo, v4.2+, Android+iOS)
- Test: GUT (Godot Unit Test) — sadece saf mantık
- Sanat referansları: Super Hexagon, Mini Metro, Downwell, Paper.io (ilham, taklit değil)
- CLAUDE.md ve PROGRESS.md gitignore'da, GitHub'da görünmüyor — cloud yedekleme önemli
