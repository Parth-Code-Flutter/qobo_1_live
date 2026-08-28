# Animated Emoji (GIF) — Full Backend Spec  
## 1:1 Chat + Audio Rooms + Video Rooms + Live Streaming

**To:** Backend team  
**From:** Mobile (Flutter)  
**App:** Qobo1live  
**Date:** 2026-08-23  
**Status:** Ready for backend implementation  

**Supersedes scope of:** `docs/api/CHAT_EMOJI_GIF_BACKEND_IMPLEMENTATION.md` (that file was **1:1 chat only**).  
**This document** is the complete contract for:

| Surface | In scope? |
|---------|-----------|
| 1:1 private chat | Yes |
| Audio rooms (`/api/room/*`) | Yes |
| Video rooms (`/api/room/*`) | Yes |
| Live streaming (`/api/live-streaming/*`) | Yes |
| PK battle overlay (same room session) | Yes (reuse room emoji send) |
| 1:1 voice/video **call** in-call spray | Optional / Phase 2 |

**Client assets:** GIF pack (~34 files, ~44 MB unpacked). Host on CDN; never put full pack in the APK; never put GIF bytes inside chat/room messages.

---

## 1. Product goal

User picks an animated emoji from a shared catalog and sends it so **receivers see the same GIF animation**:

| Context | Who sees it |
|---------|-------------|
| **1:1 chat** | Partner only (message bubble in thread) |
| **Audio / video room** | Everyone currently in that room (in-room chat + optional full-screen/burst overlay) |
| **Live streaming** | Host + all viewers currently in that live session |

Same pack and same `emojiId` everywhere. Different **transport** per surface (Firestore/REST for 1:1; Zego in-room message ± REST for rooms/live).

---

## 2. Architecture (all surfaces)

```text
                    ┌─────────────────────────────┐
                    │  CDN + Catalog API          │
                    │  GET /api/chat/emojis       │
                    │  (shared pack for all UX)   │
                    └─────────────┬───────────────┘
                                  │ emojiId → gifUrl
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
          ▼                       ▼                       ▼
   ┌─────────────┐      ┌──────────────────┐    ┌────────────────────┐
   │ 1:1 Chat    │      │ Audio / Video    │    │ Live streaming     │
   │ REST send + │      │ Room             │    │                    │
   │ Firestore   │      │ Zego in-room msg │    │ Zego in-room msg   │
   │ type=emoji  │      │ + optional REST  │    │ + optional REST    │
   └─────────────┘      └──────────────────┘    └────────────────────┘
```

### Hard rules

1. Messages carry **`emojiId` only** (tiny payload).  
2. Both sender and receivers resolve `emojiId` via **catalog / disk cache**.  
3. Do **not** mix live-streaming APIs with `/api/room/*` (existing product rule).  
4. Emoji is **free** in v1 (unlike gifts). No wallet debit unless product later adds paid packs.  
5. Catalog is **shared** across chat + rooms + live (one packVersion).

---

## 3. Shared catalog (required once for all features)

### 3.1 Asset packaging

Normalize client zip before upload:

| Rule | Example |
|------|---------|
| Stable id | `emoji_001` (never reuse for a different visual) |
| CDN object | `…/chat/emojis/v1/emoji_001.gif` |
| Compress | Prefer &lt; 300–500 KB / GIF (current pack has 1–2 MB files) |
| Deprecate | `isActive: false`; **keep CDN file** for history / late joiners |

### 3.2 `GET /api/chat/emojis`

Auth: `Authorization: Bearer <JWT>`

```json
{
  "statusCode": 1,
  "message": "Emoji catalog fetched",
  "data": {
    "packId": "qobo_emoji_v1",
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
        "height": 512,
        "surfaces": ["chat", "audio_room", "video_room", "live_stream"]
      }
    ]
  }
}
```

| Field | Required | Notes |
|--------|----------|--------|
| `id` | Yes | Used in all message transports |
| `gifUrl` | Yes | Absolute HTTPS |
| `previewUrl` | Recommended | Picker grid |
| `surfaces` | Optional | If omitted, item is allowed on **all** surfaces |
| `packVersion` | Yes | Bump when catalog changes |

Optional conditional fetch:

`GET /api/chat/emojis?packVersion=1` → `{ "unchanged": true, "packVersion": 1 }` when client is current.

> **Naming:** Path stays under `/api/chat/emojis` even though rooms/live use it — one catalog. If you prefer `/api/emoji/catalog`, dual-route or document the alternate; mobile can adapt.

---

## 4. Surface A — 1:1 private chat

Same as the previous chat-only doc; kept here for a single shareable file.

### 4.1 `POST /api/chat/send` (extend)

```json
{
  "target_id": "<receiver_uuid>",
  "room_id": "<chat_room_id>",
  "type": "emoji",
  "content": {
    "emojiId": "emoji_001",
    "packVersion": 1
  },
  "clientMessageId": "<client_id>"
}
```

### 4.2 Firestore `chatRooms/{roomId}/messages/{messageId}`

```json
{
  "type": "emoji",
  "content": {
    "emojiId": "emoji_001",
    "packVersion": 1
  },
  "senderId": "<user_A>",
  "createdAt": "<server timestamp>",
  "clientMessageId": "…"
}
```

### 4.3 Inbox / history

- `GET /api/chat/detail` returns `type: "emoji"` + `emojiId`.
- Inbox preview: `Sent an emoji` / `🎬 Kiss` (not raw JSON).

### 4.4 FCM (recommended)

```json
{
  "type": "chat_message",
  "message_type": "emoji",
  "emoji_id": "emoji_001",
  "room_id": "…",
  "preview": "Sent an emoji"
}
```

---

## 5. Surface B — Audio rooms & Video rooms

**Session APIs stay under `/api/room/*`.**  
Emoji catalog is shared; **send/log** is room-scoped.

### 5.1 Realtime delivery (primary — required for UX)

Mobile already broadcasts gifts via **Zego in-room chat messages** with markers. Emoji will use the same bus so everyone in the room sees the GIF **immediately** without waiting for REST.

#### Wire format (Zego in-room message text)

Keep it parseable and small (Zego message size limits):

```text
[[emoji:emoji_001]] [[emojiPack:1]]
```

Optional human-readable prefix for native Zego chat UI (we hide default chat UI often, but keep markers first):

```text
🎬 Kiss [[emoji:emoji_001]] [[emojiPack:1]]
```

| Marker | Meaning |
|--------|---------|
| `[[emoji:{id}]]` | Required — catalog id |
| `[[emojiPack:{n}]]` | Optional — packVersion hint |

**Do not** put `gifUrl` in the Zego string if avoidable (URLs are long; id is enough). If you want redundancy for older clients:

```text
[[emoji:emoji_001]] [[emojiAnim:https://cdn…/emoji_001.gif]]
```

Mobile will prefer `emojiId` → catalog; use `emojiAnim` only as fallback.

### 5.2 Backend REST — room emoji send / audit (required for analytics + moderation)

Even though Zego delivers realtime, backend should **record** the event (spam control, reports, heat/engagement later).

#### `POST /api/room/emoji/send`

```json
{
  "roomId": "<backend_room_uuid>",
  "room_id": "<backend_room_uuid>",
  "emojiId": "emoji_001",
  "packVersion": 1,
  "sessionType": "audio_room",
  "clientEventId": "<uuid>"
}
```

`sessionType`: `audio_room` | `video_room`

#### Success

```json
{
  "statusCode": 1,
  "message": "Emoji sent",
  "data": {
    "eventId": "evt_…",
    "roomId": "…",
    "emojiId": "emoji_001",
    "senderId": "…",
    "createdAt": "2026-08-23T08:00:00.000Z",
    "gifUrl": "https://cdn…/emoji_001.gif"
  }
}
```

#### Validation

| Check | Action |
|--------|--------|
| User is member / in room | Else reject |
| `emojiId` exists | Else reject |
| Rate limit (e.g. N/sec per user per room) | Else reject with clear message |
| Room ended | Else reject |

#### Client order (mobile)

1. Optimistic local GIF play for sender.  
2. `POST /api/room/emoji/send` (loader optional / silent).  
3. On success (or in parallel if you allow): `ZegoUIKit().sendInRoomMessage(...)` so peers animate.  
4. If REST fails (blocked/rate limit), **do not** broadcast Zego (or recall) — mobile will follow backend success as source of truth for “allowed to send”.

> If backend prefers **Zego-only** with no REST for v1: say so explicitly. Mobile still needs rate-limit guidance. We **recommend REST** for moderation.

### 5.3 Socket.IO (optional enhancement)

If you already fan out room events on Socket.IO, emit:

**Event:** `room_emoji_sent`

```json
{
  "type": "room_emoji_sent",
  "roomId": "…",
  "emojiId": "emoji_001",
  "packVersion": 1,
  "senderId": "…",
  "senderName": "…",
  "senderAvatar": "…",
  "sessionType": "audio_room",
  "createdAt": "…"
}
```

Mobile can use this as backup if Zego message is missed; Zego remains primary for in-room sync.

### 5.4 Persistence / history (optional for rooms)

Room public chat is often ephemeral. For v1:

- **Not required** to store every emoji in long-term room history.  
- REST audit log (DB) is enough.  
- If you already persist room chat lines, store:

```json
{
  "type": "emoji",
  "emojiId": "emoji_001",
  "senderId": "…"
}
```

---

## 6. Surface C — Live streaming

**Session APIs stay under `/api/live-streaming/*`.** Do not call `/api/room/emoji/send` for live streams.

### 6.1 Realtime delivery (primary)

Same Zego in-room marker as rooms (live uses Zego Live Streaming engine; in-room messages still work):

```text
[[emoji:emoji_001]] [[emojiPack:1]]
```

Audience + host all parse and play the GIF (overlay + optional chat line).

### 6.2 Backend REST

#### `POST /api/live-streaming/emoji/send`

```json
{
  "liveStreamingId": "ls_1787331523501_934491",
  "roomId": "<uuid if you use UUID>",
  "room_id": "<uuid if you use UUID>",
  "emojiId": "emoji_001",
  "packVersion": 1,
  "clientEventId": "<uuid>"
}
```

Accept either `liveStreamingId` (`ls_…`) or backend `roomId` UUID (same flexibility as live join/leave docs).

#### Success

```json
{
  "statusCode": 1,
  "message": "Emoji sent",
  "data": {
    "eventId": "evt_…",
    "liveStreamingId": "ls_…",
    "emojiId": "emoji_001",
    "senderId": "…",
    "createdAt": "…",
    "gifUrl": "https://cdn…/emoji_001.gif"
  }
}
```

#### Validation

| Check | Action |
|--------|--------|
| Stream is active / user joined | Else reject |
| Host-only or audience allowed | Product: **audience + host** can send in v1 unless you restrict |
| Rate limit | Required (live can be large) |
| Known `emojiId` | Required |

### 6.3 Socket.IO (optional)

**Event:** `live_emoji_sent` (or reuse `room_emoji_sent` with `sessionType: "live_stream"`)

```json
{
  "type": "live_emoji_sent",
  "liveStreamingId": "ls_…",
  "roomId": "…",
  "emojiId": "emoji_001",
  "senderId": "…",
  "senderName": "…",
  "createdAt": "…"
}
```

### 6.4 Relation to existing live docs

Align channel ids with `LIVE_STREAMING_MOBILE_API_DOCUMENTATION.md`:

- Zego liveID = `zegoLiveId` / `liveStreamingId` (`ls_…`)  
- Backend UUID = REST only  

Emoji send REST should key off the same ids used by join/leave/end.

---

## 7. Comparison: Emoji vs Gift (so backend doesn’t collide)

| | **Emoji (this feature)** | **Gift (existing)** |
|--|--------------------------|---------------------|
| Cost | Free (v1) | Coins via `POST /api/economy/send-gift` |
| Catalog | `GET /api/chat/emojis` | Gift list / economy catalog |
| Media | GIF (`gifUrl`) | SVGA + sound |
| Realtime | `[[emoji:id]]` Zego marker | `[[giftAnim:url]]` / gift chat label |
| REST | `/api/room/emoji/send` or `/api/live-streaming/emoji/send` | `/api/economy/send-gift` |
| UX | Compact bubble / burst | Full celebration overlay |

Keep endpoints and markers **separate** so mobile routing stays clean.

---

## 8. Rate limits (recommended defaults)

| Surface | Suggested limit |
|---------|-----------------|
| 1:1 chat | Same as text, or 1 emoji / 1s / thread |
| Audio / video room | 1 emoji / 2s / user / room |
| Live streaming | 1 emoji / 2–3s / user / stream; stricter for large rooms |

Return:

```json
{
  "statusCode": 0,
  "message": "Please wait before sending another emoji"
}
```

---

## 9. Moderation & blocking

| Rule | Behavior |
|------|----------|
| User blocked from chat | Cannot send 1:1 emoji |
| User kicked / left room | Cannot send room emoji |
| Live viewer removed | Cannot send live emoji |
| Global mute / chat ban | Apply same as text chat if you have it |
| Report | Include `emojiId` + `eventId` in report payloads when relevant |

---

## 10. Mobile behaviour summary (for backend alignment)

| Step | Chat | Room | Live |
|------|------|------|------|
| Load catalog | `GET /api/chat/emojis` | same | same |
| Picker UI | Chat input accessory | Bottom sheet / more menu | Bottom sheet / more menu |
| Authorize send | `POST /api/chat/send` | `POST /api/room/emoji/send` | `POST /api/live-streaming/emoji/send` |
| Fan-out | Firestore (+ FCM) | Zego in-room message | Zego in-room message |
| Render | Chat bubble GIF | Overlay + optional chat line | Overlay + optional chat line |
| Cache | Disk cache by `gifUrl` | same | same |

Late joiners in rooms/live **do not** need to replay old emojis (unlike gifts history bootstrap — skip replay). Only live events after join.

---

## 11. Endpoint checklist (backend deliverables)

| # | Method | Path | Purpose |
|---|--------|------|---------|
| 1 | `GET` | `/api/chat/emojis` | Shared catalog |
| 2 | `POST` | `/api/chat/send` | Extend for `type=emoji` (1:1) |
| 3 | `POST` | `/api/room/emoji/send` | Audio/video room audit + gate |
| 4 | `POST` | `/api/live-streaming/emoji/send` | Live stream audit + gate |
| 5 | (opt) Socket | `room_emoji_sent` / `live_emoji_sent` | Backup fan-out |
| 6 | CDN | Host optimized GIFs | `gifUrl` / `previewUrl` |

Firestore inbox/history updates for 1:1 emoji as in §4.

---

## 12. Acceptance / QA matrix

### Shared

- [ ] Catalog returns stable ids + working `gifUrl`  
- [ ] GIFs compressed; packVersion bumps on change  
- [ ] Inactive emoji hidden from picker; old ids still resolve  

### 1:1 chat

- [ ] A sends emoji → B bubble shows GIF  
- [ ] History reload still shows GIF  
- [ ] Inbox preview is human-readable  

### Audio room

- [ ] Member A sends emoji → all current members see GIF  
- [ ] REST rejects if not in room / rate limited  
- [ ] Zego marker parsed; no coin debit  

### Video room

- [ ] Same as audio room with `sessionType: video_room`  

### Live streaming

- [ ] Viewer sends emoji → host + other viewers see GIF  
- [ ] Uses live-streaming emoji endpoint (not room endpoint)  
- [ ] Works with `liveStreamingId` (`ls_…`) and/or UUID per your join contract  
- [ ] Fresh join after send does **not** replay old emojis  

### Negative

- [ ] Unknown `emojiId` → clear error  
- [ ] Ended room/stream → reject  
- [ ] Gift flow unchanged  

---

## 13. Out of scope (v1)

- Paid emoji packs / wallet  
- User-uploaded custom stickers  
- Full offline APK embedding of 44 MB pack  
- Mandatory long-term room/live emoji history UI  
- Replacing gift SVGA system  

---

## 14. Suggested backend build order

1. Normalize pack → CDN → `GET /api/chat/emojis`  
2. 1:1: extend `POST /api/chat/send` + Firestore  
3. `POST /api/room/emoji/send` + document Zego marker contract  
4. `POST /api/live-streaming/emoji/send`  
5. Rate limits + optional Socket events  
6. Share Postman + 3 real CDN sample URLs with mobile  

---

## 15. What we need back from backend

1. Confirmed paths (or alternates) for catalog + room + live send  
2. Whether REST is **mandatory before** Zego broadcast (recommended: yes)  
3. Sample catalog JSON with live CDN URLs  
4. Rate-limit numbers you will enforce  
5. QA environment ETA  

---

## 16. Quick sample calls

### Catalog

```http
GET /api/chat/emojis
Authorization: Bearer <TOKEN>
```

### Room (audio)

```http
POST /api/room/emoji/send
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "roomId": "<uuid>",
  "emojiId": "emoji_001",
  "packVersion": 1,
  "sessionType": "audio_room",
  "clientEventId": "c1"
}
```

### Live

```http
POST /api/live-streaming/emoji/send
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "liveStreamingId": "ls_1787331523501_934491",
  "emojiId": "emoji_001",
  "packVersion": 1,
  "clientEventId": "c2"
}
```

### Zego in-room (mobile → peers; not HTTP)

```text
[[emoji:emoji_001]] [[emojiPack:1]]
```

---

*End of document — share this file with backend for chat + rooms + live.*

**Also see (narrower, chat-only):** `docs/api/CHAT_EMOJI_GIF_BACKEND_IMPLEMENTATION.md` — prefer **this** full-scope file going forward.
