# 04 — Phase-wise Implementation Plan

Last updated: 2026-06-06

Incremental rollout from **REST-only inbox** to **full WhatsApp-style chat**. Each phase has clear owners and exit criteria.

---

## Overview timeline

```mermaid
gantt
    title Chat implementation phases
    dateFormat YYYY-MM-DD
    section Foundation
    Phase 0 Alignment           :p0, 2026-06-09, 5d
    Phase 1 REST inbox          :p1, after p0, 7d
    section Firebase
    Phase 2 Firebase bridge     :p2, after p1, 7d
    Phase 3 Realtime text       :p3, after p2, 7d
    section Features
    Phase 4 Media               :p4, after p3, 7d
    Phase 5 WhatsApp parity     :p5, after p4, 14d
    Phase 6 Push FCM            :p6, after p5, 7d
    Phase 7 Groups advanced     :p7, after p6, 21d
```

Adjust dates with your sprint calendar. Phases 5–7 can overlap sub-features.

---

## Phase 0 — Alignment (≈1 week)

**Goal:** Same contract across backend, mobile, and product before coding.

```mermaid
flowchart LR
    PM[Product] --> D1[Room ID rule]
    BE[Backend] --> D2[API envelope]
    MO[Mobile] --> D3[Package list]
    D1 --> Doc[docs/chat/ signed off]
    D2 --> Doc
    D3 --> Doc
```

| Task | Owner |
| --- | --- |
| Confirm Firebase for DMs (not Socket.IO for 1:1) | All |
| Confirm `User.id` = Firebase UID | Backend |
| Standardize new APIs on `statusCode: 201` + `data` | Backend |
| Choose Firebase project (`qobo1live-914ac` or new) | DevOps |
| List Flutter packages to add | Mobile |

**Exit criteria:** Backend + mobile leads sign off on [02 — Architecture](./02-architecture.md) and [03 — Firestore schema](./03-firestore-schema.md).

---

## Phase 1 — Wire existing REST (no Firebase)

**Goal:** Inbox and history work with APIs you already have.

```mermaid
sequenceDiagram
    participant MT as MessagesTabView
    participant CR as ChatRepo
    participant API as GET /api/chat/list
    participant CD as ChatDetailView
    participant API2 as GET /api/chat/detail

    MT->>CR: getInbox()
    CR->>API: Bearer JWT
    API-->>MT: thread list
    MT->>CD: tap thread (targetUserId)
    CD->>CR: getConversation(targetId)
    CR->>API2: page=1
    API2-->>CD: message history
```

| Owner | Deliverable |
| --- | --- |
| **Backend** | Stable `GET /api/chat/list` + `GET /api/chat/detail` |
| **Mobile** | `MessagesTabController` → `ChatRepo.getInbox()` |
| **Mobile** | `ChatDetailController` → `getConversation()` + pagination |
| **Mobile** | Map API response → `MessageListItemModel` / bubble UI |
| **Mobile** | Pass args: `targetUserId`, `name`, `imageUrl` |

**Files to touch:**

- `lib/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart`
- `lib/app/user_flow/messages/chat_detail/controllers/chat_detail_controller.dart`
- `lib/app/user_flow/call/` — pass partner id when opening chat

**Exit criteria:** User sees real inbox and history from API. Send may still be disabled or show "coming soon".

---

## Phase 2 — Firebase bridge + room API

**Goal:** After REST login, app can access Firestore; rooms created only by backend.

```mermaid
flowchart TD
    A[Login success] --> B[POST /api/chat/firebase-token]
    B --> C[signInWithCustomToken]
    C --> D[User taps Chat]
    D --> E[POST /api/chat/room]
    E --> F{Blocked?}
    F -->|Yes| G[Error toast]
    F -->|No| H[Return roomId]
    H --> I[Open ChatDetailView with roomId]
```

| Owner | Deliverable |
| --- | --- |
| **Backend** | `POST /api/chat/firebase-token` |
| **Backend** | `POST /api/chat/room` + Admin SDK writes |
| **Backend** | Block check via `Block` table |
| **Backend** | Firestore Security Rules v1 |
| **Mobile** | Add Firebase packages + `google-services` config |
| **Mobile** | `ChatFirebaseService` — init + custom token sign-in |
| **Mobile** | `ChatRepo.createRoom()` before opening chat |
| **Mobile** | Route args include `roomId` |

**Exit criteria:** Login → Firebase session active → create room API returns `roomId` → Firestore documents exist.

---

## Phase 3 — Realtime 1:1 text (MVP)

**Goal:** Live send/receive text messages.

```mermaid
flowchart LR
    subgraph Sender
        S1[Type message] --> S2[Write Firestore doc]
    end
    subgraph Firestore
        FS[(messages subcollection)]
    end
    subgraph Receiver
        R1[onSnapshot] --> R2[Render bubble]
        R2 --> R3[Set readAt]
    end
    S2 --> FS
    FS --> R1
```

| Owner | Deliverable |
| --- | --- |
| **Backend** | Optional Cloud Function: lastMessage + unreadCount |
| **Backend** | Optional Postgres message sync |
| **Mobile** | Listen `chatRooms/{roomId}/messages` (limit 50, desc) |
| **Mobile** | Send with `clientMessageId` dedupe |
| **Mobile** | Mark read: `unreadCount = 0` on open |
| **Mobile** | Replace mock `sendMessage()` in controller |

**Exit criteria:** Two test devices exchange messages in realtime; inbox shows updated last message.

---

## Phase 4 — Media messages

**Goal:** Image, video, voice notes.

```mermaid
sequenceDiagram
    participant U as User
    participant App as Flutter
    participant ST as Firebase Storage
    participant FS as Firestore

    U->>App: Pick image / record audio
    App->>ST: Upload file
    ST-->>App: downloadUrl
    App->>FS: message type image/audio + media object
    FS-->>App: Peer receives via listener
```

| Owner | Deliverable |
| --- | --- |
| **Backend** | Storage Security Rules |
| **Backend** | Optional media moderation queue |
| **Mobile** | `ChatMediaService` upload + progress UI |
| **Mobile** | Wire `+` button in `ChatDetailView` |
| **Mobile** | Types: `image`, `video`, `audio` |

**Exit criteria:** Photo and voice note send end-to-end with preview/playback.

---

## Phase 5 — WhatsApp parity (sub-phases)

```mermaid
flowchart TD
    P5[Phase 5] --> P5a[5a Read receipts]
    P5 --> P5b[5b Typing]
    P5 --> P5c[5c Reply]
    P5 --> P5d[5d Delete me/everyone]
    P5 --> P5e[5e Edit message]
    P5 --> P5f[5f Reactions]
    P5 --> P5g[5g Presence]
    P5 --> P5h[5h Mute pin archive]
```

| Sub | Feature | Backend | Mobile |
| --- | --- | --- | --- |
| 5a | ✓ / ✓✓ / blue ticks | — | Update `status.*`; UI ticks |
| 5b | Typing... | — | `typing/{userId}` doc |
| 5c | Reply | — | `replyTo` + UI |
| 5d | Delete | Security Rules time window | Long-press menu |
| 5e | Edit | Rules: sender, 15 min | Edit UI |
| 5f | Reactions | — | Emoji picker |
| 5g | Last seen | — | `presence/main` |
| 5h | Mute / pin | — | `userChats` fields |
| — | Report | `POST /api/chat/report` | Report action |

**Exit criteria:** Core social chat UX matches WhatsApp baseline for 1:1.

---

## Phase 6 — Push notifications (FCM)

```mermaid
sequenceDiagram
    participant S as Sender
    participant FS as Firestore
    participant CF as Cloud Function
    participant API as Backend FCM
    participant R as Receiver device

    S->>FS: New message
    FS->>CF: onCreate trigger
    CF->>API: Lookup FCM token
    API->>R: Push notification
    R->>R: Tap → ChatDetailView roomId
```

| Owner | Deliverable |
| --- | --- |
| **Backend** | `POST /api/user/fcm-token` — store device token |
| **Backend / CF** | Send FCM on new message when receiver offline |
| **Mobile** | Register FCM after login |
| **Mobile** | Notification tap → `Routes.CHAT_DETAIL` |

**Exit criteria:** Background notification opens correct chat thread.

---

## Phase 7 — Group chat & advanced

| Feature | Notes |
| --- | --- |
| Group rooms | `POST /api/chat/room` with `type: "group"` |
| Add/remove members | Backend Admin SDK + system messages |
| Disappearing messages | `expiresAt` + scheduled cleanup |
| Starred / search | Postgres full-text on mirrored messages |
| Support chat | `roomType: "support"` for `CustomerServiceView` |

**Exit criteria:** Product-defined group + advanced scope complete.

---

## Phase dependency diagram

```mermaid
flowchart TD
    P0[Phase 0 Alignment] --> P1[Phase 1 REST]
    P1 --> P2[Phase 2 Firebase bridge]
    P2 --> P3[Phase 3 Realtime text]
    P3 --> P4[Phase 4 Media]
    P3 --> P5[Phase 5 WhatsApp features]
    P4 --> P6[Phase 6 FCM]
    P5 --> P6
    P6 --> P7[Phase 7 Groups]
```

Phases 4 and 5 can run in parallel after Phase 3.

---

## Recommended “first month” focus

| Week | Phase | Outcome |
| --- | --- | --- |
| 1 | 0 + 1 | Inbox + history from REST |
| 2 | 2 | Firebase token + room creation |
| 3 | 3 | Live text chat |
| 4 | 4 or 6 | Media **or** push (product priority) |

---

## Next documents

- Task split → [05 — Backend vs mobile](./05-backend-vs-mobile.md)
- Endpoints → [06 — API reference](./06-api-reference.md)
