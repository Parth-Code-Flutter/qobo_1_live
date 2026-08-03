# Host Seat Manage + Floor → Seat Place (Backend API Handover)

**App:** `qobo_one_live` (Flutter)  
**Audience:** Backend team  
**Date:** 2026-08-02 (updated 2026-08-03)  
**Status:** Backend confirmed — mobile uses canonical actions + hydrated response  
**Base URL (prod/test):** `https://my-backend-api-960q.onrender.com`  
**Scope:** Audio + Video party rooms only

### Backend confirmation (2026-08-03)

- Canonical actions: **`remove_from_seat`**, **`approve_speaker`** (aliases also supported server-side).
- Explicit error codes mapped (e.g. `CANNOT_REMOVE_HOST_SEAT`, `SEAT_OCCUPIED`, `USER_NOT_ON_SEAT`).
- Success `data` returns hydrated `seats`, `floor_audience`, `my_placement` (mobile applies this; no required secondary seats GET).
- Staging goes live after backend GitHub sync → Render (~3–5 min).

---

## 0. Why this is needed

Mobile host/admin can now:

1. **Remove a seated user from a mic seat** (user stays in the room on the floor list).  
   This is **not** the same as `POST /api/room/kick` (kick removes them from the room entirely).

2. **Directly place a floor-audience user onto an empty seat** (no invite wait, no seat-request wait).  
   Host picks someone from the horizontal floor strip (or from “Seat floor user” on an empty seat) and seats them immediately.

Today these mobile actions call **`POST /api/room/mic-action`**.  
If the actions below are not implemented (or use different names), host will see API errors.

---

## 1. Endpoint (reuse existing)

```http
POST /api/room/mic-action
Authorization: Bearer <token>
Content-Type: application/json
```

Mobile already sends **both snake_case and camelCase** keys:

```json
{
  "room_id": "uuid",
  "roomId": "uuid",
  "target_user_id": "uuid",
  "targetUserId": "uuid",
  "action": "<action>",
  "seat_id": 3,
  "seatId": 3
}
```

| Field | Required | Notes |
|-------|----------|--------|
| `room_id` / `roomId` | Yes | Room UUID |
| `action` | Yes | See §2 |
| `seat_id` / `seatId` | Yes | Seat number (`>= 2` for guest seats; seat `1` is host) |
| `target_user_id` / `targetUserId` | Yes for these host flows | User being removed from seat **or** placed on seat |

**Auth:** Host or room admin only for the actions in §2.1 and §2.2.

**Success shape (recommended):**

```json
{
  "statusCode": 1,
  "success": true,
  "message": "Seat updated",
  "data": {
    "roomId": "uuid",
    "seatId": 3,
    "action": "remove_from_seat",
    "seats": [],
    "floor_audience": [],
    "my_placement": "floor"
  }
}
```

Returning updated `seats` + `floor_audience` is ideal so clients can refresh immediately. If not returned, mobile will re-call `GET /api/room/seats`.

---

## 2. Actions required

### 2.1 Remove person from seat (stay in room → floor)

**Preferred action name (please implement this):**

| `action` | Who | Behavior |
|----------|-----|----------|
| **`remove_from_seat`** | Host / room admin | Clear `target_user_id` from `seat_id`. User remains in room and is added to `floor_audience`. Cancel any pending seat request for that user. Do **not** ban / kick. |

**Aliases mobile will try if preferred fails** (optional to support):

- `leave_seat`
- `leave`

**Rules:**

- Seat `1` (host) cannot be cleared this way → `400` / `CANNOT_REMOVE_HOST_SEAT`.
- Target must currently occupy that seat → else `SEAT_USER_MISMATCH` / `USER_NOT_ON_SEAT`.
- After success:
  - seat becomes empty (unlocked unless previously locked)
  - user appears in `floor_audience`
  - `my_placement` for that user becomes `"floor"`
  - Zego / speaker publish for that user should be demoted to audience/listener as you already do on leave-seat

**Example request:**

```json
{
  "roomId": "d8646195-....",
  "targetUserId": "user-uuid",
  "action": "remove_from_seat",
  "seatId": 3
}
```

**Difference vs kick:**

| | Remove from seat | Kick |
|--|------------------|------|
| Endpoint | `POST /api/room/mic-action` | `POST /api/room/kick` |
| Still in room? | **Yes** (floor) | **No** |
| Floor list | Added | Removed |
| Rejoin cooldown | No | Optional / existing kick rules |

---

### 2.2 Place floor user directly on an empty seat

**Preferred action name (please implement this):**

| `action` | Who | Behavior |
|----------|-----|----------|
| **`approve_speaker`** | Host / room admin | Place `target_user_id` (must be in room, typically in `floor_audience`) onto empty `seat_id` **immediately**. |

**Aliases mobile will try if preferred fails** (optional to support):

- `take_seat` *(when called by host/admin with `target_user_id` — host force-place)*
- `force_take_seat`

**Rules:**

- Caller must be host or room admin.
- Target must be **in the room** (joined). Prefer: currently in `floor_audience` (not already seated).
- `seat_id` must be empty and unlocked; seat `1` reserved for host → reject guest place on seat 1.
- **Bypass follower gate** for this host action (same as approving a seat-request).  
  Non-followers may sit when host explicitly places them.
- On success:
  - remove user from `floor_audience`
  - occupy `seat_id` with that user
  - cancel other pending seat-requests from that user
  - `my_placement` → `"seat"`
  - promote mic/Zego publish as you do on normal take-seat / approve

**Example request:**

```json
{
  "roomId": "d8646195-....",
  "targetUserId": "floor-user-uuid",
  "action": "approve_speaker",
  "seatId": 2
}
```

**Not the same as invite:**

| | Direct place (`approve_speaker`) | Invite (`POST /api/room/invite`) |
|--|----------------------------------|----------------------------------|
| Target | Already in room (floor list) | Usually follower not yet in room |
| Accept step | **None** — immediate | User must accept |
| Use case | Host seats someone from horizontal floor strip | Host invites outsider to mic |

---

## 3. Related existing APIs (keep working)

These already exist / are used by mobile — do not break:

| Method | Path | Use |
|--------|------|-----|
| `GET` | `/api/room/seats?room_id=&roomId=` | Must keep returning `floor_audience`, `pending_seat_requests`, `viewer_follows_host`, `my_placement` |
| `POST` | `/api/room/kick` | Full remove from room (kicked user must leave client) |
| `POST` | `/api/room/invite` | Invite follower to seat (accept flow) |
| `POST` | `/api/room/seat-request` | Floor user requests a seat |
| `POST` | `/api/room/seat-request/respond` | Host Allow/Reject request |
| `POST` | `/api/room/mic-action` `mute` / `unmute` | Unchanged |

**Seat-request Allow** should continue to place the requester on the requested seat (same end-state as `approve_speaker`).

---

## 4. Socket events (recommended)

Emit to room channel after either action so all clients refresh without waiting for poll:

| Event | When | Payload (min) |
|-------|------|----------------|
| `seat_updated` **or** `floor_audience_updated` | After remove-from-seat or place-on-seat | `{ "room_id", "seat_id", "user_id" }` |
| `user_kicked` / `room_user_kicked` | Only for **kick**, not remove-from-seat | `{ "room_id", "targetUserId" }` |

Mobile already listens for `floor_audience_updated`, `user_kicked`, `room_user_kicked`, and polls seats every ~2s as fallback.

---

## 5. Error codes (recommended)

| Code / message | When |
|----------------|------|
| `NOT_HOST` / `FORBIDDEN` | Non-host/admin called host actions |
| `NOT_IN_ROOM` | Target not joined |
| `SEAT_OCCUPIED` | Place on occupied seat |
| `SEAT_LOCKED` | Place on locked seat |
| `USER_NOT_ON_SEAT` | Remove but user not on that seat |
| `CANNOT_REMOVE_HOST_SEAT` | Tried clear seat 1 / host |
| `USER_ALREADY_SEATED` | Place but target already on another seat |
| `INVALID_ACTION` | Unknown `action` string |

Please return a clear `message` string; mobile shows it in snackbars/dialogs.

---

## 6. Acceptance checklist for backend

- [ ] Host taps seated guest → **Remove from seat** → user leaves seat, still in room, appears in `floor_audience`.
- [ ] Host taps floor avatar → **Put on seat** → user occupies chosen empty seat, leaves floor list.
- [ ] Host taps empty seat → **Seat floor user** → same place behavior.
- [ ] Seat 1 / host cannot be overwritten or cleared by these actions.
- [ ] Place works even if target does **not** follow the host (host override).
- [ ] Kick still removes from room entirely; remove-from-seat does **not** kick.
- [ ] `GET /api/room/seats` reflects both changes within the next poll (or via socket).
- [ ] Preferred action names work: `remove_from_seat`, `approve_speaker` (aliases optional).

---

## 7. What mobile calls today (exact)

**Base path:** `/api/room/mic-action`  
**Remove from seat — tries in order:**

1. `action: "remove_from_seat"`
2. `action: "leave_seat"`
3. `action: "leave"`

**Place floor user — tries in order:**

1. `action: "approve_speaker"`
2. `action: "take_seat"`
3. `action: "force_take_seat"`

**Please confirm (reply to this doc):**

1. Will you support **`remove_from_seat`** and **`approve_speaker`** as the canonical names?  
2. If you prefer different names, tell us the exact strings so mobile can lock to one action (no fallbacks).  
3. ETA for staging deploy on `my-backend-api-960q.onrender.com`.

---

## 8. Quick copy for ticket title

> Implement `mic-action` host flows: `remove_from_seat` (seat → floor) and `approve_speaker` (floor → seat), with seats + floor_audience sync and sockets.
