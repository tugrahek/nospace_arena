# v1 coin purchases — secure architecture contract

**Real purchases are disabled.** Models, Auth boundary and emulator-tested rules
are local foundations, not deployed verification, fulfillment or a recovery promise.

## Approved product contract

| Stable SKU | Coins per verified unit | Type |
|---|---:|---|
| `coins_500` | 500 | Consumable one-time product |
| `coins_1500` | 1500 | Consumable one-time product |
| `coins_4000` | 4000 | Consumable one-time product |

`resources/purchases/` contains typed `CoinPackDefinition` resources;
`V1CoinCatalog` validates the exact allowlist and returns detached copies. These
are planned definitions, not purchasable native metadata or delivery commands.
Do not repurpose an SKU after release; introduce a reviewed new identifier instead.
No real-money price is authored here. Future UI must show current localized Play
ProductDetails/offer prices and handle unavailable or stale offers safely.
The backend must maintain its own reviewed, versioned SKU-to-amount table;
client resource values and client-supplied amounts are never authoritative.
Identifiers are public product metadata, not signing secrets. Service credentials
and purchase tokens stay out of Git/logs.

## Verified repository state

- `PurchaseService.REAL_PURCHASES_ENABLED=false` keeps the production autoload on
  the unavailable no-op backend on every platform. Fake-backend unit tests remain
  injectable. This gate prevents accidental activation, not hostile client edits.
- The Android adapter now accepts explicitly injected valid coin definitions or
  approved consumable metadata, alongside existing non-consumables. It queries
  Play-localized metadata and routes coin candidates separately. The production
  service catalog remains empty; no Store UI or coin grants are connected.
- Existing callbacks/flow markers and `Economy` transaction persistence provide
  local orchestration only. The bridge's per-flow obfuscated account marker is
  **not a durable authenticated account ID**. No trusted verification endpoint or
  server ledger exists in this repository.
- The local handler still cannot fulfill paid coin packs. The service now prevents
  the three reserved coin IDs from reaching that handler, even through the old
  transaction callback. Local persistence is not server verification or a wallet.

## Consumable adapter boundary

Explicitly injected `CoinPackDefinition` resources are validated and converted to
backend metadata; empty configuration stays empty. Unknown consumables and coin IDs
mislabeled non-consumable cannot launch. The production gate is unchanged.

For coins, metadata requires an INAPP product and exactly one structurally valid
offer: nonblank Play display price, three-uppercase-letter currency code, positive
integral price micros, nonblank purchase-option ID and optional string offer ID.
The pinned bridge passes those exact option/offer IDs to its native purchase API.
Several valid alternatives are ambiguous and excluded; no cheapest/first selection
or invented price is used. Duplicate purchasable product details fail the query and clear
offers. Fresh metadata is required after disconnect. Existing non-consumable
single-offer behavior remains covered by its regressions.

One explicit quantity is accepted for coin callbacks. Pending callbacks do not
submit a verification candidate until purchased; cancellation/errors grant nothing.
Request tokens, native flow markers and pending purchase-token correlation reject
stale/unrelated callbacks. Invalid arrays/JSON are ignored or fail the operation
without printing sensitive receipt data.

Purchased coin callbacks and owned-query recovery emit backend
`verification_required`, forwarded as service
`purchase_verification_required(request_token, sku, purchase_token)`. **This event
is unverified input, not success, durable delivery or permission to consume.** It
does not call the local delivery handler, change balance or emit purchase success.
No server listener is installed yet. Coin `delivery_confirmed` calls cannot cause
acknowledgement, including spoofed durable client context. No consumable consume
method is added to the bridge. Non-consumable delivery/acknowledgement is unchanged.

Startup/reconnection refreshes metadata and queries owned purchases. Purchased,
unconsumed coins can be resubmitted as candidates; pending owned entries wait for a
later purchased query. Duplicate candidates within a service request are suppressed,
but later recovery requests deliberately permit retry. No in-memory set claims
durable server deduplication. Consumed-history/account recovery still requires the
future server ledger. Tokens are sensitive: do not log or show these events in UI.
Mock tests establish callback behavior only; real plugin/Play-device acceptance is
still pending. Do not enable real purchases while this event has no trusted handler.

## Platform facts

Google recommends server purchase verification before granting value, retaining
unique purchase tokens and validating account attribution. Backend secrets must
not ship in the client. [Play Billing security](https://developer.android.com/google/play/billing/security)
is the reference, not the existing client's callback success flag.

Consumables must be consumed to permit repurchase; consumption also meets the
acknowledgement requirement. Pending payments must not receive value. Unacknowledged
completed purchases can be refunded after the acknowledgement window (normally
three days). [Billing integration](https://developer.android.com/google/play/billing/integrate)
defines these lifecycle rules; operational deadlines must be monitored server-side.

The [ProductPurchaseV2 API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.productsv2/getproductpurchasev2)
provides purchase/consumption state using package and token. The server must use
authenticated Play Developer API access; an order ID or client JSON is insufficient.

## Server transaction protocol: verify, commit, consume, reconcile

The server protocol below specifies the required transaction and recovery behavior.
The current client adapter does not implement server verification or persistence.

1. Authenticate the player/wallet owner before checkout. Bind an intent to that
   owner and one approved SKU; use stable, privacy-preserving account attribution.
   Reject unsupported quantity/offers. Initially configure single-quantity sales;
   multi-quantity support requires separate validation and refund accounting.
2. Client sends token and product context over authenticated HTTPS. Server queries
   Google and checks expected package `com.tugrahek.nospace`, SKU, purchased state,
   quantity, account binding and test/production environment. Pending/cancelled,
   mismatched, replayed-to-another-owner and unverifiable claims grant nothing.
   Temporary verification failures remain retryable; they are not success.
3. In one database transaction, insert the verified purchase under a unique
   `(package, purchase_token)` constraint and append the wallet credit/ledger
   event exactly once. Store owner, verified SKU/quantity, amount, source state
   and audit timestamps. Concurrent requests and duplicate callbacks return the
   original result, never another credit. Never deduplicate by order ID alone.
4. Commit a durable consumption outbox entry alongside fulfillment. A worker
   consumes through the Play backend API only after the credit is durable. Retry
   transient failures with backoff and deadline alerts. Duplicate/already-consumed
   responses must be reconciled with the existing ledger; they never grant again.
   Do not consume before fulfillment or treat acknowledgement alone as delivery.
5. Client reads an authenticated wallet snapshot/version or idempotent delivery
   event; it must not call `Economy.earn(amount)` again on every callback/retry.
   Wallet-cache persistence failure, crash or reinstall fetches the same server
   result. Paid wallet projections remain separate from the local earned economy.
6. Reconcile on session resume/reconnect and with server notification workers.
   Owned-purchase queries can recover outstanding unconsumed purchases, but are
   not a history of consumed currency. A consumed purchase requires the durable
   server ledger and wallet owner to recover; no blind consumable restore grants.

Use restricted Play API permissions, authenticated endpoints, secret management,
token-safe logging, rate limits, ledger backups and a replayable audit trail.
Client balances, raw callback data and device identifiers are not trust roots.
Test all crash boundaries, duplicate/concurrent deliveries, delayed payment,
offline return, consumption timeout, backend outage and local persistence failure
before enabling the release gate.

## Account, split-wallet and recovery contract

The [backend foundation](../backend/README.md) defines server-side models, the Auth
boundary and Firestore rules. The client has no Google/Firebase login or cloud
wallet integration.

- Free gameplay and local earned rewards require neither login nor network.
  Existing earned balance, unlocks, prices, rewards and progression stay unchanged.
  Existing saves are untrusted for server value: no upload/merge, conversion,
  one-time paid credit or automatic promotion of local unlocks to cloud ownership.
- Paid balance and paid-funded permanent character/arena unlocks belong to a
  Firebase UID on the server. There is no paid boost/consumable spend path in this
  foundation. Such a path requires its own recovery/refund contract.
- Before IAP checkout require an online Firebase session signed in with Google.
  Firebase Admin verifies the ID token for the configured project, including
  expiry/signature and revoked/disabled sessions; `google.com` is mandatory.
  Client UID/email, linked-provider lists and a Play account are not authentication.
  No anonymous paid wallets, email-based merging, account transfer or guest linking.
- The future Kotlin Godot Android-v2 bridge uses Credential Manager + Firebase Auth;
  GDScript uses authenticated HTTPS. Backend uses Firebase Admin/Firestore and
  future TypeScript Cloud Functions. Native SDK/export validation and provisioning
  are required for integration; there is no built-in Godot Firebase SDK assumed.
  [Google Auth](https://firebase.google.com/docs/auth/android/google-signin),
  [Godot Android plugins](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html),
  [Admin verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens).
- One explicit wallet per action: local earned OR paid, never combined, converted,
  automatically selected or used as fallback. UI must identify wallet and total
  cost before confirmation. Prices remain approved catalog values; the server
  owns paid item IDs/prices. No client cost or claimed local balance is trusted.
- Online paid spending atomically checks active account, positive affordable
  integral cost, nonnegative available balance, not-yet-owned item and request
  identity; debits, FIFO funding allocations, ledger event, entitlement and wallet
  version commit together. All quantities/amounts/versions are safe integers.
  A `(UID, request ID)` permanently binds the request payload/result: exact retries
  return the result; a changed item/wallet/cost payload is rejected. A unique
  `(UID, kind, item ID)` entitlement prevents two devices charging for one unlock.
  A revoked unlock can be repurchased with a new request only after reconciliation.
- Purchase attribution uses a stable server-generated opaque UID binding, not the
  current per-flow marker. Intent binds UID/SKU/environment before checkout;
  missing/mismatched attribution grants nothing and enters support review. Never
  assign an outstanding token to whichever account happens to be signed in later.
- All Firestore client reads/writes are denied, including owners and clients
  claiming `admin`. Future authenticated APIs return only that UID's versioned
  wallet/entitlement projection, never token records. Admin bypasses rules: IAM,
  backend authorization, input validation and transactions remain mandatory.
- Offline paid balance is a labeled last-known, read-only snapshot. No paid
  purchases, debits or queued offline spending. Last-verified active paid unlocks
  can be used offline; immediate revocation on a disconnected or modified client
  cannot be guaranteed. Reconcile before the next online paid operation.
- Sign-out/switch clears active paid projection and increments a session generation;
  discard late responses from old UID/generation. Persist caches separately by UID;
  never copy paid unlocks into the local earned unlock list. Local device progress
  stays available across sign-in/out and never becomes another account's paid value.
- Reinstall/device loss: sign into the same Google/Firebase account and fetch the
  durable paid projection. Consumed coin recovery comes from the server ledger,
  not repeated Play grants. Earned local saves have no new cloud recovery promise.
  Crash/timeout retries retain original UID/idempotency key; purchase token queues
  must persist before submission and contain no loggable tokens. Pending/unknown
  states give no value, including when Firebase or Play is unavailable.
- Lost Google access follows Google's recovery; support cannot transfer wallets
  using an email, device ID, screenshot or order ID alone. Account deletion requires
  recent verified Google authentication, account closure and session revocation;
  pending purchases/refunds are resolved before financial cleanup. Provide in-app
  and web deletion requests and authenticated data export before release. Retain
  minimal restricted purchase-token deduplication/refund tombstones for the legally
  reviewed financial retention period; deleting Auth must never permit token reuse.
  Re-created accounts do not inherit the deleted UID's funds. Retention duration,
  published disclosures and operator access controls remain release prerequisites.

Compared with one cloud balance, this split avoids trusting offline earnings or
requiring server validation of every mission/save. The cost is two explicit wallet
choices and device-local earned progress. Firebase reduces server maintenance but
still needs Blaze billing for future Functions, usage budgets/alerts, least-privilege
IAM, backups, consumption-deadline monitoring and refund/support ownership; budget
alerts are not hard spending caps. No free-operation or deployment readiness claim.
[Firebase pricing](https://firebase.google.com/pricing).

## Refunds and chargebacks

Use authenticated RTDN signals as reconciliation triggers and re-query Google;
notifications may duplicate or arrive out of order. Poll and paginate the
[Voided Purchases API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases/list)
with durable checkpoints/overlap: its query window is bounded (currently 30 days),
and quantity-based partial refunds need explicit handling.

Reversal policy (contract only; workers are not implemented):

1. Re-query Google before applying a confirmed full-unit refund/chargeback. Record
   a stable refund event tied to the original global purchase record. Notifications,
   repeated polling and changed accounts cannot repeat the debit. Keep original
   purchase/ledger records; never wipe earned balance or locally earned unlocks.
2. Paid spending records FIFO source-purchase lots. For each active permanent paid
   unlock funded even partly by the reversed purchase, revoke that paid entitlement
   and reverse its original entire paid spend exactly once. Then debit the original
   refunded pack amount exactly once. Commit the ledger, funding release, wallet
   version and entitlement changes atomically. Released non-refunded funding remains
   spendable; voided funding never becomes new value. Local earned ownership, if
   separately present, continues to allow the item without a paid entitlement.
3. Example: a 500-coin refunded pack plus a valid 500-coin pack funded a 1000-coin
   unlock, leaving 0. Reverse the unlock (+1000), refund the pack (-500): balance
   500 and paid unlock revoked. Refunding must not both confiscate the unlock and
   leave the user owing the same restored spend. Multiple refunded sources reverse
   the same spend only once, regardless of arrival order.
4. If Google reports an ambiguous partial monetary refund, missing funding, disputed
   ownership or an inconsistent old record, mark the wallet and affected paid
   entitlements `review_required`; block paid spending and paid access after sync.
   Keep free play available. Do not invent coin-to-currency prorating. An audited
   support decision records a unique review ID and compensating entries to reverse
   or explicitly reinstate rights, with the same no-double-recovery invariant.
5. A residual negative paid balance represents debt; future paid credits offset it
   and paid spending remains blocked until resolved. There is no forced repurchase;
   support handles disputes. Valid permanent-unlock reversals should normally restore
   enough paid funds to avoid debt; anomalies require review rather than silently
   modifying earned funds. Account switching/deletion never erases obligations.
6. Reconcile revocation on reconnect/resume and before paid operations; discard stale
   projections by UID/session/version. Offline cached access may continue until sync.
   Poll with checkpoints/overlap, alert on missed windows and consumption backlog,
   and exercise repeated/out-of-order/partial/spent refunds before activation.

The foundation contains no purchase verifier, live API, spend mutation, token
storage, consumption worker or refund/revocation worker. End-to-end implementation,
privacy/deletion flows and signed-device verification are required for production.
`PurchaseService.REAL_PURCHASES_ENABLED` remains **false**.
