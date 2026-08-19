# Host Session Earnings — Audience Rejoin API

**App:** qobo_one_live (Flutter)  
**Audience:** Backend  
**Date:** 17 Aug 2026  
**Related:** `docs/api/SESSION_EARNINGS_API.md`

Auth: `Authorization: Bearer <token>`  
Envelope: `{ "statusCode": 1|0, "message": "...", "data": { ... } }`  
Success: `statusCode` is `1`, `200`, `201`, or `true`.

---

## Why (problem)

Audio room **AppBar pill** shows **this room’s host session earnings** (gifts in the current live room).

It is **not**:

- Wallet balance
- Audience’s own coins
- Lifetime diamonds under a seat

When an **audience** user **leaves and joins the same live room again**:

1. Mobile starts that AppBar pill at `0` (new screen / new client session).
2. It then reads the host total from **join** + **session-earnings poll**.
3. If those APIs return `0`, omit `sessionCoinsEarned`, or allow **host token only**, the pill stays **0** even though the host already earned in this room.

That is wrong. Audience must see the **same host total** the host sees.

Seat diamond chips under **audience avatars** should still start at `0` on rejoin. Only the **AppBar host total** must persist for the room session.

---

## What is needed

For `session_type = audio_room` (same for `video_room` and `live_stream`):

1. **Any logged-in member of that live room** (host **and** audience) must get **host** `sessionCoinsEarned`.
2. Do **not** return the caller’s own earnings (`0` for audience).
3. Do **not** block audience with host-only / forbidden.
4. Put the same block on **join** so first paint is not `0`.

Count from when **this room session started** (host opened the room).  
Reset only when the room ends, or the host leaves and starts a new session.

---

## 1. Get host session earnings (poll)

**Method:** `GET`  
**URL:** `/api/room/session-earnings`

**Query**

| Param | Required | Example | Notes |
|---|---|---|---|
| `room_id` | Yes | room UUID | Backend room id, not Zego short id |
| `session_type` | Yes | `audio_room` | `audio_room` \| `video_room` \| `live_stream` |

**Request**

```
GET /api/room/session-earnings?room_id={room_uuid}&session_type=audio_room
Authorization: Bearer <token>
```

Token may be **host or audience**. Both must be allowed.

**Success**

```json
{
  "statusCode": 1,
  "message": "Session earnings fetched",
  "data": {
    "room_id": "room-uuid",
    "session_type": "audio_room",
    "host_user_id": "host-uuid",
    "sessionCoinsEarned": 1280,
    "sessionDiamondsEarned": 0,
    "giftCoinsEarned": 1280
  }
}
```

`sessionCoinsEarned` = **host** total for this room session.  
Same number for host token and audience token.

**Wrong (current audience case)**

```json
{
  "statusCode": 1,
  "data": {
    "sessionCoinsEarned": 0
  }
}
```

or host-only / not allowed for audience.

Aliases mobile already reads: `session_coins_earned`, `hostSessionCoins`, `host_session_coins`, `giftCoinsEarned`, `gift_coins_earned`.

---

## 2. Include on join (required so first paint is not 0)

**Method:** `POST`  
**URL:** `/api/room/join`

**Body**

```json
{
  "room_id": "room-uuid",
  "roomId": "room-uuid",
  "session_type": "audio_room"
}
```

**Success — `data` must include host session block**

```json
{
  "statusCode": 1,
  "message": "Joined",
  "data": {
    "room_id": "room-uuid",
    "sessionEarnings": {
      "sessionCoinsEarned": 1280,
      "sessionDiamondsEarned": 0
    }
  }
}
```

Aliases: `session_earnings`, `session_coins_earned`, `hostSessionCoins`.

---

## How to verify

Same live room, host already has earnings (example `1280`):

| Caller | API | Expected |
|---|---|---|
| Host | `GET /api/room/session-earnings` | `sessionCoinsEarned`: 1280 |
| Audience | `GET /api/room/session-earnings` | **same 1280** |
| Audience | `POST /api/room/join` | `sessionEarnings.sessionCoinsEarned`: **same 1280** |

If host is `1280` and audience is `0`, that is the bug.

Use the **backend room UUID**, not the short Zego id shown in the room header (e.g. `8290acc…`).

---

## Acceptance

- [ ] Audience rejoins the same audio room → AppBar host pill matches host’s session total (not `0`)
- [ ] Audience seat diamond chip still starts at `0` after leave + sit again
- [ ] Host token and audience token return the same `sessionCoinsEarned` for the same `room_id`
- [ ] Join payload includes that host total so first paint is correct
- [ ] Value resets only when the room session ends, not when one audience leaves
