# Integration Guide: Country, State, Live Streaming Access & Call Rate APIs

This integration guide details the database schemas, seed datasets, and APIs for Country/State selectors, live streaming access verification, and custom host-specific calling rates.

**Mobile binding:** qobo_one_live

---

## Public Utility APIs (Mobile Integration)

These are public endpoints (no authentication required) for your mobile app to populate dropdown lists.

### A. List All Countries
* **Endpoint**: `GET /api/auth/countries`
* **Mobile:** `GeoRepo.fetchCountries()` → `ApiService.getPublicRequest()`

### B. List States of a Country
* **Endpoint**: `GET /api/auth/states?countryId={country_id}`
* **Mobile:** `GeoRepo.fetchStates(countryId: ...)`

**Used in:**
- Update profile (post-OTP registration)
- User basic profile → Current location
- Agency host registration
- Explore country filter

---

## Live Streaming Access Verification

* **Endpoint**: `GET /api/live-streaming/verify-access?userId={user_id}`
* **Mobile:** `RoomRepo.verifyLiveStreamingAccess()` → `LiveRoomController.openGoLive()`

---

## Discover API enriched fields

* `coins`, `coinsPerSecond` on user cards — parsed in `SocialUserCard`

## Update profile call rate

* **Endpoint**: `PUT /api/user/update`
* **Field:** `coinsPerSecond` — supported in `UpdateProfileRequestModel`

---

See full backend spec in project downloads / original walkthrough from backend team.
