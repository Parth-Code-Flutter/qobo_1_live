# Backend API and UI Binding Audit

Date: 2026-05-29  
App: Qobo One Live Flutter client  
Backend tested: `https://my-backend-api-960q.onrender.com`

## Executive Summary

The Flutter app currently defines **32 repository API wrappers**. From the current UI/controllers, **18 API methods are actively used** for auth, profile, discover, live room, agency host, and Qobo Call flows. Economy, chat, family, activity, backpack, visitors, and support endpoints exist in constants/repos or backend, but most related UI is still static/mock or not fully bound.

Live backend probing found:

| Category | Count | Result |
|---|---:|---|
| Repository API wrappers in mobile code | 32 | Inventory complete |
| API methods currently consumed by UI controllers | 18 | Inventory complete |
| Public/no-token probe requests | 39 | 32 correctly returned JSON `401`; 1 missing route; 5 validation/not-found cases returned HTTP `500`; login invalid returned JSON `401` |
| Authenticated protected checks | 23 | 20 returned HTTP `200/201`; 3 returned HTTP `500` in expected empty/not-found states |
| UI-critical payload mismatches found | 4 | Registration missing route, social phone requirement, live-room field mismatch, Qobo Call empty-profile behavior |

Highest priority backend items:

1. `POST /api/auth/register` is missing. The Sign Up UI is wired to this route, but backend returns HTML `404 Cannot POST /api/auth/register`.
2. `POST /api/auth/social` throws HTTP `500` when `phone` is absent. Google/Facebook/Apple sign-in commonly does not provide phone, and the mobile app omits empty phone.
3. Several normal validation/not-found states return HTTP `500`: forgot password, reset password, verify OTP, agency host status, agency revenue, and Qobo Call list before onboarding.
4. `GET /api/room/list` returns `title` and `seatConfig`, but the current mobile room grid reads `name` and `maxSeats`, so real rooms display as fallback text like `Room, 8 Seats`.
5. `GET /api/user/search` returns sensitive backend fields to the client, including password hashes for phone users. This should be removed from public user search responses.

## Scope and Method

Checked mobile API definitions in:

- `lib/services/api_constants.dart`
- `lib/repo/auth/auth_repo.dart`
- `lib/repo/room/room_repo.dart`
- `lib/repo/agency/agency_repo.dart`
- `lib/repo/economy/economy_repo.dart`
- `lib/repo/pk/pk_repo.dart`
- UI controllers under `lib/app/**/controllers`

Backend probing was done in two passes:

- No-token/public pass to confirm route existence and auth behavior.
- Authenticated pass using a clearly marked synthetic social-login probe user. Low-risk write checks only: social login, Qobo Call onboarding, and private test room creation. Payment, gift transfer, block, follow, and destructive mutations were not executed.

## Current UI-Consumed API Methods

| UI Flow | Mobile Method | Endpoint | Current Status |
|---|---|---|---|
| Login | `AuthRepo.login` | `POST /api/auth/login` | Route exists. Invalid credentials return JSON `401`. Valid user not tested because no shared test credentials were provided. |
| Sign Up | `AuthRepo.register` | `POST /api/auth/register` | **Broken.** Backend returns HTML `404`. |
| Google/Facebook/Apple auth | `AuthRepo.socialLogin` | `POST /api/auth/social` | Works only if `phone` is included. **Broken for real OAuth profiles without phone.** |
| Phone OTP login | `AuthRepo.loginWithOtp` | `POST /api/auth/login-phone` | Route exists, not fully success-tested. |
| Forgot password | `AuthRepo.forgotPasswordSendOtp` | `POST /api/auth/forgot-password` | User-not-found returns HTTP `500`; should be `404` or `200` with `statusCode:0`. |
| Reset password | `AuthRepo.resetPassword` | `POST /api/auth/reset-password` | Invalid/expired OTP returns HTTP `500`; should be validation error. |
| Verify OTP | `AuthRepo.verifyOtp` | `POST /api/auth/verify-otp` | Invalid OTP returns HTTP `500`; should be validation error. |
| Bottom nav/profile | `AuthRepo.getProfile` | `GET /api/user/profile` | Works with token. |
| Edit profile | `AuthRepo.updateProfile` | `PUT /api/user/update` | Route protected. Multipart success not tested in live probe. |
| Poster upload | `AuthRepo.uploadPoster` | `POST /api/user/poster-upload` | Route protected. Multipart success not tested in live probe. |
| Discover search | `AuthRepo.searchUsers` | `GET /api/user/search?query=` | Works with token, but response exposes sensitive fields. |
| Discover follow | `AuthRepo.followUnfollow` | `POST /api/user/follow-unfollow` | Route protected. Mutation not executed in probe. |
| Live room list | `RoomRepo.listActiveRooms` | `GET /api/room/list?type=&country=` | Works with token, but payload field names do not match UI. |
| Go Live/create room | `RoomRepo.createRoom` | `POST /api/room/create` | Works with token. Response also uses `title/seatConfig` rather than `name/maxSeats`. |
| Agency host onboarding | `AgencyRepo.hostOnboarding` | `POST /api/agency/host-onboarding` | Route protected. Multipart success not tested. |
| Agency host status | `AgencyRepo.hostVerifyStatus` | `GET /api/agency/host-verify-status?phone=` | Application-not-found returns HTTP `500`; should be normal not-found. |
| Qobo Call onboarding | `PkRepo.callOnboarding` | `POST /api/pk/dating-onboarding` | Works with token. |
| Qobo Call list | `PkRepo.getCallList` | `GET /api/pk/dating-list` | Before onboarding returns HTTP `500`; after onboarding returns `200` with empty list. |

## Endpoint Probe Results

### Auth and Public Routes

| Endpoint | Probe Result | Backend Action Needed |
|---|---|---|
| `POST /api/auth/login` | HTTP `401`, JSON envelope for fake credentials | OK for invalid login. Provide valid test credentials for success testing. |
| `POST /api/auth/register` | HTTP `404`, HTML response `Cannot POST /api/auth/register` | Implement route or tell mobile the correct registration endpoint/body. |
| `POST /api/auth/social` without `phone` | HTTP `500`, Prisma error says `phone` is missing | Make `phone` optional for social auth, or return a clear `400` requiring phone collection before login. |
| `POST /api/auth/social` with `phone` | HTTP `200`, `statusCode:1`, returns `data.user` and `data.token` | Works. |
| `POST /api/auth/forgot-password` unknown phone | HTTP `500`, `User not found with this phone number` | Return `404` or `200/statusCode:0`; do not use `500`. |
| `POST /api/auth/reset-password` invalid OTP | HTTP `500`, `Invalid or expired OTP` | Return `400` or `200/statusCode:0`; do not use `500`. |
| `POST /api/auth/verify-otp` invalid OTP | HTTP `500`, `Invalid OTP` | Return `400` or `200/statusCode:0`; do not use `500`. |

### Profile and Discover

| Endpoint | Authenticated Result | UI Expectation / Issue |
|---|---|---|
| `GET /api/user/profile` | HTTP `200`, profile object returned | Works. App can consume `name`, `email`, `phone`, `displayPicture`, `poster`, `bio`, `gender`, `country`, etc. |
| `GET /api/user/search?query=a` | HTTP `200`, list returned | UI can render, but backend exposes full user records including `password` hash, emails, phones, roles, OTP fields. Return a sanitized public profile only. |
| `POST /api/user/follow-unfollow` | No-token returned JSON `401`; authenticated mutation not executed | Confirm request body remains `{ target_id, action }` where action is `follow`/`unfollow`. |

Recommended public search object:

```json
{
  "id": "user-id",
  "name": "Display Name",
  "displayPicture": "https://...",
  "bio": "Short bio",
  "gender": "Female",
  "country": "IN",
  "level": 12,
  "isVip": false,
  "isFollowing": false
}
```

Do not return `password`, `otp`, internal roles, auth provider secrets, or private phone/email unless the screen specifically requires them and the user is authorized.

### Live Room

| Endpoint | Authenticated Result | Current Mobile Expectation | Issue |
|---|---|---|---|
| `GET /api/room/list?type=VIDEO` | HTTP `200`, list returned | UI maps `id`, `name`, `maxSeats`, `type`, `country` | Backend returns `id`, `title`, `seatConfig`, `type`, `country`. Because `name/maxSeats` are missing, UI shows fallback `Room, 8 Seats`. |
| `GET /api/room/list?type=AUDIO` | HTTP `200`, empty list | Empty list is valid | UI falls back to mock rooms when backend has no rooms. |
| `POST /api/room/create` | HTTP `201`, room created | UI sends `name`, `type`, `country`, `maxSeats`, `isPrivate` | Backend accepts request, but response returns `title` and `seatConfig`. |
| `POST /api/room/join` | No-token returned JSON `401`; authenticated join not executed | UI repository sends `{ room_id }` | Confirm success payload includes enough room metadata for audience broadcast. |
| `POST /api/room/mic-action` | No-token returned JSON `401`; authenticated mutation not executed | UI repository sends `{ room_id, action, seat_id }` | Confirm accepted action values: `mute`, `unmute`, `lock`, `unlock`. |
| `POST /api/room/security-sos` | No-token returned JSON `401`; authenticated mutation not executed | UI repository sends `{ room_id }` | Confirm success envelope. |

Recommended room list/create response object:

```json
{
  "id": "room-id",
  "name": "Room title",
  "title": "Room title",
  "type": "VIDEO",
  "country": "IN",
  "maxSeats": 4,
  "seatConfig": 4,
  "isPrivate": false,
  "hostId": "user-id",
  "status": "active",
  "viewerCount": 0,
  "coverImage": "https://..."
}
```

For compatibility, backend can include both aliases temporarily: `name/title` and `maxSeats/seatConfig`.

Mobile-side note: the current room grid opens `/live-broadcast` for audience users with only `isHost` and `roomType`, not the selected `roomData`. That means the audience broadcast screen falls back to `test_room`. Backend can still fix payload shape, but mobile should pass selected room data and/or call `POST /api/room/join`.

### Qobo Call / Dating

| Endpoint | Authenticated Result | Current Mobile Expectation | Issue |
|---|---|---|---|
| `GET /api/pk/dating-list` before onboarding | HTTP `500`, `Dating profile not found` | Empty state or onboarding state | This should not be a server error. Return `200` with empty list or `404/statusCode:0` with a clear action message. |
| `POST /api/pk/dating-onboarding` | HTTP `200`, profile updated | App sends `interests`, `preferredGender`, `minAge`, `maxAge`, optional `location` | Works. |
| `GET /api/pk/dating-list` after onboarding | HTTP `200`, empty list | App expects `data` list of profiles | Works as empty state, but backend should seed/return matches for real testing. |

Recommended call profile object:

```json
{
  "id": "user-id",
  "name": "Aarav",
  "age": 24,
  "location": "Dhaka, Bangladesh",
  "bio": "Short intro",
  "displayPicture": "https://...",
  "matchPercentage": 91,
  "interests": ["Chatting", "Gaming"]
}
```

### Agency

| Endpoint | Probe Result | Backend Action Needed |
|---|---|---|
| `POST /api/agency/host-onboarding` | No-token returned JSON `401`; multipart success not tested | Confirm body fields: `agency_code`, `name`, `phone`, file `host_real_photo`. |
| `GET /api/agency/host-verify-status?phone=` | HTTP `500` for no application | Return `200/statusCode:0` or `404`, not `500`. Include stable statuses like `pending`, `approved`, `rejected`, `not_found`. |
| `POST /api/agency/register` | No-token returned JSON `401`; authenticated mutation not executed | UI owner register screen currently appears partially mocked; confirm final contract. |
| `GET /api/agency/revenue` | HTTP `500`, `Agency not found` for normal user | Return `403` or `404`, not `500`. |

Recommended host status response:

```json
{
  "statusCode": 1,
  "message": "Host application status fetched",
  "data": {
    "phone": "9000000000",
    "status": "pending",
    "reason": null,
    "agencyCode": "ABC123"
  }
}
```

For not found:

```json
{
  "statusCode": 0,
  "message": "Application not found",
  "data": {
    "status": "not_found"
  }
}
```

### Economy and Gifts

These repository methods exist, but the current wallet/gift/live gift UI still has mock/static behavior in several places.

| Endpoint | Authenticated Result | Notes |
|---|---|---|
| `GET /api/economy/wallet` | HTTP `200`, wallet returned | Works. |
| `GET /api/economy/history` | HTTP `200`, empty list | Works as empty state. |
| `GET /api/economy/gift-list` | HTTP `200`, gift list returned | Works. |
| `POST /api/economy/recharge` | No-token returned JSON `401`; authenticated mutation not executed | Needs payment/test-mode contract before client testing. |
| `POST /api/economy/send-gift` | No-token returned JSON `401`; authenticated mutation not executed | Needs room/user test data before client testing. |

Recommended gift object is already close to current backend output:

```json
{
  "id": "gift-001",
  "name": "Red Rose",
  "price": 50,
  "icon": "https://...",
  "type": "normal",
  "status": "active",
  "animationUrl": null,
  "soundUrl": null
}
```

### Additional Backend Routes Not Fully Bound to Current UI

The following authenticated reads returned HTTP `200` and valid JSON during probing:

- `GET /api/chat/list`
- `GET /api/user/follow-list`
- `GET /api/user/block-list`
- `GET /api/user/backpack`
- `GET /api/user/tasks`
- `GET /api/user/achievements`
- `GET /api/user/visitors`
- `GET /api/family/list`
- `GET /api/activity/list`
- `GET /api/support/tickets`

These are good candidates for future UI binding. For now, they should be considered backend-ready reads, but not fully verified against a completed UI screen contract.

## Backend Fix Checklist

### P0 - Blocks Current UI

- Implement or correct `POST /api/auth/register`.
- Make `phone` optional for `POST /api/auth/social`, or return a clear `400` requiring phone before account creation.
- Sanitize `GET /api/user/search` so it never returns password hashes or private auth fields.

### P1 - Causes Broken or Confusing App States

- Replace HTTP `500` with proper validation/not-found status for:
  - `POST /api/auth/forgot-password`
  - `POST /api/auth/reset-password`
  - `POST /api/auth/verify-otp`
  - `GET /api/agency/host-verify-status`
  - `GET /api/agency/revenue`
  - `GET /api/pk/dating-list` before onboarding
- Add room response aliases: `name` with `title`, and `maxSeats` with `seatConfig`.
- Confirm `POST /api/room/join` success response and whether it should create attendance/watch history.
- Return seeded Qobo Call profiles or a documented empty-state response after onboarding.

### P2 - Needed for Full Feature Completion

- Provide staging/test credentials and seed data for every role: normal user, host, agency owner, seller/admin.
- Document all mutation request bodies and success responses for follow, block, gifts, recharge, agency owner, PK request, mic action, SOS, and poster/profile upload.
- Align country/type enum values with mobile filters: room `type` uses `VIDEO`/`AUDIO`; country filters currently use values like `IN` and `BD`.
- Add pagination metadata to list endpoints before production data grows.

## Response Envelope Recommendation

The app expects decoded JSON maps and commonly checks `statusCode == 1`.

Use this shape consistently:

```json
{
  "statusCode": 1,
  "message": "Human readable message",
  "data": {}
}
```

For errors:

```json
{
  "statusCode": 0,
  "message": "Validation or business error message",
  "data": null
}
```

Recommended HTTP status usage:

| Case | HTTP Status |
|---|---:|
| Success | `200` or `201` |
| Invalid input / invalid OTP | `400` |
| Unauthorized / missing token | `401` |
| Authenticated but wrong role | `403` |
| Entity not found | `404` |
| Real server crash/unhandled exception | `500` |

## Client Notes for Backend Team

The Flutter client currently falls back to mock data in some screens, so a page may appear visually populated even when the backend response is empty or unusable. For integration testing, please verify logs/API responses rather than only looking at the UI.

Known client-side follow-up items:

- Live room list should map backend `title/seatConfig` or backend should provide `name/maxSeats`.
- Audience tap on a room should pass selected `roomData` and call/join the selected room instead of falling back to `test_room`.
- Economy/gift/chat/family/activity/support screens need final UI binding where still mocked.
- Qobo Call should show a clear empty state when `data: []` is returned.
