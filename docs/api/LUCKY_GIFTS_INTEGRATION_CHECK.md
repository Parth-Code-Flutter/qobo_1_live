# Lucky integration checks — 24 October 2026

Mobile now loads GET /api/gifts/lucky and uses POST /api/gifts/lucky/send.
The existing standard gift sheet/send endpoint is unchanged. The dedicated Lucky
picker stays open, serializes paid taps, uses UUID clientGiftId, and retries an
uncertain send with the same payload. Closing cancels taps not yet dispatched.
An uncertain request is retained for retry while the room controller lives;
there is no persistent recovery after process termination.

Request example (IDs from the supplied test accounts; no credentials included):
```json
{
  "gift_id": "08cf0826-3254-4f7a-a579-d3b2f4efdab5",
  "quantity": 1,
  "combo": 1,
  "comboCount": 1,
  "host_id": "idc6497937",
  "clientGiftId": "<new UUID per tap; reuse for retry>"
}
```
Room usage additionally passes channel_id from the existing room gift-ID resolver.

## Manual live API checks

- Logged into both supplied test accounts ending 6762 and 8899 using the previously
  authorized force-login option. Their other sessions may be signed out.
- Both catalogs returned HTTP 200 and five active items.
- Sent the cheapest item (100) between accounts in both directions: HTTP 200.
- Replayed identical clientGiftId: HTTP 200, data.idempotent=true. No second debit
  was observed. The replay transaction_id differs from the first response and its
  response omits balance/reward details. Mobile refreshes wallet on this response.
- Five consecutive quantity=1 sends with combo=1..5: fifth response returned
  luckyRewardTriggered=true, luckyRewardCoins=700, luckyRewardBonus=200.
  Sender spend balance before this five-send sequence: 19820; after: 20020.
- These were real API sends and changed the test accounts' wallet balances.

## Backend issues / contract differences

1. Standalone send with host_id omitted fails on both accounts:
   HTTP 400, `Cannot read properties of null (reading 'id')`.
   Wallets unchanged in these failed tests. The guide says host_id is optional.
   Mobile room picker requires another recipient for paid sends. Host-only taps
   play a clearly labeled, free local preview instead of issuing the broken request. Backend must repair this for standalone play.
2. Live responses debit wallet.diamonds / purchased balance; data.userCoins equals
   remaining_diamonds, whereas wallet.coins is the separate earnings balance.
   Mobile keeps these balances separate, displaying spend balance in Lucky.
3. Duplicate response omits luckyReward / userCoins. Returning the original full
   result would allow the app to show the recovered reward precisely.

## Validation limits

Live API tests used recipient IDs without channel_id. Device UI, remote-recipient
rendering, audio/video room routing, and live-stream/PK end-to-end behavior have
not been manually verified in this run. Automated tests cover the picker,
serialization, account switches, retry identity, rewards, and existing animation.
