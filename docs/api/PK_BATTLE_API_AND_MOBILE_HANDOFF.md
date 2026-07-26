# PK Battle API And Mobile Handoff

App: Qobo1Live Flutter mobile  
Branch/context: `new-super-admin`  
Date: 2026-07-24 (updated 2026-07-26)  
Audience: Backend team and mobile team  

## Purpose

This document separates the PK Battle work into:

- Backend API/socket/push requirements.
- Mobile integration responsibilities.
- Current mobile assumptions that backend responses must support.

PK Battle is a timed room-vs-room challenge between two active live rooms. One host sends a challenge, the other host accepts or rejects it, gifts during the battle update scores, and both sides see the winner when the timer ends.

## Backend Implementation Status

As of **2026-07-26**, backend confirmed the following are live:

- `PKRequest` persistence with **120-second** pending expiry and accepted/rejected tracking.
- `GET /api/pk/search` returns `data.rooms[]` with `title`, `hostName`, `avatar`, `coverImage`, `room_type` (excludes current + busy rooms).
- Snake_case request bodies (`room_id`, `target_room_id`) and response keys (`duration`, `remainingSeconds`, `winner_id`, `battle_id`, `room1Score`).
- Socket events: `pk_request`, `pk_started`, `pk_accepted`, `pk_rejected`, `pk_cancelled`, `pk_score_update`, `pk_completed`.
- FCM for offline hosts on challenge / cancel / battle start (and related lifecycle types).
- Gift send (`/api/transactions/send-gift`) increments PK score by gift coin value and emits `pk_score_update` with `lastGift`.

Mobile can test without workarounds:

```http
GET /api/pk/search?room_id={uuid}
POST /api/pk/send-request
POST /api/pk/accept-reject
POST /api/pk/cancel-request
GET /api/pk/status?battle_id={uuid}
GET /api/pk/active?room_id={uuid}
POST /api/pk/end
```

## Current Mobile Integration Status

Mobile already has:

- PK Battle entry from live room options.
- PK Battle screen and state handling for idle, searching, incoming request, outgoing request, active battle, and completed battle.
- REST integration for search, send request, accept/reject, cancel, end, status, and active PK lookup.
- Socket listener hooks for `pk_request`, `pk_started`, `pk_accepted`, `pk_rejected`, `pk_cancelled`, `pk_score_update`, and `pk_completed`.
- FCM/deep-link style handler for PK notification payloads.

Important mobile rule:

- Mobile passes the backend `room_id` UUID with dashes.
- Mobile should not use sanitized Zego channel ids for `/api/pk/*` APIs.

## Backend Work Required

> **Note:** Items below were the original contract. Backend has marked them **implemented** (see status section above). Keep this section as the response contract reference for QA.

### 1. Search Opponent Rooms

Endpoint:

```http
GET /api/pk/search?room_id={current_room_id}
Authorization: Bearer <token>
```

Backend should return active rooms eligible for PK.

Rules:

- Exclude the current room.
- Exclude rooms already in an active PK battle.
- Return only rooms whose host is online/live.
- Return backend room ids, not Zego-only ids.
- Prefer same room type if possible, for example audio vs audio or video/live vs video/live.

Expected response:

```json
{
  "statusCode": 1,
  "message": "Opponents found",
  "data": {
    "rooms": [
      {
        "room_id": "opponent-room-uuid",
        "title": "Room title",
        "name": "Room title",
        "host_id": "host-user-id",
        "hostName": "Host name",
        "avatar": "https://...",
        "coverImage": "https://...",
        "room_type": "audio",
        "viewerCount": 42,
        "isLive": true
      }
    ]
  }
}
```

Mobile can also handle `data` as a list or `data.opponents`, but `data.rooms` is preferred.

### 2. Send PK Request

Endpoint:

```http
POST /api/pk/send-request
Authorization: Bearer <token>
Content-Type: application/json
```

Mobile request:

```json
{
  "room_id": "challenger-room-uuid",
  "target_room_id": "opponent-room-uuid",
  "duration": 300
}
```

Backend response:

```json
{
  "statusCode": 1,
  "message": "PK request sent",
  "data": {
    "request_id": "pk-request-uuid",
    "room_id": "challenger-room-uuid",
    "target_room_id": "opponent-room-uuid",
    "duration": 300,
    "expires_at": "2026-07-24T10:20:00.000Z",
    "status": "pending"
  }
}
```

Backend must:

- Persist the pending request.
- Prevent duplicate pending requests between the same rooms.
- Expire the request after **120 seconds**.
- Notify target host through socket and FCM.
- Notify challenger if target host accepts, rejects, cancels, times out, or is unavailable.

### 3. Accept Or Reject PK Request

Endpoint:

```http
POST /api/pk/accept-reject
Authorization: Bearer <token>
Content-Type: application/json
```

Mobile request:

```json
{
  "room_id": "receiver-room-uuid",
  "request_id": "pk-request-uuid",
  "action": "accept",
  "duration": 300
}
```

`action` values:

- `accept`
- `reject`

Accept response:

```json
{
  "statusCode": 1,
  "message": "Battle started",
  "data": {
    "id": "battle-uuid",
    "battle_id": "battle-uuid",
    "request_id": "pk-request-uuid",
    "room1Id": "challenger-room-uuid",
    "room2Id": "receiver-room-uuid",
    "room1Score": 0,
    "room2Score": 0,
    "duration": 300,
    "remainingSeconds": 300,
    "status": "active",
    "startedAt": "2026-07-24T10:15:00.000Z",
    "endsAt": "2026-07-24T10:20:00.000Z",
    "room1": {
      "room_id": "challenger-room-uuid",
      "host_id": "host-a-id",
      "host_name": "Host A",
      "title": "Host A Room",
      "avatar": "https://..."
    },
    "room2": {
      "room_id": "receiver-room-uuid",
      "host_id": "host-b-id",
      "host_name": "Host B",
      "title": "Host B Room",
      "avatar": "https://..."
    }
  }
}
```

Reject response:

```json
{
  "statusCode": 1,
  "message": "PK request rejected",
  "data": {
    "request_id": "pk-request-uuid",
    "status": "rejected"
  }
}
```

Backend must:

- Reject if request is expired.
- Reject if either room is no longer live.
- Reject if either room is already in another active PK.
- On accept, create exactly one active battle.
- Broadcast `pk_started` or `pk_accepted` to both hosts.
- Broadcast `pk_rejected` to challenger when rejected.

### 4. Cancel Pending PK Request

Endpoint:

```http
POST /api/pk/cancel-request
Authorization: Bearer <token>
Content-Type: application/json
```

Mobile request:

```json
{
  "room_id": "challenger-room-uuid",
  "request_id": "pk-request-uuid"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "PK request cancelled",
  "data": {
    "request_id": "pk-request-uuid",
    "status": "cancelled"
  }
}
```

Backend must notify the target host with `pk_cancelled`.

### 5. End Active Battle

Endpoint:

```http
POST /api/pk/end
Authorization: Bearer <token>
Content-Type: application/json
```

Mobile request:

```json
{
  "battle_id": "battle-uuid",
  "room_id": "current-room-uuid",
  "reason": "host_leave"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Battle ended",
  "data": {
    "battle_id": "battle-uuid",
    "status": "completed",
    "winnerId": "winner-room-uuid",
    "winner_id": "winner-room-uuid",
    "room1Score": 4500,
    "room2Score": 3200
  }
}
```

Backend must:

- End the battle when timer expires.
- End the battle when a host leaves or force-ends.
- Notify both rooms using `pk_completed`.
- Include final scores and winner id.
- Support draw result with `winnerId: null`.

### 6. Fetch PK Status

Endpoint:

```http
GET /api/pk/status?battle_id={battle_id}
Authorization: Bearer <token>
```

Response:

```json
{
  "statusCode": 1,
  "message": "Current PK status",
  "data": {
    "id": "battle-uuid",
    "battle_id": "battle-uuid",
    "room1Id": "room-a-uuid",
    "room2Id": "room-b-uuid",
    "room1Score": 4500,
    "room2Score": 3200,
    "duration": 300,
    "remainingSeconds": 142,
    "status": "active",
    "winnerId": null,
    "winner_id": null
  }
}
```

Backend must keep this endpoint lightweight because mobile can poll it as fallback.

### 7. Restore Active PK For Room

Endpoint:

```http
GET /api/pk/active?room_id={room_id}
Authorization: Bearer <token>
```

Use cases:

- App resumed.
- Host reopens PK screen.
- Socket reconnect happened.
- User enters a live room already in active PK.

Response when active battle exists:

```json
{
  "statusCode": 1,
  "message": "Active PK found",
  "data": {
    "request": null,
    "battle": {
      "id": "battle-uuid",
      "battle_id": "battle-uuid",
      "room1Id": "room-a-uuid",
      "room2Id": "room-b-uuid",
      "room1Score": 100,
      "room2Score": 80,
      "duration": 300,
      "remainingSeconds": 250,
      "status": "active"
    }
  }
}
```

Response when pending request exists:

```json
{
  "statusCode": 1,
  "message": "Pending PK request found",
  "data": {
    "request": {
      "request_id": "pk-request-uuid",
      "room_id": "challenger-room-uuid",
      "target_room_id": "receiver-room-uuid",
      "duration": 300,
      "expires_at": "2026-07-24T10:20:00.000Z",
      "status": "pending"
    },
    "battle": null
  }
}
```

## Socket Events Required

Backend should emit Socket.IO events to room channels and/or specific host user channels.

Mobile currently listens to:

- `pk_request`
- `pk_started`
- `pk_accepted`
- `pk_rejected`
- `pk_cancelled`
- `pk_score_update`
- `pk_completed`

Mobile socket service emits these join/register events:

- `register_user` with current user id after socket connects.
- `join_room` and `joinRoom` with active room id.
- `leave_room` and `leaveRoom` when leaving room.

Backend can support either snake_case or camelCase join names, but snake_case is preferred.

### `pk_request`

Emit to the target host when another room challenges them.

```json
{
  "type": "pk_request",
  "request_id": "pk-request-uuid",
  "room_id": "target-room-uuid",
  "sender_room_id": "challenger-room-uuid",
  "target_room_id": "target-room-uuid",
  "battle_duration": 300,
  "expires_at": "2026-07-24T10:20:00.000Z",
  "sender_host_id": "host-a-id",
  "sender_host_name": "Host A",
  "sender_room_title": "Host A Room",
  "sender_avatar": "https://..."
}
```

### `pk_started` / `pk_accepted`

Emit to both hosts when battle starts.

```json
{
  "type": "pk_started",
  "battle_id": "battle-uuid",
  "request_id": "pk-request-uuid",
  "room1Id": "challenger-room-uuid",
  "room2Id": "receiver-room-uuid",
  "room1Score": 0,
  "room2Score": 0,
  "duration": 300,
  "remainingSeconds": 300,
  "status": "active",
  "startedAt": "2026-07-24T10:15:00.000Z",
  "endsAt": "2026-07-24T10:20:00.000Z"
}
```

### `pk_score_update`

Emit whenever a gift changes either room score.

```json
{
  "type": "pk_score_update",
  "battle_id": "battle-uuid",
  "room1Id": "room-a-uuid",
  "room2Id": "room-b-uuid",
  "room1Score": 1500,
  "room2Score": 1250,
  "remainingSeconds": 190,
  "lastGift": {
    "sender_id": "user-id",
    "sender_name": "Viewer name",
    "receiver_room_id": "room-a-uuid",
    "gift_id": "gift-id",
    "gift_name": "Rose",
    "coin_value": 100
  }
}
```

### `pk_completed`

Emit to both hosts and both room audiences when battle completes.

```json
{
  "type": "pk_completed",
  "battle_id": "battle-uuid",
  "room1Id": "room-a-uuid",
  "room2Id": "room-b-uuid",
  "room1Score": 4500,
  "room2Score": 3200,
  "winnerId": "room-a-uuid",
  "winner_id": "room-a-uuid",
  "status": "completed"
}
```

### `pk_rejected`

```json
{
  "type": "pk_rejected",
  "request_id": "pk-request-uuid",
  "room_id": "challenger-room-uuid",
  "target_room_id": "receiver-room-uuid",
  "status": "rejected"
}
```

### `pk_cancelled`

```json
{
  "type": "pk_cancelled",
  "request_id": "pk-request-uuid",
  "room_id": "challenger-room-uuid",
  "target_room_id": "receiver-room-uuid",
  "status": "cancelled"
}
```

## FCM Push Requirements

Socket is primary for active users. FCM is required when target host app is backgrounded, locked, or not currently inside the PK screen.

Recommended FCM data payload:

```json
{
  "type": "pk_request",
  "request_id": "pk-request-uuid",
  "room_id": "target-room-uuid",
  "sender_room_id": "challenger-room-uuid",
  "target_room_id": "target-room-uuid",
  "battle_duration": "300",
  "expires_at": "2026-07-24T10:20:00.000Z",
  "sender_host_id": "host-a-id",
  "sender_host_name": "Host A",
  "sender_room_title": "Host A Room",
  "sender_avatar": "https://..."
}
```

Suggested FCM types:

- `pk_request`
- `pk_started`
- `pk_rejected`
- `pk_cancelled`
- `pk_completed`

FCM payload should contain only strings if possible because Android/iOS notification payloads can coerce values differently.

## Gift-To-PK Score Requirement

PK score should update from successful gift transactions.

Backend expected behavior:

1. User sends gift in Room A or Room B.
2. Backend saves gift transaction.
3. If the room is in an active PK battle, backend adds gift value to that room’s PK score.
4. Backend emits `pk_score_update` to both PK rooms.
5. `GET /api/pk/status` returns the same updated scores.

Scoring recommendation:

- Use gift coin value as PK points unless product decides a multiplier.
- Store score events separately for audit/debug:
  - `battle_id`
  - `room_id`
  - `sender_id`
  - `receiver_id` or `receiver_room_id`
  - `gift_id`
  - `gift_value`
  - `points_added`
  - `created_at`

This avoids expensive score recalculation for high gift volume.

## Mobile Work Scope

Mobile will:

- Call the REST endpoints listed above.
- Show PK matchmaking/search results.
- Send challenge requests.
- Show incoming challenge UI when socket/FCM payload arrives.
- Accept, reject, or cancel requests.
- Restore active battle state using `/api/pk/active`.
- Poll `/api/pk/status` as a fallback when battle is active.
- Listen for socket events and update UI in real time.
- Use final score/winner payload to show result screen/dialog.

Mobile will not:

- Calculate authoritative scores.
- Decide winner.
- Create battle records.
- Validate whether a room is eligible.
- Implement backend APIs.
- Trust local simulated scores in production.

## Mobile UI Notes

Current mobile PK UI supports:

- Battle countdown.
- Two-side score display.
- Score progress bar.
- Search and request states.
- Incoming/outgoing request states.
- Completed/winner state.

Future UI improvements can include:

- Side-by-side live room preview.
- Top supporters during battle.
- Combo gift effect on score updates.
- “Rematch” after battle complete.
- Battle history and win rate.
- Loser punishment timer/challenge.

These are mobile enhancements, but they require backend data if they should be real.

## Validation Checklist For Backend

Backend team should verify:

- `room_id` returned by room APIs matches the `room_id` accepted by `/api/pk/*`.
- Search excludes current room and inactive rooms.
- Send request returns unique `request_id`.
- Pending request expires automatically.
- Accept creates one battle only.
- Reject/cancel notify the other host.
- Scores update after gifts.
- Status endpoint returns current scores and remaining time.
- Completed battle includes winner and final scores.
- Socket events are emitted to both rooms/users.
- FCM reaches target host when app is backgrounded.
- `/api/pk/active` restores pending request or active battle after reconnect.

## Open API Questions / Possible Issues

Please confirm these points before final production testing:

1. What exact Socket.IO auth method should mobile use: token in query, auth object, or `register_user` after connect?
2. Are PK events emitted to user channel, room channel, or both?
3. Is `request_id` a true request UUID, or is backend currently reusing room ids?
4. Should `winnerId` represent winning room id or winning host user id? Mobile currently works best with winning room id.
5. What happens if a host leaves the room during active PK?
6. What happens if both rooms have equal score at timer end?
7. Is gift value always equal to PK score points?
8. Should video live stream and audio room PK use the same endpoints?
9. Should audiences receive PK score updates, or only hosts?
10. Should backend provide a battle history endpoint now or later?

## Recommended Production Flow

1. Host A starts from active live/audio/video room.
2. Mobile calls `GET /api/pk/search`.
3. Host A selects opponent or quick match.
4. Mobile calls `POST /api/pk/send-request`.
5. Backend sends `pk_request` through Socket.IO and FCM.
6. Host B accepts using `POST /api/pk/accept-reject`.
7. Backend creates battle and emits `pk_started`.
8. Gifts update backend score.
9. Backend emits `pk_score_update`.
10. Mobile also polls `GET /api/pk/status` every 2 seconds as fallback.
11. Backend ends battle on timer and emits `pk_completed`.
12. Mobile shows Victory, Defeat, or Draw.

