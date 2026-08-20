# Qobo One Live — 1:1 Voice & Video Call Push Notification & Ringing API Documentation

**For:** Mobile Team (Flutter / iOS / Android) & Backend Team  
**Date:** 2026-08-19  
**Status:** Production Ready  

---

## 1. Overview

This document specifies the **REST Endpoints**, **FCM Push Notification Payloads**, and **Firestore Data Contracts** required for 1:1 Direct Voice and Video Calls.

When **Person A** calls **Person B**:
- If Person B's app is in **Foreground**, incoming call dialog displays via Firestore `userIncomingCalls/{calleeId}` or Socket.
- If Person B's app is in **Background** or **Terminated / Killed**, backend sends a high-priority **FCM Push Notification** (`incoming_call`), displaying the incoming call ringing UI with **Accept** and **Reject** actions.
- When Person B responds or Person A hangs up, backend dispatches `call_cancelled` FCM push to dismiss the ring UI on all callee devices.

> **Note:** This implementation applies strictly to **1:1 Voice & Video Direct Calls**. Live Streams, Audio Rooms, and Video Rooms are unaffected.

---

## 2. Authentication

All REST API requests require a Bearer JWT Token in the request header:

```http
Authorization: Bearer <user_jwt_token>
Content-Type: application/json
```

---

## 3. REST API Endpoints

### 3.1 Start Call (`POST /api/call/direct/start`)

Used when Caller (User A) dials Callee (User B).

**Request:**
```http
POST /api/call/direct/start
Authorization: Bearer <caller_token>
Content-Type: application/json
```

```json
{
  "calleeUserId": "callee-user-uuid",
  "callType": "voice",
  "roomId": "chat_room_uuid",
  "clientCallId": "vc_chat_room_uuid",
  "historyDocId": "call_1734567890123456"
}
```

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `calleeUserId` | String | **Yes** | ID of the user being called |
| `callType` | String | **Yes** | `"voice"` or `"video"` |
| `roomId` | String | Optional | Chat room UUID (`chatRooms/{roomId}`) |
| `clientCallId` | String | Optional | Zego Call Channel ID (derived from `roomId`, prefix `vc_`) |
| `historyDocId` | String | Optional | Call history ID |

**Success Response (`200 OK`):**
```json
{
  "statusCode": 1,
  "message": "Ringing",
  "data": {
    "callId": "vc_chat_room_uuid",
    "roomId": "chat_room_uuid",
    "zegoCallId": "vc_chat_room_uuid",
    "historyDocId": "call_1734567890123456",
    "expiresAt": "2026-08-19T06:01:00.000Z",
    "coinsPerSecond": 0.5,
    "callerPays": true
  }
}
```

---

### 3.2 Respond to Call (`POST /api/call/direct/respond`)

Used when Callee (User B) taps **Accept** or **Reject** from in-app dialog, notification tray action, or full-screen UI.

**Request:**
```http
POST /api/call/direct/respond
Authorization: Bearer <callee_token>
Content-Type: application/json
```

```json
{
  "callId": "vc_chat_room_uuid",
  "roomId": "chat_room_uuid",
  "action": "accept"
}
```

| Field | Type | Required | Values / Description |
|-------|------|:--------:|----------------------|
| `callId` | String | **Yes** | Zego `callId` or call session ID |
| `roomId` | String | Optional | Chat room UUID |
| `action` | String | **Yes** | `"accept"` or `"reject"` |

**Success Response (`200 OK` — Accept):**
```json
{
  "statusCode": 1,
  "message": "Accepted",
  "data": {
    "callId": "vc_chat_room_uuid",
    "roomId": "chat_room_uuid",
    "zegoCallId": "vc_chat_room_uuid",
    "callerId": "caller-user-uuid",
    "callerName": "Alex",
    "callType": "voice",
    "historyDocId": "call_1734567890123456",
    "callStartedAt": "2026-08-19T06:00:00.000Z"
  }
}
```

---

### 3.3 End / Cancel Call (`POST /api/call/direct/end`)

Used when Caller or Callee hangs up, cancels, or call ends.

**Request:**
```http
POST /api/call/direct/end
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "callId": "vc_chat_room_uuid",
  "reason": "completed"
}
```

| Field | Type | Required | Values / Description |
|-------|------|:--------:|----------------------|
| `callId` | String | **Yes** | Zego `callId` or call session ID |
| `reason` | String | **Yes** | `"completed"`, `"cancelled"`, `"rejected"`, `"missed"`, `"failed"` |

**Success Response (`200 OK`):**
```json
{
  "statusCode": 1,
  "message": "Ended",
  "data": {
    "id": "call_1734567890123456",
    "kind": "direct_call",
    "status": "completed",
    "callType": "voice",
    "durationSeconds": 45,
    "coinsCharged": 22.5
  }
}
```

---

## 4. FCM Push Notifications Payload Contract

> **Important:** All FCM `data` map values sent by the backend are **String** values.

### 4.1 `incoming_call` Push Data

Sent to Callee FCM tokens when a new ring starts.

```json
{
  "type": "incoming_call",
  "category": "INCOMING_CALL",
  "notification_id": "call_1734567890123456",
  "call_id": "vc_chat_room_uuid",
  "room_id": "chat_room_uuid",
  "caller_id": "caller-user-uuid",
  "caller_name": "Alex",
  "caller_avatar": "https://cdn.example.com/avatars/alex.jpg",
  "callee_id": "callee-user-uuid",
  "call_type": "voice",
  "zego_call_id": "vc_chat_room_uuid",
  "history_doc_id": "call_1734567890123456",
  "call_started_at": "2026-08-19T06:00:00.000Z",
  "record_call_history": "true",
  "expires_at": "2026-08-19T06:00:45.000Z"
}
```

#### Android Configuration
- High priority data-only payload (`priority: "high"`, `ttl: 45s`).
- Notification Channel ID: `incoming_calls` (Importance High with fullScreenIntent).

#### iOS APNs Configuration
- Headers: `apns-priority: "10"`, `apns-push-type: "alert"`.
- Payload Category: `INCOMING_CALL`.
- Sound: `ringtone.caf`, `interruption-level: "time-sensitive"`.
- Title: `"Incoming call"` (or `"Incoming video call"`).
- Body: `"Alex is calling you"` (or `"Alex is video calling you"`).

---

### 4.2 `call_cancelled` Push Data

Sent when caller cancels, callee answers/rejects on another device, or ring times out. Mobile must dismiss the local notification / ringing UI matching `notification_id`.

```json
{
  "type": "call_cancelled",
  "category": "INCOMING_CALL",
  "notification_id": "call_1734567890123456",
  "call_id": "vc_chat_room_uuid",
  "room_id": "chat_room_uuid",
  "reason": "accepted"
}
```

---

## 5. Firestore Reference Sync

The backend automatically keeps the following Firestore documents in sync:

1. **`chatRooms/{roomId}/calls/active`**  
   - `status`: `"ringing"` | `"accepted"` (deleted when ended/cancelled)
2. **`userIncomingCalls/{calleeUserId}`**  
   - `status`: `"ringing"` (deleted on accept, reject, or end)

---

## 6. Mobile Navigation Arguments (Zego Join)

When Callee accepts the call, navigate to existing chat call screen with arguments:

```dart
Get.toNamed(Routes.CHAT_VOICE_CALL, arguments: {
  'roomId': roomId,
  'callId': callId,
  'historyDocId': historyDocId,
  'callStartedAt': callStartedAt,
  'hostId': callerId,
  'peerName': callerName,
  'isCaller': false,
  'isVideo': callType == 'video',
  'recordCallHistory': true,
});
```
