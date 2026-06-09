# 02 — Architecture (Firebase + REST)

Last updated: 2026-06-06

Hybrid architecture: **REST controls who can chat**; **Firebase delivers messages in realtime**.

---

## High-level system diagram

```mermaid
flowchart TB
    subgraph Client["Flutter Client"]
        direction TB
        JWT[App JWT Session]
        FBS[Firebase Session — custom token]
        CR[ChatRepo REST]
        CFS[ChatFirebaseService]
        MV[Messages / Chat UI]
    end

    subgraph Server["Node Backend"]
        direction TB
        REST[REST API Layer]
        JWTVerify[JWT Middleware]
        Perm[Permissions — block, match rules]
        PG[(PostgreSQL)]
        FAdmin[Firebase Admin SDK]
    end

    subgraph FB["Google Firebase"]
        direction TB
        FAuth[Firebase Auth]
        FS[(Cloud Firestore)]
        ST[(Cloud Storage)]
        FCM[Cloud Messaging]
        CF[Cloud Functions — optional]
    end

    JWT --> REST
    REST --> JWTVerify --> Perm
    Perm --> PG
    Perm --> FAdmin
    REST --> FAdmin
    FAdmin --> FAuth
    FAdmin --> FS
    JWT --> FBS
    FBS --> FAuth
    CFS --> FS
    CFS --> ST
    CR --> REST
    MV --> CR
    MV --> CFS
    FS --> CF
    CF --> PG
    CF --> FCM
    CF --> REST
```

---

## Two paths: control vs realtime

```mermaid
sequenceDiagram
    autonumber
    participant U as User App
    participant API as REST Backend
    participant FS as Firestore
    participant P as Peer App

    Note over U,API: Control path — permissions & room lifecycle
    U->>API: POST /api/auth/login
    API-->>U: JWT + user profile
    U->>API: POST /api/chat/firebase-token
    API-->>U: firebaseCustomToken
    U->>FS: signInWithCustomToken(uid = user.id)
    U->>API: POST /api/chat/room { targetUserId }
    API->>API: Check block, business rules
    API->>FS: Admin SDK create chatRooms + userChats
    API-->>U: { roomId }

    Note over U,P: Realtime path — messages
    U->>FS: Write message doc
    FS-->>P: Snapshot listener
    P->>FS: Update readAt / unreadCount
```

| Path | Protocol | Used for |
| --- | --- | --- |
| **Control** | REST + JWT | Login, create room, inbox bootstrap, block, report, FCM token register |
| **Realtime** | Firestore | Send/receive messages, typing, presence, live last-message updates |
| **Media** | Firebase Storage | Images, video, voice notes, documents |
| **Push** | FCM | Notify when app is backgrounded |

---

## Authentication model

Your app **does not** switch to Firebase-only login.

```mermaid
flowchart LR
    A[User logs in] --> B[POST /api/auth/login]
    B --> C[Store JWT + profile]
    C --> D[POST /api/chat/firebase-token]
    D --> E[FirebaseAuth.signInWithCustomToken]
    E --> F[Firestore Security Rules use request.auth.uid]
```

Rules:

- `request.auth.uid` **must equal** PostgreSQL `User.id` (UUID string).
- Backend mints custom token with that UID via Firebase Admin SDK.
- If JWT expires (401), app clears session — Firebase sign-out should happen in the same flow.

Code references today:

- JWT storage: `lib/utils/auth/auth_session_helper.dart`, `lib/services/header_data.dart`
- User id: `lib/services/user_session_controller.dart` → `userId` from `id`

---

## Chat room lifecycle

```mermaid
stateDiagram-v2
    [*] --> NoRoom: User taps Chat on profile/match
    NoRoom --> Creating: POST /api/chat/room
    Creating --> Blocked: Block check fails
    Creating --> Active: Room created or returned
    Blocked --> [*]: Show error
    Active --> Listening: Open ChatDetailView
    Listening --> Sending: User sends message
    Sending --> Listening: Firestore write OK
    Active --> Archived: User archives (later phase)
    Archived --> Active: User unarchives
```

**1:1 room ID** (computed by backend, never by mobile alone):

```
roomId = "{min(userA, userB)}_{max(userA, userB)}"
```

Example: users `aaa-111` and `zzz-999` → `aaa-111_zzz-999`.

---

## Inbox strategy

```mermaid
flowchart TD
    A[App opens Messages tab] --> B[GET /api/chat/list]
    B --> C[Render thread list with recipient cards]
    C --> D[Subscribe userChats/myUserId/rooms]
    D --> E[Merge live lastMessage + unreadCount]
    F[User opens thread] --> G[Listen chatRooms/roomId/messages]
    G --> H[Optional: GET /api/chat/detail for older pages]
```

| When | Source | Why |
| --- | --- | --- |
| Cold start / pull-to-refresh | REST `/api/chat/list` | Fast; includes profile enrichment |
| App foreground | Firestore `userChats` | Live unread + last message |
| Scroll up in chat | REST `/api/chat/detail?page=N` | Deep history beyond Firestore window |
| Active chat tail | Firestore `messages` subcollection | Realtime send/receive |

---

## Message send flow

```mermaid
sequenceDiagram
    participant S as Sender
    participant FS as Firestore
    participant CF as Cloud Function
    participant R as Receiver
    participant FCM as FCM

    S->>FS: Create messages/{id} (clientMessageId)
    S->>FS: Optimistic UI update
    FS-->>R: onSnapshot new message
    R->>FS: status.deliveredAt = now
    alt App in foreground
        R->>FS: status.readAt = now, unreadCount = 0
    else App in background
        CF->>FCM: Push to receiver device
        FCM->>R: Notification tap → open room
    end
    opt Postgres mirror
        CF->>CF: Sync message to PostgreSQL
    end
```

---

## Security boundaries

```mermaid
flowchart TD
    subgraph ClientCan["Mobile CAN do"]
        C1[Read messages if member]
        C2[Write own messages]
        C3[Update own typing/presence]
        C4[Update own read receipts]
        C5[Upload media to allowed paths]
    end

    subgraph ClientCannot["Mobile CANNOT do"]
        X1[Create chatRooms doc]
        X2[Add self to memberIds]
        X3[Write as another senderId]
        X4[Read rooms not in memberIds]
    end

    subgraph BackendOnly["Backend ONLY"]
        B1[POST /api/chat/room]
        B2[Firebase Admin writes]
        B3[Block enforcement before room]
        B4[Moderation / ban]
    end
```

Firestore Security Rules enforce membership; room creation stays server-side.

---

## Live streaming vs DM chat

```mermaid
flowchart LR
    subgraph DM["Direct messages"]
        D1[Firestore]
        D2[ChatDetailView]
        D3[WhatsApp-style]
    end

    subgraph Live["Live broadcast"]
        L1[Socket.IO / Zego]
        L2[LiveBroadcastView]
        L3[Room comments — ephemeral]
    end

    DM -.->|separate systems| Live
```

Do not merge live room comment storage with DM `chatRooms` unless product explicitly requires it.

---

## Optional Cloud Functions

| Trigger | Purpose |
| --- | --- |
| `onCreate` message | Update `lastMessage`, increment `unreadCount`, send FCM |
| `onUpdate` read status | Sync delivery/read to PostgreSQL |
| `onSchedule` | Delete expired disappearing messages |
| `onCreate` report webhook | Alert moderators |

Functions are **optional in Phase 3** but recommended before production scale.

---

## Flutter module layout (target)

```
lib/
  services/chat/
    chat_firebase_service.dart    # Custom token, Firestore streams, send
    chat_media_service.dart       # Storage uploads
    chat_fcm_service.dart         # Phase 6
  repo/chat/
    chat_repo.dart                # REST: list, detail, room, firebase-token
    models/
      chat_room_model.dart
      chat_message_model.dart
  app/user_flow/messages/         # existing GetX modules
```

Matches project conventions: `bindings/`, `controllers/`, `views/`, `repo/`.

---

## Next documents

- Schema details → [03 — Firestore schema](./03-firestore-schema.md)
- Rollout timeline → [04 — Phase-wise plan](./04-phase-wise-plan.md)
- API list → [06 — API reference](./06-api-reference.md)
