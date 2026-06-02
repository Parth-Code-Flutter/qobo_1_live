# Create Live Streaming (Zego Host)

**Flow ID:** `LIVE-05`  
**Purpose:** Register a host **live streaming** session (Zego prebuilt live streaming). Used when the user taps **Go Live** on the Live Rooms tab — **not** the audio/video party room flow (`POST /api/room/create`).

---

## API name

| Item | Value |
|------|--------|
| **Name** | Create Live Streaming |
| **Method** | `POST` |
| **URL** | `/api/live-streaming/create` |
| **Auth** | Bearer token required |
| **Content-Type** | `application/json` |

---

## Request body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Display title of the stream (max 40 chars recommended). |
| `liveStreamingId` | string | Yes | Unique channel id for Zego. Mobile auto-generates before submit (format: `ls_{timestamp}_{random}`). Backend must persist and return the same id (or a mapped `zegoLiveId`). |
| `onlyFollows` | boolean | No | Default `false`. When `true`, only users who follow the host may join/watch. |

### Example request

```http
POST /api/live-streaming/create HTTP/1.1
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

```json
{
  "name": "Parth's Night Stream",
  "liveStreamingId": "ls_1748882400123_482910",
  "onlyFollows": false
}
```

---

## Success response

**HTTP status:** `201 Created` (or `200 OK` with `statusCode: 1`)

| Field | Type | Description |
|-------|------|-------------|
| `statusCode` | number | `1` on success (project convention). |
| `message` | string | Human-readable message. |
| `data` | object | Stream session payload (see below). |

### `data` object (recommended)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Backend UUID for this live session. |
| `name` | string | Stream title (echo of request). |
| `liveStreamingId` | string | Channel id sent by client (or server-generated). |
| `zegoLiveId` | string | **Required for mobile Zego.** Same as `liveStreamingId` unless you use a different internal mapping. |
| `onlyFollows` | boolean | Echo of request. |
| `hostId` | string | Authenticated user id. |
| `isLive` | boolean | Should be `true` when created. |
| `createdAt` | string (ISO 8601) | Creation timestamp. |

### Example success response

```json
{
  "statusCode": 1,
  "message": "Live streaming started",
  "data": {
    "id": "a8f3c2e1-9b4d-4f2a-8c1d-2e3f4a5b6c7d",
    "name": "Parth's Night Stream",
    "liveStreamingId": "ls_1748882400123_482910",
    "zegoLiveId": "ls_1748882400123_482910",
    "onlyFollows": false,
    "hostId": "e891c34a-95c1-455b-b9f1-df7418930ff2",
    "isLive": true,
    "createdAt": "2026-06-02T13:15:00.000Z"
  }
}
```

---

## Error responses

### Validation error (400)

```json
{
  "statusCode": 0,
  "message": "name is required"
}
```

### Duplicate `liveStreamingId` (409)

```json
{
  "statusCode": 0,
  "message": "liveStreamingId already in use"
}
```

### Unauthorized (401)

```json
{
  "statusCode": 0,
  "message": "Unauthorized"
}
```

---

## Mobile behaviour after success

1. App reads `data.zegoLiveId` (fallback: `data.liveStreamingId`).
2. Navigates to **Live Broadcast** screen (`/live-broadcast`) as **host**.
3. Zego `ZegoUIKitPrebuiltLiveStreaming` joins channel using `liveID = zegoLiveId`.

---

## Related APIs (not in this request)

| API | Use |
|-----|-----|
| `POST /api/room/create` | Audio/video **party room** (seats, country, `AUDIO`/`VIDEO` type). |
| `GET /api/room/agora-token` | Optional Zego/Agora token if you move off app-sign mode. |
| `POST /api/room/join` | Audience joins an existing room by `room_id`. |

---

## Notes for backend

1. **`zegoLiveId` is mandatory in the response** — the app uses it as the Zego `liveID`; without it the host cannot connect.
2. If the server generates its own channel id, return it in both `liveStreamingId` and `zegoLiveId`.
3. Enforce `onlyFollows` on join/list endpoints when `true`.
4. Consider indexing `liveStreamingId` as unique while `isLive = true`.

---

*Mobile integration: `RoomRepo.createLiveStreaming` → `LiveRoomCreateController.startLiveStreaming` → `LiveBroadcastView` (Zego).*
