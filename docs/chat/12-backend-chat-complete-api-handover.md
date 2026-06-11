# 12 — Complete Chat API Handover (Backend Team)

**Project:** Qobo One Live  
**Base URL:** `https://my-backend-api-960q.onrender.com`  
**Firebase project:** `qobo1live-914ac`  
**Last updated:** 2026-06-06  

**Audience:** Backend / API team — implement, verify, and return sample responses.  
**Mobile status:** Flutter app already calls most endpoints listed below; new endpoints marked **🆕 NEW**.

---

## How chat works (30-second summary)

| Layer | Responsibility |
| --- | --- |
| **REST + JWT** | Login, permissions, inbox bootstrap, room create, block/delete/mute, reports, FCM |
| **Firestore** | Realtime send/receive messages, typing, presence, read receipts |
| **PostgreSQL** | Users, `Block` table, chat reports, optional message mirror |

Mobile **does not** use Socket.IO for 1:1 DMs. Messages are written to  
`chatRooms/{roomId}/messages/{messageId}` by the client after `POST /api/chat/firebase-token`.

---

## Standard response envelope

All chat APIs should use the same envelope mobile already handles (`statusCode: 1` or `201` = success):

```json
{
  "statusCode": 1,
  "message": "Human-readable message",
  "data": { }
}
```

Legacy `success: true` responses still work but **prefer `statusCode`** for new work.

**Auth header (all protected routes):**

```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

**Common errors:**

| statusCode | HTTP | Meaning |
| --- | --- | --- |
| `0` | 200/400 | Business failure (validation, blocked, not allowed) |
| `401` | 401 | Missing or invalid JWT |
| `403` | 403 | Blocked user, not a room member |
| `404` | 404 | User, room, or message not found |
| `422` | 422 | Business rule (e.g. cannot message stranger) |

---

## API summary table

| Priority | Method | Endpoint | Purpose | Mobile |
| --- | --- | --- | --- | --- |
| **P0** | POST | `/api/chat/firebase-token` | Firebase custom token for Firestore | ✅ Integrated |
| **P0** | POST | `/api/chat/room` | Create/get room + **write Firestore** | ✅ Integrated |
| **P0** | GET | `/api/chat/list` | Inbox threads | ✅ Integrated |
| **P0** | GET | `/api/chat/detail` | Message history (pagination) | ✅ Integrated |
| **P0** | POST | `/api/chat/send` | REST fallback send (optional if Firestore-only) | ✅ Integrated — **404 today** |
| **P0** | POST | `/api/user/block` | Block user (global) | ✅ Repo ready |
| **P0** | POST | `/api/user/unblock` | Unblock user | ✅ Repo ready |
| **P0** | GET | `/api/user/block-list` | Blocked users list | ✅ Repo ready |
| **P1** | 🆕 POST | `/api/chat/delete` | Delete conversation from inbox (for me) | Planned |
| **P1** | 🆕 POST | `/api/chat/clear` | Clear chat history (for me) | Planned |
| **P1** | 🆕 POST | `/api/chat/block` | Block user **from chat** (+ side effects) | Planned |
| **P1** | POST | `/api/chat/report` | Report abusive message | ✅ Integrated |
| **P2** | 🆕 POST | `/api/chat/read` | Mark thread read (unread count) | Planned |
| **P2** | 🆕 POST | `/api/chat/mute` | Mute / unmute notifications | Planned |
| **P2** | 🆕 POST | `/api/chat/archive` | Archive / unarchive thread | Planned |
| **P2** | 🆕 GET | `/api/chat/can-message` | Pre-check before opening chat | Planned |
| **P2** | POST | `/api/user/fcm-token` | Register push token | ✅ Repo ready |
| **P3** | 🆕 DELETE | `/api/chat/message` | Delete single message (for me / everyone) | Future |
| **P3** | 🆕 PATCH | `/api/chat/message` | Edit message (within time window) | Future |

---

## P0 — Core chat (must work for messaging)

### POST `/api/chat/firebase-token`

Issues a Firebase custom token so mobile can sign in with `uid = PostgreSQL User.id`.

**Request:** empty body (user from JWT).

**Response:**

```json
{
  "statusCode": 1,
  "message": "Firebase token issued",
  "data": {
    "firebaseCustomToken": "eyJhbGciOiJSUzI1NiIs...",
    "firebaseUid": "logged-in-user-uuid"
  }
}
```

**Backend requirements:**

- Firebase Admin SDK initialized on Render with service account for **`qobo1live-914ac`**
- `admin.auth().createCustomToken(userId)` where `userId` = JWT user id
- Reject if user deleted/suspended

**Known issue:** Was returning `statusCode: 0` — "Firebase Admin SDK is not initialized".

---

### POST `/api/chat/room`

Create or return existing 1:1 chat room. **Must write Firestore via Admin SDK.**

**Request (mobile sends today):**

```json
{
  "type": "direct",
  "target_id": "partner-user-uuid"
}
```

> Also accept `targetUserId` as alias for backward compatibility.

**Response:**

```json
{
  "statusCode": 1,
  "message": "Chat room ready",
  "data": {
    "roomId": "uuid-a_uuid-b",
    "type": "direct",
    "isNew": true,
    "firestorePath": "chatRooms/uuid-a_uuid-b",
    "peer": {
      "id": "uuid-b",
      "name": "Jane Doe",
      "displayPicture": "/uploads/profiles/jane.png"
    }
  }
}
```

**Backend must:**

1. Validate JWT → `userIdA`
2. Load `target_id` → `userIdB`
3. **Block check** — query `Block` table both directions; if blocked → `403`
4. Compute stable `roomId` (e.g. sorted UUIDs joined: `uuid-a_uuid-b`)
5. If room missing, **Admin SDK create:**
   - `chatRooms/{roomId}` with `memberIds: [userIdA, userIdB]`, `isActive: true`
   - `userChats/{userIdA}/rooms/{roomId}` inbox row
   - `userChats/{userIdB}/rooms/{roomId}` inbox row
6. Return `roomId` + `firestorePath`

**Error — blocked:**

```json
{
  "statusCode": 0,
  "message": "You cannot message this user",
  "data": null
}
```

See [03 — Firestore schema](./03-firestore-schema.md) and [firestore.rules](./firestore.rules).

---

### GET `/api/chat/list`

Inbox for Messages tab.

**Response `data` array — each item should include `roomId`:**

```json
{
  "statusCode": 1,
  "message": "Inbox threads fetched",
  "data": [
    {
      "id": "partner-user-uuid",
      "roomId": "uuid-a_uuid-b",
      "lastMessage": "Hello there!",
      "lastMessageTime": "2026-06-06T12:30:00.000Z",
      "lastMessageType": "text",
      "unreadCount": 2,
      "isMuted": false,
      "isArchived": false,
      "recipient": {
        "id": "partner-user-uuid",
        "name": "Jane Doe",
        "displayPicture": "/uploads/profiles/jane.png",
        "gender": "female",
        "level": 5
      }
    }
  ]
}
```

**Backend:** Exclude threads where peer is blocked (either direction). Exclude `isArchived: true` unless client requests archived list.

---

### GET `/api/chat/detail`

Paginated history between current user and partner. Used for cold start / scroll-up.

**Query:**

```
GET /api/chat/detail?target_id={partnerUuid}&page=1
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "Chat history fetched",
  "data": [
    {
      "id": "message-uuid",
      "messageId": "message-uuid",
      "senderId": "partner-user-uuid",
      "content": { "text": "Hello there!" },
      "type": "text",
      "createdAt": "2026-06-06T10:00:00.000Z",
      "status": {
        "my-user-uuid": {
          "deliveredAt": "2026-06-06T10:00:05.000Z",
          "readAt": "2026-06-06T10:01:00.000Z"
        }
      }
    }
  ]
}
```

**Note:** Live tail comes from Firestore after Phase 3. REST is for bootstrap + older pages.

---

### POST `/api/chat/send` (optional fallback)

Mobile calls this only when Firebase sign-in or Firestore write fails.

**Request:**

```json
{
  "target_id": "partner-user-uuid",
  "content": "Hello",
  "type": "text",
  "room_id": "uuid-a_uuid-b"
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "Message sent",
  "data": {
    "messageId": "msg_abc123",
    "roomId": "uuid-a_uuid-b",
    "createdAt": "2026-06-06T12:30:00.000Z"
  }
}
```

**Backend must:** Write message to Firestore (Admin SDK) **or** PostgreSQL + mirror to Firestore; update inbox `lastMessage` for both users.

**Known issue:** Returns **404** today. Either implement or document **Firestore-only** path.

---

## P0 — Block user (global moderation)

These endpoints already exist in mobile (`UserRepo`). Backend must enforce them in **all chat flows**.

### POST `/api/user/block`

Block a user app-wide (not only chat).

**Request:**

```json
{
  "target_id": "user-uuid-to-block"
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "User blocked successfully",
  "data": {
    "id": "block-relationship-uuid",
    "blockerId": "my-user-uuid",
    "blockedId": "user-uuid",
    "createdAt": "2026-06-06T12:30:00.000Z"
  }
}
```

**Required side effects when blocking from chat or settings:**

| Action | Detail |
| --- | --- |
| PostgreSQL | Insert into `Block` table |
| Inbox | Hide thread for **blocker** in `GET /api/chat/list` |
| Room create | `POST /api/chat/room` → **403** for either direction |
| Firestore | Optional: set `userChats/{blocker}/rooms/{roomId}.isBlocked = true` |
| Firestore | Optional: set `chatRooms/{roomId}.isActive = false` (do not delete messages) |
| Push | Stop FCM to blocker from blocked user |

---

### POST `/api/user/unblock`

**Request:**

```json
{
  "target_id": "user-uuid"
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "User unblocked successfully",
  "data": { "count": 1 }
}
```

**Side effects:** Remove `Block` row; restore ability to `POST /api/chat/room` (room may still exist).

---

### GET `/api/user/block-list`

**Response:**

```json
{
  "statusCode": 1,
  "message": "Block list fetched",
  "data": [
    {
      "id": "blocked-user-uuid",
      "name": "Intruder",
      "displayPicture": "/uploads/profiles/intruder.png",
      "gender": "not_specified",
      "level": 1,
      "blockedAt": "2026-06-06T10:00:00.000Z"
    }
  ]
}
```

---

## P1 — Delete chat & block from chat (🆕 NEW — requested)

Mobile will add a chat options menu: **Delete chat**, **Block user**, **Report**.

### POST `/api/chat/delete` 🆕

**Delete conversation for me** — removes thread from inbox. Does **not** delete messages for the other user (WhatsApp-style).

**Request:**

```json
{
  "room_id": "uuid-a_uuid-b",
  "target_id": "partner-user-uuid"
}
```

Either `room_id` or `target_id` required; prefer `room_id` when known.

**Response:**

```json
{
  "statusCode": 1,
  "message": "Chat deleted",
  "data": {
    "roomId": "uuid-a_uuid-b",
    "deletedAt": "2026-06-06T12:30:00.000Z"
  }
}
```

**Backend must:**

1. Verify caller is member of `chatRooms/{roomId}`
2. **Soft-delete** inbox row for caller only:
   - Firestore: `userChats/{myUserId}/rooms/{roomId}` → set `isDeleted: true`, `deletedAt`, clear `unreadCount`
   - Or delete the inbox doc (mobile will not show until new message arrives)
3. PostgreSQL (optional): `ChatThreadDeletion` audit row `{ userId, roomId, deletedAt }`
4. **Do not** delete `chatRooms/{roomId}` or `messages` subcollection
5. If peer sends a new message later → recreate/update inbox row (standard WhatsApp behaviour)

**Mobile after success:** Navigate back to Messages tab; remove thread from local list.

---

### POST `/api/chat/clear` 🆕

**Clear all messages for me** in a thread (optional separate action from delete).

**Request:**

```json
{
  "room_id": "uuid-a_uuid-b",
  "target_id": "partner-user-uuid"
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "Chat cleared",
  "data": {
    "roomId": "uuid-a_uuid-b",
    "clearedAt": "2026-06-06T12:30:00.000Z"
  }
}
```

**Backend options (pick one and document):**

| Option | Implementation |
| --- | --- |
| **A — Per-user watermark (recommended)** | Store `userChats/{userId}/rooms/{roomId}.clearedAt`; mobile + `GET /api/chat/detail` filter messages before that time |
| **B — Mark deletedFor** | Batch-update each message `delete.deletedFor` array via Admin SDK (expensive for long threads) |

---

### POST `/api/chat/block` 🆕

**Block user from chat screen** — convenience wrapper that combines block + chat cleanup.

**Request:**

```json
{
  "target_id": "partner-user-uuid",
  "room_id": "uuid-a_uuid-b",
  "delete_chat": true
}
```

| Field | Required | Description |
| --- | --- | --- |
| `target_id` | Yes | User to block |
| `room_id` | No | Room to hide from inbox |
| `delete_chat` | No | Default `true` — also run delete-chat side effects |

**Response:**

```json
{
  "statusCode": 1,
  "message": "User blocked",
  "data": {
    "blockedId": "partner-user-uuid",
    "roomId": "uuid-a_uuid-b",
    "chatDeleted": true
  }
}
```

**Backend must (in order):**

1. Call same logic as `POST /api/user/block`
2. If `delete_chat` → same logic as `POST /api/chat/delete`
3. Return combined result

> **Alternative:** Mobile can call `POST /api/user/block` then `POST /api/chat/delete` separately. Provide `/api/chat/block` if you want one atomic operation.

---

## P1 — Report message (existing)

### POST `/api/chat/report`

**Request:**

```json
{
  "roomId": "uuid-a_uuid-b",
  "messageId": "msg_abc123",
  "reason": "spam"
}
```

**Allowed `reason` values (suggested enum):**

`spam` | `harassment` | `hate_speech` | `nudity` | `scam` | `other`

**Response:**

```json
{
  "statusCode": 1,
  "message": "Report submitted",
  "data": {
    "reportId": "report-uuid"
  }
}
```

Store in PostgreSQL for moderation queue. Optionally flag message in Firestore: `moderation.reported = true`.

---

## P2 — Inbox UX APIs (🆕 NEW — recommended)

### POST `/api/chat/read` 🆕

Mark thread as read (reset unread badge).

**Request:**

```json
{
  "room_id": "uuid-a_uuid-b",
  "target_id": "partner-user-uuid"
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "Marked as read",
  "data": {
    "roomId": "uuid-a_uuid-b",
    "unreadCount": 0
  }
}
```

**Backend:** Update `userChats/{userId}/rooms/{roomId}.unreadCount = 0`.  
Mobile also writes read receipts to Firestore `status.{userId}.readAt` when chat is open.

---

### POST `/api/chat/mute` 🆕

**Request:**

```json
{
  "room_id": "uuid-a_uuid-b",
  "muted": true
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "Chat muted",
  "data": {
    "roomId": "uuid-a_uuid-b",
    "isMuted": true
  }
}
```

**Backend:** Update `userChats/{userId}/rooms/{roomId}.isMuted`. Skip FCM for muted threads.

---

### POST `/api/chat/archive` 🆕

**Request:**

```json
{
  "room_id": "uuid-a_uuid-b",
  "archived": true
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "Chat archived",
  "data": {
    "roomId": "uuid-a_uuid-b",
    "isArchived": true
  }
}
```

Hide from main inbox; include in archived section when product adds it.

---

### GET `/api/chat/can-message` 🆕

Pre-check before opening chat from Discover / profile.

**Query:**

```
GET /api/chat/can-message?target_id={partnerUuid}
```

**Response — allowed:**

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": {
    "canMessage": true,
    "reason": null,
    "roomId": "uuid-a_uuid-b"
  }
}
```

**Response — blocked:**

```json
{
  "statusCode": 0,
  "message": "You cannot message this user",
  "data": {
    "canMessage": false,
    "reason": "blocked",
    "roomId": null
  }
}
```

**`reason` enum:** `blocked` | `not_found` | `not_allowed` | `suspended`

---

## P2 — Push notifications

### POST `/api/user/fcm-token`

**Request:**

```json
{
  "token": "fcm-device-token",
  "platform": "android"
}
```

`platform`: `"android"` | `"ios"`

**Backend:** Store token per user/device. On new Firestore message (Cloud Function trigger), send FCM to recipient unless `isMuted` or blocked.

---

## P3 — Message-level actions (future)

Can be **Firestore-only** (mobile writes with Security Rules) or REST for audit.

### DELETE `/api/chat/message` 🆕 (future)

**Request body:**

```json
{
  "room_id": "uuid-a_uuid-b",
  "message_id": "msg_abc123",
  "scope": "me"
}
```

`scope`: `"me"` | `"everyone"` (everyone only within 15 minutes, sender only)

### PATCH `/api/chat/message` 🆕 (future)

Edit text within 15 minutes. Update Firestore `content.text` + `edit.isEdited`, `edit.editedAt`.

---

## Firestore paths reference

```
chatRooms/{roomId}                          ← Admin SDK on room create
chatRooms/{roomId}/messages/{messageId}     ← Mobile writes on send
chatRooms/{roomId}/typing/{userId}          ← Mobile (typing)
userChats/{userId}/rooms/{roomId}           ← Admin SDK on room create; mobile updates preview
users/{userId}/presence/main                ← Mobile (online/offline)
```

**Security Rules:** Publish from [firestore.rules](./firestore.rules) in Firebase Console.

**Message document (mobile write):**

```json
{
  "messageId": "auto-id",
  "roomId": "uuid-a_uuid-b",
  "senderId": "my-user-uuid",
  "type": "text",
  "content": { "text": "Hello" },
  "deliveryState": "sent",
  "status": {
    "partner-user-uuid": {}
  },
  "createdAt": "<serverTimestamp>",
  "clientCreatedAt": "<serverTimestamp>",
  "clientMessageId": "1700000000000_my-user-uuid"
}
```

---

## Block & delete — enforcement matrix

| Action | `POST /api/chat/room` | `GET /api/chat/list` | Firestore message write | FCM to recipient |
| --- | --- | --- | --- | --- |
| User A blocks B | A cannot create room with B | Hide B for A | B can still write* | Stop to A |
| A deletes chat | — | Hide for A | Both can still write | — |
| A clears chat | — | — | Filter by `clearedAt` for A | — |

\*After block, mobile should not open chat; backend must return 403 on room create. Consider Cloud Function to reject writes from blocked users if needed.

---

## Implementation checklist for backend

### Week 1 — Messaging works

- [ ] Firebase Admin SDK on Render (`qobo1live-914ac` service account)
- [ ] `POST /api/chat/firebase-token` returns valid token
- [ ] `POST /api/chat/room` writes `chatRooms` + `userChats` in Firestore
- [ ] Publish [firestore.rules](./firestore.rules)
- [ ] `GET /api/chat/list` includes `roomId` on every row
- [ ] Block check on `POST /api/chat/room`

### Week 2 — Safety & inbox

- [ ] `POST /api/user/block` / `unblock` / `block-list` verified
- [ ] 🆕 `POST /api/chat/delete`
- [ ] 🆕 `POST /api/chat/block` (or document two-call flow)
- [ ] `POST /api/chat/report` with reason enum
- [ ] 🆕 `POST /api/chat/read`

### Week 3 — Polish

- [ ] `POST /api/chat/send` implemented **or** documented as unused
- [ ] 🆕 `POST /api/chat/mute`, `/api/chat/archive`
- [ ] 🆕 `GET /api/chat/can-message`
- [ ] `POST /api/user/fcm-token` + Cloud Function for push on new message
- [ ] 🆕 `POST /api/chat/clear` (watermark approach)

---

## Test script (curl)

Replace `TOKEN` and UUIDs.

```bash
BASE="https://my-backend-api-960q.onrender.com"
TOKEN="your-jwt"
PARTNER="partner-uuid"

# 1. Firebase token
curl -s -X POST "$BASE/api/chat/firebase-token" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'

# 2. Create room
curl -s -X POST "$BASE/api/chat/room" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"direct","target_id":"'"$PARTNER"'"}'

# 3. Inbox
curl -s "$BASE/api/chat/list" \
  -H "Authorization: Bearer $TOKEN"

# 4. Block from chat
curl -s -X POST "$BASE/api/chat/block" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"'"$PARTNER"'","delete_chat":true}'

# 5. Delete chat only
curl -s -X POST "$BASE/api/chat/delete" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"'"$PARTNER"'"}'
```

**Verify in Firebase Console:** After step 2 → `chatRooms/{roomId}` exists with `memberIds`. After mobile send → `messages` subcollection has documents.

---

## Related docs in this repo

| Doc | Content |
| --- | --- |
| [09 — Backend blockers](./09-backend-action-items-chat-blockers.md) | Live testing issues (Firestore empty, send 404) |
| [10 — Inbox Firestore handover](./10-backend-firestore-inbox-list-handover.md) | `userChats` structure |
| [03 — Firestore schema](./03-firestore-schema.md) | Full document shapes |
| [firestore.rules](./firestore.rules) | Security Rules to deploy |
| [11 — Phase 5 signals](./11-phase5-typing-presence-read-receipts.md) | Typing, presence, receipts |

---

## What we need back from backend team

1. Confirmation which **🆕 NEW** endpoints will be implemented (and ETA)
2. Sample JSON responses for `delete`, `block`, `read`, `mute`
3. Screenshot of Firestore after `POST /api/chat/room` + one test message
4. Confirmation Firestore Security Rules deployed (paste JSON)
5. Decision: **Firestore-only send** vs implement `POST /api/chat/send`

**Contact:** Reply in shared channel with deployed base URL and test user credentials for mobile re-test.
