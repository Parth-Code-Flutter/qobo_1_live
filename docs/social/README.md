# Explore Discover & Favourites — Backend API Handover

**Project:** qobo_one_live (Flutter mobile)  
**Prepared for:** Backend team  
**Date:** 2026-06-02  
**Status:** Mobile app is wired and waiting on these endpoints

---

## Overview

The **Explore** tab (bottom nav → Discover) shows a 2-column grid of user profile cards (photo + name). Each card has a **heart icon** for favourites and a **country filter** in the header.

Mobile needs **three new/updated APIs**:

| # | Method | Endpoint | Purpose |
|---|--------|----------|---------|
| 1 | `GET` | `/api/discover` | Paginated user grid for Explore tab |
| 2 | `POST` | `/api/user/favourite` | Mark a user as favourite |
| 3 | `POST` | `/api/user/unfavourite` | Remove a user from favourites |

> **Important:** The **Messages** tab “New Match” row continues to use the existing **`GET /api/user/discover`**.  
> Do **not** remove or break that endpoint. Explore uses the **separate** `/api/discover` route below.

---

## Base configuration

| Item | Value |
|------|-------|
| Base URL | `https://my-backend-api-960q.onrender.com` (or your deployed host) |
| Auth | `Authorization: Bearer {JWT}` on every request |
| Content-Type | `application/json` for POST bodies |
| Response envelope | Standard app format (see below) |

### Standard response envelope

```json
{
  "statusCode": 1,
  "message": "Success message",
  "data": {}
}
```

- `statusCode`: `1` (or `200` / `201`) = success  
- On error: non-success `statusCode` + human-readable `message`

---

## 1. Explore Discover Feed

### `GET /api/discover`

Returns paginated active users for the Explore grid.

**Behaviour:** Same as existing `GET /api/user/discover`, with one **additional response field** per user: `isFavourite`.

### Query parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | `1` | Page number |
| `limit` | integer | No | `20` | Items per page |
| `country` | string | No | — | **Filter** by country (ISO code e.g. `IN`, `US`, or country name) |
| `gender` | string | No | — | Filter by gender |
| `exclude_following` | string | No | `false` | Pass `"true"` to hide users the caller already follows |

### Example request

```http
GET /api/discover?page=1&limit=30&country=IN
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Example success response

```json
{
  "statusCode": 1,
  "message": "Discover users fetched",
  "data": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "name": "Parth Host",
      "displayPicture": "https://cdn.example.com/users/parth.jpg",
      "gender": "male",
      "country": "IN",
      "level": 5,
      "bio": "Live streamer",
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
  ]
}
```

`data` may also be wrapped as:

```json
{
  "statusCode": 1,
  "message": "Discover users fetched",
  "data": {
    "users": [ /* same user objects */ ],
    "page": 1,
    "limit": 30,
    "total": 120
  }
}
```

Mobile parses both shapes.

### User object fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string (UUID) | Yes | User ID |
| `name` | string | Yes | Display name |
| `displayPicture` | string \| null | No | Full URL to avatar |
| `gender` | string | No | e.g. `male`, `female`, `not_specified` |
| `country` | string | No | Country code or name |
| `level` | integer | No | User level |
| `bio` | string | No | Short bio |
| `isFollowing` | boolean | No | Caller follows this user |
| `isFollower` | boolean | No | This user follows caller |
| `isMutual` | boolean | No | Both follow each other |
| `canMessage` | boolean | No | Either follows the other |
| `isVip` | boolean | No | VIP badge |
| **`isFavourite`** | **boolean** | **Yes** | **NEW — caller has favourited this user** |
| `followersCount` | integer | No | |
| `followingCount` | integer | No | |
| `updatedAt` | string (ISO 8601) | No | |

### Business rules (feed)

- Exclude the logged-in user from results.
- Exclude blocked users (both directions).
- `isFavourite` defaults to `false` when the caller has never favourited that user.
- `country` filter: case-insensitive match against user profile `country` (support ISO codes like `IN`, `US`).
- Only return active/public users (same rules as `/api/user/discover`).

---

## 2. Favourite User

### `POST /api/user/favourite`

Adds a user to the logged-in user's favourites list.

### Request body

```json
{
  "target_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `target_id` | string (UUID) | Yes | User to favourite |

### Example success response

```json
{
  "statusCode": 1,
  "message": "User added to favourites",
  "data": {
    "targetId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "isFavourite": true
  }
}
```

### Business rules

- Idempotent: favouriting an already-favourited user returns success with `isFavourite: true`.
- Cannot favourite yourself → return error (`statusCode` ≠ 1).
- Target user must exist and not be blocked.

---

## 3. Unfavourite User

### `POST /api/user/unfavourite`

Removes a user from the logged-in user's favourites list.

### Request body

```json
{
  "target_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `target_id` | string (UUID) | Yes | User to unfavourite |

### Example success response

```json
{
  "statusCode": 1,
  "message": "User removed from favourites",
  "data": {
    "targetId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "isFavourite": false
  }
}
```

### Business rules

- Idempotent: unfavouriting a user who is not favourited returns success with `isFavourite: false`.
- Cannot unfavourite yourself → return error.

---

## Relationship to existing API

| Screen | Mobile method | Endpoint | Notes |
|--------|---------------|----------|-------|
| Messages → New Match row | `UserRepo.discoverUsers()` | `GET /api/user/discover` | **Unchanged** |
| Explore → user grid | `UserRepo.exploreDiscover()` | `GET /api/discover` | **New** — adds `isFavourite` |
| Explore → heart tap (on) | `UserRepo.favouriteUser()` | `POST /api/user/favourite` | **New** |
| Explore → heart tap (off) | `UserRepo.unfavouriteUser()` | `POST /api/user/unfavourite` | **New** |

Existing discover query params (`page`, `limit`, `country`, `gender`, `exclude_following`) are reused on `/api/discover`. Mobile sends `country` when the user applies the Explore header filter.

---

## curl test commands

Replace `{TOKEN}` with a valid JWT and `{TARGET_ID}` with another user's UUID.

```bash
BASE=https://my-backend-api-960q.onrender.com

# 1. Explore feed — all users
curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/discover?page=1&limit=10"

# 2. Explore feed — country filter
curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/discover?page=1&limit=10&country=IN"

# 3. Favourite a user
curl -s -X POST \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}"}' \
  "$BASE/api/user/favourite"

# 4. Unfavourite a user
curl -s -X POST \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"target_id":"{TARGET_ID}"}' \
  "$BASE/api/user/unfavourite"

# 5. Verify isFavourite in feed after favourite
curl -s -H "Authorization: Bearer {TOKEN}" \
  "$BASE/api/discover?page=1&limit=10" | jq '.data[] | select(.id=="{TARGET_ID}") | .isFavourite'
```

---

## Suggested database schema (reference)

Backend team can adapt; mobile only needs the API contract above.

```sql
-- Favourites join table (example)
CREATE TABLE user_favourites (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),      -- who favourited
  target_id   UUID NOT NULL REFERENCES users(id),      -- who was favourited
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, target_id)
);

CREATE INDEX idx_user_favourites_user_id ON user_favourites(user_id);
CREATE INDEX idx_user_favourites_target_id ON user_favourites(target_id);
```

When building `/api/discover`, join against this table to set `isFavourite` for the authenticated caller.

---

## Implementation checklist (backend)

- [ ] `GET /api/discover` — clone `/api/user/discover` logic + add `isFavourite` per row
- [ ] `country` query param filters results by user profile country
- [ ] `POST /api/user/favourite` — create favourite record
- [ ] `POST /api/user/unfavourite` — delete favourite record
- [ ] Both POST endpoints return `{ targetId, isFavourite }` in `data`
- [ ] Idempotent favourite / unfavourite
- [ ] Block self-favourite
- [ ] Respect block list on all three endpoints
- [ ] Keep `GET /api/user/discover` working for Messages tab

---

## Mobile integration (for reference)

These files are already implemented in the Flutter app:

| File | What it does |
|------|--------------|
| `lib/services/api_constants.dart` | Endpoint constants |
| `lib/repo/user/user_repo.dart` | API calls |
| `lib/app/user_flow/discover/discover_tab/controllers/discover_tab_controller.dart` | Feed, filter, favourite toggle |
| `lib/app/user_flow/discover/discover_tab/widgets/discover_users_feed.dart` | Grid UI + heart icon |
| `lib/app/user_flow/messages/messages_tab/models/social_user_card.dart` | Parses `isFavourite` |

---

## Contact / questions

If field names or response shape need to differ, please align on:

1. **`isFavourite`** (preferred) or `isFavorite` — mobile accepts both spellings in JSON.
2. **`target_id`** in POST body — matches existing follow/unfollow pattern.
3. **`data`** as array **or** `{ "users": [...] }` — mobile supports both.

---

*End of handover document.*
