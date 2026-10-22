# Google Play coin purchases — mobile-reported success contract

## Requested flow

This document supersedes the previous server-verification contract.
The client requests NO server-side Google purchase verification and no payment
dashboard. No Google Cloud project, service account, Google Play Developer API,
or Google server notification integration is required for this proposed flow.

1. User selects a coin pack and pays through Google Play in the mobile app.
2. Mobile receives a PURCHASED result from Google Play (not merely checkout-open
   success). Pending, cancelled and failed payments do not request coins.
3. Mobile sends the purchase details to the authenticated coin-credit API below.
4. Backend credits the mapped coin quantity once and returns success.
5. Mobile consumes the purchase through the Google Play Billing SDK, then
   refreshes the wallet. Consumption permits another purchase of the same pack
   and fulfils Google's acknowledgement requirement. Do not auto-consume before
   the backend has committed the coin credit.

The backend trusts the mobile payment-success report. Authentication, product
mapping and duplicate-request protection below are normal wallet safeguards;
they are NOT payment verification against Google.

Limitation: without independent verification, modified clients can submit fake
purchase claims. This design cannot establish payment authenticity or current
refund status; it does not automatically reverse coins after refunds. Bank
payout statements are not used to authorize individual coin credits.

## Implementation status — 21 October 2026

Mobile integration now uses `/api/economy/google-play/confirm`, with checkout
enabled by default. Build version is 1.0.1 (13). The old `/verify` endpoint is
not called. Set `--dart-define=GOOGLE_PLAY_BILLING_ENABLED=false` to disable
checkout in a particular build.

The live backend catalog was checked with both supplied test accounts: all eight
product mappings are present. Empty-token confirmation returned HTTP 400 for
both accounts and their balances were unchanged. No synthetic successful
purchase was submitted to the live coin-credit API.

## Catalog: GET /api/economy/package-list

Keep existing package fields. Add `googlePlayProductId` to each pack and map
these product IDs to coin quantities on the server:

| googlePlayProductId | Coins |
| --- | ---: |
| qobo_coins_4000 | 4000 |
| qobo_coins_8000 | 8000 |
| qobo_coins_16000 | 16000 |
| qobo_coins_24000 | 24000 |
| qobo_coins_32000 | 32000 |
| qobo_coins_40000 | 40000 |
| qobo_coins_80000 | 80000 |
| qobo_coins_400000 | 400000 |

Product IDs must match Console exactly. Android displays the price returned by
Google Play. Keep multi-quantity checkout disabled; one transaction buys one
pack. Repeat transactions remain allowed. Preserve historical product mappings
when introducing new packs so unfinished purchases can still receive coins.

## NEW: POST /api/economy/google-play/confirm

Use the existing authenticated session. Example request:

```json
{
  "packageName": "com.qobo1live.live",
  "productId": "qobo_coins_4000",
  "purchaseToken": "GOOGLE_PURCHASE_TOKEN",
  "orderId": "GOOGLE_ORDER_ID_IF_AVAILABLE"
}
```

`orderId` is optional. Mobile calls this only after a purchased/restored-owned
purchase event, never simply because buyConsumable returned true.

Backend actions (NO request to Google):

1. Get the Qobo user from the authenticated session. Require the expected package
   name, a known product mapping and a nonempty purchase token. Do not accept a
   client-supplied coin amount as the amount to credit.
2. Atomically record the token and credit the mapped quantity to the same wallet
   balance used by existing coin recharges. Persist user, product, coins, optional
   order ID and timestamps. Enforce a database unique constraint on purchaseToken
   across all users, including concurrent requests.
3. For a repeated token belonging to the same user and product, return the prior
   successful result without adding coins again. Reject reuse for a different
   user/product. Never return success before the credit transaction commits.
4. Return the following response. The backend neither verifies nor consumes the
   Google purchase, so do not include `verified` or `consumed` success assertions.

```json
{
  "success": true,
  "data": {
    "productId": "qobo_coins_4000",
    "userId": "AUTHENTICATED_QOBO_USER_ID",
    "credited": true,
    "coinsAdded": 4000,
    "alreadyCredited": false
  }
}
```

On an idempotent retry, return the original coinsAdded and alreadyCredited:true.
On errors, return success:false with a diagnostic code/message and an appropriate
HTTP status. Never echo purchase tokens in responses or logs.

## Implemented mobile behavior

- Calls confirm with the initiating account's captured bearer token and optional
  Google order ID. Checks returned user/product and explicit credit confirmation.
- Uses autoConsume:false; consumes through Android Billing only after credit.
- Stores pending receipts and credit markers in encrypted Android storage in a
  separate namespace that survives normal app logout.
- Uses Google's obfuscated account ID to keep retries bound to the original
  Qobo account. Unbound receipts cannot credit whichever account is signed in.
- Retries on app resume, while foregrounded, and after restart. A persisted credit
  marker allows consumption retry without another coin-credit request. Backend
  idempotency handles a lost confirmation response.
- Refreshes the wallet on credit, including when consumption needs another retry.

## Release test still required

Upload build 13 (or a higher unused version code) to internal testing. Install
from Google Play using a configured license tester. Check approved, cancelled,
pending, repeated purchases, interruption/recovery, wallet balance changes and
account switching. Keep multi-quantity disabled. A real Play checkout has not
been tested in this workspace because no Android device is connected.

## Acceptance tests

- Purchased event → confirm API → one wallet credit → mobile consumption.
- Purchase launch success alone, pending, cancellation and failure → no credit.
- Repeated and concurrent token submissions → one credit total.
- Credit committed but response lost → retry returns alreadyCredited:true.
- App killed/offline between payment, credit and consumption → recover safely.
- Account switch during checkout/recovery → originating Qobo user only.
- Consumption failure → retry consumption; no extra credit.
- Successfully consumed pack can be purchased again with a new token.

Automated tests cover this confirm/consume flow with fake Google billing and
backend responses; they do not establish real Google checkout or backend atomicity.
