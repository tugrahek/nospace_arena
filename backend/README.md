# Wallet foundation — Step 34A

Local-only TypeScript/Firebase foundation, **not a payment service**. No Firebase
project is provisioned or selected, no credentials are included, and nothing is
deployed. No Functions handlers are exported or configured for deployment.
`PurchaseService.REAL_PURCHASES_ENABLED=false` remains unchanged in the game.
The authoritative product/recovery/spend/refund contract is
[the IAP architecture](../docs/iap-v1-architecture.md); release blockers remain in
[the checklist](../docs/release-v1-checklist.md).

## Included boundary

- `src/catalog.ts`: immutable, versioned `coins_500/1500/4000` server grants,
  exact IDs and one numeric unit. This validates catalog input, **not a purchase**.
- `src/auth.ts`: accepts a Bearer Firebase ID token only through injected Firebase
  Admin `Auth.verifyIdToken(token, true)`; current provider must be `google.com`.
  Production wiring must use Admin Auth initialized for the owned project, not a
  custom decoder or test verifier. UID comes exclusively from verified claims.
  Revoked/disabled/invalid sessions return a generic error without token details.
- `src/models.ts`: readonly wallet, purchase, funding, entitlement, ledger and
  consumption-outbox contracts. There is no Firestore writer or balance mutator.
  TypeScript interfaces are not runtime validation or an atomicity guarantee.
- `firestore.rules`: deny **every client read/write**, including authenticated
  owners. Future authenticated APIs return sanitized, owner-scoped projections.
  Admin SDK bypasses rules and needs separate IAM, authentication, authorization,
  amount validation and transaction enforcement. Client `admin` claims confer nothing.
- `firebase.json`: localhost Firestore emulator only; no Functions deploy config,
  real project mapping, `.firebaserc`, indexes or service account file.
- `.gdignore`: isolates backend dependencies/tests from Godot resource imports.
  No game/export settings are changed; final release packaging must explicitly
  verify that backend sources/dependencies are absent from shipped game assets.

## Future persistence layout — not created by this foundation

| Path | Authority and invariant |
| --- | --- |
| `wallets/{uid}` | Server: safe-integer paid balance/version, active/review/closed state |
| `wallets/{uid}/ledger/{eventId}` | Append-only, stable event ID, cause, signed delta, resulting balance/version |
| `wallets/{uid}/entitlements/{itemKey}` | Unique permanent kind/item key; status, spend ID and source-lot funding |
| `purchases/{purchaseId}` | Global token uniqueness and immutable UID; verified catalog amount/environment |
| `consumptionOutbox/{purchaseId}` | Durable credit-linked server consume work and deadline |
| `checkoutIntents/{intentId}` | Server-issued UID/SKU/environment/opaque attribution binding |
| `refunds/{refundId}` / `reviews/{reviewId}` | Idempotent reversal or audited support resolution |
| `tokenTombstones/{purchaseId}` | Restricted deduplication retained through account deletion |

`purchaseId` is SHA-256 of the UTF-8 JSON tuple `[packageName, purchaseToken]`;
the raw token is needed only in future server-only protected storage for Play calls,
never a document ID, client projection, Git artifact or log. Event and request IDs
also need deterministic unambiguous encoding. Entitlement keys encode kind/item
without path injection. Request records under the UID must bind canonical payload
and original result. No client can create any of these records.

Future server writes must validate all records at runtime, reject unsafe/fractional
amounts, maintain funding conservation, and transactionally enforce the invariants
in the architecture. Refunds can produce negative paid debt; normal spend cannot.
Paid unlocks never enter earned save data, and no local coin import is supported.
Refund-linked unlocks are reversible/reviewable; retaining them forever is not the
policy. A revoked paid right does not erase independently earned local ownership.

## Focused verification

Prerequisites: Node 24, npm and Java 21+; no Google login or credentials required.
From this directory:

```text
npm ci --ignore-scripts
npm test
```

This compiles strict TypeScript, runs Node's built-in test runner for Auth/catalog,
then uses `firebase emulators:exec --project demo-nospace-wallet --only firestore`
to exercise the actual rules with `@firebase/rules-unit-testing`. The `demo-`
project is non-production; tests refuse a different project/host and do not skip
when the emulator is missing. Install/emulator downloads require network initially.
All generated dependencies, builds, emulator caches and logs are ignored.

Auth unit tests inject a verifier to test delegation, revocation flag, provider
enforcement, malformed input and error redaction. A real Admin SDK negative test
rejects an unsigned forged JWT. These tests do not prove a production Google login,
real project/audience configuration, Play verification, durable fulfillment,
double-spend prevention, refund execution, or native device behavior.
Rules tests try create/replace/update/delete, nested records, owner/other/guest,
anonymous and fake-admin sessions, private reads, batch/transaction escalation and
unchanged seed state. Rules prevent direct client access, not privileged Admin bugs.

## Remaining work and operation

Separately implement: server project/least-privilege IAM, Google sign-in bridge,
checkout attribution, verification and idempotent transactional credit/spend,
protected token queue, consumption worker, RTDN/polling and refund/review operations,
account deletion/export, and explicit wallet UI. No Android dependencies are added
by Step 34A. Keep real purchases disabled throughout this foundation.

Future Functions need Blaze billing; monitor usage, quotas, consume deadlines,
unfulfilled charges and refund polling. Budget alerts do not cap bills. Establish
backups, retention, published privacy/deletion notices and incident/support ownership
before activation. Owner-controlled Firebase/Play accounts and signed Play-device
acceptance remain external prerequisites, not evidence supplied by these tests.

Official references: [Admin ID tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens),
[rules testing](https://firebase.google.com/docs/rules/unit-tests),
[emulator setup](https://firebase.google.com/docs/emulator-suite/install_and_configure).
