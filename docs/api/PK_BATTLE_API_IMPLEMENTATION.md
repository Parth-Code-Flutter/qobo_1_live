# PK Battle API Implementation

Backend status note (synced from backend completion notice, 2026-07-26).

The backend PK Battle integration is implemented and matches the mobile handoff in `PK_BATTLE_API_AND_MOBILE_HANDOFF.md`.

## What Was Completed

### 1. Database Persistence
- Created the **`PKRequest`** model in `schema.prisma`.
- Pending PK challenges expire automatically after **120 seconds**, with accepted/rejected tracking.

### 2. Search & Matchmaking (`/api/pk/search`)
- Returns `data.rooms` as requested by mobile.
- Filters out the current room and rooms already in an active PK battle.
- Room details include: `title`, `hostName`, `avatar` (full URL), `coverImage`, and `room_type`.

### 3. API Payload Structuring
- Accepts inbound `snake_case` JSON fields (e.g. `room_id`, `target_room_id`).
- Outbound keys include: `duration`, `remainingSeconds`, `winner_id`, `battle_id`, and `room1Score`.

### 4. Socket.IO & FCM Push Notifications
- Socket events: `pk_request`, `pk_started`, `pk_accepted`, `pk_rejected`, `pk_cancelled`, `pk_completed`, and `pk_score_update`.
- FCM for offline hosts on challenge, cancel, and battle start (plus related lifecycle types).

### 5. Economy & Gift Scoring
- Gift send (`/api/transactions/send-gift`) checks whether the room is in an active PK battle.
- Room PK score increments by the gift coin value.
- Emits `pk_score_update` to both rooms with updated scores and `lastGift`.

## Mobile Test Endpoints

```http
GET /api/pk/search?room_id={uuid}
POST /api/pk/send-request
POST /api/pk/accept-reject
POST /api/pk/cancel-request
GET /api/pk/status?battle_id={uuid}
GET /api/pk/active?room_id={uuid}
POST /api/pk/end
```
