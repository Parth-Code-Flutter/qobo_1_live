# End Live Streaming (Host)

**Flow ID:** `LIVE-05` (close)  
**Purpose:** Called when the **host ends** a live streaming session. Mobile sends total **duration** and a **join list** of users who entered the Zego room during the stream so backend can persist analytics, payouts, and viewer history.

**Pairs with:** `POST /api/live-streaming/create` (see `POST_live_streaming_create.md`)

---

## API name

| Item | Value |
|------|--------|
| **Name** | End Live Streaming |
| **Method** | `POST` |
| **URL** | `/api/live-streaming/end` |
| **Auth** | Bearer token required (must be the stream **host**) |
| **Content-Type** | `application/json` |

---

## When mobile calls this

| Trigger | Who calls |
|---------|-----------|
| Host taps **close (X)** on live broadcast screen | Host |
| Zego `onEnded` with reason `hostEnd` | Host |
| Host leaves room / navigates back after stream started | Host |

**Not called by audience** — viewers only join via Zego + existing `POST /api/room/join` (if applicable).

Mobile tracks:

- `startedAt` — when Zego room login succeeds (`Logined`, errorCode `0`)
- `endedAt` — when host ends or leaves
- `durationSeconds` — `endedAt - startedAt` (seconds, integer ≥ 0)
- `joins[]` — users seen in the Zego room (from Zego user-join events + host self)

---

## Request body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `liveStreamingId` | string | **Yes** | Same channel id sent to `POST /api/live-streaming/create` and used as Zego `liveID`. |
| `sessionId` | string | No | Backend UUID from create response `data.id`. Send when available. |
| `zegoLiveId` | string | No | Echo of `liveStreamingId` (alias for compatibility). |
| `startedAt` | string (ISO 8601) | **Yes** | UTC timestamp when host entered live (Zego room login success). |
| `endedAt` | string (ISO 8601) | **Yes** | UTC timestamp when host ended the stream. |
| `durationSeconds` | integer | **Yes** | Total live duration in seconds (`≥ 0`). |
| `endReason` | string | No | `host_end` (default), `local_leave`, `kick_out`, `connection_lost`, `app_background` |
| `roomType` | string | No | `VIDEO` or `AUDIO`. Mobile Go Live uses `VIDEO`. |
| `peakViewerCount` | integer | No | Max concurrent viewers (excluding host), if tracked on device. |
| `uniqueViewerCount` | integer | No | Distinct viewer user ids in `joins` (excluding host). |
| `joins` | array | **Yes** | List of users who joined the stream (see below). Can be `[]` if none. |

### `joins[]` item

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | string | **Yes** | App user UUID (PostgreSQL `users.id`). Same id used after `ZegoLiveIdUtils.sanitizeUserId()`. |
| `userName` | string | No | Display name in Zego room at join time. |
| `role` | string | **Yes** | `host` \| `audience` \| `cohost` |
| `joinedAt` | string (ISO 8601) | **Yes** | When this user entered the Zego room. |
| `leftAt` | string (ISO 8601) | No | When user left (if tracked). |
| `watchDurationSeconds` | integer | No | Viewer watch time in seconds (if tracked). |

### Example request

```http
POST /api/live-streaming/end HTTP/1.1
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

```json
{
  "liveStreamingId": "ls_1748882400123_482910",
  "sessionId": "a8f3c2e1-9b4d-4f2a-8c1d-2e3f4a5b6c7d",
  "zegoLiveId": "ls_1748882400123_482910",
  "startedAt": "2026-06-13T08:10:00.000Z",
  "endedAt": "2026-06-13T08:45:30.000Z",
  "durationSeconds": 2130,
  "endReason": "host_end",
  "roomType": "VIDEO",
  "peakViewerCount": 12,
  "uniqueViewerCount": 28,
  "joins": [
    {
      "userId": "d72d18a2-1489-4781-b42e-7f4b9c371921",
      "userName": "Parth",
      "role": "host",
      "joinedAt": "2026-06-13T08:10:00.000Z",
      "leftAt": "2026-06-13T08:45:30.000Z",
      "watchDurationSeconds": 2130
    },
    {
      "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "userName": "Viewer One",
      "role": "audience",
      "joinedAt": "2026-06-13T08:12:15.000Z",
      "leftAt": "2026-06-13T08:30:00.000Z",
      "watchDurationSeconds": 1065
    },
    {
      "userId": "f9e8d7c6-b5a4-3210-fedc-ba9876543210",
      "userName": "Viewer Two",
      "role": "audience",
      "joinedAt": "2026-06-13T08:20:00.000Z"
    }
  ]
}
```

---

## Success response

**HTTP status:** `200 OK` (or `201` with `statusCode: 1`)

| Field | Type | Description |
|-------|------|-------------|
| `statusCode` | number | `1` on success (project convention). |
| `message` | string | e.g. `"Live stream ended"` |
| `data` | object | Stored session summary (see below). |

### `data` object (recommended)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Backend live session id (same as create `data.id`). |
| `liveStreamingId` | string | Channel id. |
| `hostId` | string | Host user id. |
| `isLive` | boolean | Should be `false` after end. |
| `durationSeconds` | integer | Echo / server-computed duration. |
| `startedAt` | string (ISO 8601) | Stream start. |
| `endedAt` | string (ISO 8601) | Stream end. |
| `uniqueViewerCount` | integer | Distinct viewers stored. |
| `totalJoinEvents` | integer | Length of `joins` persisted. |
| `updatedAt` | string (ISO 8601) | Server timestamp. |

### Example success response

```json
{
  "statusCode": 1,
  "message": "Live stream ended",
  "data": {
    "id": "a8f3c2e1-9b4d-4f2a-8c1d-2e3f4a5b6c7d",
    "liveStreamingId": "ls_1748882400123_482910",
    "hostId": "d72d18a2-1489-4781-b42e-7f4b9c371921",
    "isLive": false,
    "durationSeconds": 2130,
    "startedAt": "2026-06-13T08:10:00.000Z",
    "endedAt": "2026-06-13T08:45:30.000Z",
    "uniqueViewerCount": 28,
    "totalJoinEvents": 3,
    "updatedAt": "2026-06-13T08:45:31.000Z"
  }
}
```

---

## Error responses

### Session not found (404)

```json
{
  "statusCode": 0,
  "message": "Live streaming session not found"
}
```

### Not the host (403)

```json
{
  "statusCode": 0,
  "message": "Only the host can end this live stream"
}
```

### Already ended (409)

```json
{
  "statusCode": 0,
  "message": "Live stream already ended"
}
```

### Validation error (400)

```json
{
  "statusCode": 0,
  "message": "durationSeconds must be a non-negative integer"
}
```

---

## Mapping from current mobile implementation

| Mobile source | API field |
|---------------|-----------|
| `LiveBroadcastController.roomId` | `liveStreamingId`, `zegoLiveId` |
| `roomData['id']` from create response | `sessionId` |
| `roomData['hostId']` | Used server-side to verify caller |
| Zego room login success time | `startedAt` |
| Host close / `onEnded` time | `endedAt`, `durationSeconds` |
| `ZegoLiveStreamingEndEvent.reason` | `endReason` (`hostEnd` → `host_end`) |
| `Get.arguments['roomType']` | `roomType` |
| Zego `getUserJoinStream()` + user list | `joins[]` |
| `UserSessionController.userId` (sanitized) | `joins[].userId` for host |
| `UserSessionController.displayName` | `joins[].userName` for host |

---

## Backend storage (suggested)

1. Update live session row: `isLive = false`, `endedAt`, `durationSeconds`.
2. Upsert `live_stream_joins` (or equivalent) from `joins[]`:
   - `session_id`, `user_id`, `role`, `joined_at`, `left_at`, `watch_duration_seconds`
3. Optionally merge with existing `POST /api/room/join` / watch-history rows if the same `liveStreamingId` was used.

---

## Related APIs

| API | Use |
|-----|-----|
| `POST /api/live-streaming/create` | Start session — must exist before end. |
| `POST /api/room/join` | Audience may call when entering from discover/list. |
| `POST /api/room/watch-history/record` | Optional per-viewer ping; end API is the host summary. |
| `POST /api/economy/gift/send` | Gifts during stream (`roomId` = `liveStreamingId`). |

---

## Notes for backend

1. **Idempotent end:** If the same host calls end twice, return `409` or success with existing summary.
2. **`liveStreamingId` is the primary lookup key** if `sessionId` is omitted.
3. **`joins` may include only users the host device observed** — merge with server-side join logs if you also record `POST /api/room/join`.
4. **Duration:** Prefer server validation: `endedAt - startedAt` should be close to `durationSeconds` (allow small drift).
5. Party rooms (`POST /api/room/create`) can reuse the same shape later as `POST /api/room/end` with `room_id` instead of `liveStreamingId`.

---

*Mobile integration (planned): `RoomRepo.endLiveStreaming` → `LiveBroadcastController` on host leave / Zego `onEnded`.*
