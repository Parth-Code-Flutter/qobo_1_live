# Messages — New Match, Follow/Unfollow & Chat (Backend Spec)

**Document version:** 1.0  
**Last updated:** 2026-06-02  
**Mobile app:** qobo_one_live (Flutter)  
**Audience:** Backend team  

This document defines the APIs required for the **Messages tab → New Match** row, **follow/unfollow**, and connecting users so they can appear in the **Message** inbox and open **1-on-1 chat**.

---

## 1. Product goal (mobile)

| Area | Expected behaviour |
|------|-------------------|
| **New Match** | Show a real list of app users (not dummy search). User can **Follow / Unfollow** from this list. |
| **Connect** | After follow (or mutual follow — see §5), user can open chat from the match row or inbox. |
| **Message** | Inbox lists existing conversations (`GET /api/chat/list`). Tapping opens chat detail. |

**Current mobile gap (for context):**

- `MessagesTabController` loads matches via `GET /api/user/search?query=a` (placeholder query).
- `MessageMatchUser` has no `userId` / `isFollowing` — follow cannot work on this row yet.
- Follow/unfollow **is already wired** on Discover search via `POST /api/user/follow-unfollow`.
- `FollowListView` UI exists but is **not bound** to `GET /api/user/follow-list`.
- Message list on Messages tab is **static empty**; `ChatRepo.getInbox()` exists but is not used on that screen.

---

## 2. General conventions

### Authentication

All endpoints in this document require:

```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

(unless noted otherwise)

### Response envelope

Mobile accepts both legacy and canonical shapes. **Preferred for all new/updated endpoints:**

```json
{
  "statusCode": 1,
  "message": "Human-readable message",
  "data": {}
}
```

| `statusCode` | Meaning |
|--------------|---------|
| `1` | Success |
| `0` | Business failure (validation, blocked user, not allowed to chat, etc.) |

HTTP: `200` or `201` on success.

### Public user card (sanitized)

**Never return** in list/search/discover responses: `password`, `otp`, internal roles, auth secrets, private email/phone (unless the viewer is authorized).

**Minimum fields mobile needs for match/follow UI:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string (UUID) | Yes | Target user id |
| `name` | string | Yes | Display name |
| `displayPicture` | string \| null | No | Absolute URL |
| `gender` | string | No | e.g. `male`, `female`, `not_specified` |
| `country` | string | No | ISO or label |
| `level` | number | No | User level badge |
| `bio` | string | No | Short bio (optional) |
| `isFollowing` | boolean | Yes | Current user follows this user |
| `isFollower` | boolean | No | This user follows current user |
| `isMutual` | boolean | No | Both follow each other |
| `canMessage` | boolean | No | Backend rule: allowed to open chat |

Aliases mobile can map if needed: `userId`, `display_picture`, `avatar`, `photoUrl`.

---

## 3. Existing endpoints (reuse + required fixes)

### 3.1 Follow / Unfollow — **already in app**

**`POST /api/user/follow-unfollow`**

| | |
|--|--|
| **Auth** | Bearer token |
| **Purpose** | Follow or unfollow another user |

**Request body:**

```json
{
  "target_id": "target-user-uuid",
  "action": "follow"
}
```

| Field | Values |
|-------|--------|
| `action` | `"follow"` \| `"unfollow"` |

**Success response:**

```json
{
  "statusCode": 1,
  "message": "Followed successfully",
  "data": {
    "targetId": "target-user-uuid",
    "isFollowing": true,
    "followersCount": 42,
    "followingCount": 18
  }
}
```

**Backend must confirm:**

- [ ] Idempotent follow (second follow → success, no duplicate row)
- [ ] Cannot follow self → `statusCode: 0` + clear message
- [ ] Blocked users cannot follow each other → `statusCode: 0`
- [ ] Response includes updated `isFollowing` boolean

**Mobile repo:** `AuthRepo.followUnfollow()` — already implemented.

---

### 3.2 User search — **already in app (needs sanitization + follow flag)**

**`GET /api/user/search?query={text}`**

| Param | Required | Notes |
|-------|----------|-------|
| `query` | Yes | Min 1 char; debounced on mobile (~350 ms) |
| `page` | No | Recommended for pagination |
| `limit` | No | Default `20`, max `50` |

**Success response:**

```json
{
  "statusCode": 1,
  "message": "Users found",
  "data": [
    {
      "id": "user-uuid",
      "name": "Alex",
      "displayPicture": "https://cdn.example.com/u/alex.jpg",
      "gender": "male",
      "country": "IN",
      "level": 5,
      "bio": "Hello",
      "isFollowing": false,
      "isFollower": false,
      "isMutual": false,
      "canMessage": false
    }
  ]
}
```

**Backend must fix (known issue):**

- [ ] Remove sensitive fields (`password`, OTP, raw email/phone) from search results
- [ ] Add `isFollowing` (and ideally `isFollower`, `isMutual`, `canMessage`) per item

**Mobile repo:** `AuthRepo.searchUsers()` — used today on Discover + Messages (temporary).

---

### 3.3 Follow list — **repo exists, UI not wired**

**`GET /api/user/follow-list`**

Optional query (recommended for profile screens):

| Param | Required | Notes |
|-------|----------|-------|
| `user_id` | No | Omit = logged-in user. Else public lists for another profile. |

**Success response:**

```json
{
  "statusCode": 1,
  "message": "Follow list fetched",
  "data": {
    "followers": [
      {
        "id": "follower-uuid",
        "name": "Alex",
        "displayPicture": "https://...",
        "gender": "male",
        "level": 3,
        "isFollowing": true,
        "isFollower": true,
        "isMutual": true
      }
    ],
    "following": [
      {
        "id": "following-uuid",
        "name": "Sam",
        "displayPicture": "https://...",
        "gender": "female",
        "level": 7,
        "isFollowing": true,
        "isFollower": false,
        "isMutual": false
      }
    ],
    "followersCount": 120,
    "followingCount": 85
  }
}
```

**Backend must confirm:**

- [ ] Each list item includes `isFollowing` relative to **logged-in viewer** (for Follow back / Unfollow buttons)
- [ ] Exclude blocked users from both lists

**Mobile repo:** `UserRepo.getFollowList()` — exists, not yet bound to `FollowListView`.

---

### 3.4 Chat inbox — **repo exists, Messages tab not wired**

**`GET /api/chat/list`**

**Success response:**

```json
{
  "statusCode": 1,
  "message": "Inbox threads fetched",
  "data": [
    {
      "id": "partner-user-uuid",
      "lastMessage": "Hello there!",
      "lastMessageTime": "2026-05-25T05:12:31.000Z",
      "lastMessageType": "text",
      "unreadCount": 2,
      "recipient": {
        "id": "partner-user-uuid",
        "name": "Jane Doe",
        "displayPicture": "https://...",
        "gender": "female",
        "level": 5
      }
    }
  ]
}
```

**Mobile repo:** `ChatRepo.getInbox()`.

---

### 3.5 Chat history — **repo exists**

**`GET /api/chat/detail?target_id={uuid}&page=1`**

| Param | Required |
|-------|----------|
| `target_id` | Yes — partner user UUID |
| `page` | No — default `1` |

Marks messages read on fetch (per current backend docs).

**Mobile repo:** `ChatRepo.getConversation()`.

---

## 4. New endpoint recommended for “New Match” (backend)

Search with `query=a` is a **temporary hack**. Please provide a dedicated discover feed.

### 4.1 User discover / match suggestions

**`GET /api/user/discover`**

| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `page` | int | No | `1` | Page index |
| `limit` | int | No | `20` | Max `50` |
| `country` | string | No | — | Filter same country |
| `gender` | string | No | — | Filter preference |
| `exclude_following` | bool | No | `false` | If `true`, only users not yet followed |

**Purpose:**

- Return active, non-blocked users for the **Messages → New Match** horizontal list (and optional “See all” screen).
- Exclude current user.
- Prefer recently active / online users first (optional `lastActiveAt` field).

**Success response:**

```json
{
  "statusCode": 1,
  "message": "Discover users fetched",
  "data": {
    "users": [
      {
        "id": "user-uuid",
        "name": "Parth Host",
        "displayPicture": "https://...",
        "gender": "male",
        "country": "IN",
        "level": 5,
        "bio": "Streamer",
        "isFollowing": false,
        "isFollower": false,
        "isMutual": false,
        "canMessage": false,
        "lastActiveAt": "2026-06-02T10:00:00.000Z"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 156,
    "hasMore": true
  }
}
```

**Errors:**

| Case | HTTP | `statusCode` | `message` |
|------|------|--------------|-----------|
| Invalid page/limit | 400 | 0 | Validation message |
| Unauthorized | 401 | 0 | Token required |

**Alternative (if you prefer not to add `/discover`):**  
Extend `GET /api/user/search` with `query=*` or empty query to mean “suggested users” — **not recommended**; explicit `/discover` is clearer.

---

### 4.2 Optional — public profile card

**`GET /api/user/public/{userId}`**

Used when user taps a match avatar (bottom sheet / profile preview) before follow or chat.

**Response `data`:** same public user card as §2, plus optional:

```json
{
  "followersCount": 10,
  "followingCount": 4,
  "isBlocked": false,
  "canMessage": true
}
```

---

### 4.3 Optional — chat room bootstrap (Firebase path)

If chat uses Firestore (see `docs/chat/06-api-reference.md`):

**`POST /api/chat/room`**

```json
{
  "target_id": "partner-user-uuid"
}
```

**Response:**

```json
{
  "statusCode": 1,
  "message": "Chat room ready",
  "data": {
    "roomId": "deterministic-room-id",
    "participants": ["my-uuid", "partner-uuid"]
  }
}
```

Required when opening chat from New Match if no thread exists yet in `/api/chat/list`.

---

## 5. Business rules (please confirm with product)

Mobile needs a single rule set for **`canMessage`** and New Match behaviour:

| Option | Rule | Suggested for Qobo |
|--------|------|-------------------|
| A | Anyone can message anyone | Simplest; `canMessage: true` for all non-blocked users |
| B | Only if **mutual follow** | “Match” = both followed each other; chat enabled when `isMutual: true` |
| C | If **either** follows the other | Chat if `isFollowing \|\| isFollower` |
| D | Follow first, then message | Chat only if `isFollowing: true` |

**Recommendation:** **Option C or D** for social apps — prevents spam while still allowing connection after follow.

**New Match row content:**

| Option | Source API |
|--------|------------|
| Suggested strangers | `GET /api/user/discover` |
| People you follow (quick access) | `GET /api/user/follow-list` → `data.following` |
| Mutual follows only | Filter discover/follow-list where `isMutual: true` |

Please reply with chosen option; mobile will enforce `canMessage` from API (not hard-coded).

---

## 6. Block list interaction

Existing:

- `POST /api/user/block` — body `{ "target_id": "uuid" }`
- `POST /api/user/unblock`
- `GET /api/user/block-list`

**Backend must:**

- [ ] Remove blocked users from `/discover`, `/search`, and `/follow-list`
- [ ] Reject follow with clear error if either user blocked the other

---

## 7. Mobile implementation plan (for coordination)

No new full app module required. Planned changes:

| Screen / file | Work |
|---------------|------|
| `MessagesTabView` | Replace placeholder match data; add “See all” optional |
| `MessagesTabController` | Call `GET /api/user/discover` (or enhanced search); store `userId`, `isFollowing` |
| `MessageMatchUser` / `MessageMatchAvatarItem` | Add `id`, `isFollowing`; long-press or sheet with Follow + Message |
| `DiscoverTabController` | Extract shared `FollowActionsMixin` or small `SocialUserRepo` helper (reuse follow API) |
| `FollowListView` / `FollowListController` | Bind `UserRepo.getFollowList()` + real follow/unfollow |
| `MessagesTabView` Message section | Bind `ChatRepo.getInbox()` |
| `ChatDetailView` | Pass `target_id`; bind `ChatRepo.getConversation()` |

**Optional new screen (only if product wants full list):**

| Route | Purpose |
|-------|---------|
| `/match-users` | Paginated discover list with Follow buttons (extends New Match “See all”) |

**Not required:** duplicate follow UI on Profile tab — already has `FollowListView` route.

---

## 8. Backend delivery checklist

| Priority | Item | Endpoint |
|----------|------|----------|
| P0 | Sanitize search + add `isFollowing` | `GET /api/user/search` |
| P0 | Stable follow/unfollow response with `isFollowing` | `POST /api/user/follow-unfollow` |
| P0 | Discover feed for New Match | **`GET /api/user/discover`** (new) |
| P0 | Inbox for Message list | `GET /api/chat/list` |
| P1 | Follow list with viewer-relative flags | `GET /api/user/follow-list` |
| P1 | Chat history + read receipts | `GET /api/chat/detail` |
| P1 | Document `canMessage` rule | All user list endpoints |
| P2 | Public profile card | `GET /api/user/public/{id}` |
| P2 | Chat room create (Firebase) | `POST /api/chat/room` |

---

## 9. Test scenarios (curl / Postman)

Replace `{TOKEN}` and `{TARGET_ID}`.

```bash
# 1) Discover users (New Match)
curl -s -H "Authorization: Bearer {TOKEN}" \
  "https://my-backend-api-960q.onrender.com/api/user/discover?page=1&limit=20"

# 2) Follow
curl -s -X POST -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}","action":"follow"}' \
  "https://my-backend-api-960q.onrender.com/api/user/follow-unfollow"

# 3) Unfollow
curl -s -X POST -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}","action":"unfollow"}' \
  "https://my-backend-api-960q.onrender.com/api/user/follow-unfollow"

# 4) Follow lists
curl -s -H "Authorization: Bearer {TOKEN}" \
  "https://my-backend-api-960q.onrender.com/api/user/follow-list"

# 5) Chat inbox
curl -s -H "Authorization: Bearer {TOKEN}" \
  "https://my-backend-api-960q.onrender.com/api/chat/list"

# 6) Chat detail
curl -s -H "Authorization: Bearer {TOKEN}" \
  "https://my-backend-api-960q.onrender.com/api/chat/detail?target_id={TARGET_ID}&page=1"
```

**Acceptance:**

1. Discover returns ≥1 user with `isFollowing: false` for a fresh account.
2. After follow, same user appears with `isFollowing: true` on discover/search.
3. Follow list `following` array includes that user.
4. If `canMessage: true`, inbox can list or create thread with partner (per product rule).
5. Search never returns password/OTP fields.

---

## 10. Related mobile docs

| Doc | Topic |
|-----|--------|
| `docs/developer_api_handover.md` | Follow list, chat list shapes |
| `docs/backend_api_ui_binding_audit_2026-05-29.md` | Search sanitization issue |
| `docs/chat/06-api-reference.md` | Chat + Firebase room APIs |
| `docs/IMPLEMENTATION_TRACKER.md` | MSG-01, PROF-06, PROF-07 status |

---

## 11. Open questions for backend team

1. Which **`canMessage`** rule (§5) is official?
2. Will **`GET /api/user/discover`** be implemented, or should mobile keep using **`/search`** temporarily?
3. Should New Match show **suggested users**, **following only**, or **mutual follows**?
4. Confirm **`statusCode: 1`** vs legacy `"success": true` — mobile accepts both but prefers `statusCode`.
5. Pagination format: `hasMore` boolean vs `total` count — either is fine if documented.

**Contact:** Mobile team will bind endpoints as soon as staging returns the shapes above.
