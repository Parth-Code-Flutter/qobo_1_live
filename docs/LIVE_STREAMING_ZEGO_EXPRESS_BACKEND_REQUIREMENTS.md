# Live Streaming Zego Express Backend Requirements

## Purpose

Mobile is currently seeing live streams get stuck on loading / black screen. The stable solution is to make live streaming use explicit Zego Express session data from backend, instead of relying only on Zego Prebuilt Live Streaming internals.

Backend should provide one consistent Zego payload for host create, live list, and audience join, so mobile can:

- Host: login to Zego room and publish the host stream.
- Audience: login to the same Zego room and play the exact host stream.
- End/leave: close backend live session and stop Zego cleanly.

## Current Issue

`/api/live-streaming/join` returns useful `zegoStreaming` data, but `/api/live-streaming/list` currently returns only stream metadata in some cases.

That means mobile can see a live card, but may not have enough reliable Zego data until after join. For permanent stability, all live-streaming APIs should return the same Zego identifiers.

## Required Backend Rule

Live Streaming must be fully isolated from room APIs.

- Live Streaming APIs: `/api/live-streaming/*`
- Audio/video room APIs: `/api/room/*`

Do not mix `/api/room/join` or `/api/room/end` into live streaming flows.

## Required Zego Payload

Every live-streaming API response that returns a live stream object should include:

```json
{
  "zegoStreaming": {
    "appId": 1538269104,
    "appSign": "ZEGO_APP_SIGN",
    "roomId": "ls_1787332473634_602",
    "liveId": "ls_1787332473634_602",
    "userId": "current_mobile_user_id",
    "token": "ZEGO_TOKEN_FOR_CURRENT_USER",
    "hostUserId": "host_user_id",
    "hostStreamId": "stream_ls1787332473634602_hostuserid",
    "playStreamId": "stream_ls1787332473634602_hostuserid",
    "publishStreamId": "stream_ls1787332473634602_currentuserid"
  }
}
```

Aliases are acceptable, but the canonical mobile keys should be present exactly:

- `appId`
- `appSign`
- `roomId`
- `token`
- `hostUserId`
- `hostStreamId`
- `playStreamId`
- `publishStreamId`

## Stream ID Rules

Backend must generate deterministic stream IDs.

Recommended:

```text
roomId = liveStreamingId
hostStreamId = stream_{sanitizedRoomId}_{sanitizedHostUserId}
viewerPublishStreamId = stream_{sanitizedRoomId}_{sanitizedViewerUserId}
```

Example:

```text
roomId: ls_1787332473634_602
hostUserId: idc6678233
hostStreamId: stream_ls1787332473634602_idc6678233
```

Important:

- The host must publish using `hostStreamId`.
- Audience must play using `hostStreamId` or `playStreamId`.
- `roomId` must be the Zego room/channel id, not only backend UUID.
- Backend UUID should remain available as `id`, `room_id`, or `roomId` for API operations, but Zego `roomId` inside `zegoStreaming` must be the `ls_...` channel.

## API Requirements

### 1. Create Live Stream

`POST /api/live-streaming/create`

Request:

```json
{
  "name": "Test Live Stream",
  "liveStreamingId": "ls_1787332473634_602",
  "onlyFollows": false,
  "joinApprovalRequired": false,
  "coverImage": "optional_url"
}
```

Response must include:

```json
{
  "statusCode": 1,
  "message": "Live streaming started",
  "data": {
    "id": "backend_uuid",
    "room_id": "backend_uuid",
    "roomId": "backend_uuid",
    "name": "Test Live Stream",
    "title": "Test Live Stream",
    "liveStreamingId": "ls_1787332473634_602",
    "zegoLiveId": "ls_1787332473634_602",
    "channelName": "ls_1787332473634_602",
    "hostId": "host_user_id",
    "hostName": "Host Name",
    "hostAvatar": "host_profile_url",
    "isLive": true,
    "isActive": true,
    "viewerCount": 0,
    "zegoStreaming": {
      "appId": 1538269104,
      "appSign": "ZEGO_APP_SIGN",
      "roomId": "ls_1787332473634_602",
      "token": "HOST_ZEGO_TOKEN",
      "hostUserId": "host_user_id",
      "hostStreamId": "stream_ls1787332473634602_hostuserid",
      "playStreamId": "stream_ls1787332473634602_hostuserid",
      "publishStreamId": "stream_ls1787332473634602_hostuserid"
    }
  }
}
```

### 2. List Active Live Streams

`GET /api/live-streaming/list?page=1&limit=20`

Response should include the same live metadata plus `zegoStreaming`.

If backend does not want to expose viewer token in list, then at minimum return:

```json
{
  "zegoStreaming": {
    "appId": 1538269104,
    "roomId": "ls_1787332473634_602",
    "hostUserId": "host_user_id",
    "hostStreamId": "stream_ls1787332473634602_hostuserid",
    "playStreamId": "stream_ls1787332473634602_hostuserid"
  }
}
```

Then `/join` must return the viewer-specific token.

### 3. Join Live Stream

`POST /api/live-streaming/join`

Request can use backend UUID or live streaming id:

```json
{
  "roomId": "backend_uuid",
  "liveStreamingId": "ls_1787332473634_602"
}
```

Response must include viewer-specific Zego token:

```json
{
  "statusCode": 1,
  "message": "Joined live stream successfully",
  "data": {
    "id": "backend_uuid",
    "liveStreamingId": "ls_1787332473634_602",
    "hostId": "host_user_id",
    "hostName": "Host Name",
    "isLive": true,
    "zegoStreaming": {
      "appId": 1538269104,
      "appSign": "ZEGO_APP_SIGN",
      "roomId": "ls_1787332473634_602",
      "token": "VIEWER_ZEGO_TOKEN",
      "userId": "viewer_user_id",
      "hostUserId": "host_user_id",
      "hostStreamId": "stream_ls1787332473634602_hostuserid",
      "playStreamId": "stream_ls1787332473634602_hostuserid",
      "publishStreamId": "stream_ls1787332473634602_vieweruserid"
    }
  }
}
```

### 4. Leave Live Stream

`POST /api/live-streaming/leave`

Request:

```json
{
  "roomId": "backend_uuid",
  "liveStreamingId": "ls_1787332473634_602"
}
```

Expected:

- Decrease active viewer count.
- Broadcast viewer count update through socket if available.
- Do not end the live stream.

### 5. End Live Stream

`POST /api/live-streaming/end`

Request:

```json
{
  "roomId": "backend_uuid",
  "liveStreamingId": "ls_1787332473634_602",
  "startedAt": "2026-08-22T00:00:00.000Z",
  "endedAt": "2026-08-22T00:05:00.000Z",
  "durationSeconds": 300
}
```

Expected:

- Mark live as inactive.
- Return `statusCode: 1`.
- Notify all viewers through socket that live ended.
- Viewers should close live screen on mobile after receiving this event.

## Recommended Socket Events

For a production-quality live stream, backend should emit these events:

### Viewer Joined

```json
{
  "event": "live_stream.viewer_joined",
  "liveStreamingId": "ls_1787332473634_602",
  "viewerCount": 12,
  "viewer": {
    "id": "viewer_user_id",
    "name": "Viewer Name",
    "displayPicture": "url"
  }
}
```

### Viewer Left

```json
{
  "event": "live_stream.viewer_left",
  "liveStreamingId": "ls_1787332473634_602",
  "viewerCount": 11
}
```

### Live Ended

```json
{
  "event": "live_stream.ended",
  "liveStreamingId": "ls_1787332473634_602",
  "roomId": "backend_uuid"
}
```

### Gift Sent

```json
{
  "event": "live_stream.gift_sent",
  "liveStreamingId": "ls_1787332473634_602",
  "scope": "all",
  "gift": {
    "id": "gift_id",
    "name": "Rose",
    "animationUrl": "https://..."
  },
  "sender": {
    "id": "sender_id",
    "name": "Sender"
  },
  "receiver": null
}
```

## Mobile Implementation Plan

Mobile will:

1. Call `/api/live-streaming/create` for host.
2. Login to Zego Express room using `zegoStreaming.roomId` and `zegoStreaming.token`.
3. Host publishes camera stream using `zegoStreaming.publishStreamId`.
4. Audience calls `/api/live-streaming/join`.
5. Audience logs into Zego Express using returned `roomId/token`.
6. Audience plays `zegoStreaming.playStreamId` or `hostStreamId`.
7. Mobile keeps the current UI and overlays unchanged.
8. On end/leave, mobile stops publishing/playing, logs out from Zego room, then closes screen.

## Backend Validation Checklist

Backend should verify:

- Host token allows room login and publishing.
- Viewer token allows room login and playing.
- `roomId` is exactly same for host and viewer.
- `hostStreamId` returned to viewer exactly matches host publish stream id.
- `/list` only returns `isLive: true` streams.
- `/join` rejects ended/inactive streams.
- `/end` is host-only.
- `/leave` does not end stream.
- All live-streaming endpoints return `statusCode: 1` on success.

## What Mobile Needs From Backend

Please provide:

1. Confirm final Zego AppID for live streaming.
2. Confirm whether mobile should use AppSign or token-only auth.
3. Confirm exact `zegoStreaming` response object for create/list/join.
4. Confirm socket event names for viewer joined, viewer left, gift sent, and live ended.
5. Confirm whether host can have only one active live stream at a time.
6. Confirm if backend can force-end older live sessions when host starts a new one.

## What I Need From Client / Tester

For mobile testing, please provide:

1. One host login account.
2. One audience login account.
3. Confirmation that both devices are on the latest installed build.
4. A fresh live stream created after the fix, not an older active stream.
5. If still failing, send:
   - Host device logs from live start.
   - Audience device logs from live join.
   - `/api/live-streaming/create` response.
   - `/api/live-streaming/join` response.

