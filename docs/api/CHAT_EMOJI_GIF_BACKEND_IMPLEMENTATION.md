# 1:1 Chat Animated Emoji (GIF) — Backend Implementation Spec

> **Scope note:** This file covers **1:1 chat only**.  
> For **audio rooms + video rooms + live streaming + 1:1**, share this instead:  
> **`docs/api/CHAT_ROOM_LIVE_EMOJI_GIF_BACKEND_IMPLEMENTATION.md`**

**To:** Backend team  
**From:** Mobile (Flutter)  
**App:** Qobo1live  
**Scope (v1):** One-to-one private chat only  
**Date:** 2026-08-23  
**Status:** Superseded for full product scope — use the room/live doc above when sharing with backend for rooms/live.

**Related assets:** Client emoji pack delivered as GIF files (`512(n).gif`, ~34 items, ~44 MB unpacked / ~22 MB zip).

---

## 1. Product goal

When **Person A** picks an animated emoji and sends it to **Person B** in 1:1 chat:

1. A sees the emoji as an animated GIF in their outgoing bubble immediately (optimistic UI).
2. B receives a normal chat message and sees the **same** emoji as an animated GIF in the bubble.
3. History (REST + Firestore) continues to show the GIF correctly for both users later.

This is **not** a system Unicode emoji. These are **custom animated sticker/GIF assets** owned by the product.

---

## 2. Architecture decision (please follow)

| Layer | Decision | Why |
|--------|----------|-----|
| GIF binary storage | **CDN / object storage (server-side)** | Pack is ~44 MB; must not ship full pack in APK; pack can change without app release |
| Chat message payload | **Stable `emojiId` only** (tiny JSON) | Never upload or embed GIF bytes in Firestore / `POST /api/chat/send` |
| Catalog | **Backend API** (`GET /api/chat/emojis`) | Single source of truth for A and B |
| Device cache | Mobile caches GIF URLs after first download | Offline replay of already-seen emojis; saves bandwidth |
| Optional local bundle | Mobile may ship **0–5** tiny preview assets only | Optional; **not** required for v1 if CDN is reliable |

### Do **not** implement

- Storing GIF binaries inside each chat message
- Sending a local file path / asset name that only exists on the sender’s device
- Requiring an app-store update every time the client adds/removes an emoji
- Using messy original filenames (`512(20) (1).gif`) as public IDs

**Mental model:** Same as gifts — send an **id**, play media from a **catalog URL**.

---

## 3. High-level flow

```text
┌────────────┐     GET /api/chat/emojis      ┌──────────────┐
│  Mobile A  │ ─────────────────────────────►│   Backend    │
│  (picker)  │◄──── catalog + gifUrl ────────│  + CDN URLs  │
└─────┬──────┘                               └──────┬───────┘
      │                                             │
      │  POST /api/chat/send                        │
      │  type=emoji, emojiId=…                      │
      │  + Firestore message write                   │
      ▼                                             ▼
┌────────────┐     realtime / FCM / poll     ┌──────────────┐
│  Mobile B  │◄──── type=emoji, emojiId ─────│  Firestore   │
│  (bubble)  │  resolve emojiId → gifUrl     │  chatRooms/… │
└────────────┘  (from cache or catalog)      └──────────────┘
```

---

## 4. Asset packaging requirements (backend + content ops)

### 4.1 Normalize the client pack before upload

Original files look like:

- `512(1).gif`
- `512(20) (1).gif`
- `512(34) (2).gif`

Before hosting, produce a **clean pack**:

| Rule | Example |
|------|---------|
| Stable id | `emoji_001`, `emoji_002`, … (lowercase, snake/number only) |
| CDN file name | `emoji_001.gif` |
| Display name | Human label for picker (`Kiss`, `Heart`, …) — can be English first |
| Dimensions | Prefer ≤ 320×320 for chat bubbles if redesign is allowed; 512×512 acceptable for v1 if compressed |
| Size target | Prefer **&lt; 300–500 KB** per GIF after optimization (current pack has 1–2 MB files — please compress) |
| Format | GIF for v1 (mobile will animate GIF). Optional later: animated WebP + GIF fallback |

Deliver a **manifest JSON** with the pack (can be generated offline and uploaded with the files):

```json
{
  "packId": "qobo_chat_emoji_v1",
  "packVersion": 1,
  "items": [
    {
      "id": "emoji_001",
      "name": "Emoji 001",
      "file": "emoji_001.gif",
      "sortOrder": 1
    }
  ]
}
```

**Critical:** `id` must never change once messages exist in production. Adding new emojis = new ids. Deprecating = set `isActive: false` (keep URL for history).

### 4.2 CDN / storage layout (suggested)

```text
https://{cdn-host}/chat/emojis/v1/emoji_001.gif
https://{cdn-host}/chat/emojis/v1/emoji_001_thumb.webp   // optional small static preview for picker
```

- Public read (or signed URL with long TTL — public is simpler for chat history).
- Cache-Control: long cache (`max-age=31536000, immutable`) keyed by versioned path.
- When replacing a file for the same id, bump path version (`v2/…`) **or** change id — avoid silent mutation of history visuals without care.

---

## 5. API endpoints

Base URL (current prod pattern): `https://my-backend-api-960q.onrender.com`  
Auth: `Authorization: Bearer <JWT>` on all routes below.

Suggested root: `/api/chat/emojis` (isolated under chat, not live-streaming / gifts).

---

### 5.1 List emoji catalog (required)

- **Method:** `GET`
- **Path:** `/api/chat/emojis`
- **Query (optional):**
  - `packVersion` — if client already has this version, backend may return `{ unchanged: true }`
  - `includeInactive=false` (default) — picker should only see active items

#### Success response

```json
{
  "statusCode": 1,
  "message": "Chat emoji catalog fetched",
  "data": {
    "packId": "qobo_chat_emoji_v1",
    "packVersion": 1,
    "updatedAt": "2026-08-23T07:00:00.000Z",
    "items": [
      {
        "id": "emoji_001",
        "name": "Kiss",
        "sortOrder": 1,
        "isActive": true,
        "previewUrl": "https://cdn.example.com/chat/emojis/v1/emoji_001_thumb.webp",
        "gifUrl": "https://cdn.example.com/chat/emojis/v1/emoji_001.gif",
        "width": 512,
        "height": 512
      },
      {
        "id": "emoji_002",
        "name": "Heart",
        "sortOrder": 2,
        "isActive": true,
        "previewUrl": "https://cdn.example.com/chat/emojis/v1/emoji_002_thumb.webp",
        "gifUrl": "https://cdn.example.com/chat/emojis/v1/emoji_002.gif",
        "width": 512,
        "height": 512
      }
    ]
  }
}
```

#### Field rules

| Field | Required | Notes |
|--------|----------|--------|
| `id` | Yes | Stable public key used in chat messages |
| `name` | Yes | Picker label |
| `gifUrl` | Yes | Absolute HTTPS URL; must animate |
| `previewUrl` | Recommended | Smaller static/animated preview for grid |
| `sortOrder` | Yes | Ascending in picker |
| `isActive` | Yes | `false` hides from picker but keeps history playable |
| `packVersion` | Yes | Integer; bump when catalog changes |
| `width` / `height` | Optional | Helps mobile layout |

#### Caching hint for mobile

Mobile will cache this response by `packVersion`. If you support conditional fetch:

```http
GET /api/chat/emojis?packVersion=1
```

```json
{
  "statusCode": 1,
  "message": "Catalog unchanged",
  "data": {
    "unchanged": true,
    "packId": "qobo_chat_emoji_v1",
    "packVersion": 1
  }
}
```

---

### 5.2 Send emoji message (extend existing send)

Mobile already calls:

- `POST /api/chat/send`

Please **extend** this endpoint to accept emoji messages (do not invent a separate send path unless necessary).

#### Request body (emoji)

```json
{
  "target_id": "6aae455a-9bc0-41e3-88dc-a0e86fc2c6f7",
  "room_id": "chat_abc123",
  "type": "emoji",
  "content": {
    "emojiId": "emoji_001",
    "packVersion": 1
  },
  "clientMessageId": "1724400000000_senderUserId"
}
```

Alternate flat shape (also acceptable if you already flatten `content` as string today):

```json
{
  "target_id": "…",
  "room_id": "…",
  "type": "emoji",
  "content": "emoji_001",
  "emojiId": "emoji_001",
  "packVersion": 1,
  "clientMessageId": "…"
}
```

**Preferred:** structured `content` object with `emojiId` so history stays typed.

#### Validation (backend)

| Check | Expected |
|--------|----------|
| `type == "emoji"` | Accept |
| `emojiId` present & known in catalog | Else `400` / `statusCode: 0` |
| `emojiId` inactive | Prefer **still allow send** if you want history continuity for deprecated stickers, OR reject with clear message — pick one and document; mobile recommends **allow send if id exists** |
| `target_id` / room membership | Same as text messages |
| Blocked users | Same as text messages |
| Rate limit | Same as text (or slightly stricter) |

#### Success response

Return the same envelope as text send, with persisted message shape including `type` and emoji content:

```json
{
  "statusCode": 1,
  "message": "Message sent",
  "data": {
    "messageId": "msg_…",
    "roomId": "chat_abc123",
    "type": "emoji",
    "content": {
      "emojiId": "emoji_001",
      "packVersion": 1
    },
    "senderId": "…",
    "createdAt": "2026-08-23T07:05:00.000Z"
  }
}
```

---

### 5.3 History / inbox preview

#### `GET /api/chat/detail`

Each emoji message in `data.messages[]` must include:

```json
{
  "id": "msg_…",
  "type": "emoji",
  "content": {
    "emojiId": "emoji_001",
    "packVersion": 1
  },
  "senderId": "…",
  "createdAt": "…"
}
```

Optional enrichment (nice-to-have, not required if catalog is always available):

```json
"content": {
  "emojiId": "emoji_001",
  "packVersion": 1,
  "gifUrl": "https://cdn…/emoji_001.gif",
  "name": "Kiss"
}
```

If you enrich `gifUrl` on history, mobile can render even before catalog refresh — still keep `emojiId` as source of truth.

#### `GET /api/chat/list` (inbox last-message preview)

For last message of type emoji, return a short preview string so inbox UI does not show blank/raw JSON:

| Field | Example |
|--------|---------|
| `lastMessage` / `preview` | `🎬 Kiss` or `[Emoji]` or localized `Sent an emoji` |
| `lastMessageType` | `emoji` |

---

## 6. Firestore contract (required for realtime 1:1)

Existing path (from chat docs):

`chatRooms/{roomId}/messages/{messageId}`

### 6.1 Message document for emoji

```json
{
  "type": "emoji",
  "content": {
    "emojiId": "emoji_001",
    "packVersion": 1
  },
  "senderId": "user_A",
  "receiverId": "user_B",
  "clientMessageId": "1724400000000_user_A",
  "createdAt": "<server timestamp>",
  "status": "sent"
}
```

### 6.2 Who writes Firestore?

Pick **one** consistent policy (same as text today):

| Option | Notes |
|--------|--------|
| **A. Backend writes Firestore on `POST /api/chat/send`** (preferred) | Mobile only calls REST; both sides get identical docs |
| B. Mobile writes Firestore + REST | Backend must still accept `type=emoji` and update inbox mirrors |

Inbox mirrors (`userChats/{userId}/rooms`) must update `lastMessage` preview for emoji the same way as text.

### 6.3 Security rules

- Same as other 1:1 messages: only room members can read/write.
- Do **not** allow arbitrary large binary fields on message docs.

---

## 7. Push notification (recommended)

When B is backgrounded, send data/notification consistent with other chat messages:

```json
{
  "type": "chat_message",
  "room_id": "chat_abc123",
  "message_id": "msg_…",
  "message_type": "emoji",
  "emoji_id": "emoji_001",
  "sender_id": "user_A",
  "sender_name": "Jitendra",
  "preview": "Sent an emoji"
}
```

Tray title/body can be: `Jitendra sent an emoji` (not the raw id).

---

## 8. Admin / ops (optional but useful)

Not required for mobile v1, but helpful:

| Capability | Purpose |
|------------|---------|
| Upload / replace pack files | Content updates without app release |
| Toggle `isActive` | Hide from picker without breaking old messages |
| Bump `packVersion` | Clients refresh catalog |
| Audit list of ids in use | Prevent deleting CDN objects still referenced in history |

---

## 9. Mobile responsibilities (for alignment — not backend work)

Backend can assume mobile will:

1. Fetch `GET /api/chat/emojis` on chat open / app start; cache by `packVersion`.
2. Show picker grid from `previewUrl` / `gifUrl`.
3. On send: call `POST /api/chat/send` with `type: "emoji"` + `emojiId` (and write/listen Firestore as per existing chat pipeline).
4. On receive / history: if `type == "emoji"`, render animated GIF from catalog `gifUrl` (disk-cached).
5. Never depend on original zip filenames.

---

## 10. Error codes / messages (suggested)

| Case | `statusCode` | Message example |
|------|--------------|-----------------|
| Unknown `emojiId` | `0` | `Unknown emoji id` |
| Missing `emojiId` for type emoji | `0` | `emojiId is required` |
| Not room member / blocked | same as text | existing messages |
| Catalog empty / CDN misconfigured | `0` on catalog GET | `Emoji catalog unavailable` |

---

## 11. Acceptance checklist (backend)

Please confirm before mobile ships UI:

- [ ] Pack uploaded to CDN with **stable ids** (`emoji_001` …), not raw `512(n).gif` names  
- [ ] GIFs compressed to reasonable size  
- [ ] `GET /api/chat/emojis` returns `packVersion` + `items[]` with `id`, `name`, `gifUrl`, `sortOrder`, `isActive`  
- [ ] `POST /api/chat/send` accepts `type: "emoji"` + `emojiId`  
- [ ] Invalid `emojiId` rejected clearly  
- [ ] Firestore message docs use `type: "emoji"` + `content.emojiId`  
- [ ] Inbox last-message preview shows human text for emoji (not raw JSON)  
- [ ] `GET /api/chat/detail` returns emoji messages with `type` + `emojiId`  
- [ ] Inactive emoji still resolvable by id for old history (CDN object kept)  
- [ ] (Recommended) FCM includes `message_type: emoji` + preview  

### QA scenario

1. User A and User B on two devices, same build, logged in.  
2. A opens chat with B → picker loads from catalog.  
3. A taps `emoji_001` → A bubble shows GIF.  
4. B receives message within realtime window → B bubble shows **same** GIF animation.  
5. Kill app on B → reopen chat → history still plays GIF.  
6. Backend sets `emoji_001.isActive=false` → picker hides it; old messages still play.  

---

## 12. Out of scope for v1 (explicit)

- Live room / audio room / PK emoji spray  
- Paid emoji packs / wallet charge  
- Custom user-uploaded stickers  
- Converting pack to Lottie/SVGA (can be a later optimization)  
- Full offline pack bundled in APK (~44 MB)  

---

## 13. Suggested implementation order for backend

1. Normalize + upload pack + write manifest  
2. Implement `GET /api/chat/emojis`  
3. Extend `POST /api/chat/send` + Firestore message shape  
4. Update inbox preview + `GET /api/chat/detail`  
5. (Optional) FCM fields  
6. Share sample Postman collection + 2–3 real CDN URLs with mobile  

---

## 14. Sample Postman-style calls

### Catalog

```http
GET /api/chat/emojis HTTP/1.1
Host: my-backend-api-960q.onrender.com
Authorization: Bearer <TOKEN>
```

### Send emoji

```http
POST /api/chat/send HTTP/1.1
Host: my-backend-api-960q.onrender.com
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "target_id": "<receiver_uuid>",
  "room_id": "<room_id>",
  "type": "emoji",
  "content": {
    "emojiId": "emoji_001",
    "packVersion": 1
  },
  "clientMessageId": "1724400000000_<sender_uuid>"
}
```

---

## 15. Reply we need from backend

Please reply with:

1. Confirmed endpoint paths (if different from `/api/chat/emojis` / extended `/api/chat/send`)  
2. Final message JSON shape (object `content` vs flat string)  
3. Sample catalog response with **real CDN URLs** for at least 3 emojis  
4. Whether Firestore write is backend-owned or mobile-owned for emoji (should match text)  
5. ETA for QA environment  

Once those are confirmed, mobile can implement picker + bubble rendering against this contract.

---

*End of document — share as-is with backend.*
