# Discover Profile Preview — Active Room / Live Session API Guide

**Target Audience:** Mobile Developers (iOS / Android / Flutter)  
**App:** qobo_one_live (Discover Profile Preview Sheet & Explore Grid)  
**Status:** Implemented & Verified  
**Date:** 2026-08-21  

---

## 1. Overview

When a user taps a profile card on the **Discover (Explore)** screen, the preview bottom sheet can now display whether that user is currently hosting/in an **audio room**, **video room**, or **live stream**, along with room details and a **Join / Enter** button.

The backend implementation is **100% additive** and backward-compatible. Existing profile fields (`followersCount`, `isFollowing`, `canMessage`, etc.) remain completely unchanged.

---

## 2. API Endpoints

### Primary Endpoint

```http
GET /api/user/public/{userId}
Authorization: Bearer {VIEWER_JWT_TOKEN}
```

| Detail | Description |
|---|---|
| **When Called** | Immediately when the user taps a Discover profile card, **before** presenting the preview bottom sheet. |
| **Mobile Repository** | `UserRepo.getPublicProfile()` $\rightarrow$ `DiscoverTabController.fetchPublicProfile()` $\rightarrow$ `showDiscoverUserCallDialog()` |
| **Response** | Contains full profile details + `activeSession` object + flat aliases. |

### Optional Grid Endpoint

```http
GET /api/user/discover
Authorization: Bearer {VIEWER_JWT_TOKEN}
```

Every user object inside `data.users[]` on the explore grid also includes `activeSession` and `isLive`, allowing the grid to show a small **LIVE** badge on cards before opening.

---

## 3. Data Structure & Response Format

The backend returns both the preferred **nested `activeSession`** object AND **flat aliases** on `data` for maximum client compatibility.

### Active Session Field Specification (`data.activeSession`)

| Field | Type | Description |
|---|---|---|
| `isLive` | `boolean` | `true` if the host is currently in a joinable session, `false` otherwise. |
| `roomId` | `string \| null` | The ID to pass to `POST /api/room/join`. |
| `roomType` | `string \| null` | `"AUDIO"` \| `"VIDEO"` \| `"LIVE_STREAM"` (for UI button label & icons). |
| `sessionType` | `string \| null` | `"audio_room"` \| `"video_room"` \| `"live_stream"` (passed to join API). |
| `title` | `string \| null` | Room or stream title to display in UI subtitle. |
| `hostId` | `string \| null` | Host user ID. |
| `viewerCount` | `number` | Viewer/Audience count (e.g. "12 watching"). |
| `joinApprovalRequired` | `boolean` | `true` if joining requires host approval gate. |
| `liveStreamingId` | `string \| null` | ZEGOCLOUD stream ID (when live streaming). |
| `coverUrl` | `string \| null` | Full URL of room/stream cover image (if available). |

---

## 4. `roomType` & `sessionType` Mapping

| Product Surface | `roomType` (UI Label) | `sessionType` (Join Payload) |
|---|---|---|
| **Audio Room** | `"AUDIO"` | `"audio_room"` |
| **Video Room** | `"VIDEO"` | `"video_room"` |
| **Live Streaming** | `"LIVE_STREAM"` | `"live_stream"` |

---

## 5. Joining a Session (Existing Flow)

When the user taps **Join / Enter** on the bottom sheet, use the existing room join API:

```http
POST /api/room/join
Authorization: Bearer {VIEWER_TOKEN}
Content-Type: application/json

{
  "roomId": "<data.activeSession.roomId>",
  "room_id": "<data.activeSession.roomId>",
  "session_type": "<data.activeSession.sessionType>"
}
```

Navigate to the respective Audio Room / Video Room / Live Stream screen with the join response payload.

---

## 6. Example API Responses

### A) Host is in an Audio Room

`GET /api/user/public/idc6363131`

```json
{
  "statusCode": 1,
  "message": "Public profile fetched",
  "data": {
    "id": "idc6363131",
    "name": "Agency Owner",
    "displayPicture": "https://cdn.example.com/uploads/dp.png",
    "bio": "Welcome to my lounge!",
    "gender": "female",
    "country": "IN",
    "level": 5,
    "followersCount": 140,
    "followingCount": 32,
    "coinsPerSecond": 2.0,
    "isFollowing": false,
    "isFollower": false,
    "isMutual": false,
    "canMessage": false,

    "activeSession": {
      "isLive": true,
      "roomId": "1ce693c8-09ac-402b-ab74-dec8330b65bc",
      "roomType": "AUDIO",
      "sessionType": "audio_room",
      "title": "Friday Audio Lounge",
      "hostId": "idc6363131",
      "viewerCount": 19,
      "joinApprovalRequired": false,
      "liveStreamingId": "live_1ce693c809ac402bab74_1787303641",
      "coverUrl": null
    },

    "isLive": true,
    "is_live": true,
    "roomId": "1ce693c8-09ac-402b-ab74-dec8330b65bc",
    "room_id": "1ce693c8-09ac-402b-ab74-dec8330b65bc",
    "roomType": "AUDIO",
    "room_type": "AUDIO",
    "sessionType": "audio_room",
    "session_type": "audio_room",
    "title": "Friday Audio Lounge",
    "hostId": "idc6363131",
    "host_id": "idc6363131",
    "viewerCount": 19,
    "viewer_count": 19,
    "joinApprovalRequired": false
  }
}
```

### B) Host is Live Streaming

`GET /api/user/public/idc6363131`

```json
{
  "statusCode": 1,
  "message": "Public profile fetched",
  "data": {
    "id": "idc6363131",
    "name": "Agency Owner",
    "displayPicture": "https://cdn.example.com/uploads/dp.png",

    "activeSession": {
      "isLive": true,
      "roomId": "6bc0f4dc-78e9-4de1-829b-80983783052d",
      "roomType": "LIVE_STREAM",
      "sessionType": "live_stream",
      "title": "Midnight Music Stream",
      "hostId": "idc6363131",
      "viewerCount": 24,
      "joinApprovalRequired": false,
      "liveStreamingId": "live_stream_1787303642926",
      "coverUrl": "https://cdn.example.com/uploads/cover.png"
    },

    "isLive": true,
    "is_live": true,
    "roomId": "6bc0f4dc-78e9-4de1-829b-80983783052d",
    "room_id": "6bc0f4dc-78e9-4de1-829b-80983783052d",
    "roomType": "LIVE_STREAM",
    "room_type": "LIVE_STREAM",
    "sessionType": "live_stream",
    "session_type": "live_stream"
  }
}
```

### C) Host is Offline (Not Live)

`GET /api/user/public/idc6363131`

```json
{
  "statusCode": 1,
  "message": "Public profile fetched",
  "data": {
    "id": "idc6363131",
    "name": "Agency Owner",

    "activeSession": {
      "isLive": false,
      "roomId": null,
      "roomType": null,
      "sessionType": null,
      "title": null,
      "hostId": null,
      "viewerCount": 0,
      "joinApprovalRequired": false,
      "liveStreamingId": null,
      "coverUrl": null
    },

    "isLive": false,
    "is_live": false,
    "roomId": null,
    "room_id": null,
    "roomType": null,
    "room_type": null,
    "sessionType": null,
    "session_type": null
  }
}
```

---

## 7. Mobile UI Logic Summary

| Condition | Mobile Action |
|---|---|
| `data.activeSession.isLive == true` && `roomId` present | Show **Join / Enter** action button on profile sheet with `roomType` label (`"Join Audio Room"` / `"Join Live Stream"`). |
| Tap **Join** | Execute `POST /api/room/join` with `roomId` and `sessionType`. |
| `data.activeSession.isLive == false` or missing | Hide Join button. Sheet shows standard Follow / Message / View Profile options. |

---

## 8. cURL Smoke Test

```bash
BASE=https://my-backend-api-960q.onrender.com
TOKEN=your_bearer_jwt_token
TARGET=host_user_id

curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/api/user/public/$TARGET" | jq '.data.activeSession'
```
