# Host Join Approval (Rooms + Live Streaming) — Backend Requirements

**App:** `qobo_one_live` (Flutter)  
**Audience:** Backend team  
**Date:** 2026-07-23  
**Feature:** When a user tries to join an **audio/video room** or **live stream**, the **host must Approve or Reject**. Only after **Approve** may the user enter.

---

## 1. Goal

| Today (mobile) | Target |
|----------------|--------|
| User taps Join → `POST /api/room/join` (or live audience join) → enters immediately | User taps Join → **pending approval** → host Approve/Reject → enter **only if approved** |

This must work for:

1. **Audio room**
2. **Video room**
3. **Live streaming** (Zego live audience)

Optional product modes (backend should support flags so mobile can toggle later):

| Mode | Behavior |
|------|----------|
| `open` (default today) | Auto-join, no host approval |
| `approval_required` | Every joiner waits for host/admin approval |
| `followers_only` | Existing `onlyFollows` gate (already partially documented for live create) |
| `private` + password / invite | Existing private-room / invite flows |

**Ask backend to confirm:** Is approval required for **all** public rooms, or only when host enables a setting (recommended)?

**Mobile recommendation:** Add room/live setting `joinApprovalRequired: true|false` (default `false` for backward compatibility). When `true`, enforce the flow below.

---

## 2. Current mobile join paths (no approval today)

| Surface | Current API | Result |
|---------|-------------|--------|
| Rooms list / Discover / typed join | `POST /api/room/join` | Immediate entry |
| Room invite push Join | `POST /api/room/join` (+ `invitation_id`) | Immediate entry |
| Live stream list / push Join | Opens live broadcast; may call `joinRoom` for counts | Immediate watch |
| Mic seat “Request” | `POST /api/room/mic-action` `request_to_speak` | Seat request only — **not** room admission |

**Important:** Mic request ≠ join approval. This feature is about **entering the room/stream at all**.

---

## 3. Target user experience

### 3.1 Viewer / audience

1. Taps **Join** on a room or live stream that requires approval.
2. Sees **“Waiting for host approval…”** (cannot hear/see content yet; no Zego login yet).
3. Host Approves → mobile receives realtime/push → then join succeeds → enter room/live UI.
4. Host Rejects → mobile shows “Host declined your request” → stay outside.

### 3.2 Host (and room admin, if allowed)

1. While live, receives **Join request** (in-app sheet + push if background).
2. Sees requester name, avatar, user id, room/live title.
3. Actions: **Approve** / **Reject**.
4. Optional: Approve all / Reject all (nice-to-have).

---

## 4. Proposed API design

Use a dedicated **join-request** resource so private invites and open joins stay separate.

### 4.1 Create join request (viewer)

```http
POST /api/room/join-request
Authorization: Bearer <token>
```

**Body:**

```json
{
  "room_id": "room-or-live-backend-uuid",
  "session_type": "audio_room"
}
```

| Field | Values | Notes |
|-------|--------|-------|
| `room_id` | UUID | Backend room id for audio/video **or** live stream room record |
| `session_type` | `audio_room` \| `video_room` \| `live_stream` | Helps host UI + analytics |

**Responses:**

#### A) Approval required → pending

```json
{
  "statusCode": 1,
  "message": "Waiting for host approval",
  "data": {
    "request_id": "join-req-uuid",
    "room_id": "room-uuid",
    "session_type": "audio_room",
    "status": "pending",
    "expires_at": "2026-07-23T17:05:00.000Z",
    "poll_after_ms": 2000
  }
}
```

Mobile stays on waiting screen; does **not** open Zego yet.

#### B) Approval not required → treat as immediate join (compat)

```json
{
  "statusCode": 1,
  "message": "Joined",
  "data": {
    "status": "approved",
    "auto_joined": true,
    "join": { "...same payload as POST /api/room/join success..." }
  }
}
```

#### C) Already pending

```json
{
  "statusCode": 1,
  "message": "Join request already pending",
  "data": {
    "request_id": "existing-join-req-uuid",
    "status": "pending",
    "expires_at": "2026-07-23T17:05:00.000Z"
  }
}
```

#### D) Rejected / blocked

```json
{
  "statusCode": 0,
  "message": "Host rejected your join request",
  "data": {
    "request_id": "join-req-uuid",
    "status": "rejected"
  }
}
```

#### E) Banned / kicked cooldown

```json
{
  "statusCode": 0,
  "message": "You cannot join this room right now",
  "data": {
    "status": "blocked",
    "reason": "kicked",
    "blocked_until": "2026-07-23T18:00:00.000Z"
  }
}
```

---

### 4.2 Change existing `POST /api/room/join` (required)

Keep the endpoint, but enforce approval:

| Case | Behavior |
|------|----------|
| Room has `joinApprovalRequired=false` | Current behavior (immediate join) |
| Room has `joinApprovalRequired=true` and **no** approved request | Return `statusCode: 0` with `code: "APPROVAL_REQUIRED"` **or** create pending request and return pending payload (prefer dedicated `join-request`) |
| Approved `request_id` / token provided | Allow join |

**Preferred mobile contract when approval is on:**

1. Viewer calls `POST /api/room/join-request`
2. After approve, viewer calls:

```http
POST /api/room/join
```

```json
{
  "room_id": "room-uuid",
  "join_request_id": "join-req-uuid"
}
```

Only then return Zego / seat / stream payload.

For **live streaming**, same pattern:

```json
{
  "room_id": "live-room-uuid",
  "join_request_id": "join-req-uuid",
  "session_type": "live_stream"
}
```

If live uses a separate join endpoint today, apply the same `join_request_id` gate there.

---

### 4.3 Host: list pending join requests

```http
GET /api/room/join-requests?room_id={uuid}&status=pending
Authorization: Bearer <host-token>
```

**Response:**

```json
{
  "statusCode": 1,
  "data": {
    "items": [
      {
        "request_id": "join-req-uuid",
        "room_id": "room-uuid",
        "session_type": "live_stream",
        "status": "pending",
        "created_at": "2026-07-23T17:00:00.000Z",
        "expires_at": "2026-07-23T17:05:00.000Z",
        "user": {
          "id": "idc6740290",
          "name": "Sunil",
          "avatar": "https://...",
          "level": 5,
          "gender": "male"
        }
      }
    ]
  }
}
```

Only **host** (and optionally room admins with `isAdmin=true`) may call this.

---

### 4.4 Host: approve / reject

```http
POST /api/room/join-request/respond
Authorization: Bearer <host-or-admin-token>
```

**Body:**

```json
{
  "room_id": "room-uuid",
  "request_id": "join-req-uuid",
  "action": "approve"
}
```

`action`: `"approve"` | `"reject"`.

**Approve response:**

```json
{
  "statusCode": 1,
  "message": "Approved",
  "data": {
    "request_id": "join-req-uuid",
    "status": "approved",
    "approved_at": "2026-07-23T17:01:10.000Z",
    "join_token": "optional-short-lived-token",
    "user_id": "idc6740290"
  }
}
```

**Reject response:**

```json
{
  "statusCode": 1,
  "message": "Rejected",
  "data": {
    "request_id": "join-req-uuid",
    "status": "rejected",
    "rejected_at": "2026-07-23T17:01:10.000Z"
  }
}
```

**Side effects (required):**

1. Persist status.
2. Notify requester via **FCM + Socket**.
3. On approve, allow subsequent `POST /api/room/join` with that `join_request_id` (single-use or short TTL, e.g. 60–120s).

---

### 4.5 Viewer: cancel own pending request

```http
POST /api/room/join-request/cancel
```

```json
{
  "room_id": "room-uuid",
  "request_id": "join-req-uuid"
}
```

Notify host (remove from pending list / socket `join_request_cancelled`).

---

### 4.6 Viewer: poll request status (fallback if socket delayed)

```http
GET /api/room/join-request/status?request_id={uuid}
```

```json
{
  "statusCode": 1,
  "data": {
    "request_id": "join-req-uuid",
    "status": "approved",
    "room_id": "room-uuid",
    "session_type": "audio_room",
    "expires_at": "2026-07-23T17:05:00.000Z"
  }
}
```

`status`: `pending` | `approved` | `rejected` | `expired` | `cancelled`.

---

### 4.7 Host setting (recommended)

On create/update room + live create:

```json
{
  "joinApprovalRequired": true
}
```

Expose on room list / detail / seats / live payload so mobile knows whether to call `join-request` vs direct join.

Also allow toggle mid-session:

```http
POST /api/room/settings
```

```json
{
  "room_id": "room-uuid",
  "joinApprovalRequired": true
}
```

---

## 5. Live streaming specifics

Live streaming must use the **same join-request model** keyed by the live room’s backend `room_id`.

| Step | API |
|------|-----|
| Audience wants to watch approval-required live | `POST /api/room/join-request` with `session_type: "live_stream"` |
| Host approves | `POST /api/room/join-request/respond` |
| Audience enters Zego live channel | `POST /api/room/join` (or live join) **with** `join_request_id` |

Do **not** let audience connect to Zego live AppId/channel before approval (prevents peeking).

If `onlyFollows=true` and user is not a follower → reject before creating a join request.

---

## 6. Push notification contract (FCM)

Mobile does **not** handle these types yet. Please send them so we can wire Accept UI + waiting redirect.

All `data` values must be **strings**.

### 6.1 New types

| `type` | Recipient | Purpose |
|--------|-----------|---------|
| `join_request` | Host (+ room admins) | New viewer wants to join |
| `join_approved` | Viewer | Host approved → proceed to join |
| `join_rejected` | Viewer | Host rejected |
| `join_request_expired` | Viewer (+ host optional) | Timed out waiting |

### 6.2 Host receives `join_request`

Android: data-only high priority.  
iOS: alert + category `JOIN_REQUEST` with **Approve** / **Reject**.

```json
{
  "token": "<host-fcm-token>",
  "data": {
    "type": "join_request",
    "notification_id": "unique-event-id",
    "request_id": "join-req-uuid",
    "room_id": "room-uuid",
    "session_type": "audio_room",
    "room_title": "Star Host Test's Room",
    "requester_id": "idc6740290",
    "requester_name": "Sunil",
    "requester_avatar": "https://...",
    "expires_at": "2026-07-23T17:05:00.000Z"
  },
  "android": {
    "priority": "high",
    "ttl": 300000
  }
}
```

**Planned mobile actions:**
- Approve → `POST /api/room/join-request/respond` `{ action: "approve" }`
- Reject → same with `{ action: "reject" }`
- Tap body → open host room + pending requests sheet

### 6.3 Viewer receives `join_approved`

```json
{
  "type": "join_approved",
  "notification_id": "unique-event-id",
  "request_id": "join-req-uuid",
  "room_id": "room-uuid",
  "session_type": "live_stream",
  "room_title": "Star Host Test's Room",
  "host_id": "host-user-id",
  "host_name": "Star Host Test"
}
```

**Planned mobile redirect:** call `POST /api/room/join` with `join_request_id`, then open `LIVE_BROADCAST` (room or live UI based on `session_type`).

### 6.4 Viewer receives `join_rejected`

```json
{
  "type": "join_rejected",
  "notification_id": "unique-event-id",
  "request_id": "join-req-uuid",
  "room_id": "room-uuid",
  "session_type": "audio_room",
  "message": "Host declined your request to join"
}
```

---

## 7. Socket.IO events (required for in-room UX)

While host is live, push alone is slow. Emit:

| Event | To | Payload |
|-------|----|---------|
| `join_request` | Host / admins (user + room channel) | Same fields as FCM (object JSON) |
| `join_request_cancelled` | Host / admins | `{ request_id, room_id, user_id }` |
| `join_approved` | Requester user channel | `{ request_id, room_id, session_type }` |
| `join_rejected` | Requester user channel | `{ request_id, room_id, reason? }` |
| `join_request_expired` | Both | `{ request_id, room_id }` |

Mobile already connects with `register_user` and `join_room` / `joinRoom`.

---

## 8. Interaction with existing flows

| Existing feature | How it should interact |
|------------------|------------------------|
| **Private room password** | Password check first; if pass + approval required → still create join request |
| **Room invite push (`room_invite`)** | Invite can **auto-approve** that user (skip waiting) OR still require host approval — **please decide** |
| **Follower live alerts** | Join button must go through approval when enabled |
| **Mic `request_to_speak`** | Only after user is **already inside** the room |
| **Kick** | Kicked users should not re-enter without new approval; optional cooldown |
| **Room admin (`isAdmin`)** | Confirm if admins can approve join requests like host |

---

## 9. Security rules

1. Do not return Zego tokens / channel ids until status is `approved` and join succeeds.
2. `join_request_id` must be single-use or short-lived after approve.
3. Only host/admin of that `room_id` can respond.
4. Requester can only cancel their own request.
5. Expired pending requests auto-status `expired`.
6. Rate-limit join requests per user/room (e.g. 1 pending at a time; retry after reject cooldown).

---

## 10. Suggested DB fields (guidance)

**Room / Live settings**

- `joinApprovalRequired` boolean default `false`

**JoinRequest**

- `id` (request_id)
- `roomId`
- `sessionType` (`audio_room` | `video_room` | `live_stream`)
- `userId` (requester)
- `status` (`pending` | `approved` | `rejected` | `expired` | `cancelled`)
- `createdAt`, `expiresAt`, `respondedAt`
- `respondedBy` (host/admin user id)

---

## 11. Mobile implementation plan (after backend ready)

1. If room/live payload `joinApprovalRequired == true`:
   - Call `join-request` instead of immediate join.
   - Show waiting UI.
2. Host room overlay: pending join requests list + Approve/Reject.
3. Add FCM types to `PushNotificationTypes` + handlers.
4. Socket listeners on host + requester.
5. On `join_approved`: call `join` with `join_request_id` → open broadcast UI.

Until backend ships this, mobile cannot enforce host approval safely (client-only gates can be bypassed).

---

## 12. Acceptance checklist (backend QA)

- [ ] Host can enable `joinApprovalRequired` on audio/video/live.
- [ ] Viewer join creates pending request; no Zego access yet.
- [ ] Host gets FCM `join_request` (killed/background) and socket event (foreground).
- [ ] Approve → viewer gets `join_approved` → join with `join_request_id` succeeds.
- [ ] Reject → viewer cannot join; clear error.
- [ ] Expired request cannot be approved.
- [ ] Open rooms (`joinApprovalRequired=false`) still join instantly (no regression).
- [ ] Live stream audience cannot watch before approval.
- [ ] Room invite behavior documented (auto-approve vs still ask host).
- [ ] Admins (optional) can approve when `isAdmin=true`.

---

## 13. Open questions for backend

Please answer:

1. Default: approval off (setting) or always on for all rooms/lives?
2. Can room admins approve, or host only?
3. Does an accepted **room invite** bypass approval?
4. Pending TTL — 2 min / 5 min?
5. After reject, cooldown before re-request?
6. Exact endpoint names — OK to use section 4 as-is?
7. One shared join-request API for room + live, or separate live endpoints?
8. Should audiences already inside see a “waiting users” count?

---

## 14. Summary

| Item | Needed from backend |
|------|---------------------|
| Setting | `joinApprovalRequired` on room/live |
| APIs | `join-request`, `respond`, `cancel`, `status`, list pending; gate `join` |
| Push | `join_request`, `join_approved`, `join_rejected` (+ optional expired) |
| Socket | Same events for realtime host/viewer UX |
| Security | No media tokens before approve |

This is the full product + API + push contract for **host approval before joining rooms and live streaming**. Once confirmed, mobile can implement waiting UI, host inbox, and push/socket redirection against this doc.
