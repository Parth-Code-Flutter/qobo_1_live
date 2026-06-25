# Audio & Video Rooms API Handover

**Purpose:** Backend contract for Discover tab **Video Rooms** and **Audio Rooms** so mobile can replace dummy UI data with real room creation, listing, joining, ZEGOCLOUD entry, seat state, and room lifecycle.

**Mobile entry:** `Discover -> Video Rooms | Audio Rooms`  
**Create screen:** `LiveRoomCreateView`  
**Mobile repo files:** `RoomRepo`, `DiscoverTabController`, `DiscoverVideoRoomView`, `DiscoverAudioRoomView`, `LiveRoomCreateController`

---

## 1. Standard Response Envelope

All APIs should use the project envelope:

```json
{
  "statusCode": 1,
  "message": "Success message",
  "data": {}
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `statusCode` | number | `1` for success, `0` for app-level failure. |
| `message` | string | Human-readable message for toast/dialog. |
| `data` | object/array/null | API payload. |

All room APIs require:

```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

---

## 2. Critical Mobile Requirement

For both **AUDIO** and **VIDEO** rooms, backend must persist and return a stable ZEGOCLOUD room/channel id.

Mobile can read any of these keys, but backend should standardize on:

```json
{
  "zegoRoomId": "room_182736451_demo",
  "channelName": "room_182736451_demo"
}
```

Recommended:

| Field | Required | Notes |
| --- | --- | --- |
| `id` or `_id` | Yes | Backend DB room id. |
| `roomId` | Yes | Same as backend DB id, for mobile convenience. |
| `zegoRoomId` | Yes | Stable Zego room id used by mobile to join media room. |
| `channelName` | Yes | Same as `zegoRoomId`; useful alias. |
| `type` | Yes | `AUDIO` or `VIDEO`. |
| `status` | Yes | `active`, `ended`, `blocked`, etc. |

Without `zegoRoomId` / `channelName`, mobile cannot reliably join the correct Zego room.

---

## 3. Shared Room Object

Backend should return this shape from create/list/join/detail APIs.

```json
{
  "id": "room_uuid_123",
  "roomId": "room_uuid_123",
  "name": "Creator Hangout",
  "title": "Creator Hangout",
  "type": "VIDEO",
  "status": "active",
  "country": "IN",
  "countryCode": "IN",
  "countryName": "India",
  "category": "Open cam chat",
  "maxSeats": 8,
  "seatConfig": 8,
  "isPrivate": false,
  "coverImage": "https://cdn.example.com/rooms/cover.jpg",
  "zegoRoomId": "vr_room_uuid_123",
  "channelName": "vr_room_uuid_123",
  "hostId": "user_uuid_host",
  "hostName": "Ritvik",
  "hostAvatar": "https://cdn.example.com/users/host.jpg",
  "host": {
    "id": "user_uuid_host",
    "name": "Ritvik",
    "displayPicture": "https://cdn.example.com/users/host.jpg"
  },
  "viewerCount": 2100,
  "listenerCount": 0,
  "speakerCount": 1,
  "onlineCount": 2100,
  "heatScore": 2100,
  "isFollowing": false,
  "isFavorite": false,
  "createdAt": "2026-06-25T06:00:00.000Z",
  "startedAt": "2026-06-25T06:00:05.000Z"
}
```

### Field Aliases Mobile Can Read

To reduce UI fallback issues, please include both canonical and legacy aliases for now:

| Canonical | Alias to also return | Why |
| --- | --- | --- |
| `name` | `title` | Existing backend sometimes returns `title`. |
| `maxSeats` | `seatConfig` | Existing backend sometimes returns `seatConfig`. |
| `zegoRoomId` | `channelName` | Mobile/Zego naming compatibility. |
| `hostAvatar` | `hostDisplayPicture`, `displayPicture` | Different screens read different keys. |
| `viewerCount` | `onlineCount`, `audienceCount`, `heatScore` | Different list UIs display different count labels. |

---

## 4. Create Audio/Video Room

### `POST /api/room/create`

Creates an audio or video party room and returns a room object immediately usable by mobile/Zego.

#### Request

```json
{
  "name": "Creator Hangout",
  "type": "VIDEO",
  "country": "IN",
  "maxSeats": 8,
  "isPrivate": false,
  "category": "Open cam chat",
  "announcement": "Welcome everyone",
  "coverImage": "https://cdn.example.com/rooms/cover.jpg"
}
```

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | Yes | Max 40 chars recommended. |
| `type` | string | Yes | `AUDIO` or `VIDEO`. |
| `country` | string | Yes | ISO code like `IN`, `BD`, or `GLOBAL`. |
| `maxSeats` | number | Yes | Supported values from mobile UI: `4`, `6`, `8`, `12`. |
| `isPrivate` | boolean | No | Default `false`. |
| `category` | string | No | e.g. `Music`, `Talk show`, `Open cam chat`. |
| `announcement` | string | No | Welcome text. |
| `coverImage` | string | No | URL if upload is added. |

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Room created successfully",
  "data": {
    "id": "room_uuid_123",
    "roomId": "room_uuid_123",
    "name": "Creator Hangout",
    "title": "Creator Hangout",
    "type": "VIDEO",
    "status": "active",
    "country": "IN",
    "countryCode": "IN",
    "countryName": "India",
    "category": "Open cam chat",
    "maxSeats": 8,
    "seatConfig": 8,
    "isPrivate": false,
    "zegoRoomId": "vr_room_uuid_123",
    "channelName": "vr_room_uuid_123",
    "hostId": "user_uuid_host",
    "hostName": "Ritvik",
    "hostAvatar": "https://cdn.example.com/users/host.jpg",
    "viewerCount": 1,
    "speakerCount": 1,
    "onlineCount": 1,
    "seats": [
      {
        "seatId": 1,
        "status": "occupied",
        "isLocked": false,
        "isMuted": false,
        "role": "host",
        "occupant": {
          "id": "user_uuid_host",
          "name": "Ritvik",
          "displayPicture": "https://cdn.example.com/users/host.jpg"
        }
      }
    ],
    "createdAt": "2026-06-25T06:00:00.000Z",
    "startedAt": "2026-06-25T06:00:05.000Z"
  }
}
```

### Backend Rules

- Authenticated user becomes room host.
- Generate `zegoRoomId` server-side. Suggested:
  - video: `vr_<roomId>`
  - audio: `ar_<roomId>`
- `status` should be `active` after creation.
- Host should be inserted into seat `1`.
- Room should appear in `GET /api/room/list` immediately.

---

## 5. List Discover Rooms

### `GET /api/room/list`

Used by Discover tabs to show joinable audio/video rooms.

#### Query Parameters

| Query | Required | Example | Notes |
| --- | --- | --- | --- |
| `type` | No | `VIDEO` | `VIDEO`, `AUDIO`; if omitted return all active rooms. |
| `country` | No | `IN` | `GLOBAL` or omitted means all countries. |
| `category` | No | `trending` | Optional mobile filter. |
| `page` | No | `1` | Recommended for pagination. |
| `limit` | No | `20` | Recommended. |

#### Example

```http
GET /api/room/list?type=VIDEO&country=IN&page=1&limit=20
Authorization: Bearer <jwt_token>
```

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Rooms fetched",
  "data": [
    {
      "id": "room_uuid_123",
      "roomId": "room_uuid_123",
      "name": "Creator Hangout",
      "title": "Creator Hangout",
      "type": "VIDEO",
      "status": "active",
      "country": "IN",
      "countryName": "India",
      "category": "Open cam chat",
      "maxSeats": 8,
      "seatConfig": 8,
      "zegoRoomId": "vr_room_uuid_123",
      "channelName": "vr_room_uuid_123",
      "hostId": "user_uuid_host",
      "hostName": "Ritvik",
      "hostAvatar": "https://cdn.example.com/users/host.jpg",
      "coverImage": "https://cdn.example.com/rooms/cover.jpg",
      "viewerCount": 2100,
      "onlineCount": 2100,
      "speakerCount": 1,
      "isFollowing": false,
      "isFavorite": false,
      "createdAt": "2026-06-25T06:00:00.000Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "hasMore": false,
    "total": 1
  }
}
```

### Mobile Expectations

- Discover `Video Rooms` tab calls `GET /api/room/list?type=VIDEO`.
- Discover `Audio Rooms` tab calls `GET /api/room/list?type=AUDIO`.
- Mobile should not need to call detail API just to render list cards.
- Return only active/joinable rooms by default.
- Sort recommended: live rooms with highest `heatScore` / `onlineCount` first.

---

## 6. Join Room

### `POST /api/room/join`

Called when a user taps `Join` in Video Rooms or Audio Rooms.

#### Request

```json
{
  "room_id": "room_uuid_123"
}
```

Recommended accepted aliases:

```json
{
  "roomId": "room_uuid_123"
}
```

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Joined room successfully",
  "data": {
    "room": {
      "id": "room_uuid_123",
      "roomId": "room_uuid_123",
      "name": "Creator Hangout",
      "type": "VIDEO",
      "status": "active",
      "zegoRoomId": "vr_room_uuid_123",
      "channelName": "vr_room_uuid_123",
      "hostId": "user_uuid_host",
      "hostName": "Ritvik",
      "hostAvatar": "https://cdn.example.com/users/host.jpg",
      "maxSeats": 8,
      "viewerCount": 2101,
      "onlineCount": 2101,
      "speakerCount": 1
    },
    "participant": {
      "userId": "user_uuid_joiner",
      "role": "audience",
      "joinedAt": "2026-06-25T06:05:00.000Z",
      "canPublishAudio": false,
      "canPublishVideo": false
    },
    "zego": {
      "appId": 1291066184,
      "roomId": "vr_room_uuid_123",
      "token": null,
      "tokenExpiresAt": null
    }
  }
}
```

### Mobile Join Behaviour

1. Mobile calls `POST /api/room/join`.
2. Mobile reads `data.room.zegoRoomId` or `data.room.channelName`.
3. Mobile opens Zego room:
   - `VIDEO`: video room UI / Zego live-streaming style room.
   - `AUDIO`: audio room UI / Zego live-audio-room style room.
4. If backend returns token mode later, mobile can use `data.zego.token`.

### Backend Rules

- Do not allow joining if `status != active`.
- Do not allow joining if room is full and user must take a seat immediately.
- If `isPrivate = true`, enforce access rules before success.
- Update `onlineCount` / `viewerCount` / `listenerCount`.
- Create attendance/watch-history row.
- Return enough room data for mobile to open Zego without another API call.

---

## 7. Leave Room

### `POST /api/room/leave`

Needed for accurate counts and room cleanup.

#### Request

```json
{
  "room_id": "room_uuid_123"
}
```

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Left room successfully",
  "data": {
    "roomId": "room_uuid_123",
    "userId": "user_uuid_joiner",
    "leftAt": "2026-06-25T06:30:00.000Z",
    "onlineCount": 124,
    "viewerCount": 124,
    "listenerCount": 124
  }
}
```

### Backend Rules

- Remove user from active participants.
- If user occupied a seat, clear that seat.
- If host leaves without ending:
  - Option A: end the room.
  - Option B: transfer host to next moderator/co-host.
- Mobile recommendation: call this when user exits room screen.

---

## 8. End Room

### `POST /api/room/end`

Host-only endpoint to end audio/video party room.

#### Request

```json
{
  "room_id": "room_uuid_123",
  "endReason": "host_end",
  "startedAt": "2026-06-25T06:00:05.000Z",
  "endedAt": "2026-06-25T07:10:20.000Z",
  "peakViewerCount": 2300,
  "uniqueViewerCount": 1980
}
```

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Room ended successfully",
  "data": {
    "roomId": "room_uuid_123",
    "status": "ended",
    "durationSeconds": 4215,
    "peakViewerCount": 2300,
    "uniqueViewerCount": 1980,
    "endedAt": "2026-06-25T07:10:20.000Z"
  }
}
```

### Backend Rules

- Only host/admin can end.
- Mark room `ended`.
- Exclude ended rooms from `/api/room/list`.
- Idempotency: repeated end call should return success with existing summary or `409` with clear message.

---

## 9. Seat / Mic Actions

### `POST /api/room/mic-action`

Used mainly for **Audio Rooms**, but can also support video co-host seats.

#### Request

```json
{
  "room_id": "room_uuid_123",
  "action": "mute",
  "seat_id": 2,
  "target_user_id": "user_uuid_target"
}
```

| Action | Meaning |
| --- | --- |
| `take` | Current user takes an empty seat. |
| `leave` | Current user leaves their seat. |
| `mute` | Host/self mutes seat. |
| `unmute` | Host/self unmutes seat. |
| `lock` | Host locks a seat. |
| `unlock` | Host unlocks a seat. |

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Seat updated",
  "data": {
    "roomId": "room_uuid_123",
    "seatId": 2,
    "action": "mute",
    "seats": [
      {
        "seatId": 1,
        "status": "occupied",
        "isLocked": false,
        "isMuted": false,
        "role": "host",
        "occupant": {
          "id": "user_uuid_host",
          "name": "Ritvik",
          "displayPicture": "https://cdn.example.com/users/host.jpg"
        }
      },
      {
        "seatId": 2,
        "status": "occupied",
        "isLocked": false,
        "isMuted": true,
        "role": "speaker",
        "occupant": {
          "id": "user_uuid_target",
          "name": "Priya",
          "displayPicture": "https://cdn.example.com/users/priya.jpg"
        }
      }
    ]
  }
}
```

### Seat Object

```json
{
  "seatId": 1,
  "status": "empty",
  "isLocked": false,
  "isMuted": false,
  "role": "speaker",
  "occupant": null
}
```

---

## 10. Kick / Moderation

### `POST /api/room/kick`

Host/admin removes participant from room.

#### Request

```json
{
  "room_id": "room_uuid_123",
  "target_user_id": "user_uuid_target"
}
```

#### Success Response

```json
{
  "statusCode": 1,
  "message": "User kicked successfully",
  "data": {
    "roomId": "room_uuid_123",
    "kickedId": "user_uuid_target",
    "kickedUntil": "2026-06-25T08:00:00.000Z"
  }
}
```

Recommended backend:

- Prevent kicked user from rejoining for a cooldown window.
- Remove user from seat if seated.
- Notify mobile via socket/Zego signal later if real-time moderation is added.

---

## 11. Share Room

### `GET /api/room/share?room_id=room_uuid_123`

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Share link generated",
  "data": {
    "roomId": "room_uuid_123",
    "shareUrl": "https://qobo.live/room/room_uuid_123",
    "title": "Creator Hangout",
    "description": "Join Ritvik's video room on Qobo One Live"
  }
}
```

---

## 12. Optional Zego Token API

Current mobile uses AppID/AppSign from `ZegoConfig.liveAppId`. For production, backend can move to token auth.

### `GET /api/room/zego-token?room_id=room_uuid_123`

#### Success Response

```json
{
  "statusCode": 1,
  "message": "Zego token generated",
  "data": {
    "appId": 1291066184,
    "roomId": "vr_room_uuid_123",
    "userId": "user_uuid_joiner",
    "token": "zego_token_here",
    "expiresAt": "2026-06-25T07:00:00.000Z"
  }
}
```

---

## 13. Real-time Count & Seat Sync

For smooth rooms, backend should support at least one of these:

### Option A — Polling v1

Mobile calls detail/list refresh every few seconds.

Recommended detail API:

```http
GET /api/room/detail?room_id=room_uuid_123
```

Returns full shared room object including `seats`, `onlineCount`, `listenerCount`, `viewerCount`.

### Option B — Socket v2

Emit room events:

| Event | Payload |
| --- | --- |
| `room_participant_joined` | `{ roomId, user, onlineCount }` |
| `room_participant_left` | `{ roomId, userId, onlineCount }` |
| `room_seats_updated` | `{ roomId, seats }` |
| `room_ended` | `{ roomId, endedAt, reason }` |
| `room_user_kicked` | `{ roomId, targetUserId }` |

Mobile can start with polling and upgrade to sockets later.

---

## 14. Mobile Implementation Notes

### Current mobile files

| Mobile file | Role |
| --- | --- |
| `lib/repo/room/room_repo.dart` | API methods for create/list/join/mic/kick/share/token. |
| `lib/app/user_flow/discover/discover_tab/controllers/discover_tab_controller.dart` | Discover People/Video/Audio mode state. Currently has dummy room data. |
| `lib/app/user_flow/discover/discover_tab/widgets/discover_video_room_view.dart` | Video room list UI. |
| `lib/app/user_flow/discover/discover_tab/widgets/discover_audio_room_view.dart` | Audio room list UI. |
| `lib/app/user_flow/live_room_create/controllers/live_room_create_controller.dart` | Create room form and `POST /api/room/create`. |
| `lib/app/user_flow/live_broadcast/views/live_broadcast_view.dart` | Current Zego room/live entry surface. |

### Mobile work after backend is ready

1. Replace dummy `demoVideoRooms` with `RoomRepo.listActiveRooms(type: 'VIDEO')`.
2. Replace dummy `demoAudioRooms` with `RoomRepo.listActiveRooms(type: 'AUDIO')`.
3. On `Join`, call `RoomRepo.joinRoom(roomId)` before opening Zego.
4. Use returned `data.room.zegoRoomId` / `channelName` for Zego room id.
5. For create, `LiveRoomCreateController.createRoom()` already posts `name`, `type`, `country`, `maxSeats`, `isPrivate`.
6. Ensure create response includes the shared room object, then mobile can open the correct Zego room.

### Zego Project

Audio/video party rooms should use the **live room Zego project**, not the separate 1:1 call project:

```dart
ZegoConfig.liveAppId
ZegoConfig.liveAppSign
```

The separate `callAppId` is only for direct 1:1 chat calls.

---

## 15. Error Response Examples

### Unauthorized

```json
{
  "statusCode": 0,
  "message": "Unauthorized"
}
```

### Room not found

```json
{
  "statusCode": 0,
  "message": "Room not found"
}
```

### Room ended

```json
{
  "statusCode": 0,
  "message": "This room has ended"
}
```

### Room full

```json
{
  "statusCode": 0,
  "message": "Room is full"
}
```

### Missing Zego room id

```json
{
  "statusCode": 0,
  "message": "Room channel is not ready"
}
```

---

## 16. Backend Checklist

- [ ] `POST /api/room/create` returns `name`, `maxSeats`, `zegoRoomId`, `channelName`, host fields.
- [ ] `GET /api/room/list?type=VIDEO` returns active video rooms for Discover.
- [ ] `GET /api/room/list?type=AUDIO` returns active audio rooms for Discover.
- [ ] `POST /api/room/join` returns room + participant + Zego info.
- [ ] `POST /api/room/leave` added for accurate counts.
- [ ] `POST /api/room/end` added for host ending room.
- [ ] `POST /api/room/mic-action` supports seat take/leave/mute/unmute/lock/unlock.
- [ ] `POST /api/room/kick` removes participant and prevents immediate rejoin.
- [ ] `GET /api/room/share` returns a share URL.
- [ ] Optional: `GET /api/room/zego-token` if moving to token auth.
- [ ] Counts update consistently: `viewerCount`, `listenerCount`, `onlineCount`, `speakerCount`.
- [ ] Ended/private/full rooms are handled with clear messages.

---

## 17. Suggested Implementation Order

1. Fix `/api/room/create` response shape.
2. Implement `/api/room/list` with correct `AUDIO` / `VIDEO` data.
3. Implement `/api/room/join`.
4. Add `/api/room/leave` and `/api/room/end`.
5. Finish seat/mic actions for audio rooms.
6. Add moderation/share/token improvements.

