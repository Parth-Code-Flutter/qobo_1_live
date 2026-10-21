# Google Play coin purchases — mobile integration and backend contract

## Current rollout state

The Android manifest declares BILLING and the mobile app includes
`in_app_purchase ^3.3.1` (latest stable verified on pub.dev on 2026-10-21).
Android coin checkout now uses Google Play; iOS retains its existing flow.
The default build has Google checkout disabled until verification is deployed.
It shows purchases unavailable, never falls back to Razorpay on Android, and
never calls the legacy recharge endpoint for Google purchases.
This build is for INTERNAL TESTING / unlocking product setup, not a production
payment release. No production purchases should be enabled yet.

Build a normal AAB for Console product setup. Ensure its version code exceeds
ALL previously uploaded codes (pubspec currently 1.0.1+11; do not reuse 11 if
already uploaded). No special build flag is needed to expose BILLING permission.

After the server implements this contract and products exist, enable checkout
in an internal-testing build with `--dart-define=GOOGLE_PLAY_BILLING_ENABLED=true`.
Use Google license testers; do not use real money to test the unfinished flow.
Do not enable this flag in production before end-to-end validation.

## Catalog: GET /api/economy/package-list

Keep existing package fields. Add `googlePlayProductId` to each Android pack,
for example `qobo_coins_100`. There is deliberately no guessed mapping from coin
quantity or package ID. Product IDs must match Console exactly. Missing mapping
or unavailable Play product disables the pack. Mobile displays Google's localized
price, not the backend price, at Android checkout.

Create a one-time product with a Buy option for each pack. Packs are consumable
by the processing flow, not a Console subscription. Use new product IDs when
changing coin quantities; preserve old mappings for pending purchases.

## POST /api/economy/google-play/verify (NEW — backend not implemented here)

Use the existing authenticated API session. Body:

```json
{
  "packageName": "com.qobo1live.live",
  "productId": "qobo_coins_100",
  "purchaseToken": "GOOGLE_PURCHASE_TOKEN"
}
```

No client coin quantity, price, user ID or success assertion is authoritative.
Server requirements:

1. Verify the token with the Google Play Developer API using server-only service
   credentials and the fixed Qobo package name. Check PURCHASED state, product,
   quantity and purchase validity. Pending/invalid purchases grant nothing.
2. Compare Google's obfuscated account ID with lowercase hex SHA-256 of UTF-8
   `qobo-play:<authenticated Qobo userId>`. Mobile passes this as
   PurchaseParam.applicationUserName. Reject an account mismatch; do not reassign
   another user's payment on logout/login or restore. Do not accept legacy
   unbound purchases without a separately designed recovery procedure.
3. Credit the mapped package's coins in an atomic wallet transaction. Enforce
   a unique purchase-token ledger key across all users, retries and API workers.
   Persist the original user, product, quantity, credited amount and Google order.
4. AFTER wallet credit commits, consume the product through Google's API.
   Server consumption also satisfies acknowledgement. Retry consumption safely
   after outages and within Google's acknowledgement window. Never consume
   before committing delivery. Multi-quantity orders must be handled correctly
   (or disallowed in Console); do not blindly assume quantity 1.
5. Return the strict response below only when credit and consumption are done.
   Duplicate retries for the same owner return the same confirmed result without
   new credit. If consumption already succeeded but the response was lost, use
   the persisted ledger and Google's state to reconcile.

```json
{
  "success": true,
  "data": {
    "productId": "qobo_coins_100",
    "userId": "authenticated Qobo user ID",
    "credited": true,
    "consumed": true
  }
}
```

Mobile never treats a generic 200/statusCode as delivery proof, never adds coins
locally, and NEVER calls client completePurchase/consumePurchase: the SERVER
owns consumption and acknowledgement. The mobile app refreshes GET wallet only
after the strict confirmation, and when the wallet opens normally.

For pending/failed verification return success:false (with your normal HTTP
status and diagnostic code). Do not echo tokens. The client keeps the purchase
owned in Play and retries. Implement server retries/reconciliation independently
of mobile uptime: consumed products are no longer returned by Play recovery.
Configure Real-time Developer Notifications and voided purchase reconciliation
for refunds/chargebacks. Define reversal rules for already-spent coins and host
balances before production rollout. Never log purchase tokens or credentials.

## Mobile lifecycle

Permanent service subscribes at app initialization when enabled; foreground
resume, wallet catalog refresh and a 60-second foreground retry query owned
purchases. Unauthenticated events are left unconsumed for later recovery.
Concurrent duplicate token events are suppressed; server idempotency remains
mandatory across app restarts/devices. Logout/account switches must not cause
purchase credit to the wrong user (server account binding is required).

## Validation before production

- Internal-track installation signed by Play; active product and Buy option.
- License-test payment success; matching wallet credit; repeat same-pack buy.
- Cancellation and decline: zero credit; pending: no credit until purchased.
- Disconnect/kill app after payment; resume and recover exactly once.
- Duplicate callbacks/verification requests and consume timeout: no double credit.
- Switch Qobo accounts while payment is pending: original account only.
- Refund/voided purchase and server reconciliation tested.
- Reopen wallet: balance from backend; all gift/withdraw behavior unchanged.

Local automated tests cover the mobile state/verification contract with a fake
store; they do not prove actual Google checkout or backend integration works.
