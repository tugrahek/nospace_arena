# v1 coin purchases — secure architecture contract

Status: foundation only, 2026-11-02. **Real purchases are disabled.** This is the
required future design, not a deployed verification service or a recovery promise.
Release completion is tracked in [the permanent v1 checklist](release-v1-checklist.md).

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
Identifiers are public product metadata, not signing secrets; this task explicitly
approves these names. Service credentials and purchase tokens stay out of Git/logs.

## Verified repository state

- `PurchaseService.REAL_PURCHASES_ENABLED=false` keeps the production autoload on
  the unavailable no-op backend on every platform. Fake-backend unit tests remain
  injectable. This gate prevents accidental activation, not hostile client edits.
- The existing Android adapter handles non-consumables, not these consumable packs.
  The live service catalog remains empty; no Store layout, prices or coin grants
  are connected to these definitions.
- Existing callbacks/flow markers and `Economy` transaction persistence provide
  local orchestration only. The bridge's per-flow obfuscated account marker is
  **not a durable authenticated account ID**. No trusted verification endpoint or
  server ledger exists in this repository.
- The current local handler can mark a consumable transaction delivered without
  crediting coins. Do not connect the new SKUs to that handler as fulfillment.
  Local save deduplication cannot prevent cross-device replay/save rollback.

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

## Required implementation: verify, commit, consume, reconcile

This sequence is the project's proposed v1 design; none of the following server
components are implemented in Step 32.

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
   result. The current local economy path needs a separately reviewed integration.
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

## BLOCKER: account and wallet recovery decision

There is currently no player login or cloud wallet. A per-install identifier
cannot recover consumed paid coins after uninstall, data clearing, device loss
or switching devices. **No recovery model has been approved.** Decide authenticated
identity/linking and account switching; authoritative ownership of paid balance
and spending; migration/merge of existing locally earned coins; offline behavior;
cross-device conflicts; deletion/export/support and lost-access recovery.

An anonymous model would need an explicit, secure recoverable credential/linking
design and reviewed loss/support policy; it is not a shortcut supplied by Play
purchase queries. Do not invent that decision or promise restore in the listing.
This decision and secure delivery are mandatory blockers for v1 IAP activation.
Step 32 does not change balances, rewards, save schema or progression.

## Refunds and chargebacks

Use authenticated RTDN signals as reconciliation triggers and re-query Google;
notifications may duplicate or arrive out of order. Poll and paginate the
[Voided Purchases API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases/list)
with durable checkpoints/overlap: its query window is bounded (currently 30 days),
and quantity-based partial refunds need explicit handling.

Append idempotent compensating ledger entries for confirmed reversals. Never
delete the original purchase record or let a refund replay debit twice. The
publisher must decide treatment of already-spent coins, partial refunds, disputes,
negative paid balances and support corrections. Do not silently wipe earned coins
or apply a new balance policy in this foundation task. Alert on missed windows,
unfulfilled charged purchases and consumption backlog. Refund/revocation operations
need a reviewed operational policy; no automated refund implementation is present.
