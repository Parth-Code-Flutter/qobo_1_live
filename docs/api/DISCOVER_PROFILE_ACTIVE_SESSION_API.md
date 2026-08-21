# Discover Profile Preview — Active Room / Live Session API

**Audience:** Backend  
**Product ask:** On Discover (Explore), when a user taps a profile card, the preview bottom sheet should show if that person is currently hosting/in an **audio room**, **video room**, or **live stream**, with a **Join / Enter** action.  
**Mobile constraint:** Additive fields only. Existing Follow / Message / View Profile flow must keep working unchanged.

**Date:** 2026-08-21  
**App:** qobo_one_live (Discover → profile preview sheet)

---

## 1. Which API needs the data

### Primary (required)

**`GET /api/user/public/{userId}`**

| | |
|--|--|
| **When called** | Immediately when the user taps a Discover profile card, **before** the bottom sheet is shown |
| **Mobile** | `UserRepo.getPublicProfile()` → `DiscoverTabController.fetchPublicProfile()` → `showDiscoverUserCallDialog()` |
| **Auth** | Bearer JWT of the viewer |

This is the **single best place** to return live/session status. The sheet already refreshes from this endpoint; no new API is required for the first version.

### Optional (nice-to-have, not blocking)

**`GET /api/discover`** (Explore grid cards)

Same live fields on each feed item enable a small **LIVE** badge on the grid **before** open.  
Mobile will **not** depend on this for Join/Enter — Join still uses public profile (freshest state).

Do **not** change `GET /api/user/discover` (Messages New Match) unless product asks later.

---

## 2. Current behaviour (must not break)

Today `GET /api/user/public/{userId}` returns a sanitized public card used by:

- Discover profile preview bottom sheet  
- Discover full profile (`View Profile`)  
- Messages match sheet / chat contact profile  

Existing fields (keep as-is):

```json
{
  "id": "uuid",
  "name": "Agency Owner",
  "displayPicture": "https://...",
  "gender": "female",
  "country": "IN",
  "level": 1,
  "bio": "...",
  "isFollowing": false,
  "isFollower": false,
  "isMutual": false,
  "canMessage": false,
  "isVip": false,
  "isFavourite": false,
  "coinsPerSecond": 2,
  "followersCount": 0,
  "followingCount": 0
}
```

**Rule:** Only **add** new keys. Do not rename/remove existing keys. Missing new keys = treat as “not live” (sheet hides Join).

---

## 3. New fields to add on `data`

Prefer a nested object so the card stays clean. Flat aliases are also accepted by mobile.

### Preferred shape — nested `activeSession`

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": {
    "id": "idc4658315",
    "name": "Agency Owner",
    "displayPicture": "https://...",
    "level": 1,
    "followersCount": 0,
    "followingCount": 0,
    "coinsPerSecond": 2,
    "isFollowing": false,
    "isFollower": false,
    "isMutual": false,
    "canMessage": false,

    "activeSession": {
      "isLive": true,
      "roomId": "room_abc123",
      "roomType": "AUDIO",
      "sessionType": "audio_room",
      "title": "Friday Night Vibes",
      "hostId": "idc4658315",
      "viewerCount": 42,
      "joinApprovalRequired": false,
      "liveStreamingId": null,
      "coverUrl": "https://..."
    }
  }
}
```

### When the user is **not** in a live session

Either omit `activeSession`, or return:

```json
"activeSession": {
  "isLive": false,
  "roomId": null,
  "roomType": null
}
```

### Flat aliases (optional, same meaning)

If nesting is hard, put these on `data` root (camelCase **or** snake_case):

| Field | Type | Required when live | Description |
|-------|------|--------------------|-------------|
| `isLive` / `is_live` | boolean | yes | `true` only if there is a joinable active session |
| `roomId` / `room_id` | string | yes | Id mobile passes to `POST /api/room/join` |
| `roomType` / `room_type` | string | yes | `AUDIO` \| `VIDEO` \| `LIVE_STREAM` |
| `sessionType` / `session_type` | string | recommended | `audio_room` \| `video_room` \| `live_stream` (same values used by join-approval) |
| `title` | string | no | Room / stream title for button subtitle |
| `hostId` / `host_id` | string | no | Usually the profile user id |
| `viewerCount` / `viewer_count` | number | no | Shown as “42 watching” if present |
| `joinApprovalRequired` / `join_approval_required` | boolean | no | Hint for approval gate UI |
| `liveStreamingId` / `live_streaming_id` | string | when live stream | Same id used by live-streaming create/end |
| `coverUrl` / `cover_url` | string | no | Optional cover for sheet badge |

---

## 4. `roomType` / `sessionType` mapping

| Product surface | `roomType` (UI) | `sessionType` (join API) |
|-----------------|-----------------|---------------------------|
| Audio room | `AUDIO` | `audio_room` |
| Video room | `VIDEO` | `video_room` |
| Live streaming | `LIVE_STREAM` | `live_stream` |

Mobile join path (already exists — **no new join API**):

```http
POST /api/room/join
Authorization: Bearer {VIEWER_TOKEN}
Content-Type: application/json

{
  "roomId": "room_abc123",
  "room_id": "room_abc123",
  "session_type": "audio_room"
}
```

Then navigate to the existing live broadcast / room screen with the join response payload (same as Discover room cards / invite push).

---

## 5. Business rules for backend

1. **`isLive: true` only when the session is actually joinable**  
   - Room/stream must be active (not ended).  
   - Prefer sessions where this user is the **host** (or clearly “on stage”).  
   - If the user is only a silent audience in someone else’s room, prefer `isLive: false` unless product explicitly wants “Join their room”.

2. **One active session max**  
   If somehow multiple exist, return the most recent / host-owned one.

3. **Privacy / blocks**  
   - If viewer is blocked (either direction), keep current public-profile rules (hide or 403 as today).  
   - Do not leak private room ids to blocked viewers.  
   - Password / private rooms: still return `isLive` + `roomId` only if the viewer is allowed to attempt join (or return `isLive: true` with `joinRequiresInvite: true` and **no** joinable `roomId` — tell mobile if you add that flag).

4. **Freshness**  
   Public profile is fetched on every sheet open — keep `activeSession` up to date (end room → `isLive: false` immediately).

5. **Backward compatible**  
   Old app versions ignore unknown fields. New app versions hide Join when `isLive` is missing/false.

---

## 6. Example responses

### A) Host is in an audio room

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": {
    "id": "idc4658315",
    "name": "Agency Owner",
    "displayPicture": "https://cdn.example.com/a.jpg",
    "level": 1,
    "followersCount": 0,
    "followingCount": 0,
    "coinsPerSecond": 2,
    "isFollowing": false,
    "canMessage": false,
    "activeSession": {
      "isLive": true,
      "roomId": "audio_room_9988",
      "roomType": "AUDIO",
      "sessionType": "audio_room",
      "title": "Chill Audio",
      "hostId": "idc4658315",
      "viewerCount": 12,
      "joinApprovalRequired": false
    }
  }
}
```

### B) Host is live streaming

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": {
    "id": "idc4658315",
    "name": "Agency Owner",
    "activeSession": {
      "isLive": true,
      "roomId": "live_channel_5544",
      "roomType": "LIVE_STREAM",
      "sessionType": "live_stream",
      "liveStreamingId": "live_channel_5544",
      "title": "Go Live Night",
      "viewerCount": 120
    }
  }
}
```

### C) Not live

```json
{
  "statusCode": 1,
  "message": "OK",
  "data": {
    "id": "idc4658315",
    "name": "Agency Owner",
    "activeSession": {
      "isLive": false
    }
  }
}
```

---

## 7. Mobile UI plan (after API is ready)

No backend change beyond this response is required for Join.

| UI | Behaviour |
|----|-----------|
| Preview sheet | If `activeSession.isLive == true` && `roomId` non-empty → show **Join / Enter** (label by `roomType`) |
| Tap Join | Existing `JoinApprovalService` + `POST /api/room/join` → open room / live screen |
| Not live | Sheet stays as today (Follow / Message / View Profile only) |

Working flows that must stay unchanged:

- Follow / Unfollow  
- Message (canMessage rules)  
- View Profile  
- Voice/Video call buttons (current disabled/enabled policy)

---

## 8. Acceptance checklist for backend

- [ ] `GET /api/user/public/{userId}` includes `activeSession` (or flat aliases)  
- [ ] Existing public profile fields unchanged  
- [ ] `isLive: true` only for real active audio / video / live sessions  
- [ ] `roomId` is the same id accepted by `POST /api/room/join`  
- [ ] `roomType` / `sessionType` match the mapping table above  
- [ ] When session ends, next public-profile call returns `isLive: false`  
- [ ] Blocked / private visibility rules preserved  

---

## 9. curl smoke test

```bash
BASE=https://my-backend-api-960q.onrender.com
TOKEN=viewer_jwt
TARGET=host_user_id

curl -s -H "Authorization: Bearer $TOKEN" \
  "$BASE/api/user/public/$TARGET" | jq '.data.activeSession'
```

Expected while host is live:

```json
{
  "isLive": true,
  "roomId": "...",
  "roomType": "AUDIO",
  "sessionType": "audio_room"
}
```

---

## 10. Summary for backend

| Item | Value |
|------|--------|
| **API to extend** | `GET /api/user/public/{userId}` |
| **Optional later** | Same fields on `GET /api/discover` items |
| **Minimal keys** | `isLive`, `roomId`, `roomType` (+ `sessionType` recommended) |
| **Join API** | Existing `POST /api/room/join` — no new endpoint |
| **Compatibility** | Additive only — do not break current profile card fields |

Questions? Prefer nested `activeSession` as in §3. Mobile will parse both nested and flat forms.
