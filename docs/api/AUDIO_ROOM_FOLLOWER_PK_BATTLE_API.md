# Audio Room Follower PK Battle — Backend API Support Doc

**App:** `qobo_one_live` (Flutter)  
**Audience:** Backend team  
**Date:** 2026-08-05  
**Status:** **Client requirements for new audio-room PK mode** — share with backend; mobile will implement after APIs are ready.  
**Related (existing):** `docs/api/PK_BATTLE_API_AND_MOBILE_HANDOFF.md` = current **room-vs-room** PK. This doc is a **new mode** and must not break that flow.

---

## 1. Product goal (client words → rules)

### 1.1 What the client wants (audio room)

1. User **Rahul** is in an **audio room** and taps **PK Battle**.
2. A challenge is created. **Push / invite goes only to Rahul’s followers**.
3. Only people allowed to **accept** that challenge are:
   - Rahul’s **followers** (from the push / invite list), **and/or**
   - People **already in the same audio room** who tap the **PK icon on Rahul’s seat/profile** (same UX idea as joining floor / seat flows — even if they are not followers).
4. When **Sumit** accepts / joins, battle becomes **Rahul vs Sumit**.
5. **Rahul** (challenger) chooses battle length: **5 / 10 / 15 minutes**.
6. During battle:
   - Rahul’s supporters may **gift only Rahul** (must be Rahul’s follower to gift Rahul’s side).
   - Sumit’s supporters may **gift only Sumit** (must be Sumit’s follower to gift Sumit’s side).
   - Cross-gifting the opponent is **rejected**.
7. When the timer ends, **higher gift-coin score wins**. Tie = draw.

### 1.2 What stays unchanged

| Item | Keep as-is |
|------|------------|
| Existing **room-vs-room** PK (`/api/pk/search`, `send-request` with `target_room_id`, etc.) | Still used for current PK screen / room matchmaking |
| Audio room seats, floor audience, seat request, gifts outside PK | Unchanged except gift rules **while a follower-PK is active** |
| Auth | Bearer token on all REST calls |

### 1.3 New mode name (recommended)

Use an explicit mode so old and new PK do not collide:

```text
mode = "audio_follower_pk"
```

Existing room PK can stay:

```text
mode = "room_pk"   // current behaviour
```

---

## 2. High-level flow

```text
Rahul (audio room)                    Rahul followers              Same audio room users
      |                                      |                              |
      | POST /api/pk/follower/start          |                              |
      |------------------------------------->| FCM + socket invite           |
      |                                      |                              |
      | seat/profile shows pkBadge=true  ---------------------------------->|
      |                                      |                              |
      |                         Sumit POST accept / join                    |
      |<--------------------------------------------------------------------|
      |                                      |                              |
      | POST /api/pk/follower/set-duration (5|10|15 min)                    |
      |------------------------------------->|                              |
      |                                      |                              |
      |======== battle active ==============|======= gift side-lock =======|
      | scores via gifts + socket            |                              |
      |                                      |                              |
      | timer end → complete / winner        |                              |
```

**Suggested phases**

| `status` | Meaning |
|----------|---------|
| `waiting_opponent` | Rahul started PK; waiting for first valid opponent |
| `duration_pending` | Opponent joined; Rahul must pick 5/10/15 |
| `active` | Timer running; gifts update scores |
| `completed` | Winner / draw declared |
| `cancelled` | Rahul cancelled before start, or expired waiting |
| `expired` | No opponent within invite window |

---

## 3. Domain model (suggested)

### 3.1 `FollowerPkBattle`

| Field | Type | Notes |
|-------|------|--------|
| `battle_id` | uuid | Primary id |
| `mode` | string | always `audio_follower_pk` |
| `room_id` | uuid | Audio room where PK was started |
| `challenger_user_id` | uuid | Rahul |
| `opponent_user_id` | uuid? | Sumit (null until joined) |
| `status` | string | see table above |
| `duration_seconds` | int? | `300` / `600` / `900` after challenger picks |
| `allowed_durations` | int[] | server constant `[300,600,900]` |
| `started_at` | datetime? | when status → `active` |
| `ends_at` | datetime? | `started_at + duration` |
| `challenger_score` | int | gift coins credited to Rahul’s side |
| `opponent_score` | int | gift coins credited to Sumit’s side |
| `winner_user_id` | uuid? | null on draw |
| `result` | `challenger_win` \| `opponent_win` \| `draw` \| null |
| `invite_expires_at` | datetime | e.g. 120s–300s while waiting for opponent |
| `created_at` / `updated_at` | datetime | |

### 3.2 Side / supporter rules

| Actor | Rule |
|-------|------|
| Challenger / opponent | Contestants; cannot gift themselves (existing gift rules) |
| Gifter → Rahul | Allowed only if gifter **follows Rahul** |
| Gifter → Sumit | Allowed only if gifter **follows Sumit** |
| Gifter → wrong side | `403` / `statusCode` fail with clear message |
| Non-follower trying to gift either side during this PK | Reject |

Backend must resolve “follows” from the existing follow graph (same as app Follow Host).

### 3.3 Who can become the opponent

Accept **first valid join** only (1v1). Reject later joiners.

| Join path | Eligibility |
|-----------|-------------|
| A. Invite accept | Caller is in Rahul’s **followers** list at accept time |
| B. In-room join (PK badge) | Caller is in the **same `room_id`** (seat or floor), and battle is `waiting_opponent` |

Optional hardening (ask product if needed):

- Block opponent if they already have another `active` / `waiting_opponent` follower-PK.
- Block if caller is the challenger.

---

## 4. REST APIs (required)

Envelope (same as rest of app):

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": { }
}
```

Accepted success: `statusCode` in `1 | 200 | 201 | true`.

All endpoints: `Authorization: Bearer <token>`.

---

### 4.1 Start follower PK (from audio room)

```http
POST /api/pk/follower/start
Content-Type: application/json
```

**Body**

```json
{
  "room_id": "audio-room-uuid",
  "mode": "audio_follower_pk"
}
```

**Rules**

- Caller must be in that audio room (seat or floor).
- Prefer: only one `waiting_opponent` / `duration_pending` / `active` follower-PK per user and per room.
- Create battle with `status=waiting_opponent`.
- Fan-out invite to **followers of challenger** (FCM + socket). Do **not** notify non-followers.

**Response `data`**

```json
{
  "battle_id": "uuid",
  "mode": "audio_follower_pk",
  "room_id": "audio-room-uuid",
  "status": "waiting_opponent",
  "challenger": {
    "user_id": "rahul-id",
    "name": "Rahul",
    "avatar": "https://..."
  },
  "opponent": null,
  "duration_seconds": null,
  "allowed_durations": [300, 600, 900],
  "invite_expires_at": "2026-08-05T16:05:00.000Z",
  "challenger_score": 0,
  "opponent_score": 0,
  "notified_follower_count": 128
}
```

**Errors**

| Case | Message example |
|------|-----------------|
| Not in room | `You must be in the audio room to start PK.` |
| Already in PK | `You already have an active PK battle.` |
| Room busy | `This room already has an active follower PK.` |

---

### 4.2 List / search challengeable followers (optional but recommended)

For an in-app “invite list” UI (in addition to push):

```http
GET /api/pk/follower/invitees?battle_id={battle_id}
```

or

```http
GET /api/pk/follower/invitees?room_id={room_id}
```

**Response `data`**

```json
{
  "followers": [
    {
      "user_id": "sumit-id",
      "name": "Sumit",
      "avatar": "https://...",
      "is_online": true,
      "in_same_room": false,
      "can_accept": true
    }
  ]
}
```

---

### 4.3 Accept challenge (follower path)

```http
POST /api/pk/follower/accept
Content-Type: application/json
```

**Body**

```json
{
  "battle_id": "uuid"
}
```

**Rules**

- Battle `status` must be `waiting_opponent`.
- Caller must follow challenger (or be on invite list).
- First accept wins; others get “already filled”.
- On success → `status=duration_pending`, set `opponent_user_id`.
- Notify challenger (socket + FCM): pick duration.

**Response `data`** — full battle object (same shape as status).

---

### 4.4 Join from audio room (PK badge on profile / seat)

Same UX idea as floor audience / seat join — tap PK icon on the starter.

```http
POST /api/pk/follower/join-from-room
Content-Type: application/json
```

**Body**

```json
{
  "battle_id": "uuid",
  "room_id": "audio-room-uuid"
}
```

**Rules**

- Caller is in `room_id` (seat or floor).
- Battle belongs to that `room_id` and is `waiting_opponent`.
- Non-followers **are allowed** on this path (per client).
- First join wins → `duration_pending`.

If backend prefers one endpoint, merge 4.3 + 4.4:

```http
POST /api/pk/follower/join
{ "battle_id": "...", "join_source": "invite" | "room_badge" }
```

with source-specific eligibility checks.

---

### 4.5 Challenger sets duration (then battle starts)

```http
POST /api/pk/follower/set-duration
Content-Type: application/json
```

**Body**

```json
{
  "battle_id": "uuid",
  "duration_seconds": 300
}
```

Allowed: `300` | `600` | `900` only.

**Rules**

- Only **challenger** can call.
- Status must be `duration_pending`.
- On success:
  - `status=active`
  - `started_at=now`, `ends_at=now+duration`
  - start server timer
  - notify both sides + room (socket)

**Response `data`**

```json
{
  "battle_id": "uuid",
  "status": "active",
  "duration_seconds": 300,
  "remaining_seconds": 300,
  "started_at": "...",
  "ends_at": "...",
  "challenger": { "user_id": "...", "name": "Rahul", "avatar": "..." },
  "opponent": { "user_id": "...", "name": "Sumit", "avatar": "..." },
  "challenger_score": 0,
  "opponent_score": 0
}
```

---

### 4.6 Reject / ignore invite (follower)

```http
POST /api/pk/follower/reject
Content-Type: application/json
```

```json
{ "battle_id": "uuid" }
```

Does **not** cancel the battle for others; only marks this user dismissed the invite (optional tracking).

---

### 4.7 Cancel waiting PK (challenger)

```http
POST /api/pk/follower/cancel
Content-Type: application/json
```

```json
{
  "battle_id": "uuid",
  "room_id": "audio-room-uuid"
}
```

Allowed while `waiting_opponent` or `duration_pending` (before `active`).  
Clear `pkBadge` on room seat payloads. Notify followers + room.

---

### 4.8 Get battle status (poll fallback)

```http
GET /api/pk/follower/status?battle_id={uuid}
```

**Response `data`**

```json
{
  "battle_id": "uuid",
  "mode": "audio_follower_pk",
  "room_id": "uuid",
  "status": "active",
  "duration_seconds": 300,
  "remaining_seconds": 187,
  "challenger": {
    "user_id": "rahul-id",
    "name": "Rahul",
    "avatar": "https://...",
    "score": 1200
  },
  "opponent": {
    "user_id": "sumit-id",
    "name": "Sumit",
    "avatar": "https://...",
    "score": 950
  },
  "challenger_score": 1200,
  "opponent_score": 950,
  "winner_user_id": null,
  "result": null,
  "last_gift": {
    "from_user_id": "...",
    "to_user_id": "rahul-id",
    "gift_name": "Rose",
    "coins": 50,
    "side": "challenger"
  }
}
```

Mobile will poll ~2s during `active` if socket drops (same pattern as room PK).

---

### 4.9 Active follower PK for room / me (restore UI)

```http
GET /api/pk/follower/active?room_id={uuid}
```

```http
GET /api/pk/follower/active-for-me
```

**Purpose**

- Room members re-open room → see who has `pkBadge` / ongoing battle.
- Challenger / opponent restore battle screen after kill-app.

**Response `data`**

```json
{
  "battle": { /* full status object or null */ },
  "pending_invite": {
    "battle_id": "uuid",
    "from_user": { "user_id": "...", "name": "Rahul", "avatar": "..." },
    "room_id": "uuid",
    "expires_at": "..."
  }
}
```

---

### 4.10 Force end (optional)

```http
POST /api/pk/follower/end
```

```json
{
  "battle_id": "uuid",
  "reason": "host_leave" | "admin" | "error"
}
```

Decide product rule: who may force-end (challenger only / both / admin).  
On end before timer: either cancel with no winner, or compute current scores — **please confirm**.

Default recommendation: if `active` and force-end by contestant → **cancel** (no winner) unless scores already unequal and product wants early winner.

---

### 4.11 Gift send during follower PK (extend existing gift API)

Existing:

```http
POST /api/economy/send-gift
```

(and legacy `/api/transactions/send-gift` if still used)

**Extra rules when an `audio_follower_pk` battle is `active` in that room:**

| Check | Action |
|-------|--------|
| `receiver_id` is challenger | Allow only if sender **follows challenger**; add gift coins to `challenger_score` |
| `receiver_id` is opponent | Allow only if sender **follows opponent**; add to `opponent_score` |
| `receiver_id` is someone else in room | Normal gift rules (optional: still allow non-PK gifts — **confirm**) |
| Sender does not follow the contestant they try to gift | Reject: `You can only gift the PK player you follow.` |
| Gift to opponent of the person you follow | Reject |

**Recommended gift response extras when PK credited**

```json
{
  "pk": {
    "battle_id": "uuid",
    "side": "challenger",
    "challenger_score": 1200,
    "opponent_score": 950,
    "credited_coins": 50
  }
}
```

Also emit socket `pk_follower_score_update` (see §5).

---

### 4.12 Room / seats payload — PK badge (required for in-room join)

Whenever seats / room detail / floor audience is returned for an audio room that has `waiting_opponent` or `duration_pending` / `active` follower PK, include badge fields on the **challenger** (and opponent once joined):

```json
{
  "userId": "rahul-id",
  "name": "Rahul",
  "pkBattle": {
    "active": true,
    "battle_id": "uuid",
    "status": "waiting_opponent",
    "mode": "audio_follower_pk",
    "can_join": true
  }
}
```

Mobile will show a **PK icon** on that seat/profile (like invite/floor actions). Tap → call `join-from-room`.

Also useful on room list / room detail:

```json
"active_follower_pk": {
  "battle_id": "uuid",
  "status": "waiting_opponent",
  "challenger_user_id": "rahul-id"
}
```

---

## 5. Socket.IO events (required)

Namespace / room channel: same pattern as existing room + `pk_*` events.

Prefer **new event names** so room-PK handlers stay clean:

| Event | To | When |
|-------|-----|------|
| `pk_follower_invite` | each follower of challenger | start |
| `pk_follower_waiting` | room channel | start / badge update |
| `pk_follower_joined` | challenger + room | opponent accepted/joined |
| `pk_follower_duration_set` | both contestants + room | after set-duration → active |
| `pk_follower_score_update` | both contestants + room / supporters | after gift |
| `pk_follower_completed` | both + room | timer end |
| `pk_follower_cancelled` | followers + room | cancel / expire |

### Example payloads

**`pk_follower_invite`**

```json
{
  "type": "pk_follower_invite",
  "battle_id": "uuid",
  "room_id": "uuid",
  "from_user": { "user_id": "rahul-id", "name": "Rahul", "avatar": "..." },
  "expires_at": "..."
}
```

**`pk_follower_score_update`**

```json
{
  "battle_id": "uuid",
  "challenger_score": 1200,
  "opponent_score": 950,
  "remaining_seconds": 140,
  "last_gift": {
    "from_user_id": "...",
    "to_user_id": "rahul-id",
    "gift_name": "Rose",
    "coins": 50,
    "side": "challenger"
  }
}
```

**`pk_follower_completed`**

```json
{
  "battle_id": "uuid",
  "status": "completed",
  "result": "challenger_win",
  "winner_user_id": "rahul-id",
  "challenger_score": 5000,
  "opponent_score": 4200,
  "duration_seconds": 300
}
```

---

## 6. FCM / push (required)

| `type` / `data.type` | Audience | Purpose |
|----------------------|----------|---------|
| `pk_follower_invite` | Challenger’s followers | Open accept UI / deep link |
| `pk_follower_joined` | Challenger | Opponent found → pick duration |
| `pk_follower_started` | Both contestants | Battle active |
| `pk_follower_completed` | Both contestants | Result screen |
| `pk_follower_cancelled` | Followers who got invite | Dismiss pending UI |

**Deep link / data fields (minimum)**

```json
{
  "type": "pk_follower_invite",
  "battle_id": "uuid",
  "room_id": "uuid",
  "from_user_id": "rahul-id",
  "from_user_name": "Rahul"
}
```

Mobile already has `PkBattlePushHandler` for room PK; we will extend it for these `type`s after backend confirms names.

---

## 7. Timer & completion (server-authoritative)

1. Timer starts only after `set-duration` succeeds.
2. Server owns `ends_at`; clients show `remaining_seconds` from status/socket.
3. At `ends_at`:
   - Freeze gift credits for this battle.
   - Compare `challenger_score` vs `opponent_score`.
   - Set `result` + `winner_user_id`.
   - Emit `pk_follower_completed`.
4. Waiting without opponent: expire after `invite_expires_at` (recommend **120s or 180s** — confirm).

Score = **sum of gift coin values** credited to that contestant during `active` only (not diamonds unless product says otherwise).

---

## 8. Edge cases (please implement)

| Case | Expected |
|------|----------|
| Second person tries to join after Sumit | Reject: battle already has opponent |
| Rahul leaves room while `waiting_opponent` | Cancel battle + clear badge |
| Sumit leaves during `duration_pending` | Cancel or reopen waiting — **confirm** |
| Contestant leaves during `active` | Recommend: forfeit → other wins, or cancel — **confirm** |
| Follower unfollows mid-battle then tries to gift | Reject gift |
| User follows both Rahul and Sumit | May gift **either** side (each gift still targets one receiver) |
| Gift API called with wrong room | Reject |
| Room-PK and follower-PK both | Prefer **only one PK mode active per room** |

---

## 9. API checklist for backend (copy/paste)

| # | Method | Path | Owner |
|---|--------|------|--------|
| 1 | `POST` | `/api/pk/follower/start` | Start waiting PK + notify followers |
| 2 | `GET` | `/api/pk/follower/invitees` | Optional follower invite list |
| 3 | `POST` | `/api/pk/follower/accept` | Follower accepts invite |
| 4 | `POST` | `/api/pk/follower/join-from-room` | In-room PK badge join |
| 5 | `POST` | `/api/pk/follower/reject` | Dismiss invite |
| 6 | `POST` | `/api/pk/follower/set-duration` | Challenger picks 300/600/900 → start |
| 7 | `POST` | `/api/pk/follower/cancel` | Cancel before active |
| 8 | `GET` | `/api/pk/follower/status` | Poll scores / timer |
| 9 | `GET` | `/api/pk/follower/active` | Restore by `room_id` |
| 10 | `GET` | `/api/pk/follower/active-for-me` | Restore invites / my battle |
| 11 | `POST` | `/api/pk/follower/end` | Optional force end |
| 12 | Extend | `POST /api/economy/send-gift` | Side-locked gifts + score |
| 13 | Extend | Room seats / floor payloads | `pkBattle` badge fields |
| 14 | Socket | `pk_follower_*` events | Realtime |
| 15 | FCM | `pk_follower_*` types | Offline / background |

---

## 10. Decisions needed from product / backend (before mobile coding)

Please confirm:

1. **In-room join:** non-followers in the same audio room **can** join via PK badge — OK?  
2. **Invite TTL:** 120s / 180s / 300s?  
3. **Force leave during active battle:** forfeit vs cancel?  
4. **Normal gifts** to non-contestants in the same room during PK — still allowed?  
5. **Who picks duration:** only challenger (as above), or either side?  
6. **Reuse** any existing `/api/pk/*` room endpoints vs **new `/api/pk/follower/*`** only?  
   - Mobile recommendation: **new `/api/pk/follower/*`** so room-PK stays stable.

---

## 11. Mobile implementation note (after backend ships)

Flutter will **not** implement this UI/flow until backend shares:

- Final path names + request/response JSON samples  
- Socket event names  
- FCM `type` strings  
- Gift rejection error codes/messages  

Then mobile will:

- Wire audio-room PK button → `follower/start`  
- Show PK badge on seats from room payload  
- Duration picker (5 / 10 / 15)  
- Side-aware gift UI (only giftable contestant for current user)  
- Result screen from `completed`  

Existing room-vs-room PK screen remains for the old mode until product deprecates it.

---

## 12. Example happy path (Rahul vs Sumit, 5 min)

1. Rahul `POST /api/pk/follower/start` `{ room_id }`  
2. Backend notifies Rahul’s followers; room seats show Rahul `pkBattle.active=true`  
3. Sumit (follower) `POST /api/pk/follower/accept` **or** (in room) `join-from-room`  
4. Rahul `POST /api/pk/follower/set-duration` `{ duration_seconds: 300 }`  
5. Battle `active`; Rahul followers gift Rahul only; Sumit followers gift Sumit only  
6. At `ends_at`, backend completes; higher score wins  
7. Clients show Victory / Defeat / Draw  

---

**Document owner:** Mobile (Flutter) — Parth / qobo_one_live  
**Next step:** Backend confirm §10 + implement §9 checklist → share sample responses → mobile implements UI.
