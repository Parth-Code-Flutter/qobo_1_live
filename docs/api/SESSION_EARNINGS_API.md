# Session Earnings API — Mobile Requirements

**App:** qobo_one_live (Flutter)  
**Audience:** Backend  
**Date:** 2026-07-28  

Mobile must show **current session earnings** (gifts + paid call minutes in this room/call), **not** total wallet balance, in:

- Audio room app bar
- Live stream host banner
- Video room host banner
- 1:1 voice / video call (callee earning panel)

---

## Problem today

- Audio room header shows **heat / engagement** (`heatScore`, viewer count) — not earnings.
- Live/video host card reads **`GET /api/economy/wallet`** (`diamondsBalance`) — wrong for “this session”.
- Calls show wallet under the earning chip — should emphasize **session** total.

Mobile already tracks session earnings locally (gift price fallback + call billing timer) but needs authoritative server totals for reconnect, multi-device, and anti-tamper.

---

## 1. Get session earnings (poll / refresh)

```http
GET /api/room/session-earnings?room_id={uuid}&session_type={audio_room|video_room|live_stream|call}
Authorization: Bearer <user_token>
```

### Response `200 OK`

```json
{
  "statusCode": 1,
  "message": "Session earnings fetched",
  "data": {
    "roomId": "room-uuid",
    "sessionType": "audio_room",
    "hostUserId": "host-uuid",
    "sessionCoinsEarned": 1280,
    "sessionDiamondsEarned": 0,
    "giftCoinsEarned": 900,
    "callCoinsEarned": 380,
    "updatedAt": "2026-07-28T06:30:00.000Z"
  }
}
```

**Rules**

- Count only gifts / call billing **since host joined this session** (reset when room ends or host leaves and re-joins).
- `sessionCoinsEarned` = authoritative total for UI badge.
- Host-only for room surfaces; for 1:1 calls both parties may poll with `session_type=call`.

Mobile polls every **30s** while host is in room (404 → keep local tracker until backend ships).

---

## 2. Include on room join

`POST /api/room/join` and create-room responses should embed the same block so first paint is correct:

```json
{
  "sessionEarnings": {
    "sessionCoinsEarned": 0,
    "sessionDiamondsEarned": 0
  }
}
```

Aliases accepted: `session_coins_earned`, `hostSessionCoins`, `session_earnings`.

---

## 3. Gift send response (increment host)

`POST /api/economy/send-gift` — when the host earns (receiver is host, or `scope=room`), include:

```json
{
  "statusCode": 1,
  "data": {
    "gift": { "price": 100 },
    "hostEarnings": {
      "coinsAdded": 70,
      "sessionCoinsEarned": 1280
    }
  }
}
```

`coinsAdded` = this gift’s host share (after platform cut if any).  
`sessionCoinsEarned` = running session total after this gift.

---

## 4. Realtime (optional, preferred)

On successful gift, emit to room socket:

```json
{
  "event": "gift_sent",
  "roomId": "room-uuid",
  "hostEarnings": {
    "coinsAdded": 70,
    "sessionCoinsEarned": 1280
  }
}
```

Host clients update badge without polling.

---

## 5. Call billing

For `session_type=call`, include per-minute callee earnings in:

- Call answer webhook / billing tick, or
- Same `GET /api/room/session-earnings` with `callCoinsEarned` incremented each billed minute.

---

## Mobile wiring (already in app)

| Layer | Path |
|-------|------|
| Tracker | `lib/services/session/session_earnings_tracker.dart` |
| Parse helpers | `lib/utils/session_earnings_utils.dart` |
| Widgets | `lib/utils/app_widgets/session_earnings_badge.dart` |
| Repo | `RoomRepo.getSessionEarnings` |
| Surfaces | `audio_room_stage_overlay`, `live_broadcast_view`, `chat_voice_call_view` |

---

## Acceptance checklist

- [ ] Host audio room badge matches backend after gift in same session
- [ ] Live/video banner shows session coins, not wallet diamonds
- [ ] Re-open room mid-session → join or poll restores same total
- [ ] 1:1 call callee chip shows session earn (gifts + minutes), not wallet
- [ ] Wallet balance unchanged on badge when user receives unrelated wallet credit
