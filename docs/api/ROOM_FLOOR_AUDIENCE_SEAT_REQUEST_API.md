# Audio & Video Rooms — Floor Audience + Seat Request (API Handover)

**App:** `qobo_one_live` (Flutter)  
**Audience:** Backend + Mobile  
**Date:** 2026-08-02  
**Status:** Spec for implementation (do not ship until both sides agree)  
**Scope:** **Audio rooms** and **Video rooms** only (not live-stream Go Live, unless noted)

---

## 0. Goal (product)

Today (party rooms):

1. Optional **host join approval** gates entering the room at all.
2. Empty seats mostly open **Invite**.
3. **Request** bottom button calls `request_to_speak`, but host has little/no approve UI.
4. Gifts: `scope: room | user` — room gifts credit almost everyone in-room on mobile.

**Target:**

| Rule | Behavior |
|------|----------|
| Room entry | **Anyone can join** audio/video rooms. Pause / disable host **join accept–reject** for these rooms (comment/disable on mobile; backend treat as open join). |
| Who sits on mic seats | Users who **already follow the host** may take / sit on empty seats (subject to lock/admin rules). |
| Who stays on floor | Users who **do not follow the host** join the room but appear in a **horizontal floor audience strip** (below seats, above chat input), overlapping avatars when many. |
| Gift from floor user | Floor user **can send gifts**; coins credit **host** and/or **specific seated user** (normal `user` / targeted gift). |
| Gift “to all” from host/seat | Coins go **only to seated users** (mic seats), **not** to floor-list users. |
| Floor user wants a seat | Tap empty seat → options **Invite** (host/admin) and/or **Request to seat**. Request → host dialog → **Allow** moves user from floor list onto that seat (then they can earn seat/room gifts). |

This must work for **AUDIO** and **VIDEO** rooms without breaking mute/kick/admin/invite/gift/Zego join.

---

## 1. Definitions

| Term | Meaning |
|------|---------|
| **Host** | Room owner; UI seat 1; `role: host` on seats payload |
| **Seated user** | Occupies a mic seat (`userId` non-null on `GET /api/room/seats`) |
| **Floor audience** | Joined room media + presence, **not** on a seat; shown in bottom horizontal strip |
| **Follower** | Current user **follows host** (social graph) at time of seat action |
| **Non-follower** | Does not follow host → must stay on floor until host approves a **seat request** (or until they follow + take seat, if product allows) |
| **Seat request** | Ask host to place requester on a specific empty `seat_id` (not the same as room join-request) |

**Important:** Room **join approval** (`/api/room/join-request`) ≠ **seat request**.  
Join approval = enter room at all.  
Seat request = move from floor → mic seat.

---

## 2. Current API baseline (do not break)

### 2.1 Seats (existing — keep)

```http
GET /api/room/seats?room_id={uuid}
```

Example shape (already in production):

```json
{
  "statusCode": 1,
  "message": "Seats fetched",
  "data": {
    "room_id": "557a2f38-ca12-42eb-b01d-d62e86ede060",
    "seatConfig": 4,
    "backgroundImage": "...",
    "backgroundId": "...",
    "seats": [
      {
        "seatNo": 1,
        "userId": "6aae455a-9bc0-41e3-88dc-a0e86fc2c6f7",
        "name": "Test Host 3",
        "avatarUrl": "...",
        "role": "host",
        "isMuted": false,
        "isLocked": false,
        "diamonds": 0,
        "isAdmin": true,
        "avatarFrame": null,
        "isVIP": false,
        "vipFrameUrl": null,
        "pattiStyle": "classic",
        "isCoinsSeller": false
      }
    ]
  }
}
```

### 2.2 Mic / invite / admin (existing)

| Method | Path | Notes |
|--------|------|--------|
| POST | `/api/room/mic-action` | Mobile today: `mute`, `unmute`, `request_to_speak` |
| GET | `/api/room/invite-candidates` | Invite picker |
| POST | `/api/room/invite` | Invite to seat |
| POST | `/api/room/invite/respond` | Accept/decline invite |
| POST | `/api/room/admin-action` | `make_admin` / `remove_admin` |
| POST | `/api/room/kick` | Remove from room |

### 2.3 Join approval (existing — **pause for party rooms**)

| Method | Path |
|--------|------|
| POST | `/api/room/join` |
| POST | `/api/room/join-request` (+ respond / cancel / status / list) |
| POST | `/api/room/settings` (`joinApprovalRequired`) |

### 2.4 Gifts (existing)

```http
POST /api/economy/send-gift
```

Body (mobile today):

```json
{
  "roomId": "uuid",
  "giftId": "uuid",
  "receiverId": "uuid-or-null",
  "quantity": 1,
  "scope": "room",
  "clientGiftId": "client-uuid"
}
```

`scope`: `"room"` | `"user"` only today.

---

## 3. Product rules (authoritative)

### 3.1 Join (audio + video)

1. Disable / ignore **host join accept–reject** for audio & video rooms for this release.
2. `POST /api/room/join` always succeeds for public rooms (password/private still apply).
3. Mobile: stop forcing `join-request` gate for audio/video listing joins (comment out / feature-flag off).
4. Live streaming join-approval can stay as-is (out of scope unless product says otherwise).

### 3.2 After join — where does the user go?

| Condition | Placement |
|-----------|-----------|
| User is **host** | Seat 1 |
| User **follows host** | Eligible to sit on empty unlocked seats (take / invite / request as designed) |
| User **does not follow host** | Added to **floor audience**; **cannot** occupy a seat until host approves a seat request (or invite accept) |

Recommended backend enforcement (required):

- Reject seat take / auto-sit for non-followers with code `FOLLOW_REQUIRED_FOR_SEAT` (or place them on floor only).
- Host invite accept and host seat-request approve **override** follow requirement (host explicitly allowed them on seat).

### 3.3 Empty seat tap (mobile UX)

| Actor | Options |
|-------|---------|
| Host / room admin | **Invite** (existing) + optionally lock (if supported) |
| Follower (not seated) | **Sit / Take seat** (new or via mic-action) |
| Non-follower (floor) | **Request to seat** (new) — and they should **not** get a silent auto-sit |

Dialog for host when request arrives: requester avatar, name, requested `seatNo`, **Allow** / **Reject**.

On **Allow**: remove from floor list → occupy that seat → can receive seat/room gift credits.

### 3.4 Gift earning matrix (backend must enforce)

| Sender | Gift mode | Recipients who get coins |
|--------|-----------|---------------------------|
| Anyone (seat or floor) | `scope: user` + `receiverId` | **Only** that user (host or seated or even floor if targeted — product: allow target host/seat; floor-to-floor optional) |
| Floor user | `scope: room` (“to all”) | **Only seated users + host seats** — **exclude floor audience** |
| Seated user / host | `scope: room` (“to all”) | **Only seated users** (all mic seats except sender) — **exclude floor audience** |
| Floor user | gift to host | Host earns |
| Floor user | gift to a seat user | That seat user earns |

**Critical change vs current mobile assumption:**  
Today mobile often treats `scope: room` as “everyone in room except sender”.  
New rule: **`scope: room` = all seated participants except sender** (mic seats only). Floor list never earns from `room` gifts.

Optional clearer API (recommended): introduce `scope: "seats"` as alias of new room meaning, keep `room` = seats-only for party rooms. See §5.

---

## 4. Changes to existing APIs

### 4.1 `GET /api/room/seats` — **extend `data`**

Keep existing `seats[]`. Add floor audience + flags:

```json
{
  "statusCode": 1,
  "message": "Seats fetched",
  "data": {
    "room_id": "557a2f38-ca12-42eb-b01d-d62e86ede060",
    "seatConfig": 4,
    "backgroundImage": "...",
    "backgroundId": "...",
    "host_id": "6aae455a-9bc0-41e3-88dc-a0e86fc2c6f7",
    "viewer_follows_host": false,
    "my_placement": "floor",
    "seats": [ /* unchanged shape */ ],
    "floor_audience": [
      {
        "userId": "uuid",
        "name": "Guest",
        "avatarUrl": "...",
        "avatarFrame": null,
        "isVIP": false,
        "vipFrameUrl": null,
        "isCoinsSeller": false,
        "joinedAt": "2026-08-02T06:00:00.000Z"
      }
    ],
    "pending_seat_requests": [
      {
        "request_id": "uuid",
        "userId": "uuid",
        "name": "Guest",
        "avatarUrl": "...",
        "seatNo": 2,
        "createdAt": "2026-08-02T06:01:00.000Z"
      }
    ]
  }
}
```

| New field | Type | Who needs it |
|-----------|------|----------------|
| `host_id` | string | Mobile follow + gift target |
| `viewer_follows_host` | bool | **Current caller** follows host? |
| `my_placement` | `seat` \| `floor` \| `none` | Where am I right now |
| `floor_audience` | array | Horizontal strip (exclude seated users; exclude self optional or include) |
| `pending_seat_requests` | array | Host/admin inbox (may also come via socket) |

**Compatibility:** Old clients ignore new fields. New mobile requires them for the strip.

**Polling:** Mobile already polls seats ~2s. Floor list can ride the same poll **or** socket push (preferred for requests).

### 4.2 `POST /api/room/join` — **placement on join**

Response `data` should include:

```json
{
  "placement": "seat" | "floor",
  "seatNo": 1,
  "viewer_follows_host": true,
  "host_id": "uuid"
}
```

Rules:

1. Host rejoining → seat 1.
2. Follower → may auto-sit first free seat **or** join as floor until they tap seat (product choice — **recommend: join as floor/listener until they take seat**, except host).  
   **Product from this ticket:** non-followers → floor; followers may sit. Clarify auto-sit:  
   - **Recommended:** Followers do **not** auto-sit; they tap empty seat to sit. Non-followers only **Request to seat**.
3. Non-follower → `placement: "floor"` always.

### 4.3 `POST /api/room/mic-action` — **extend actions**

Existing body:

```json
{
  "room_id": "uuid",
  "target_user_id": "uuid-optional",
  "action": "mute",
  "seat_id": 2
}
```

| Action | Who | Behavior |
|--------|-----|----------|
| `mute` / `unmute` | Host/admin/self | Unchanged |
| `request_to_speak` | **Deprecated for this flow** | Prefer new seat-request API; or map to seat request on empty `seat_id` |
| **`take_seat`** *(new)* | Follower only | Occupy empty unlocked `seat_id`; fail if non-follower / locked / occupied |
| **`leave_seat`** *(new)* | Seated user | Leave seat → move to floor (still in room) |
| **`approve_seat`** *(optional alias)* | Host | Prefer dedicated respond endpoint §5 |

Error codes (suggested):

| Code | When |
|------|------|
| `FOLLOW_REQUIRED_FOR_SEAT` | Non-follower tried `take_seat` |
| `SEAT_LOCKED` | Locked seat |
| `SEAT_OCCUPIED` | Already taken |
| `NOT_IN_ROOM` | Not joined |
| `NOT_HOST` | Approve/reject without permission |

### 4.4 `POST /api/economy/send-gift` — **recipient rules**

For `session_type` / room type `audio_room` | `video_room`:

| `scope` | Backend credit targets |
|---------|------------------------|
| `user` | Exact `receiverId` only (must be in room) |
| `room` | All **seated** userIds except sender (**exclude `floor_audience`**) |

Return in response (helps mobile sync diamonds):

```json
{
  "statusCode": 1,
  "data": {
    "credited_user_ids": ["uuid1", "uuid2"],
    "scope": "room",
    "amount_each": 10
  }
}
```

Also update seat `diamonds` for credited seated users so `GET /seats` stays correct.

### 4.5 Join-approval APIs

| Backend | Mobile |
|---------|--------|
| Keep endpoints for future / live | **Comment out / feature-flag off** forced approval for audio+video list joins |
| For party rooms, `joinApprovalRequired` treat as **false** or ignore | Default create toggle off; do not call `forceApprovalFlow` for AUDIO/VIDEO |

---

## 5. New APIs (required)

### 5.1 List floor audience (optional if always embedded in seats)

```http
GET /api/room/floor-audience?room_id={uuid}
```

**Response:**

```json
{
  "statusCode": 1,
  "data": {
    "room_id": "uuid",
    "items": [ /* same as floor_audience[] */ ],
    "total": 12
  }
}
```

Prefer embedding in seats to avoid extra poll; this endpoint is for pagination if strip grows large.

### 5.2 Create seat request (floor → host)

```http
POST /api/room/seat-request
```

**Body:**

```json
{
  "room_id": "uuid",
  "seat_id": 2,
  "session_type": "audio_room"
}
```

`session_type`: `audio_room` | `video_room`

**Success (pending):**

```json
{
  "statusCode": 1,
  "message": "Seat request sent",
  "data": {
    "request_id": "uuid",
    "room_id": "uuid",
    "seat_id": 2,
    "status": "pending",
    "expires_at": "2026-08-02T06:10:00.000Z"
  }
}
```

**Errors:**

- Already seated → `ALREADY_ON_SEAT`
- Seat locked/occupied → `SEAT_UNAVAILABLE`
- Duplicate pending → return existing `request_id` or `ALREADY_PENDING`
- Not in room → `NOT_IN_ROOM`

**Side effects:**

1. Notify host (and admins if desired) via socket + FCM.
2. Add to `pending_seat_requests` on seats payload.

### 5.3 Host respond to seat request

```http
POST /api/room/seat-request/respond
```

**Body:**

```json
{
  "room_id": "uuid",
  "request_id": "uuid",
  "action": "approve"
}
```

`action`: `approve` | `reject`

**On approve:**

1. Place requester on requested `seat_id` (if still free; else next free or fail with `SEAT_UNAVAILABLE`).
2. Remove from `floor_audience`.
3. Clear pending request.
4. Socket to requester: `seat_request_approved` (+ updated seats).
5. Broadcast seats update to room.

**On reject:**

1. Socket/FCM to requester: `seat_request_rejected`.
2. User stays on floor.

### 5.4 Cancel seat request (requester)

```http
POST /api/room/seat-request/cancel
```

```json
{
  "room_id": "uuid",
  "request_id": "uuid"
}
```

### 5.5 List pending seat requests (host)

```http
GET /api/room/seat-requests?room_id={uuid}&status=pending
```

Useful if host opens “Seat requests” sheet; also embed in seats for polling fallback.

---

## 6. Realtime (socket + FCM)

Emit to host (and optionally room channel):

| Event | Payload (min) |
|-------|----------------|
| `seat_request` | `request_id`, `room_id`, `seat_id`, `requester_id`, `requester_name`, `requester_avatar`, `expires_at` |
| `seat_request_approved` | `request_id`, `room_id`, `seat_id`, `user_id` |
| `seat_request_rejected` | `request_id`, `room_id`, `message` |
| `seat_request_cancelled` | `request_id`, `room_id` |
| `floor_audience_updated` | `room_id` (clients refresh seats) |
| `seats_updated` | `room_id` (optional; or rely on poll) |

Reuse patterns from join-request FCM types if convenient, but **use distinct type names** so mobile does not reuse join-approval UI.

Suggested FCM `type` values:

- `seat_request`
- `seat_request_approved`
- `seat_request_rejected`

---

## 7. Mobile responsibilities

### 7.1 Disable room join accept/reject (audio/video)

- Comment out / feature-flag `forceApprovalFlow` for AUDIO/VIDEO listing joins.
- Do not auto-enable `joinApprovalRequired` on host bootstrap for party rooms.
- Keep join-request UI code for later / live if needed.

### 7.2 Floor audience UI (audio + video)

- Horizontal overlapping avatar strip **below seats, above** “Say something…” input (per screenshot region).
- Data from `floor_audience` on seats poll (or socket).
- Tap avatar → profile / gift-to-user (optional, same as viewers sheet).

**Video rooms:** today seat overlay is audio-focused. Mobile must show **same seat grid + floor strip** for VIDEO party rooms (or shared stage widget), not only Zego grid — otherwise this product is audio-only.

### 7.3 Empty seat actions

- Host/admin: Invite (existing) + maybe lock.
- Follower: Take seat → `take_seat`.
- Non-follower: **Request to seat** → `POST /seat-request` → waiting toast; host sees dialog.

### 7.4 Host seat-request dialog

- Mirror join-request banner style: avatar, name, seat number, **Allow** / **Reject**.
- On Allow → `seat-request/respond` `approve`.
- Poll `pending_seat_requests` as fallback if socket misses.

### 7.5 Gifts

- Update local earnings logic: `scope: room` → credit **seated users only**.
- Floor senders: allow gift to host / specific seat; room gift still seats-only.
- Trust backend `credited_user_ids` when present.

### 7.6 Follow

- Use `viewer_follows_host` from seats/join; refresh after Follow button.
- If user follows host mid-room, unlock **Take seat** without requiring seat request (backend must recompute `viewer_follows_host`).

---

## 8. Backend responsibilities (checklist)

| # | Item | Priority |
|---|------|----------|
| 1 | Party room join always open (ignore join-approval for audio/video) | P0 |
| 2 | Maintain `floor_audience` membership on join/leave/kick | P0 |
| 3 | Enforce follow gate on `take_seat` | P0 |
| 4 | Seat-request create / respond / cancel / list | P0 |
| 5 | Extend `GET /seats` with floor + flags + pending requests | P0 |
| 6 | Gift `scope: room` credits **seats only** in party rooms | P0 |
| 7 | Socket/FCM for seat requests | P0 |
| 8 | Approve seat diamonds for room gifts correctly | P0 |
| 9 | Kick removes from seat **and** floor | P0 |
| 10 | Video room same seat/floor model as audio | P0 |
| 11 | Idempotent approve if seat taken | P1 |
| 12 | Expire seat requests | P1 |

---

## 9. Suggested sequence

### 9.1 Non-follower joins and requests seat

```text
Guest                Backend                 Host app
  |  POST /join         |                       |
  |-------------------->|                       |
  |  placement=floor    |                       |
  |  GET /seats (floor) |                       |
  |  POST /seat-request |                       |
  |-------------------->|  socket seat_request  |
  |                     |---------------------->|
  |                     |      Allow            |
  |                     |<----------------------|
  |                     |  place on seat        |
  |  seat_approved      |  seats broadcast      |
  |<--------------------|<----------------------|
  |  leave floor strip, show on seat            |
```

### 9.2 Room gift from seated user

```text
Seated A  --send-gift scope=room-->  Backend
Backend credits: all seated userIds except A
Backend does NOT credit floor_audience
```

---

## 10. Non-goals / out of scope

- Changing live-stream (Go Live) audience model (unless later).
- Replacing Zego IDs (already separate).
- Mic “request_to_speak” without seat number (replace with seat-request).
- Paying / withdraw flows.

---

## 11. Test plan (QA)

| # | Case | Expected |
|---|------|----------|
| 1 | Non-follower joins audio room | In room, on floor strip, not on seats |
| 2 | Follower taps empty seat | Takes seat (or invite flow) |
| 3 | Non-follower taps empty seat → Request | Host gets dialog |
| 4 | Host Allow | Guest leaves strip, occupies seat, earns room gifts |
| 5 | Host Reject | Guest stays on floor; toast rejected |
| 6 | Floor user gifts host | Host coins/diamonds up |
| 7 | Floor user gifts seat 3 | Seat 3 diamonds up only |
| 8 | Host sends room gift | All seats except host earn; floor does not |
| 9 | Seated user sends room gift | Other seats earn; floor does not |
| 10 | Same flows on **video** room | Parity with audio |
| 11 | Join-approval UI not blocking party join | Direct join |
| 12 | Kick floor user | Removed from strip + Zego |
| 13 | Follow host then take seat | Allowed without seat-request |

---

## 12. Open questions for product/backend

1. After non-follower **follows** host in-room, can they **Take seat** immediately without request? (**Recommend: yes.**)
2. Should followers **auto-sit** on join or only after tapping a seat? (**Recommend: tap to sit.**)
3. Can floor users be gift **receivers** for `scope: user`? (**Recommend: yes if explicitly targeted; no for `room`.**)
4. Do **room admins** also receive seat-request dialogs? (**Recommend: yes.**)
5. Max floor audience size / pagination?
6. When requested seat is taken before approve — auto next seat or fail?

---

## 13. Summary for backend team

**Must build**

1. Floor audience membership + seats payload fields.  
2. Seat-request APIs + host notify/respond.  
3. Follow gate on take seat; host approve bypasses gate.  
4. Gift `room` scope = seated only.  
5. Open join for audio/video (no join-approval required).  

**Must keep working**

- `GET /seats`, mute/unmute, invite, kick, admin, backgrounds, Zego join.  

**Mobile will**

- Disable join accept/reject for party rooms.  
- Add floor strip UI (audio + video).  
- Wire seat request + host Allow/Reject dialog.  
- Fix gift earnings UI to match seats-only room gifts.  

---

*End of handover. Please confirm §12 answers before coding so mobile and backend ship the same rules.*
