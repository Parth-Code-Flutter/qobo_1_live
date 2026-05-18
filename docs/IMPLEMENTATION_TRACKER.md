# Qobo One Live — Implementation Tracker

> **Purpose:** Single source of truth for what is built vs what remains.  
> When you ask to *"do the X flow"*, point to a **Flow ID** (e.g. `AUTH-01`, `LIVE-03`) from this file.

**Last reviewed:** 2026-05-15  
**Sources:** Client PDF, Req-2 / Req-3 spreadsheets, `api_documentation_extracted.txt`, current `lib/` codebase.

---

## How to use this file

| Column | Meaning |
|--------|---------|
| **Flow ID** | Unique ID — use in chat: *"Implement LIVE-03"* |
| **Status** | `DONE` · `PARTIAL` · `NOT_STARTED` |
| **Screen / Route** | Flutter view or route name |
| **API** | Backend endpoint (if any) |
| **Notes** | What works today vs what is missing |

**Status rules**

- **DONE** — UI exists and main API is wired (or not needed).
- **PARTIAL** — UI exists but mock data, empty `onTap`, or API not connected.
- **NOT_STARTED** — No screen or no meaningful UI.

---

## Quick numbers (mobile app only)

| Metric | Count |
|--------|-------|
| Registered GetX routes | 9 |
| UI surfaces built (incl. sub-screens) | ~17 |
| Flows DONE | 8 |
| Flows PARTIAL | 24 |
| Flows NOT_STARTED | ~25+ |
| Admin panel (separate web app) | Not in this repo |

**Rough completion:** ~25–30% of user-facing screens; auth/onboarding is the strongest area.

---

## Registered routes (today)

| Route constant | Path | View file |
|----------------|------|-----------|
| `SPLASH` | `/splash` | `lib/app/splash/splash/views/splash_view.dart` |
| `AUTH_LOGIN` | `/login` | `lib/app/auth/login/views/auth_login_view.dart` |
| `AUTH_SIGN_UP` | `/sign-up` | `lib/app/auth/signUp/views/auth_sign_up_view.dart` |
| `AUTH_VERIFY_ACCOUNT` | `/verify-account` | `lib/app/auth/verifyAccount/views/auth_verify_account_view.dart` |
| `AUTH_NEW_PASSWORD` | `/new-password` | `lib/app/auth/new_password/views/new_password_view.dart` |
| `BOTTOM_NAV` | `/bottom-nav` | `lib/app/bottom_nav/views/bottom_nav_view.dart` |
| `UPDATE_PROFILE` | `/update-profile` | `lib/app/user_flow/update_profile/views/update_profile_view.dart` |
| `USER_BASIC_PROFILE` | `/user-basic-profile` | `lib/app/user_flow/user_basic_profile/views/user_basic_profile_view.dart` |
| `LEADER_BOARD` | `/leader-board` | `lib/app/user_flow/leader_board/views/leader_board_view.dart` |
| `AGENCY_HOST_ONBOARDING` | `/agency-host-onboarding` | `lib/app/user_flow/agency_host_onboarding/views/agency_host_onboarding_view.dart` |
| `AGENCY_HOST_STATUS` | `/agency-host-status` | `lib/app/user_flow/agency_host_status/views/agency_host_status_view.dart` |
| `AGENCY_OWNER_REGISTER` | `/agency-owner-register` | `lib/app/user_flow/agency_owner_register/views/agency_owner_register_view.dart` |
| `AGENCY_RECRUIT_LINK` | `/agency-recruit-link` | `lib/app/user_flow/agency_recruit_link/views/agency_recruit_link_view.dart` |
| `AGENCY_HOST_LIST` | `/agency-host-list` | `lib/app/user_flow/agency_host_list/views/agency_host_list_view.dart` |
| `AGENCY_REVENUE` | `/agency-revenue` | `lib/app/user_flow/agency_revenue/views/agency_revenue_view.dart` |
| `LIVE_ACTION` | `/live-action` | `lib/app/user_flow/live_action/views/live_action_view.dart` |
| `LIVE_ROOM_CREATE` | `/live-room-create` | `lib/app/user_flow/live_room_create/views/live_room_create_view.dart` |
| `LIVE_BROADCAST` | `/live-broadcast` | `lib/app/user_flow/live_broadcast/views/live_broadcast_view.dart` |
| `CHAT_DETAIL` | `/chat-detail` | `lib/app/user_flow/messages/chat_detail/views/chat_detail_view.dart` |

**Not a route (opened via `Get.to` or `Get.bottomSheet`):**
- `WalletView` → `Get.to(WalletView)`
- `GiftsBottomSheet` → `Get.bottomSheet`
- `RoomOptionsSheet` → `Get.bottomSheet`

**Routes file:** `lib/routes/app_routes.dart` · `lib/routes/app_pages.dart`

---

## Bottom navigation map

| Tab index | Label | View | Status |
|-----------|-------|------|--------|
| 0 | Discover | `DiscoverTabView` | PARTIAL — includes **Agency Host** entry card → AGENCY-01 |
| 0b | (sub) Audio room | `DiscoverAudioRoomView` | PARTIAL |
| 0c | (sub) Video room | `DiscoverVideoRoomView` | PARTIAL |
| 1 | Live Rooms | `LiveRoomView` | PARTIAL |
| 2 | Center ❤️ | `LiveActionView` | DONE — Renders Explore screen Figma UI |
| 3 | Messages | `MessagesTabView` | PARTIAL |
| 4 | Profile | `ProfileTabView` | PARTIAL |

**Controller:** `lib/app/bottom_nav/controllers/bottom_nav_controller.dart`

---

# 1. Auth & onboarding

| Flow ID | Feature | Status | Screen / Route | API | Code / notes |
|---------|---------|--------|----------------|-----|--------------|
| AUTH-01 | Splash → login or home | DONE | `SplashView` / `SPLASH` | — | Token check → `BOTTOM_NAV` or `AUTH_LOGIN` |
| AUTH-02 | Email/phone + password login | DONE | `AuthLoginView` | `POST /api/auth/login` | `auth_login_controller.dart` |
| AUTH-03 | Google sign-in | DONE | `AuthLoginView` | `POST /api/auth/social` | `google_social_auth_provider.dart` |
| AUTH-04 | Facebook sign-in | DONE | `AuthLoginView` | `POST /api/auth/social` | `facebook_social_auth_provider.dart` |
| AUTH-05 | Sign up | PARTIAL | `AuthSignUpView` | — | UI → verify; full register API TBD |
| AUTH-06 | Send OTP (phone) | DONE | `AuthVerifyAccountView` | `POST /api/auth/login-phone` | |
| AUTH-07 | Verify OTP + session | DONE | `AuthVerifyAccountView` | `POST /api/auth/verify-otp` | → `UPDATE_PROFILE` or home |
| AUTH-08 | Forgot password OTP | DONE | `AuthVerifyAccountView` | `POST /api/auth/forgot-password` | |
| AUTH-09 | Reset password | DONE | `NewPasswordView` | `POST /api/auth/reset-password` | |
| AUTH-10 | Update profile (onboarding) | DONE | `UpdateProfileView` | `PUT /api/user/update` | Multipart + avatar |
| AUTH-11 | Firebase phone login | NOT_STARTED | — | `POST /api/auth/firebase-login` | Endpoint in `api_constants.dart` only |
| AUTH-12 | Apple sign-in | NOT_STARTED | — | `POST /api/auth/social` | Mentioned in UI strings only |

**Repo:** `lib/repo/auth/auth_repo.dart` (only repository in project today)

---

# 2. Agency (client Req-3 spreadsheet)

| Flow ID | Feature | Status | Screen / Route | API | Required fields |
|---------|---------|--------|----------------|-----|-----------------|
| AGENCY-01 | Agency host onboarding form | PARTIAL | `AgencyHostOnboardingView` / `AGENCY_HOST_ONBOARDING` | `POST /api/agency/host-onboarding` | **UI done** — Discover banner + Live Streamer Center; API not wired |
| AGENCY-02 | Check application status | PARTIAL | `AgencyHostStatusView` / `AGENCY_HOST_STATUS` | `GET /api/agency/host-verify-status` | application_id |
| AGENCY-03 | Register agency (owner) | PARTIAL | `AgencyOwnerRegisterView` / `AGENCY_OWNER_REGISTER` | `POST /api/agency/register` | agency_name |
| AGENCY-04 | Generate recruit link | PARTIAL | `AgencyRecruitLinkView` / `AGENCY_RECRUIT_LINK` | `GET /api/agency/generate-link` | Req #9 — agency link code |
| AGENCY-05 | Host list | PARTIAL | `AgencyHostListView` / `AGENCY_HOST_LIST` | `GET /api/agency/host-list` | |
| AGENCY-06 | Revenue & payout | PARTIAL | `AgencyRevenueView` / `AGENCY_REVENUE` | `GET /api/agency/revenue`, `POST /api/agency/payout` | |

---

# 3. Discover & home

| Flow ID | Feature | Status | Screen / Route | API | Notes |
|---------|---------|--------|----------------|-----|-------|
| DISC-01 | Discover home | PARTIAL | `DiscoverTabView` | `GET /api/room/list` | Mock suggested users & trending rooms |
| DISC-02 | Audio room layout | PARTIAL | `DiscoverAudioRoomView` | join, mic | UI only; mock participants |
| DISC-03 | Video room / vertical scroll | PARTIAL | `DiscoverVideoRoomView` | — | Dating-style cards; mock |
| DISC-04 | Search users | NOT_STARTED | — | `GET /api/user/search` | Search bar UI exists; no API |

---

# 4. Live rooms

| Flow ID | Feature | Status | Screen / Route | API | Notes |
|---------|---------|--------|----------------|-----|-------|
| LIVE-01 | Live room feed / categories | PARTIAL | `LiveRoomView` (tab 1) | `GET /api/room/list` | Tabs: Sab, Shresth, Naya, Bangladesh — **Req #19 partial** (mock data) |
| LIVE-01 | Main room container (bottom nav) | PARTIAL | `LiveRoomView` | — | UI skeleton |
| LIVE-02 | Scrollable list of active rooms | PARTIAL | `LiveRoomView` | `GET /api/room/list` | UI skeleton |
| LIVE-03 | Center ❤️ tab (go live / action) | DONE | `LiveActionView` (index 2) | — | Displays Explore screen Figma UI |
| LIVE-04 | Create room | PARTIAL | `LiveRoomCreateView` / `LIVE_ROOM_CREATE` | `POST /api/room/create` | name, type AUDIO/VIDEO, country, seats |
| LIVE-05 | Inside Room (Host/Broadcaster view) | PARTIAL | `LiveBroadcastView` / `LIVE_BROADCAST` | `WS /socket` | Handles host video, chat, controls |
| LIVE-06 | Inside Room (Audience view) | PARTIAL | `LiveBroadcastView` / `LIVE_BROADCAST` | `WS /socket` | Navigated from Feed directly |
| LIVE-07 | Mic mute/lock | PARTIAL | `RoomOptionsSheet` | `POST /api/room/mic-action` | UI available |
| LIVE-08 | Security SOS | NOT_STARTED | in-room | `POST /api/room/security-sos` | **Req #3** calling security |
| LIVE-09 | Share live / room link | NOT_STARTED | in-room | `GET /api/room/share` | **Req #18** |
| LIVE-10 | Send/receive gifts | PARTIAL | `GiftsBottomSheet` | `POST /api/room/gift` | **Req #1** |
| LIVE-11 | Ban/Kick user | PARTIAL | `RoomOptionsSheet` | `POST /api/room/kick` | **Req #3** |

---

# 5. PK battle & dating

| Flow ID | Feature | Status | Screen / Route | API | Notes |
|---------|---------|--------|----------------|-----|-------|
| PK-01 | Search PK opponents | NOT_STARTED | *(new)* | `GET /api/pk/search` | |
| PK-02 | Send / accept PK | NOT_STARTED | *(new)* | `POST /api/pk/send-request`, accept-reject | |
| PK-03 | PK battle status UI | NOT_STARTED | *(new)* | `GET /api/pk/status` | |
| DATE-01 | Dating onboarding | NOT_STARTED | *(new)* | `POST /api/pk/dating-onboarding` | README mentions dating |
| DATE-02 | Matches list | NOT_STARTED | *(new)* | `GET /api/pk/dating-list` | Messages tab has demo "New Match" only |
| DATE-03 | Swipe like/dislike | NOT_STARTED | *(new)* | `POST /api/pk/dating-action` | |

---

# 6. Messages / Chat (MSG)

| Flow ID | Feature | Status | Screen / Route | API | Notes |
|---------|---------|--------|----------------|-----|-------|
| MSG-01 | Global message list | PARTIAL | `Bottom nav index 3` / `MessagesTabView`| `GET /api/chat/list` | Notifications, system msgs, DMs |
| MSG-02 | 1-on-1 Chat | PARTIAL | `ChatDetailView` / `CHAT_DETAIL` | `WS /chat` | Text messages, mocked |

---

# 7. Profile & social

| Flow ID | Feature | Status | Screen / Route | API | Notes |
|---------|---------|--------|----------------|-----|-------|
| PROF-01 | Profile tab | PARTIAL | `ProfileTabView` | `GET /api/user/profile` | Hero from session; grid not wired |
| PROF-02 | User basic profile edit | DONE | `UserBasicProfileView` | `GET/PUT /api/user/update` | Nickname, age, gender, photo |
| PROF-03 | Poster photo upload | NOT_STARTED | *(new or extend profile)* | `POST /api/user/poster-upload` | **Req #10** |
| PROF-04 | User Patti style | NOT_STARTED | *(new)* | `GET /api/user/patti-style/:user_id` | **Req #16** |
| PROF-05 | Level + level icon history | PARTIAL | `UserLevelView` | — | **Req #15**; vipLevel in API models only |
| PROF-06 | Follow / unfollow | NOT_STARTED | *(new)* | `POST /api/user/follow-unfollow` | |
| PROF-07 | User search (from profile/discover) | NOT_STARTED | — | `GET /api/user/search` | |

### Profile feature grid (Profile tab — all NOT_STARTED)

Each tile is UI-only (`ProfileTabView` — no navigation).

| Flow ID | Label | Icon constant | Status |
|---------|-------|---------------|--------|
| PROF-G01 | Visitors | `kIconVisitor` | PARTIAL |
| PROF-G02 | User Level | `kIconUserLevel` | PARTIAL |
| PROF-G03 | Backpack | `kIconBackpack` | PARTIAL |
| PROF-G04 | Family | `kIconFamily` | PARTIAL |
| PROF-G05 | SVIP | `kIconSVIP` | PARTIAL |
| PROF-G06 | Activity | `kIconActivity` | PARTIAL |
| PROF-G07 | Aristocracy Center | `kIconAristocracyCenter` | PARTIAL |
| PROF-G08 | Mall | `kIconMall` | PARTIAL |
| PROF-G09 | Point Center | `kIconPointerCenter` | PARTIAL |
| PROF-G10 | Award | `kIconAward` | NOT_STARTED |
| PROF-G11 | Broadcast Watched | `kIconBroadcastWatched` | NOT_STARTED |
| PROF-G12 | Customer service | `kIconCustomerService` | NOT_STARTED |

### Profile action cards

| Flow ID | Label | Status | Notes |
|---------|-------|--------|-------|
| PROF-A01 | Wallet | PARTIAL | Opens `WalletView` — mock balances |
| PROF-A02 | Live Streamer Center | NOT_STARTED | `onTap: () {}` |

**File:** `lib/app/user_flow/profile_tab/views/profile_tab_view.dart`

---

# 8. Wallet, payments & economy

| Flow ID | Feature | Status | Screen / Route | API | Notes |
|---------|---------|--------|----------------|-----|-------|
| ECON-01 | Wallet balances | PARTIAL | `WalletView` | `GET /api/economy/wallet` | Static coin/diamond numbers |
| ECON-02 | Buy coins / recharge UI | PARTIAL | `WalletView` | `POST /api/economy/recharge` | Static PKR plans |
| ECON-03 | Razorpay integration | NOT_STARTED | checkout flow | method: `razorpay` | **Req #8** — no SDK in pubspec |
| ECON-04 | Google Pay | NOT_STARTED | — | — | **Req #6** |
| ECON-05 | PayPal | NOT_STARTED | — | — | **Req #7** |
| ECON-06 | Gift list + send gift | NOT_STARTED | in-room sheet | `GET gift-list`, `POST send-gift` | |
| ECON-07 | Transaction history | NOT_STARTED | *(new)* | `GET /api/economy/history` | |
| ECON-08 | VIP Store | NOT_STARTED | *(new)* | Admin VIP packages | **Req #12** |
| ECON-09 | Coin seller dashboard | NOT_STARTED | *(new or web)* | Admin sellers APIs | **Req #1** |
| ECON-10 | AdMob ads | NOT_STARTED | — | — | **Req #4** |
| ECON-11 | Facebook ads | NOT_STARTED | — | — | **Req #5** |

---

# 9. Client spreadsheet Req-2 (19 items)

| # | Requirement | Flow ID(s) | Status |
|---|-------------|------------|--------|
| 1 | Coin seller dashboard | ECON-09 | NOT_STARTED |
| 2 | Bad comment moderation | LIVE-11 | NOT_STARTED |
| 3 | Calling security option | LIVE-08 | NOT_STARTED |
| 4 | AdMob account | ECON-10 | NOT_STARTED |
| 5 | Facebook ads | ECON-11 | NOT_STARTED |
| 6 | Google payment | ECON-04 | NOT_STARTED |
| 7 | PayPal activate | ECON-05 | NOT_STARTED |
| 8 | Razorpay account | ECON-03 | NOT_STARTED |
| 9 | Agency link create code | AGENCY-04 | NOT_STARTED |
| 10 | Profile poster photo upload | PROF-03 | NOT_STARTED |
| 11 | Admin phone + Gmail login | ADMIN-* | Out of mobile app |
| 12 | VIP Store | ECON-08 | NOT_STARTED |
| 13 | Admin dashboard by country | ADMIN-* | Out of mobile app |
| 14 | Chat icon | CHAT-01, CHAT-02 | PARTIAL |
| 15 | Level icon history | PROF-05 | NOT_STARTED |
| 16 | User Patti | PROF-04 | NOT_STARTED |
| 17 | Language translate | LIVE-10 | NOT_STARTED |
| 18 | Live sharing | LIVE-09 | NOT_STARTED |
| 19 | Popular / new / old users | LIVE-01 | PARTIAL |

---

# 10. Admin panel (not in Flutter app)

Backend module: `/api/admin/*` — expect a **separate web admin**, not this mobile repo.

| Area | Example endpoints |
|------|-------------------|
| Login | `POST /api/admin/login` |
| Dashboard | `GET /api/admin/stats?country=IN` |
| Users, gifts, VIP, moderation, sellers, ads, games, tasks, notifications, settings | See `api_documentation_extracted.txt` §7 |

---

# 11. Dependencies & integrations checklist

| Integration | In `pubspec.yaml`? | Required for |
|-------------|-------------------|--------------|
| `get` | ✅ | Navigation / state |
| `google_sign_in` | ✅ | AUTH-03 |
| `flutter_facebook_auth` | ✅ | AUTH-04 |
| `image_picker` / `file_picker` | ✅ | Profile photos |
| Razorpay SDK | ❌ | ECON-03 |
| Google Pay / in_app_purchase | ❌ | ECON-04 |
| PayPal SDK | ❌ | ECON-05 |
| `google_mobile_ads` (AdMob) | ❌ | ECON-10 |
| Firebase Auth (phone) | ❌ | AUTH-11 |
| Live streaming SDK (Zego/Agora/etc.) | ❌ | LIVE-06 |

---

# 12. Suggested build order (when you say "do the flow")

Use this order unless the client prioritizes differently:

| Priority | Flow IDs | Why |
|----------|----------|-----|
| P0 | AGENCY-01 | Explicit client form (Req-3) |
| P0 | LIVE-03, LIVE-04, LIVE-05, LIVE-06 | Core product (live audio/video) |
| P1 | ECON-01, ECON-02, ECON-03 | Monetization |
| P1 | CHAT-02 | Messaging |
| P1 | PROF-03, PROF-05, ECON-08 | Profile polish + VIP |
| P2 | AGENCY-03, AGENCY-04 | Agency owners |
| P2 | PK-*, DATE-* | PK & dating |
| P2 | PROF-G01 … PROF-G12 | Profile grid features |
| P3 | ECON-10, ECON-11 | Ads |
| — | ADMIN-* | Separate web project |

---

# 13. How to request work in chat

Copy this template:

```
Implement flow: LIVE-06
Reference: docs/IMPLEMENTATION_TRACKER.md
Notes: [any design link or field rules]
```

Or multiple flows:

```
Implement: AGENCY-01, then wire AGENCY-02 status screen
```

---

# 14. Related project files

| File | Purpose |
|------|---------|
| `docs/IMPLEMENTATION_TRACKER.md` | **This file** |
| `api_documentation_extracted.txt` | Full backend API reference |
| `API_ENDPOINTS_SUMMARY.md` | Shorter endpoint summary |
| `lib/routes/app_pages.dart` | Route registration |
| `lib/repo/auth/auth_repo.dart` | Only API repo today |
| `lib/services/api_constants.dart` | Base URL + auth endpoints |
| `assets/locale/en.json` | UI strings |
| `.cursor/rules/qobo-flutter-getx-conventions.mdc` | Flutter/GetX conventions |

---

*Update this file when a flow moves to DONE or PARTIAL → DONE.*
