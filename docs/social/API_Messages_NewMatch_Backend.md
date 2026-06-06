# API Documentation: Messages, New Match, and Follow/Unfollow

**Base URL**: `/api`  
**Authentication**: Bearer Token required for all endpoints.  
**Mobile binding:** qobo_one_live — Messages tab, Follow list, Chat detail (2026-06-02)

All responses use the standardized format:
```json
{
  "statusCode": 1,
  "message": "Human-readable message",
  "data": {}
}
```

---

## 1. Discover Feed (New Match)
**`GET /api/user/discover`**

Fetch a paginated list of active users for the "New Match" horizontal list. This automatically filters out blocked users and the logged-in user.

**Query Parameters:**
- `page` (optional, default 1)
- `limit` (optional, default 20)
- `country` (optional)
- `gender` (optional)
- `exclude_following` (optional, boolean string 'true' / 'false')

**Response Data Array Items:**
```json
{
  "id": "uuid",
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
  "isVip": false,
  "updatedAt": "2026-06-02T10:00:00.000Z"
}
```

**Mobile:** `UserRepo.discoverUsers()` → `MessagesTabController.fetchNewMatches()`

---

## 2. Follow / Unfollow
**`POST /api/user/follow-unfollow`**

**Body:**
```json
{
  "target_id": "uuid",
  "action": "follow"
}
```

**Response Data:**
```json
{
  "targetId": "uuid",
  "isFollowing": true,
  "followersCount": 42,
  "followingCount": 18
}
```

**Mobile:** `AuthRepo.followUnfollow()` → Messages match sheet, Discover search, Follow list

---

## 3. Public Profile Card
**`GET /api/user/public/:id`**

**Mobile:** `UserRepo.getPublicProfile()` → match user bottom sheet

---

## 4. Search
**`GET /api/user/search?query={text}`**

**Mobile:** `AuthRepo.searchUsers()` → Messages tab search bar

---

## 5. Follow Lists
**`GET /api/user/follow-list?user_id={uuid}`**

**Mobile:** `UserRepo.getFollowList()` → `FollowListView`

---

## 6. Create Chat Room
**`POST /api/chat/room`**

**Body:**
```json
{
  "target_id": "uuid"
}
```

**Response Data:**
```json
{
  "roomId": "uuid1_uuid2",
  "participants": ["uuid1", "uuid2"]
}
```

**Mobile:** `ChatRepo.createRoom()` before navigating to chat detail

---

## 7. Chat Inbox & History
- **`GET /api/chat/list`** → `ChatRepo.getInbox()` → Messages tab inbox
- **`GET /api/chat/detail?target_id={uuid}`** → `ChatRepo.getConversation()` → Chat detail

---

## Business Rules
- **canMessage:** Option C — either user follows the other (`isFollowing || isFollower`).
- **Blocks:** Blocked users excluded from Discover, Search, Follow Lists, Chat Inbox.

---

## curl tests

Replace `{TOKEN}` and `{TARGET_ID}`.

```bash
BASE=https://my-backend-api-960q.onrender.com

curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/user/discover?page=1&limit=5"

curl -s -X POST -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}","action":"follow"}' \
  "$BASE/api/user/follow-unfollow"

curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/user/public/{TARGET_ID}"

curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/user/follow-list"

curl -s -X POST -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}"}' \
  "$BASE/api/chat/room"

curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/chat/list"
```
