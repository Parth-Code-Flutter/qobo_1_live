# API Documentation: Explore Discover Feed & Favourites

**Base URL**: `/api`  
**Authentication**: Bearer token required for all endpoints.  
**Mobile binding:** qobo_one_live — Explore tab (Discover grid), 2026-06-02

> **Note:** The Messages tab **New Match** row continues to use `GET /api/user/discover`.  
> The **Explore** grid uses the dedicated endpoint below.

All responses use the standardized envelope:

```json
{
  "statusCode": 1,
  "message": "Human-readable message",
  "data": {}
}
```

---

## 1. Explore Discover Feed

**`GET /api/discover`**

Paginated user listing for the Explore tab grid. Same behaviour as `GET /api/user/discover`, plus **`isFavourite`** on each user card.

### Query parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | Page number |
| `limit` | integer | No | `20` | Items per page |
| `country` | string | No | — | **Filter** users by country (ISO code e.g. `IN`, `US`, or country name) |
| `gender` | string | No | — | Filter by gender |
| `exclude_following` | string | No | `false` | Pass `"true"` to hide users the caller already follows |

### Example request

```http
GET /api/discover?page=1&limit=30&country=IN
Authorization: Bearer {TOKEN}
```

### Response `data`

Either a **list** of users, or an object `{ "users": [ ... ] }`.

Each user item:

```json
{
  "id": "uuid",
  "name": "Parth Host",
  "displayPicture": "https://cdn.example.com/avatar.jpg",
  "gender": "male",
  "country": "IN",
  "level": 5,
  "bio": "Streamer",
  "isFollowing": false,
  "isFollower": false,
  "isMutual": false,
  "canMessage": false,
  "isVip": false,
  "isFavourite": true,
  "followersCount": 42,
  "followingCount": 18,
  "updatedAt": "2026-06-02T10:00:00.000Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `isFavourite` | boolean | Whether the **logged-in user** has marked this user as a favourite. Used to show the filled heart icon on Explore cards. |

**Mobile:** `UserRepo.exploreDiscover()` → `DiscoverTabController.fetchDiscoverUsers()`

---

## 2. Favourite User

**`POST /api/user/favourite`**

Add a user to the logged-in user's favourites list.

### Request body

```json
{
  "target_id": "uuid-of-user-to-favourite"
}
```

### Response `data`

```json
{
  "targetId": "uuid-of-user-to-favourite",
  "isFavourite": true
}
```

**Mobile:** `UserRepo.favouriteUser()` → Explore card heart tap (favourite)

---

## 3. Unfavourite User

**`POST /api/user/unfavourite`**

Remove a user from the logged-in user's favourites list.

### Request body

```json
{
  "target_id": "uuid-of-user-to-unfavourite"
}
```

### Response `data`

```json
{
  "targetId": "uuid-of-user-to-unfavourite",
  "isFavourite": false
}
```

**Mobile:** `UserRepo.unfavouriteUser()` → Explore card heart tap (unfavourite)

---

## Business rules

- Exclude blocked users and the logged-in user from the feed (same as `/api/user/discover`).
- `isFavourite` is per logged-in user; default `false` when never favourited.
- Favourite / unfavourite must be idempotent (calling favourite twice stays favourited; unfavourite twice stays not favourited).
- Cannot favourite yourself — return `statusCode` ≠ 1 with a clear message.
- `country` filter should match user profile `country` field (case-insensitive; support ISO codes).

---

## curl tests

Replace `{TOKEN}` and `{TARGET_ID}`.

```bash
BASE=https://my-backend-api-960q.onrender.com

# Explore feed (all users)
curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/discover?page=1&limit=10"

# Explore feed filtered by country
curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/discover?page=1&limit=10&country=IN"

# Favourite
curl -s -X POST -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}"}' \
  "$BASE/api/user/favourite"

# Unfavourite
curl -s -X POST -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}"}' \
  "$BASE/api/user/unfavourite"
```

---

## Mobile file map

| File | Role |
|------|------|
| `lib/services/api_constants.dart` | `UserEndpoints.exploreDiscover`, `favourite`, `unfavourite` |
| `lib/repo/user/user_repo.dart` | `exploreDiscover`, `favouriteUser`, `unfavouriteUser` |
| `lib/app/user_flow/discover/discover_tab/controllers/discover_tab_controller.dart` | Feed + country filter + favourite toggle |
| `lib/app/user_flow/discover/discover_tab/widgets/discover_users_feed.dart` | Grid UI + heart icon |
| `lib/app/user_flow/messages/messages_tab/models/social_user_card.dart` | Parses `isFavourite` |
