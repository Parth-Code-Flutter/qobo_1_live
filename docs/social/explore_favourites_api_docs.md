# Explore Discover Feed & Favourites API Documentation

**Base URL**: `/api`  
**Authentication**: Bearer token required for all endpoints (`Authorization: Bearer <TOKEN>`).  
**Mobile binding:** qobo_one_live — Explore tab (Discover grid), 2026-06-02

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

* **Method**: `GET`
* **Endpoint**: `/api/discover`
* **Description**: Paginated user listing for the Explore tab grid.

### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | Page number |
| `limit` | integer | No | `20` | Items per page |
| `country` | string | No | — | **Filter** users by country (ISO code e.g. `IN`, `US`, or country name) |
| `gender` | string | No | — | Filter by gender (`male` or `female`) |
| `exclude_following` | string | No | `false` | Pass `"true"` to hide users the caller already follows |

### Example request

```http
GET /api/discover?page=1&limit=30&country=IN
Authorization: Bearer {TOKEN}
```

### Response `data`

```json
{
  "statusCode": 1,
  "message": "Explore discover feed fetched",
  "data": {
    "users": [
      {
        "id": "uuid-12345",
        "name": "Parth Host",
        "displayPicture": "https://your-domain.com/uploads/profiles/avatar.jpg",
        "gender": "male",
        "country": "India",
        "level": 5,
        "bio": "Streamer",
        "isFollowing": false,
        "isFollower": false,
        "isMutual": false,
        "canMessage": true,
        "isVip": false,
        "isFavourite": true,
        "followersCount": 42,
        "followingCount": 18,
        "updatedAt": "2026-06-02T10:00:00.000Z"
      }
    ],
    "total": 1,
    "page": 1,
    "limit": 30,
    "hasMore": false
  }
}
```

---

## 2. Favourite User

* **Method**: `POST`
* **Endpoint**: `/api/user/favourite`
* **Description**: Add a user to the logged-in user's favourites list (Explore card heart tap).

### Request Body

```json
{
  "target_id": "target-user-uuid"
}
```

### Response `data`

```json
{
  "statusCode": 1,
  "message": "Favourited successfully",
  "data": {
    "targetId": "target-user-uuid",
    "isFavourite": true
  }
}
```

---

## 3. Unfavourite User

* **Method**: `POST`
* **Endpoint**: `/api/user/unfavourite`
* **Description**: Remove a user from the logged-in user's favourites list.

### Request Body

```json
{
  "target_id": "target-user-uuid"
}
```

### Response `data`

```json
{
  "statusCode": 1,
  "message": "Unfavourited successfully",
  "data": {
    "targetId": "target-user-uuid",
    "isFavourite": false
  }
}
```

---

## Business Rules

- Exclude blocked users and the logged-in user from the feed.
- `isFavourite` is per logged-in user; default `false` when never favourited.
- Favourite / unfavourite are idempotent operations.
- Cannot favourite yourself (returns `statusCode: 0` with an error message).
- `country` filter matches user profile `country` field (case-insensitive; supports ISO codes).

---

## Mobile binding (qobo_one_live)

| API | Mobile |
|-----|--------|
| `GET /api/discover` | `UserRepo.exploreDiscover()` → `DiscoverTabController.fetchDiscoverUsers()` |
| `POST /api/user/favourite` | `UserRepo.favouriteUser()` → heart tap on Explore card |
| `POST /api/user/unfavourite` | `UserRepo.unfavouriteUser()` → heart tap on Explore card |

Messages tab **New Match** row remains on `GET /api/user/discover` (unchanged).
