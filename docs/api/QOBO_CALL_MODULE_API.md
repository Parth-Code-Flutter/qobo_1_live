# Qobo Call Module — Backend API Handover

**App:** `qobo_one_live` (Flutter / GetX)  
**Entry:** Profile tab → **Call** → `Routes.CALL` (`/call`)  
**Audience:** Backend  
**Date:** 2026-07-29  
**Status:** Mobile **Live Now** listing + join is wired to existing room APIs. Discover dating stays as-is. History / Direct Call UI are stubs waiting on APIs below.

---

## 1. Product scope (mobile)

| Tab | Purpose | Mobile status |
|-----|---------|---------------|
| **Live Now** | List ongoing **audio rooms**, **video rooms**, and **live streams**. Tap → join same as Rooms / Live tabs. | **Working** via `GET /api/room/list` + `POST /api/room/join` (+ approval flow) |
| **Discover** | Dating prefs → swipe → matches | **Existing** (`/api/pk/dating-*`) |
| **History** | Unified call + session join history with call-back | **UI stub** — needs APIs in §4 |
| **Direct Call** | Search user → 1:1 voice / video dialer | **UI stub** — chat 1:1 already works; needs hub APIs in §5 |

**Non-goals for Call hub:** Do not create a separate Zego join stack. Always reuse the same join payload + `LIVE_BROADCAST` navigation already used by Live / Rooms.

---

## 2. Auth & conventions

- Base URL: existing app API host  
- Header: `Authorization: Bearer <user_token>`  
- Success: `statusCode == 1` (also accept `200` / `201` where already used)  
- Errors: `{ "statusCode": 0, "message": "..." }`  
- IDs: prefer UUID strings; accept `_id` / `id` aliases on room objects  

---

## 3. Live Now — APIs (mostly **already exist**)

### 3.1 List active sessions

```http
GET /api/room/list?type={audio|video|live_stream}&country={optional}&category={optional}&page=1&limit=40
Authorization: Bearer <token>
```

| Query | Notes |
|-------|--------|
| `type` | Omit = mixed feed (preferred for Call “All”). `audio`, `video`, `live_stream` for chips. |
| `page` / `limit` | Pagination; Call uses `page=1`, `limit=40` today. |

#### Response `200`

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": [
    {
      "_id": "room-uuid",
      "id": "room-uuid",
      "name": "Friday Night",
      "title": "Friday Night",
      "type": "audio",
      "coverImage": "/uploads/cover.jpg",
      "countryCode": "IN",
      "countryName": "India",
      "maxSeats": 8,
      "heatScore": 120,
      "viewerCount": 45,
      "onlineCount": 45,
      "hostUserId": "user-uuid",
      "hostName": "Ava",
      "hostAvatar": "/uploads/a.jpg",
      "joinApprovalRequired": false,
      "isFavorite": false,
      "roomRankBadge": { "label": "TOP" },
      "zegoLiveId": "optional-for-live_stream",
      "channelName": "optional-for-live_stream"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 40,
    "total": 120,
    "hasMore": true
  }
}
```

#### Backend checklist (Live Now)

- [ ] `type=live_stream` returns only Go Live / streaming sessions  
- [ ] Mixed list (no `type`) includes audio + video + live_stream  
- [ ] Private / ended / empty host rooms excluded  
- [ ] Cover + host fields always present when possible  
- [ ] For live streams: include a joinable Zego id under one of: `room_id`, `_id`, `id`, `zegoLiveId`, `channelName` (mobile normalizes these)  
- [ ] `joinApprovalRequired` accurate so mobile can gate with join-request flow  

**Optional enhancement (nice for Call hub):**

```http
GET /api/call/live-now?type=all|audio|video|live&page=1&limit=40
```

Same item shape as `/api/room/list`, plus:

```json
{
  "sessionKind": "audio_room|video_room|live_stream",
  "canJoin": true,
  "viewerLabel": "45 watching",
  "startedAt": "2026-07-29T10:00:00.000Z"
}
```

Mobile can keep using `/api/room/list` if this is delayed.

### 3.2 Join room / live (existing)

```http
POST /api/room/join
Authorization: Bearer <token>
Content-Type: application/json

{
  "room_id": "room-uuid",
  "session_type": "audio_room|video_room|live_stream"
}
```

When `joinApprovalRequired`:

- Viewer: `POST /api/room/join-request` → poll `GET /api/room/join-request/status`  
- Host: `POST /api/room/join-request/respond`  

Mobile already implements this via `JoinApprovalService`. After success, opens `Routes.LIVE_BROADCAST` with `{ isHost: false, roomType, roomData }` — **same as Rooms / Live**.

#### Join response fields mobile needs

```json
{
  "statusCode": 1,
  "data": {
    "_id": "room-uuid",
    "room_id": "room-uuid",
    "type": "audio",
    "name": "Friday Night",
    "hostUserId": "…",
    "join_request_id": "optional",
    "zegoLiveId": "required-for-live_stream",
    "channelName": "…"
  }
}
```

### 3.3 Leave / end (existing — no Call-specific change)

- `POST /api/room/leave`  
- `POST /api/room/end`  
- Live stream end: `POST /api/live-streaming/end`  

---

## 4. Call History — **NEW** APIs required

History today is only partial (Firestore under chat + local cache). Call hub needs a **REST** feed.

### 4.1 List history

```http
GET /api/call/history?filter=all|missed|outgoing|incoming|rooms&call_type=all|voice|video|audio_room|video_room|live_stream&page=1&limit=30
Authorization: Bearer <token>
```

#### Response

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": [
    {
      "id": "history-uuid",
      "kind": "direct_call",
      "direction": "outgoing",
      "status": "completed",
      "callType": "voice",
      "peer": {
        "userId": "user-uuid",
        "name": "Maya",
        "avatar": "/uploads/m.jpg",
        "isOnline": false
      },
      "startedAt": "2026-07-29T08:00:00.000Z",
      "endedAt": "2026-07-29T08:04:12.000Z",
      "durationSeconds": 252,
      "coinsCharged": 126,
      "coinsPerSecond": 0.5,
      "zegoCallId": "call-id",
      "chatRoomId": "chat-room-uuid",
      "canCallBack": true
    },
    {
      "id": "history-uuid-2",
      "kind": "room_join",
      "direction": "outgoing",
      "status": "completed",
      "callType": "audio_room",
      "room": {
        "roomId": "room-uuid",
        "name": "Friday Night",
        "type": "audio",
        "coverImage": "/uploads/cover.jpg",
        "isLiveNow": true
      },
      "startedAt": "2026-07-29T07:10:00.000Z",
      "endedAt": "2026-07-29T07:40:00.000Z",
      "durationSeconds": 1800,
      "canRejoin": true
    }
  ],
  "meta": { "page": 1, "limit": 30, "total": 54, "hasMore": true }
}
```

| Field | Values |
|-------|--------|
| `kind` | `direct_call` \| `room_join` |
| `direction` | `outgoing` \| `incoming` \| `missed` (or status=`missed`) |
| `status` | `ringing` \| `answered` \| `completed` \| `missed` \| `rejected` \| `cancelled` \| `failed` |
| `callType` | `voice` \| `video` \| `audio_room` \| `video_room` \| `live_stream` |

#### Rules

- Persist **direct voice/video** when Call Kit starts/ends (even if chat already writes Firestore — REST is source of truth for History tab).  
- Persist **room joins from Call Live Now** (and ideally all joins) with `kind=room_join`.  
- Soft-delete / hide blocked peers.  
- Sort newest first.

### 4.2 Record / upsert history event (server-driven preferred)

If mobile must report:

```http
POST /api/call/history
Content-Type: application/json

{
  "kind": "direct_call",
  "peerUserId": "user-uuid",
  "callType": "video",
  "direction": "outgoing",
  "status": "completed",
  "startedAt": "…",
  "endedAt": "…",
  "durationSeconds": 120,
  "coinsCharged": 60,
  "zegoCallId": "…",
  "chatRoomId": "…"
}
```

Prefer **server-side** writes from join/leave/charge webhooks so clients cannot forge durations.

### 4.3 Delete / clear (optional)

```http
DELETE /api/call/history/{id}
POST /api/call/history/clear
```

---

## 5. Direct Call — **NEW** / wire existing pieces

1:1 voice/video **already works from chat** via Zego Call Kit + Firestore ring + `POST /api/economy/calling/charge`.  
Call hub dialer needs **user search + callability + start** without requiring an open chat thread first (mobile can still bootstrap chat room under the hood).

### 5.1 Search callable users

```http
GET /api/call/users/search?q={query}&page=1&limit=20
Authorization: Bearer <token>
```

```json
{
  "statusCode": 1,
  "data": [
    {
      "userId": "user-uuid",
      "name": "Maya",
      "username": "maya",
      "avatar": "/uploads/m.jpg",
      "countryCode": "IN",
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

### 5.2 Start direct call (optional REST; signaling can stay Firestore/Zego)

```http
POST /api/call/direct/start
Content-Type: application/json

{
  "calleeUserId": "user-uuid",
  "callType": "voice|video",
  "clientCallId": "zego-call-id"
}
```

```json
{
  "statusCode": 1,
  "data": {
    "callId": "server-call-uuid",
    "zegoCallId": "zego-call-id",
    "chatRoomId": "chat-room-uuid",
    "coinsPerSecond": 0.5,
    "callerPays": true,
    "expiresAt": "2026-07-29T10:00:30.000Z"
  }
}
```

Reject with clear messages when:

- callee busy / offline / blocked  
- callee disabled voice/video  
- insufficient wallet balance  

### 5.3 End / cancel / reject

```http
POST /api/call/direct/end
{ "callId": "…", "reason": "completed|cancelled|rejected|missed|failed" }
```

### 5.4 Billing (existing)

```http
POST /api/economy/calling/charge
```

Keep current contract; History should use charged totals from billing ledger.

### 5.5 Push / FCM for incoming Call-hub dials

Same shape as chat incoming call (callId, caller name/avatar, callType, zegoCallId) so mobile can reuse `ChatIncomingCallCoordinator`.

---

## 6. Discover dating (existing — keep stable)

| Method | Endpoint | Notes |
|--------|----------|--------|
| POST | `/api/pk/dating-onboarding` | Prefs: gender, age, interests |
| GET | `/api/pk/dating-list` | Candidate deck |
| POST | `/api/pk/dating-action` | **Exists but not wired in UI yet** — like / pass / match |

### Recommended dating-action body

```json
{
  "targetUserId": "user-uuid",
  "action": "like|pass|superlike"
}
```

```json
{
  "statusCode": 1,
  "data": {
    "matched": true,
    "matchId": "match-uuid",
    "chatRoomId": "chat-room-uuid",
    "peer": { "userId": "…", "name": "…", "avatar": "…" }
  }
}
```

Mobile still simulates some match UX locally; wiring this API is a follow-up and must **not** break Live Now.

---

## 7. Suggested implementation order for backend

1. **Confirm / harden** `GET /api/room/list` filters (`audio` / `video` / `live_stream` / mixed) — unblocks Live Now polish.  
2. **`GET /api/call/history`** (+ server-side writes on call/room events).  
3. **`GET /api/call/users/search`** + optional **`POST /api/call/direct/start`**.  
4. Wire **`POST /api/pk/dating-action`** for Discover.  
5. Optional **`GET /api/call/live-now`** if Call needs a curated feed separate from Rooms.

---

## 8. Mobile mapping (for QA)

| Mobile action | API / code path |
|---------------|-----------------|
| Open Profile → Call | `Routes.CALL` → `CallView` |
| Live Now load / pull refresh | `RoomRepo.listActiveRooms` → `GET /api/room/list` |
| Live Now card tap | `LiveRoomController.joinRoom` → approval + `POST /api/room/join` → `LIVE_BROADCAST` |
| Discover prefs save | `PkRepo.callOnboarding` |
| Discover deck | `PkRepo.getCallList` |
| History / Direct Call buttons | Stub snackbar until §4–§5 land |
| Chat voice/video today | `ChatCallLauncher` → `CHAT_VOICE_CALL` + charge API |

---

## 9. Compatibility rules

- Do **not** change join payload shapes in a breaking way — Rooms, Live, Join Live, invites, and Call Live Now share them.  
- Prefer additive fields (`sessionKind`, `canJoin`, `meta`) over renaming.  
- When `type=live_stream` is unsupported, mobile falls back to mixed list + client filter; please still fix server filter for correctness.

---

## 10. Open questions for backend

1. Should room joins from Rooms / Live tabs also appear in Call History, or only joins started from Call → Live Now?  
2. Who pays for Direct Call by default (caller always vs host/agency rates)? Confirm `coinsPerSecond` source of truth.  
3. Retention window for history (30 / 90 days)?  
4. Should Discover matches expose “Call now” using Direct Call APIs?

---

**Document path:** `docs/api/QOBO_CALL_MODULE_API.md`  
Share this file with backend as the contract for History + Direct Call; Live Now can ship against existing room list/join today.
