# Qobo One Live — Developed Screens & API Integration Status

This document maps out **every single developed UI screen** in the application and classifies its integration state. Use this to track progress, assign integration tasks, and coordinate with the backend team.

---

## 📊 Summary of Screen Statuses
*   **✅ DONE (Fully Integrated):** 12 Screens
*   **⏳ NEEDS INTEGRATION (API exists, UI needs to be wired):** 12 Screens
*   **🆘 NEEDS BACKEND API (UI exists, Backend API endpoints are missing/not implemented):** 15 Screens

---

## 🗺️ Screen & API Status Matrix

### 1. Authentication & Onboarding

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Splash Screen** | `/splash` | *None* | **✅ DONE** | Session check completed offline. |
| **Login Screen** | `/login` | `/api/auth/login`<br>`/api/auth/social`<br>`/api/auth/firebase-login` | **✅ DONE** | Credential, Social, and Firebase mock sign-in are fully integrated. |
| **Sign Up Screen** | `/sign-up` | `/api/auth/register`<br>`/api/auth/social` | **✅ DONE** | Wired with registration database entries. |
| **OTP Verification** | `/verify-account` | `/api/auth/login-phone`<br>`/api/auth/verify-otp`<br>`/api/auth/forgot-password` | **✅ DONE** | SMS Verification and OTP checks are wired. |
| **New Password** | `/new-password` | `/api/auth/reset-password` | **✅ DONE** | Password recovery and database reset wired. |
| **Onboarding Profile** | `/update-profile` | `/api/user/update` | **✅ DONE** | Updates user details and profile picture (Multipart). |

---

### 2. Discover & Home Feed

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Discover Home Feed** | `Bottom Tab 0` | `/api/room/list` | **⏳ NEEDS INTEGRATION** | Discover category pills and trending cards are built. Needs to pull active rooms from the list endpoint. |
| **Audio Room Layout** | *Sub-view* | *TBD / Socket* | **🆘 NEEDS BACKEND API** | UI layout is done. **Needs WebSocket audio streaming socket API from backend.** |
| **Video Room Swiper** | *Sub-view* | *TBD* | **🆘 NEEDS BACKEND API** | Call-style streamer list. **Needs active video signal endpoints from backend.** |
| **User Search Overlay** | *In-feed search* | `/api/user/search` | **✅ DONE** | Debounced active user matching is fully operational. |
| **Follow Action** | *In-feed CTAs* | `/api/user/follow-unfollow` | **✅ DONE** | Following/unfollowing database actions fully wired. |

---

### 3. Live Streaming Rooms

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Live Rooms Grid** | `/live-room` (Tab 1) | `/api/room/list` | **⏳ NEEDS INTEGRATION** | Feed categories (Sab, Shresth, Naya, Bangladesh) display mock grids. Needs to parse active rooms from backend. |
| **Go Live Hub** | `/live-action` (Tab 2) | *None* | **✅ DONE** | Figma spec matching complete. Routes to room creation. |
| **Create Room Screen** | `/live-room-create` | `/api/room/create` | **✅ DONE** | Registers new AUDIO/VIDEO rooms in database. |
| **Live Broadcast Room** | `/live-broadcast` | *TBD / WebSocket* | **🆘 NEEDS BACKEND API** | Streaming viewport UI, co-host seats, and comment bars are built. **Needs Agora/Zego SDK keys and RTMP live signals from backend.** |
| **Live Moderation SOS** | `/live-moderation` | `/api/room/security-sos` | **✅ DONE** | Alarms and security alerts wired to database. |
| **Gifts Bottom Sheet** | *In-room sheet* | `/api/economy/send-gift`<br>`/api/economy/gift-list` | **⏳ NEEDS INTEGRATION** | Gift list is mocked in UI. Needs to wire up the actual sending transactional APIs. |
| **Room Options Sheet** | *In-room sheet* | `/api/room/mic-action`<br>`/api/room/kick` | **⏳ NEEDS INTEGRATION** | Mute, Kick, and Lock seat buttons are mocked. Needs wiring with mic-action endpoints. |

---

### 4. Messages & Chat

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Messages Tab Feed** | `Bottom Tab 3` | `/api/chat/list` | **⏳ NEEDS INTEGRATION** | Messaging inbox is designed. Needs chat lists and history endpoint from backend. |
| **1-on-1 Chat Detail** | `/chat-detail` | *TBD / WebSocket* | **🆘 NEEDS BACKEND API** | Dynamic chat bubbles are designed. **Needs real-time WebSocket chat gateway from backend.** |

---

### 5. Profile & Social Features

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Profile Home Tab** | `Bottom Tab 4` | `/api/user/profile` | **⏳ NEEDS INTEGRATION** | Profile metrics display static user data. Needs to bind to personal profile database payload. |
| **User Profile Edit** | `/user-basic-profile` | `/api/user/profile`<br>`/api/user/update` | **✅ DONE** | Form updates name, age, gender, relationships, languages, and location. |
| **Poster Photo Upload** | *Inside profile* | `/api/user/poster-upload` | **✅ DONE** | Uploads poster background images (Multipart) successfully. |
| **Entrance Patti Store** | `/entrance-patti` | `/api/user/patti-style/:user_id` | **✅ DONE** | Ribbon decoration selectors fully wired. |
| **User Level View** | `/user-level` | *None* | **✅ DONE** | Computes level progress and badge milestones. |
| **Follow List Screen** | `/follow-list` | *TBD* | **⏳ NEEDS INTEGRATION** | Displays follower list. Needs API endpoint listing current followers/followings. |
| **Settings Screen** | `/settings` | *None* | **✅ DONE** | Configuration options list, triggers logout session. |
| **Block List Screen** | `/block-list` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs block/unblock user endpoints from backend.** |

---

### 6. Profile Grid Sub-views (Mocked Features)

These screens are built but need supporting features and APIs from the backend team:

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Backpack Screen** | `/backpack` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs backpack inventory listing and decoration equip endpoints.** |
| **Family Dashboard** | `/family` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs family listing, search, creation, and detail endpoints.** |
| **SVIP Store** | `/svip` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs SVIP benefit packages and purchase endpoints.** |
| **Activity Center** | `/activity` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs active event listings and schedule endpoints.** |
| **Aristocracy Center** | `/aristocracy-center`| *TBD* | **🆘 NEEDS BACKEND API** | **Needs noble rank options list and subscription purchase endpoints.** |
| **Mall Store** | `/mall` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs virtual items store listing and buy endpoints.** |
| **Point Center** | `/point-center` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs point conversion catalog and daily tasks listing.** |
| **Award Achievements** | `/award` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs badges unlock status and claim rewards endpoints.** |
| **Broadcast Watched** | `/broadcast-watched`| *TBD* | **🆘 NEEDS BACKEND API** | **Needs watching history list endpoints.** |
| **Customer Service** | `/customer-service` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs help ticket creation and feedback chat endpoints.** |
| **Visitors Analytics** | `/visitors` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs visitors history log endpoints.** |

---

### 7. Agency Management

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Host Onboarding Form**| `/agency-host-onboarding`| `/api/agency/host-onboarding` | **⏳ NEEDS INTEGRATION** | Onboarding form fields are built. Needs to wire inputs to `AgencyRepo.hostOnboarding` method. |
| **Onboarding Status** | `/agency-host-status` | `/api/agency/host-verify-status` | **⏳ NEEDS INTEGRATION** | Progress tracker UI is built. Needs connection to verify-status endpoint. |
| **Agency Registry** | `/agency-owner-register`| `/api/agency/register` | **⏳ NEEDS INTEGRATION** | Form is built. Needs registry endpoint to assign user as Agency Owner. |
| **Recruit Link Code** | `/agency-recruit-link` | `/api/agency/generate-link` | **⏳ NEEDS INTEGRATION** | UI is built. Needs to copy invite links dynamically from generate-link API. |
| **Agency Host List** | `/agency-host-list` | `/api/agency/host-list` | **⏳ NEEDS INTEGRATION** | Host list UI is built. Needs to parse agency hosts. |
| **Agency Owner View** | `/agency-owner` | `/api/agency/host-list` | **⏳ NEEDS INTEGRATION** | Owner dashboard UI is built. Needs backend variables. |
| **Agency Revenue** | `/agency-revenue` | `/api/agency/revenue` | **⏳ NEEDS INTEGRATION** | Revenue graphs and payout ledgers are designed. Needs to bind revenue API. |

---

### 8. Wallet, Payments & Economy

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Wallet Screen** | *Get.to* | `/api/economy/wallet`<br>`/api/economy/recharge` | **⏳ NEEDS INTEGRATION** | Coin recharge grids are designed. Needs wallet balance and recharge endpoints. |
| **Payment Gateways** | *In-wallet sheet* | *TBD* | **⏳ NEEDS INTEGRATION** | Razorpay, Google Pay, and PayPal sheets are designed. Needs SDK keys or web checkout redirects. |
| **Transaction Logs** | `/transaction-history`| `/api/economy/history` | **⏳ NEEDS INTEGRATION** | History tabs are designed. Needs to display coin/diamond records. |
| **VIP Store** | `/vip-store` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs VIP package catalog and purchase endpoints.** |
| **Coin Seller Panel** | `/coin-seller` | *TBD* | **🆘 NEEDS BACKEND API** | **Needs seller dashboard metrics and coin transfer endpoints.** |

---

### 9. PK Battle & Call Matching (New Modules)

| Screen View | Route/Path | API Endpoint | Integration Status | Notes / Actions Needed |
| :--- | :--- | :--- | :--- | :--- |
| **PK Battle Screen** | `/pk-battle` | `/api/pk/search`<br>`/api/pk/send-request`<br>`/api/pk/status` | **⏳ NEEDS INTEGRATION** | Duel UI matching radars, scorebars, and matching are designed. Needs wiring to PK APIs. |
| **Call Swiper & deck** | `/call` | `/api/pk/dating-onboarding`<br>`/api/pk/dating-list`<br>`/api/pk/dating-action` | **⏳ NEEDS INTEGRATION** | Swiping deck, match animations, and chat inbox are designed. Needs wiring to call matching endpoints. |
