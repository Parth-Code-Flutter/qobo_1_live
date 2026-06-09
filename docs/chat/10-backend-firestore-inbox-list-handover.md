# Backend handover — Firestore chat inbox list for logged-in user

**To:** Backend team  
**From:** Mobile team  
**Date:** 2026-06-08  
**Firebase project:** `qobo1live-914ac`  
**Base URL:** `https://my-backend-api-960q.onrender.com`

---

## Request (what we need)

Implement and maintain **per-user chat inbox data in Firestore** so the mobile app can list all conversations for the **currently logged-in user**, each row keyed by **`roomId`**, with last message preview, time, and unread count.

Mobile already uses:

- `POST /api/chat/room` → opens a chat (returns `roomId`, `firestorePath`)
- `GET /api/chat/list` → inbox on Messages tab (REST today)
- Firestore realtime messages in `chatRooms/{roomId}/messages`

We need Firestore inbox rows populated and kept in sync when rooms are created and messages are sent.

---

## Firestore data model (source of truth for inbox)

### Path for listing chats for user `{userId}`

```
userChats/{userId}/rooms/{roomId}
```

- `{userId}` = PostgreSQL `User.id` = Firebase Auth `uid` (same UUID string)
- `{roomId}` = direct room id, e.g. `uuid-a_uuid-b` (sorted pair or your existing convention)

### List query (mobile or backend)

**All inbox threads for current user:**

```
Collection: userChats/{userId}/rooms
Order by:   lastMessageAt desc
Limit:      20–50 (paginate with startAfter)
```

**Single thread by room id:**

```
Document: userChats/{userId}/rooms/{roomId}
```

### Required document shape

```json
{
  "roomId": "d72d18a2-1489-4781-b42e-7f4b9c371921_idc2210865",
  "type": "direct",
  "peerId": "idc2210865",
  "title": "New Host 6",
  "photoUrl": "/uploads/host_real_photo-1780748882753-149243517.jpg",
  "lastMessagePreview": "Hi",
  "lastMessageAt": "2026-06-08T10:00:00.000Z",
  "lastMessageType": "text",
  "lastMessageSenderId": "d72d18a2-1489-4781-b42e-7f4b9c371921",
  "unreadCount": 0,
  "isPinned": false,
  "isMuted": false,
  "isArchived": false,
  "updatedAt": "2026-06-08T10:00:00.000Z"
}
```

| Field | Purpose |
| --- | --- |
| `roomId` | Open chat without calling `POST /api/chat/room` again |
| `peerId` | Partner user id (maps to mobile `targetId`) |
| `title` / `photoUrl` | Inbox row display (denormalized from user profile) |
| `lastMessagePreview` | Last message snippet |
| `lastMessageAt` | Sort inbox newest first |
| `unreadCount` | Badge on inbox row |

Parent room document (required for Security Rules + membership):

```
chatRooms/{roomId}
```

```json
{
  "roomId": "d72d18a2-1489-4781-b42e-7f4b9c371921_idc2210865",
  "type": "direct",
  "memberIds": ["d72d18a2-1489-4781-b42e-7f4b9c371921", "idc2210865"],
  "memberCount": 2,
  "isActive": true,
  "lastMessage": {
    "messageId": "msg_xyz",
    "senderId": "d72d18a2-1489-4781-b42e-7f4b9c371921",
    "type": "text",
    "preview": "Hi",
    "createdAt": "2026-06-08T10:00:00.000Z"
  },
  "updatedAt": "2026-06-08T10:00:00.000Z"
}
```

---

## When backend must write / update Firestore

### 1. On `POST /api/chat/room` (create or return existing room)

Using **Firebase Admin SDK**, upsert for **both** members:

```
chatRooms/{roomId}
userChats/{userIdA}/rooms/{roomId}
userChats/{userIdB}/rooms/{roomId}
```

Each `userChats` row: `peerId` = the **other** user, `title`/`photoUrl` from that user’s profile.

### 2. On new message (Firestore write from mobile or Cloud Function)

When a message is created at `chatRooms/{roomId}/messages/{messageId}`:

| Update | Action |
| --- | --- |
| `chatRooms/{roomId}.lastMessage` | Set preview, sender, time |
| `chatRooms/{roomId}.updatedAt` | Server timestamp |
| `userChats/{senderId}/rooms/{roomId}` | Update `lastMessagePreview`, `lastMessageAt`, `lastMessageSenderId` |
| `userChats/{receiverId}/rooms/{roomId}` | Same + **increment `unreadCount`** |
| Receiver offline | Optional: send FCM (Phase 6) |

**Recommended:** Cloud Function `onCreate` on `chatRooms/{roomId}/messages/{messageId}` so inbox stays correct even if mobile only writes the message doc.

### 3. On open chat / mark read (optional REST or client)

When user opens `chatRooms/{roomId}`:

```
userChats/{userId}/rooms/{roomId}.unreadCount = 0
```

Can be client `update` (allowed by current Security Rules) or `POST /api/chat/read` if you add it.

---

## Architecture options (pick one or hybrid)

### Option A — Mobile reads Firestore inbox directly (preferred for realtime)

1. User signs in via `POST /api/chat/firebase-token`
2. Mobile queries:

   ```
   userChats/{myUserId}/rooms
   orderBy lastMessageAt desc
   ```

3. Mobile listens with `snapshots()` for live inbox updates

**Backend responsibility:** Keep `userChats` documents correct (room create + message Cloud Function).

### Option B — REST proxy (bootstrap / search)

Keep or enhance `GET /api/chat/list`:

1. Backend reads Firestore `userChats/{userId}/rooms` via Admin SDK **or** PostgreSQL mirror
2. Enrich with fresh `recipient` profile from DB
3. Return JSON matching mobile shape below

**Backend responsibility:** Same Firestore writes + stable REST response.

### Hybrid (current mobile plan)

| When | Source |
| --- | --- |
| App open / pull-to-refresh | `GET /api/chat/list` |
| App foreground | Firestore listener on `userChats/{userId}/rooms` |

---

## REST response shape mobile expects (`GET /api/chat/list`)

Please include **`roomId`** in each row (currently missing — mobile re-calls `POST /api/chat/room` on every open).

```json
{
  "statusCode": 1,
  "message": "Inbox threads fetched",
  "data": [
    {
      "id": "idc2210865",
      "roomId": "d72d18a2-1489-4781-b42e-7f4b9c371921_idc2210865",
      "firestorePath": "chatRooms/d72d18a2-1489-4781-b42e-7f4b9c371921_idc2210865",
      "lastMessage": "Hi",
      "lastMessageTime": "2026-06-08T10:00:00.000Z",
      "lastMessageType": "text",
      "unreadCount": 2,
      "recipient": {
        "id": "idc2210865",
        "name": "New Host 6",
        "displayPicture": "/uploads/host_real_photo-1780748882753-149243517.jpg"
      }
    }
  ]
}
```

### Field mapping: Firestore → REST

| REST field | Firestore field |
| --- | --- |
| `id` | `peerId` |
| `roomId` | `roomId` |
| `lastMessage` | `lastMessagePreview` |
| `lastMessageTime` | `lastMessageAt` |
| `lastMessageType` | `lastMessageType` |
| `unreadCount` | `unreadCount` |
| `recipient.id` | `peerId` |
| `recipient.name` | `title` |
| `recipient.displayPicture` | `photoUrl` |

---

## Security Rules (already deployed)

Mobile can **read/update** own inbox rows:

```javascript
match /userChats/{userId}/rooms/{roomId} {
  allow read, update: if request.auth.uid == userId;
  allow create: if false; // Admin SDK only on room create
}
```

Backend **must create** `userChats/...` via Admin SDK on `POST /api/chat/room`.

---

## Firestore index (if query fails)

Composite index may be required:

```
Collection: userChats/{userId}/rooms
Fields:     lastMessageAt Descending
```

Firebase Console will show a link to create it if missing.

---

## Prerequisites (blockers from live testing)

Before inbox list works end-to-end:

| # | Item | Status |
| --- | --- | --- |
| 1 | Firebase Admin SDK initialized on Render | **Required** — `firebase-token` currently fails with "Admin SDK is not initialized" |
| 2 | Service account for **`qobo1live-914ac`** (not another GCP project) | **Required** — fixes `custom-token-mismatch` |
| 3 | `POST /api/chat/room` writes `chatRooms` + `userChats` | **Required** — Firestore Data was empty after room API |
| 4 | Security Rules published | Done |
| 5 | Cloud Function or hook to update inbox on new message | **Required** for accurate list after send |

---

## Acceptance tests

### Test 1 — Room create populates inbox

1. User A calls `POST /api/chat/room` with `target_id` = User B  
2. Firestore must contain:
   - `chatRooms/{roomId}`
   - `userChats/{userA}/rooms/{roomId}`
   - `userChats/{userB}/rooms/{roomId}`

### Test 2 — List inbox for User A

**Firestore (Admin SDK or mobile client):**

```
GET userChats/{userA}/rooms ORDER BY lastMessageAt DESC
```

Must return at least one document with correct `peerId` and `roomId`.

### Test 3 — Message updates inbox

1. User A sends message in `chatRooms/{roomId}/messages`  
2. `userChats/{userA}/rooms/{roomId}.lastMessagePreview` = message text  
3. `userChats/{userB}/rooms/{roomId}.unreadCount` incremented  
4. `GET /api/chat/list` for User B reflects new `lastMessage` (if REST mirror enabled)

### Test 4 — Open by roomId

Given `roomId`, mobile can open chat with:

- `roomId`
- `firestorePath`: `chatRooms/{roomId}`
- `targetId`: `peerId` from inbox row

No extra `POST /api/chat/room` required if inbox row exists.

---

## Optional: new REST endpoint (if you prefer server-side list)

```
GET /api/chat/inbox
Authorization: Bearer {jwt}
```

Backend reads `userChats/{jwt.userId}/rooms` from Firestore, enriches profiles, returns same `data` array as `/api/chat/list` with `roomId` on every item.

---

## Related docs

- [03 — Firestore schema](./03-firestore-schema.md)  
- [09 — Backend blockers](./09-backend-action-items-chat-blockers.md)  
- Mobile: `lib/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart` (`fetchInbox`)

---

**Reply with:** Sample Firestore screenshot of `userChats/{userId}/rooms` after room create + one message, and updated `GET /api/chat/list` sample including `roomId`.
