# Qobo Call Module Backend API

This document describes the APIs added and modified to support the mobile App's "Call Module".

## 1. Live Now Feed

### `GET /api/room/list`
Modified to support fetching a mixed feed for the Call Hub.
**Params:**
- `type`: Optional. If omitted, returns a mixed list of `live_stream`, `audio`, and `video` rooms.
- `category`: String (e.g., "Trending").
**Response:**
Standard room list response.

---

## 2. Call History

### `GET /api/call/history`
Get the user's unified call history (both direct calls and room joins).

**Query Params:**
- `filter`: "all", "missed", "outgoing", "incoming", "rooms"
- `call_type`: "all", "voice", "video", "audio_room", "video_room", "live_stream"
- `page`: default 1
- `limit`: default 30

**Response:**
```json
{
    "statusCode": 1,
    "message": "OK",
    "data": [
        {
            "id": "uuid",
            "kind": "direct_call", // or "room_join"
            "direction": "incoming", // "outgoing", "missed"
            "status": "completed",
            "callType": "video",
            "peer": {
                "userId": "123",
                "name": "Jane",
                "avatar": "https://...",
                "isOnline": false
            },
            "startedAt": "2026-07-29T12:00:00Z",
            "endedAt": "2026-07-29T12:05:00Z",
            "durationSeconds": 300,
            "coinsCharged": 150,
            "coinsPerSecond": 0.5,
            "chatRoomId": "chat_123_456"
        }
    ],
    "meta": {
        "page": 1,
        "limit": 30,
        "total": 1,
        "hasMore": false
    }
}
```

---

## 3. Direct Call setup

### `GET /api/call/users/search?q={query}&page=1&limit=20`
Search users to initiate a direct call.

**Response:**
```json
{
    "statusCode": 1,
    "data": [
        {
            "userId": "456",
            "name": "John",
            "username": "john",
            "avatar": "https://...",
            "countryCode": "US",
            "isOnline": true,
            "acceptsVoiceCall": true,
            "acceptsVideoCall": true,
            "voiceCoinsPerSecond": 0.5,
            "videoCoinsPerSecond": 1.0,
            "busy": false,
            "minWalletCoinsRequired": 50
        }
    ]
}
```

### `POST /api/call/direct/start`
Initialize a direct call from the caller's side.

**Request:**
```json
{
    "calleeUserId": "456",
    "callType": "video",
    "clientCallId": "zego_custom_id"
}
```
**Response:**
```json
{
    "statusCode": 1,
    "data": {
        "callId": "uuid",
        "zegoCallId": "zego_custom_id",
        "chatRoomId": "chat_123_456",
        "coinsPerSecond": 1.0,
        "callerPays": true
    }
}
```

### `POST /api/call/direct/end`
Mark the call as ended/rejected/cancelled.

**Request:**
```json
{
    "callId": "uuid",
    "reason": "completed" // or "missed", "rejected", "cancelled"
}
```

---

## 4. Discover (Dating)

### `POST /api/pk/dating-action`
Process a dating swipe.

**Request:**
```json
{
    "target_id": "456",
    "type": "LIKE" // or "DISLIKE", "SUPERLIKE"
}
```

**Response:**
If there is a mutual match, the API generates and returns a `chatRoomId` to initiate 1:1 chat immediately.
```json
{
    "statusCode": 1,
    "data": {
        "isMatch": true, // Legacy, deprecated
        "matched": true,
        "chatRoomId": "chat_123_456"
    }
}
```
