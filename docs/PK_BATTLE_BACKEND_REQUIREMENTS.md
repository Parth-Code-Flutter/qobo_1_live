# PK Battle — Backend Requirements (Mobile Handover)

**App:** `qobo_one_live` (Flutter)  
**Audience:** Backend team  
**Date:** 2026-07-23 (status updated 2026-07-26)  
**Status:** Backend PK Battle integration is **complete** (REST, Socket.IO `pk_*`, FCM, 120s request expiry, gift→score). Prefer `docs/api/PK_BATTLE_API_AND_MOBILE_HANDOFF.md` as the live contract. This file is retained for historical context.

---

## 1. Product summary (what mobile expects)

PK Battle is a **timed room-vs-room duel** between two hosts who are already live in their own rooms (audio / video / live stream).

1. Host A opens **More → PK Battle** from inside their live room.
2. Host A searches / matchmakes another active room and sends a challenge.
3. Host B receives a **push + in-app / socket** challenge and Accepts or Rejects.
4. On Accept, both rooms enter a battle (default **300 seconds**).
5. Audience gifts / support raise that room’s PK score.
6. When time ends (or status becomes completed), winner is declared and both hosts see Victory / Defeat / Draw.

PK is **not** a seat-vs-seat game inside one room. It is **Room A vs Room B**.

---

## 2. Current mobile implementation (already in app)

### 2.1 Entry point

| Role | Where |
|------|--------|
| Host | Live / audio / video room → bottom **More** → **PK Battle** |
| Audience | No PK start entry (by design) |

Route: `/pk-battle` (`Routes.PK_BATTLE`)  
Controller: `PKBattleController`  
Repo: `PkRepo` (`lib/repo/pk/pk_repo.dart`)

Mobile always passes the **backend room UUID** (`room_id` with dashes), **not** the sanitized Zego channel id.

### 2.2 REST APIs mobile already calls

| Method | Endpoint | Mobile usage | Status on mobile |
|--------|----------|--------------|------------------|
| `GET` | `/api/pk/search?room_id={uuid}` | List challengeable rooms / matchmaking | Wired |
| `POST` | `/api/pk/send-request` | Send challenge to another room | Wired |
| `POST` | `/api/pk/accept-reject` | Accept or reject incoming challenge | Wired (UI exists; **incoming delivery missing**) |
| `GET` | `/api/pk/status?battle_id={id}` | Poll scores / status every ~2s during battle | Wired |

### 2.3 Historical gaps (now closed on mobile + backend)

Earlier mobile builds were missing FCM/socket wiring and used a local gift simulator. Current app wires REST + Socket `pk_*` + FCM, restores via `/api/pk/active`, and trusts backend gift→score updates (`pk_score_update` / `lastGift`).

---

## 3. Complete flow (target)

```text
Host A (Room A)                         Host B (Room B)
     |                                       |
     |  GET /api/pk/search                   |
     |-------------------------------------->| (list Room B)
     |                                       |
     |  POST /api/pk/send-request            |
     |-------------------------------------->|
     |                                       |  FCM type=pk_request
     |                                       |  + Socket pk_request
     |                                       |
     |                                       |  POST /api/pk/accept-reject
     |                                       |  action=accept|reject
     |  FCM/Socket pk_accepted | pk_rejected |
     |<--------------------------------------|
     |                                       |
     |======== battle_id active (300s) ======|
     |  gifts → score updates (REST/Socket)  |
     |  GET /api/pk/status poll (fallback)   |
     |                                       |
     |  FCM/Socket pk_completed              |
     |<------------------------------------->|
```

---

## 4. REST API contract (required responses)

All responses should follow the app’s usual envelope:

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": { }
}
```

`statusCode` accepted by mobile: `1`, `200`, `201`, or `true`.

### 4.1 `GET /api/pk/search?room_id={challengerRoomId}`

**Purpose:** Return other **active** rooms eligible for PK (not the caller’s own room).

**Suggested `data` shapes (mobile accepts any of these):**

```json
{
  "rooms": [
    {
      "room_id": "uuid-of-opponent-room",
      "name": "Sunil's Room",
      "title": "Sunil's Room",
      "avatar": "https://...",
      "displayPicture": "https://...",
      "coverImage": "https://...",
      "hostName": "Sunil",
      "level": 12,
      "vip": "SVIP",
      "room_type": "audio",
      "isLive": true,
      "viewerCount": 120
    }
  ]
}
```

Also accepted: bare list, or `{ "opponents": [ ... ] }`, or a single room object.

**Rules backend should enforce:**
- Only rooms currently live / open.
- Exclude caller’s `room_id`.
- Prefer hosts who are not already in an active PK.
- Return **backend room UUID** (`room_id`), never Zego-only ids.

---

### 4.2 `POST /api/pk/send-request`

**Request (mobile sends today):**

```json
{
  "room_id": "challenger-room-uuid",
  "target_room_id": "opponent-room-uuid",
  "duration": 300
}
```

**Required `data` response:**

```json
{
  "request_id": "pk-request-uuid",
  "room_id": "challenger-room-uuid",
  "target_room_id": "opponent-room-uuid",
  "duration": 300,
  "expires_at": "2026-07-23T16:10:00.000Z",
  "status": "pending"
}
```

| Field | Required | Notes |
|-------|:--------:|-------|
| `request_id` | **Yes** | Mobile stores this for accept/reject; do **not** reuse room id |
| `expires_at` | Yes | Challenge TTL (recommend 60–120s) |
| `status` | Yes | `pending` |

**Side effects required:**
1. Persist pending PK request.
2. Send **FCM** to Host B (and optionally Host A confirmation).
3. Emit **Socket** `pk_request` to Host B’s user / room channel.

---

### 4.3 `POST /api/pk/accept-reject`

**Request (mobile sends today):**

```json
{
  "room_id": "this-host-room-uuid",
  "request_id": "pk-request-uuid",
  "action": "accept",
  "duration": 300
}
```

`action`: `"accept"` | `"reject"`.

#### On `reject` — suggested `data`

```json
{
  "request_id": "pk-request-uuid",
  "status": "rejected"
}
```

Notify challenger via FCM `pk_rejected` + socket `pk_rejected`.

#### On `accept` — suggested `data` (battle starts)

```json
{
  "id": "battle-uuid",
  "battle_id": "battle-uuid",
  "request_id": "pk-request-uuid",
  "room1Id": "challenger-room-uuid",
  "room2Id": "opponent-room-uuid",
  "room1Score": 0,
  "room2Score": 0,
  "duration": 300,
  "status": "active",
  "startedAt": "2026-07-23T16:05:00.000Z",
  "endsAt": "2026-07-23T16:10:00.000Z",
  "room1": {
    "room_id": "challenger-room-uuid",
    "name": "Star Host Test's Room",
    "host_id": "idc...",
    "host_name": "Star Host Test",
    "avatar": "https://..."
  },
  "room2": {
    "room_id": "opponent-room-uuid",
    "name": "Sunil's Room",
    "host_id": "idc...",
    "host_name": "Sunil",
    "avatar": "https://..."
  }
}
```

Mobile maps scores using `room1Id` / `room2Id` vs local `room_id`.

**Side effects on accept:**
1. Create active battle record.
2. FCM + Socket `pk_started` / `pk_accepted` to **both** hosts.
3. Optionally notify audiences in both rooms (`pk_battle_live` broadcast).

---

### 4.4 `GET /api/pk/status?battle_id={battleId}`

**Purpose:** Fallback polling while battle is active (mobile polls ~every 2s).

**Suggested `data`:**

```json
{
  "id": "battle-uuid",
  "battle_id": "battle-uuid",
  "room1Id": "uuid-a",
  "room2Id": "uuid-b",
  "room1Score": 1250,
  "room2Score": 980,
  "duration": 300,
  "remainingSeconds": 142,
  "status": "active",
  "winnerId": null,
  "winner_id": null
}
```

| `status` | Meaning |
|----------|---------|
| `pending` | Request not accepted yet |
| `active` | Battle running |
| `completed` / `ended` | Finished — mobile shows result dialog |
| `cancelled` | Cancelled / expired |

When completed, set `winnerId` / `winner_id` to the **winning room_id** (or omit / null for draw).

---

## 5. Missing REST APIs (please add)

These are **not** called by mobile yet, but are required for a production-complete PK flow.

### 5.1 `POST /api/pk/cancel-request` (recommended)

Cancel an outgoing pending challenge (Host A taps Cancel).

```json
{
  "room_id": "challenger-room-uuid",
  "request_id": "pk-request-uuid"
}
```

Notify Host B: FCM / socket `pk_cancelled`.

---

### 5.2 `POST /api/pk/end` (recommended)

Host-forced or server-forced end (disconnect, report, timeout failsafe).

```json
{
  "battle_id": "battle-uuid",
  "room_id": "caller-room-uuid",
  "reason": "host_leave" 
}
```

`reason` examples: `host_leave`, `timeout`, `moderation`, `error`.

Response should match status payload with `status: "completed"` / `"cancelled"` and optional `winner_id`.

---

### 5.3 Gift → PK score contribution (required for real scoring)

Today gifts use economy APIs (`POST /api/economy/send-gift` with `room_id`, `receiver_id`, `gift_id`).  
For PK, backend must **attribute gift value to that room’s battle score** when a battle is active.

**Options (pick one and confirm):**

**Option A (preferred): enhance existing gift send**

When `room_id` is in an active PK battle, increment that room’s PK score automatically and emit socket `pk_score_update`.

**Option B: dedicated endpoint**

```http
POST /api/pk/contribute
```

```json
{
  "battle_id": "battle-uuid",
  "room_id": "room-receiving-support-uuid",
  "gift_id": "gift-uuid",
  "sender_id": "viewer-user-id",
  "points": 100
}
```

Please document the **points formula** (e.g. gift coin price × multiplier).

---

### 5.4 `GET /api/pk/active?room_id={uuid}` (recommended)

Restore / reconnect: if host reopens PK screen mid-battle, return active `request` or `battle` for that room.

```json
{
  "request": null,
  "battle": { "...same as status data..." }
}
```

---

### 5.5 Optional history

```http
GET /api/pk/history?page=1&limit=20
```

Not required for v1 live flow.

---

## 6. Push notification contract (FCM)

### 6.1 Current gap

Mobile `PushNotificationTypes` currently supports only:

- `room_invite`
- `room_created`
- `live_streaming_created`
- `live_stream_started`
- `general` / `custom`

**No PK types exist.** Backend should start sending the types below; mobile will add parsers + redirection in a follow-up.

### 6.2 New FCM `data.type` values

| `type` | When to send | Primary recipient | Mobile actions (planned) |
|--------|--------------|-------------------|--------------------------|
| `pk_request` | After `send-request` | Opponent host (Host B) | **Accept** / **Reject** |
| `pk_accepted` | After accept | Challenger host (Host A) | Open battle UI |
| `pk_rejected` | After reject | Challenger host (Host A) | Dismiss / snackbar |
| `pk_cancelled` | Challenger cancels / expired | Opponent host | Dismiss |
| `pk_started` | Battle becomes active | Both hosts (+ optional audience) | Open / refresh battle UI |
| `pk_score_update` | Optional (prefer socket) | Both hosts | Refresh scores |
| `pk_completed` | Battle finished | Both hosts (+ optional audience) | Show result |

All FCM `data` values **must be strings**.

### 6.3 `pk_request` payload (required)

Android: **data-only**, high priority (same pattern as `room_invite`).  
iOS: include `notification` + `data`, category `PK_REQUEST` (Accept / Reject).

```json
{
  "token": "<host-b-fcm-token>",
  "data": {
    "type": "pk_request",
    "notification_id": "unique-event-id",
    "request_id": "pk-request-uuid",
    "battle_duration": "300",
    "expires_at": "2026-07-23T16:06:00.000Z",

    "room_id": "host-b-room-uuid",
    "sender_room_id": "host-a-room-uuid",
    "sender_host_id": "host-a-user-id",
    "sender_host_name": "Star Host Test",
    "sender_room_title": "Star Host Test's Room",
    "sender_avatar": "https://...",

    "target_room_id": "host-b-room-uuid",
    "target_host_id": "host-b-user-id"
  },
  "android": {
    "priority": "high",
    "ttl": 120000
  }
}
```

| Field | Required | Purpose |
|-------|:--------:|---------|
| `type` | Yes | Must be `pk_request` |
| `notification_id` | Yes | Deduplicate |
| `request_id` | Yes | Passed to `/api/pk/accept-reject` |
| `sender_room_id` | Yes | Challenger room |
| `room_id` | Yes | Recipient’s own room (Host B) |
| `sender_host_name` | Yes | Banner / notification text |
| `expires_at` | Yes | Block Accept after expiry |
| `battle_duration` | Yes | Seconds (default `300`) |

**Planned mobile redirect on Accept / tap:**
- Ensure Host B is still in (or rejoins) their live room.
- Open `/pk-battle` with args:
  - `room_id` = Host B room
  - incoming request fields from payload  
- Call `POST /api/pk/accept-reject` with `action=accept|reject`.

### 6.4 `pk_started` / `pk_accepted` payload

```json
{
  "type": "pk_started",
  "notification_id": "unique-event-id",
  "battle_id": "battle-uuid",
  "request_id": "pk-request-uuid",
  "room_id": "recipient-room-uuid",
  "opponent_room_id": "other-room-uuid",
  "opponent_host_name": "Sunil",
  "opponent_avatar": "https://...",
  "duration": "300",
  "status": "active"
}
```

Redirect: open `/pk-battle` in **inBattle** state (or refresh if already open).

### 6.5 `pk_completed` payload

```json
{
  "type": "pk_completed",
  "notification_id": "unique-event-id",
  "battle_id": "battle-uuid",
  "room_id": "recipient-room-uuid",
  "opponent_room_id": "other-room-uuid",
  "room1Id": "uuid-a",
  "room2Id": "uuid-b",
  "room1Score": "1250",
  "room2Score": "980",
  "winner_id": "uuid-a",
  "status": "completed"
}
```

`winner_id` empty / omitted / `"draw"` ⇒ treat as draw (confirm exact convention).

### 6.6 iOS categories (to register)

| Category | Actions |
|----------|---------|
| `PK_REQUEST` | `ACCEPT_PK`, `REJECT_PK` |
| `PK_BATTLE` | `OPEN_PK` (optional single action) |

---

## 7. Socket.IO realtime (strongly recommended)

Push alone is not enough while both hosts are foregrounded in a live room. Please emit room/user events mirroring FCM.

### 7.1 Suggested events

| Event name | Direction | Payload |
|------------|-----------|---------|
| `pk_request` | → Host B | Same fields as FCM `pk_request` (JSON object, not all-strings) |
| `pk_accepted` / `pk_started` | → both hosts | Battle start payload |
| `pk_rejected` | → Host A | `{ request_id, status }` |
| `pk_cancelled` | → Host B | `{ request_id, status }` |
| `pk_score_update` | → both hosts (+ rooms) | `{ battle_id, room1Id, room2Id, room1Score, room2Score }` |
| `pk_completed` | → both hosts (+ rooms) | Completed payload |

### 7.2 Channeling

Prefer emitting to:
- Host user personal channel (after `register_user`), **and/or**
- Room channel after `join_room` / `joinRoom`

Mobile already uses `register_user`, `join_room`, `host_live_started`, `room_background_updated`. Please keep naming consistent (`snake_case` event names).

---

## 8. Scoring rules (backend must define)

Mobile will display whatever scores `/status` and sockets return. Backend owns the truth.

Please confirm and document:

1. What increases score? (gift coins, gift diamonds, likes, seat gifts, host gifts only?)
2. Points formula (example: `points = gift.priceCoins * 1`).
3. Can host gifts to self count?
4. Are points per **room** or per **host user**?
5. Soft close: if one host leaves room mid-PK → forfeit / cancel / keep counting?
6. Max concurrent PK per host/room (expect **1**).

Until this exists, mobile’s gift simulator is **UI-only** and must not be treated as production scoring.

---

## 9. Auth / validation rules

| Rule | Expectation |
|------|-------------|
| Who can `send-request` | Host (or room admin, if product allows) of `room_id` |
| Who can accept/reject | Host of `target_room_id` only |
| Room must be live | Both rooms active |
| Idempotency | Accepting twice returns same `battle_id` |
| Expired request | `accept` returns clear error message |
| Wrong room id format | Prefer UUID; mobile sends backend UUID |

---

## 10. Error messages (useful for mobile UX)

Please return clear `message` strings for:

- `No eligible opponents`
- `Opponent is already in a PK`
- `Request expired`
- `Not the room host`
- `Room is not live`
- `Battle not found`
- `Insufficient permissions`

---

## 11. Acceptance checklist for backend QA

- [ ] Host A can search and see Host B’s live room.
- [ ] `send-request` returns a real `request_id`.
- [ ] Host B receives FCM `pk_request` within a few seconds (app background + killed).
- [ ] Host B receives socket `pk_request` while foreground in room.
- [ ] Accept creates `battle_id` and both hosts get `pk_started`.
- [ ] Reject notifies Host A (`pk_rejected`).
- [ ] Gifts in either room increase that room’s score.
- [ ] `/api/pk/status` reflects scores within ~2s.
- [ ] At timeout, status becomes `completed` with `winner_id` or draw.
- [ ] Both hosts can reopen / restore active battle via status or `GET /api/pk/active`.

---

## 12. Open questions for backend team

Please reply with decisions on:

1. Exact FCM type strings — OK to use section 6.2 as-is?
2. Challenge TTL (`expires_at`) — 60s / 90s / 120s?
3. Default battle duration — keep **300**?
4. Scoring formula and whether existing `send-gift` auto-contributes.
5. Socket event names — OK to use section 7.1?
6. Will you implement `cancel-request` and `end` in v1?
7. Should audience see a PK banner inside the room, or hosts-only UI?
8. Draw convention for `winner_id`.

---

## 13. Related mobile files (for reference)

| File | Role |
|------|------|
| `lib/repo/pk/pk_repo.dart` | REST client |
| `lib/app/user_flow/pk_battle/controllers/pk_battle_controller.dart` | State machine + polling |
| `lib/app/user_flow/pk_battle/views/pk_battle_view.dart` | Arena UI |
| `lib/app/user_flow/live_broadcast/widgets/room_options_sheet.dart` | Host **More → PK Battle** entry |
| `packages/push_notification_service/lib/src/push_notification_types.dart` | FCM types (PK not added yet) |
| `lib/services/realtime/user_realtime_socket_service.dart` | Socket hub (PK events not added yet) |

---

## 14. Summary for backend

| Area | Mobile ready? | Backend needed? |
|------|:-------------:|:---------------:|
| Search / send / accept-reject / status REST | Yes | Confirm response shapes + `request_id` |
| Push (`pk_request` etc.) | No handler yet | **Must send** so we can wire |
| Socket PK events | No listener yet | **Must emit** so we can wire |
| Score from gifts | Simulated only | **Must implement** |
| Cancel / end / active restore | Partial / missing | Recommended for v1 |

Once backend confirms this contract (especially push types + gift scoring), mobile can implement FCM parsing, deep-link Accept/Reject, and socket listeners without further API guesswork.
