# Host Join Approval — API Contract

**App:** `qobo_one_live` (Flutter)  
**Audience:** Backend  
**Date:** 2026-07-26  
**Sources:** `docs/HOST_JOIN_APPROVAL_BACKEND_REQUIREMENTS.md` + mobile (`RoomRepo`, `JoinApprovalService`, FCM/socket handlers)

Auth for all endpoints: `Authorization: Bearer <token>`  
Envelope: `{ "statusCode": 1|0, "message": "...", "data": { ... } }`  
Success: `statusCode` is `1`, `200`, `201`, or `true`.

---

## 1. Overview

When a room/live has **`joinApprovalRequired: true`**, a guest cannot enter media until the **host (or room admin)** approves a join request.

| Setting | Behavior |
|---------|----------|
| `joinApprovalRequired: false` (default) | Immediate join via `POST /api/room/join` |
| `joinApprovalRequired: true` | Guest → create join-request → wait → host approve/reject → only then `POST /api/room/join` with `join_request_id` |

Applies to: **audio room**, **video room**, **live stream** (`session_type`).

**Not this feature:** mic seat `request_to_speak` — that is seat access after already inside.

**Guest flow (mobile):**

1. `POST /api/room/join-request`
2. Wait (socket / FCM / poll status)
3. On approve → `POST /api/room/join` with `join_request_id`
4. Only then open Zego

---

## 2. Field naming

Mobile sends **both** snake_case and camelCase on many bodies; responses should prefer **snake_case** (mobile also accepts camelCase).

| Concept | Prefer in API | Also accepted by mobile |
|---------|---------------|-------------------------|
| Room id | `room_id` | `roomId` |
| Request id | `request_id` | `requestId`, `join_request_id` |
| Join after approve | `join_request_id` | `joinRequestId` |
| Session type | `session_type` | `sessionType` |
| Approval flag | `joinApprovalRequired` | `join_approval_required` |
| Expiry | `expires_at` | `expiresAt` |
| Poll hint | `poll_after_ms` | — |

**`session_type` values:** `audio_room` | `video_room` | `live_stream`

**Request `status` values:** `pending` | `approved` | `rejected` | `expired` | `cancelled`

---

## 3. Endpoints

### 3.1 Create join request (guest)

```http
POST /api/room/join-request
```

**Body (mobile):**

```json
{
  "room_id": "room-uuid",
  "roomId": "room-uuid",
  "session_type": "audio_room"
}
```

**A) Pending (approval required)**

```json
{
  "statusCode": 1,
  "message": "Waiting for host approval",
  "data": {
    "request_id": "join-req-uuid",
    "room_id": "room-uuid",
    "session_type": "audio_room",
    "status": "pending",
    "expires_at": "2026-07-23T17:05:00.000Z",
    "poll_after_ms": 2000
  }
}
```

**B) Auto-joined (approval off / compat)**

```json
{
  "statusCode": 1,
  "message": "Joined",
  "data": {
    "status": "approved",
    "auto_joined": true,
    "join": { }
  }
}
```

`join` should mirror a successful `POST /api/room/join` `data` payload.

**C) Already pending**

```json
{
  "statusCode": 1,
  "message": "Join request already pending",
  "data": {
    "request_id": "existing-join-req-uuid",
    "status": "pending",
    "expires_at": "2026-07-23T17:05:00.000Z"
  }
}
```

**D) Rejected / blocked**

```json
{
  "statusCode": 0,
  "message": "Host rejected your join request",
  "data": {
    "request_id": "join-req-uuid",
    "status": "rejected"
  }
}
```

```json
{
  "statusCode": 0,
  "message": "You cannot join this room right now",
  "data": {
    "status": "blocked",
    "reason": "kicked",
    "blocked_until": "2026-07-23T18:00:00.000Z"
  }
}
```

Side effect: notify host via FCM + socket `join_request`.

---

### 3.2 Join room (gated)

```http
POST /api/room/join
```

**Body (mobile):**

```json
{
  "roomId": "room-uuid",
  "room_id": "room-uuid",
  "join_request_id": "join-req-uuid",
  "session_type": "live_stream",
  "password": "optional",
  "invitation_id": "optional"
}
```

| Case | Behavior |
|------|----------|
| `joinApprovalRequired=false` | Current immediate join |
| Approval on, no approved `join_request_id` | Fail with `statusCode: 0` and `code: "APPROVAL_REQUIRED"` (or message containing “approval required”) |
| Approval on + valid approved `join_request_id` | Return Zego / seat / stream payload |

`join_request_id` must be **single-use or short-lived** after approve (e.g. 60–120s). Do **not** return media tokens until this succeeds.

---

### 3.3 List pending (host / admin)

```http
GET /api/room/join-requests?room_id={uuid}&status=pending
```

```json
{
  "statusCode": 1,
  "data": {
    "items": [
      {
        "request_id": "join-req-uuid",
        "room_id": "room-uuid",
        "session_type": "live_stream",
        "status": "pending",
        "created_at": "2026-07-23T17:00:00.000Z",
        "expires_at": "2026-07-23T17:05:00.000Z",
        "user": {
          "id": "idc6740290",
          "name": "Sunil",
          "avatar": "https://...",
          "level": 5,
          "gender": "male"
        }
      }
    ]
  }
}
```

Mobile also reads flat `requester_id` / `requester_name` / `requester_avatar` when present.

---

### 3.4 Approve / Reject (host respond)

```http
POST /api/room/join-request/respond
```

**Body (mobile):**

```json
{
  "room_id": "room-uuid",
  "roomId": "room-uuid",
  "request_id": "join-req-uuid",
  "requestId": "join-req-uuid",
  "action": "approve"
}
```

`action`: `"approve"` | `"reject"` (lowercase).

**Approve**

```json
{
  "statusCode": 1,
  "message": "Approved",
  "data": {
    "request_id": "join-req-uuid",
    "status": "approved",
    "approved_at": "2026-07-23T17:01:10.000Z",
    "join_token": "optional-short-lived-token",
    "user_id": "idc6740290"
  }
}
```

**Reject**

```json
{
  "statusCode": 1,
  "message": "Rejected",
  "data": {
    "request_id": "join-req-uuid",
    "status": "rejected",
    "rejected_at": "2026-07-23T17:01:10.000Z"
  }
}
```

**Required side effects**

1. Persist status.
2. Notify requester: FCM + socket (`join_approved` / `join_rejected`).
3. On approve, allow subsequent `POST /api/room/join` with that `join_request_id`.
4. Only host (and optionally `isAdmin` for that room) may call this.

iOS FCM category for host: `JOIN_REQUEST` with actions `APPROVE_JOIN` / `REJECT_JOIN`.

---

### 3.5 Cancel (guest)

```http
POST /api/room/join-request/cancel
```

```json
{
  "room_id": "room-uuid",
  "roomId": "room-uuid",
  "request_id": "join-req-uuid",
  "requestId": "join-req-uuid"
}
```

Notify host: socket/FCM `join_request_cancelled` with `{ request_id, room_id, user_id }`.

---

### 3.6 Status poll (guest fallback)

```http
GET /api/room/join-request/status?request_id={uuid}
```

```json
{
  "statusCode": 1,
  "data": {
    "request_id": "join-req-uuid",
    "status": "approved",
    "room_id": "room-uuid",
    "session_type": "audio_room",
    "expires_at": "2026-07-23T17:05:00.000Z"
  }
}
```

Mobile polls using `poll_after_ms` from the create response (default 2000).

---

### 3.7 Room setting `joinApprovalRequired`

**On create** (already sent by mobile):

- `POST /api/rooms` (or legacy create): `"joinApprovalRequired": true|false`
- `POST /api/live-streaming/create`: `"joinApprovalRequired": true|false`

**Mid-session toggle:**

```http
POST /api/room/settings
```

```json
{
  "room_id": "room-uuid",
  "roomId": "room-uuid",
  "joinApprovalRequired": true
}
```

Expose the flag on room list / detail / seats / live payloads so mobile can choose join-request vs direct join.

---

## 4. Socket.IO events

Emit to the appropriate user / room channel (mobile uses `register_user` + `join_room` / `joinRoom`).

| Event | To | Payload fields |
|-------|----|----------------|
| `join_request` | Host / admins | Same as FCM `join_request` (object JSON) |
| `join_request_cancelled` | Host / admins | `request_id`, `room_id`, `user_id` |
| `join_approved` | Requester | `request_id`, `room_id`, `session_type` |
| `join_rejected` | Requester | `request_id`, `room_id`, `reason?` / `message?` |
| `join_request_expired` | Both | `request_id`, `room_id` |

Mobile listens for these exact event names.

---

## 5. FCM push types

All `data` values must be **strings**. Mobile handles these types.

| `type` | Recipient | Purpose |
|--------|-----------|---------|
| `join_request` | Host (+ admins) | New viewer wants in |
| `join_approved` | Viewer | Proceed to join |
| `join_rejected` | Viewer | Declined |
| `join_request_expired` | Viewer (+ host optional) | Timed out |
| `join_request_cancelled` | Host | Viewer cancelled |

### Host — `join_request`

Android: data-only, high priority.  
iOS: alert + category **`JOIN_REQUEST`** (Approve / Reject).

```json
{
  "type": "join_request",
  "notification_id": "unique-event-id",
  "request_id": "join-req-uuid",
  "room_id": "room-uuid",
  "session_type": "audio_room",
  "room_title": "Star Host Test's Room",
  "requester_id": "idc6740290",
  "requester_name": "Sunil",
  "requester_avatar": "https://...",
  "expires_at": "2026-07-23T17:05:00.000Z"
}
```

### Viewer — `join_approved`

```json
{
  "type": "join_approved",
  "notification_id": "unique-event-id",
  "request_id": "join-req-uuid",
  "room_id": "room-uuid",
  "session_type": "live_stream",
  "room_title": "Star Host Test's Room",
  "host_id": "host-user-id",
  "host_name": "Star Host Test"
}
```

Viewer then calls `POST /api/room/join` with `join_request_id` = `request_id`.

### Viewer — `join_rejected`

```json
{
  "type": "join_rejected",
  "notification_id": "unique-event-id",
  "request_id": "join-req-uuid",
  "room_id": "room-uuid",
  "session_type": "audio_room",
  "message": "Host declined your request to join"
}
```

---

## 6. Security / product rules

1. No Zego tokens / channel ids until join succeeds after approve.
2. `join_request_id` single-use or short TTL after approve.
3. Only host/admin of that `room_id` can respond.
4. Requester can only cancel their own request.
5. Expired pending → status `expired` (cannot approve).
6. Rate-limit: one pending per user/room; optional cooldown after reject.
7. Private password: check password first; if pass + approval required → still create join request.
8. Live `onlyFollows`: reject non-followers before creating a join request.
9. Mic requests only after the user is already inside.

---

## 7. Mobile wiring reference

| Concern | Mobile location |
|---------|-----------------|
| Paths | `lib/services/api_constants.dart` → `RoomEndpoints` |
| HTTP bodies | `lib/repo/room/room_repo.dart` |
| Guest gate | `lib/services/room/join_approval_service.dart` |
| FCM / socket | `join_request_push_handler.dart`, `user_realtime_socket_service.dart` |
| Payload parse | `join_request_payload.dart` (accepts snake + camel) |

---

## 8. Open questions (need backend confirmation)

1. Default: approval off (setting) vs always on?
2. Can room admins approve, or host only?
3. Does an accepted **room invite** bypass approval?
4. Pending TTL (2 min / 5 min)?
5. Cooldown after reject before re-request?
6. Shared join-request API for room + live (this doc assumes yes)?
