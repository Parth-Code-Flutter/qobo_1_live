# Qobo One Live — Unified API Documentation & Integration Tracker

This document serves as the single source of truth for **Qobo One Live** backend-frontend API contracts. It is structured to help both the mobile development team and the backend team coordinate integrations.

## 📌 Standard Response Envelope
Every backend API response must follow this standard JSON envelope format:
```json
{
  "statusCode": 1,
  "message": "Description of the result",
  "data": {}
}
```
*   `statusCode`: `1` (Success) or `0` (Failure).
*   `message`: Human-readable result description.
*   `data`: Payload object, array, or `null`.

### 🔒 Authentication
All endpoints marked with 🔒 require a valid JSON Web Token (JWT) sent in the headers:
```http
Authorization: Bearer <jwt_token>
```

---

## 🗺️ API Integration Summary Tracker

| Flow ID | API Endpoint | HTTP Method | Integration Status | UI View / Route | Controller |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **AUTH-02** | `/api/auth/login` | `POST` | **✅ Fully Wired** | `AuthLoginView` (`/login`) | `AuthLoginController` |
| **AUTH-03/04** | `/api/auth/social` | `POST` | **✅ Fully Wired** | `AuthLoginView` / `AuthSignUpView` | `AuthLoginController` / `AuthSignUpController` |
| **AUTH-06** | `/api/auth/login-phone` | `POST` | **✅ Fully Wired** | `AuthVerifyAccountView` | `AuthVerifyAccountController` |
| **AUTH-07** | `/api/auth/verify-otp` | `POST` | **✅ Fully Wired** | `AuthVerifyAccountView` | `AuthVerifyAccountController` |
| **AUTH-08** | `/api/auth/forgot-password` | `POST` | **✅ Fully Wired** | `AuthVerifyAccountView` | `AuthVerifyAccountController` |
| **AUTH-09** | `/api/auth/reset-password` | `POST` | **✅ Fully Wired** | `NewPasswordView` | `NewPasswordController` |
| **AUTH-10** | `/api/user/update` (Onboarding) | `PUT` | **✅ Fully Wired** | `UpdateProfileView` | `UpdateProfileController` |
| **PROF-02** | `/api/user/update` (Profile Edit) | `PUT` | **✅ Fully Wired** | `UserBasicProfileView` | `UserBasicProfileController` |
| **PROF-01** | `/api/user/profile` | `GET` | **✅ Fully Wired** | `UserBasicProfileView` / `ProfileTabView` | `UserBasicProfileController` |
| **PROF-03** | `/api/user/poster-upload` | `POST` | **✅ Fully Wired** | `UserBasicProfileView` | `UserBasicProfileController` |
| **PROF-07** | `/api/user/search` | `GET` | **✅ Fully Wired** | `DiscoverTabView` (search query) | `DiscoverTabController` |
| **PROF-06** | `/api/user/follow-unfollow` | `POST` | **✅ Fully Wired** | `DiscoverTabView` (search list) | `DiscoverTabController` |
| **LIVE-04** | `/api/room/create` | `POST` | **✅ Fully Wired** | `LiveRoomCreateView` | `LiveRoomCreateController` |
| **AGENCY-01** | `/api/agency/host-onboarding` | `POST` | **⚠️ Repo Ready (UI Mock)** | `AgencyHostOnboardingView` | `AgencyHostOnboardingController` |
| **AGENCY-02** | `/api/agency/host-verify-status` | `GET` | **⏳ Pending UI Wire** | `AgencyHostStatusView` | *Mocked* |
| **AGENCY-03** | `/api/agency/register` | `POST` | **⏳ Pending UI Wire** | `AgencyOwnerRegisterView` | *Mocked* |
| **AGENCY-04** | `/api/agency/generate-link` | `GET` | **⏳ Pending UI Wire** | `AgencyRecruitLinkView` | *Mocked* |
| **AGENCY-05** | `/api/agency/host-list` | `GET` | **⏳ Pending UI Wire** | `AgencyHostListView` | *Mocked* |
| **AGENCY-06** | `/api/agency/revenue` | `GET` | **⏳ Pending UI Wire** | `AgencyRevenueView` | *Mocked* |
| **ECON-01** | `/api/economy/wallet` | `GET` | **⏳ Pending UI Wire** | `WalletView` | *Mocked* |
| **ECON-02** | `/api/economy/recharge` | `POST` | **⏳ Pending UI Wire** | `WalletView` | *Mocked* |
| **ECON-07** | `/api/economy/history` | `GET` | **⏳ Pending UI Wire** | `TransactionHistoryView` | *Mocked* |
| **LIVE-01** | `/api/room/list` | `GET` | **⏳ Pending UI Wire** | `LiveRoomView` | *Mocked* |

---

## 1. Fully Wired & Integrated APIs (UI Screen ↔️ Backend)

These APIs have their UI elements, controllers, and GetX repository layers completely wired and operational.

### 1.1 Social Sign-In & Login (Google & Facebook)
*   **Flow ID:** `AUTH-03 / AUTH-04`
*   **Endpoint:** `/api/auth/social`
*   **HTTP Method:** `POST`
*   **Authentication:** ❌ Public
*   **Content-Type:** `application/json`
*   **UI Location:** `AuthLoginView` (Google/Facebook buttons) & `AuthSignUpView` (Google/Facebook buttons)
*   **Controller:** `AuthLoginController` / `AuthSignUpController`
*   **Description:** authenticates social profile logins via Google or Facebook. If the email or social ID does not exist in the database, it acts as a silent signup.

#### Request Payload
```json
{
  "name": "John Doe",
  "email": "johndoe@gmail.com",
  "phone": "9876543210",
  "socialId": "google_11674895027493012",
  "authType": "google",
  "displayPicture": "https://lh3.googleusercontent.com/a/ALm5wu..."
}
```
*   `authType`: Must be `"google"` or `"facebook"`.
*   `email`, `phone`, `displayPicture` are optional depending on provider payload.

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "7ac156d8-fa79-4bc7-9dbf-124b8908da22",
      "name": "John Doe",
      "phone": "9876543210",
      "email": "johndoe@gmail.com",
      "displayPicture": "https://lh3.googleusercontent.com/a/ALm5wu...",
      "level": 1,
      "vipLevel": 0,
      "role": "USER",
      "isOnline": true,
      "country": null,
      "bio": null,
      "gender": null,
      "dob": null,
      "createdAt": "2026-05-18T10:15:30.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjdhYzE1NmQ4LWZhNzktNGJjNy05ZGJmLTEyNGI4OTA4ZGEyMiJ9..."
  }
}
```

---

### 1.2 Phone Login (Request OTP)
*   **Flow ID:** `AUTH-06`
*   **Endpoint:** `/api/auth/login-phone`
*   **HTTP Method:** `POST`
*   **Authentication:** ❌ Public
*   **Content-Type:** `application/json`
*   **UI Location:** `AuthVerifyAccountView`
*   **Controller:** `AuthVerifyAccountController`
*   **Description:** Sends a 4 or 6-digit Verification OTP via SMS to the specified phone number.

#### Request Payload
```json
{
  "phone": "9876543210",
  "country_code": "91"
}
```

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "OTP sent",
  "data": {
    "message": "OTP sent successfully",
    "smsResult": {
      "return": true,
      "request_id": "req_sh83kdb7923h"
    }
  }
}
```

---

### 1.3 Verify Phone OTP
*   **Flow ID:** `AUTH-07`
*   **Endpoint:** `/api/auth/verify-otp`
*   **HTTP Method:** `POST`
*   **Authentication:** ❌ Public
*   **Content-Type:** `application/json`
*   **UI Location:** `AuthVerifyAccountView` (verification state)
*   **Controller:** `AuthVerifyAccountController`
*   **Description:** Validates the OTP received by the user and establishes their session token.

#### Request Payload
```json
{
  "phone": "9876543210",
  "otp": "1234"
}
```

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "OTP verified successfully",
  "data": {
    "user": {
      "id": "e891c34a-95c1-455b-b9f1-df7418930ff2",
      "name": "User_98765",
      "phone": "9876543210",
      "email": null,
      "displayPicture": null,
      "level": 1,
      "vipLevel": 0,
      "role": "USER",
      "isOnline": true,
      "country": null,
      "bio": null,
      "gender": null,
      "dob": null,
      "createdAt": "2026-05-18T10:15:30.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImU4OTFjMzRhLTk1YzEtNDU1Yi1iOWYxLWRmNzQxODkzMGZmMiJ9..."
  }
}
```

---

### 1.4 Forgot Password (Send Reset OTP)
*   **Flow ID:** `AUTH-08`
*   **Endpoint:** `/api/auth/forgot-password`
*   **HTTP Method:** `POST`
*   **Authentication:** ❌ Public
*   **Content-Type:** `application/json`
*   **UI Location:** `AuthVerifyAccountView` (reset-pass triggers)
*   **Controller:** `AuthVerifyAccountController`
*   **Description:** Sends a password reset OTP code to the verified user phone number.

#### Request Payload
```json
{
  "phone": "9876543210"
}
```

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "OTP sent successfully to your phone number",
  "data": {
    "success": true
  }
}
```

---

### 1.5 Reset Password
*   **Flow ID:** `AUTH-09`
*   **Endpoint:** `/api/auth/reset-password`
*   **HTTP Method:** `POST`
*   **Authentication:** ❌ Public
*   **Content-Type:** `application/json`
*   **UI Location:** `NewPasswordView`
*   **Controller:** `NewPasswordController`
*   **Description:** Resets the password using the OTP validated on the previous screen.

#### Request Payload
```json
{
  "phone": "9876543210",
  "otp": "1234",
  "password": "NewSecretPassword123"
}
```

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Password reset successfully",
  "data": null
}
```

---

### 1.6 Standard Login (Username + Password)
*   **Flow ID:** `AUTH-02`
*   **Endpoint:** `/api/auth/login`
*   **HTTP Method:** `POST`
*   **Authentication:** ❌ Public
*   **Content-Type:** `application/json`
*   **UI Location:** `AuthLoginView`
*   **Controller:** `AuthLoginController`
*   **Description:** Traditional login via registered username and password.

#### Request Payload
```json
{
  "username": "johndoe",
  "password": "secretPassword123"
}
```

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "e891c34a-95c1-455b-b9f1-df7418930ff2",
      "name": "johndoe",
      "phone": "9876543210",
      "email": "johndoe@gmail.com",
      "displayPicture": "/uploads/avatars/john.jpg",
      "level": 3,
      "vipLevel": 1,
      "role": "USER",
      "isOnline": true,
      "country": "IN",
      "createdAt": "2026-05-01T08:00:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 1.7 Fetch Current User Profile
*   **Flow ID:** `PROF-01`
*   **Endpoint:** `/api/user/profile`
*   **HTTP Method:** `GET`
*   **Authentication:** 🔒 Bearer Token Required
*   **UI Location:** `UserBasicProfileView` (on load) & `ProfileTabView`
*   **Controller:** `UserBasicProfileController`
*   **Description:** Fetches all personal profile records for the currently authenticated session.

#### Request
*   *Headers: `Authorization: Bearer <token>`*
*   *Body: None*

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Profile fetched successfully",
  "data": {
    "id": "e891c34a-95c1-455b-b9f1-df7418930ff2",
    "name": "John Doe",
    "phone": "9876543210",
    "email": "john@gmail.com",
    "displayPicture": "/uploads/avatars/john.jpg",
    "poster": "/uploads/posters/john_bg.jpg",
    "level": 5,
    "vipLevel": 2,
    "role": "USER",
    "isOnline": true,
    "country": "IN",
    "bio": "Audio streamer & PK Enthusiast",
    "gender": "male",
    "dob": "1995-01-15T00:00:00.000Z",
    "relationshipStatus": "Single",
    "languages": "English, Hindi",
    "currentLocation": "India",
    "interests": "Travel, Music",
    "createdAt": "2026-05-01T08:00:00.000Z"
  }
}
```

---

### 1.8 Update User Profile Details (Onboarding & Profile Tab)
*   **Flow ID:** `AUTH-10 / PROF-02`
*   **Endpoint:** `/api/user/update`
*   **HTTP Method:** `PUT`
*   **Authentication:** 🔒 Bearer Token Required
*   **Content-Type:** `multipart/form-data`
*   **UI Location:** `UpdateProfileView` & `UserBasicProfileView`
*   **Controller:** `UpdateProfileController` & `UserBasicProfileController`
*   **Description:** Updates the profile attributes. Supports uploading the avatar (`displayPicture`) as a binary file alongside key metadata fields.

#### Multipart Form Fields
*   `displayPicture` (File, Optional) - Avatar image binary file.
*   `name` (String, Optional) - E.g., `"John Doe"`
*   `gender` (String, Optional) - E.g., `"male"` or `"female"`
*   `dob` (String, Optional) - Date of birth in `"YYYY-MM-DD"` format (e.g. `"1995-01-15"`).
*   `country` (String, Optional) - E.g., `"IN"`
*   `bio` (String, Optional) - User description.
*   `relationshipStatus` (String, Optional) - E.g., `"Single"` or `"Married"`
*   `languages` (String, Optional) - Languages spoken.
*   `interests` (String, Optional) - Hobbies.
*   `currentLocation` (String, Optional) - E.g., `"India"`

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Profile updated successfully",
  "data": {
    "id": "e891c34a-95c1-455b-b9f1-df7418930ff2",
    "name": "John Doe",
    "phone": "9876543210",
    "email": "john@gmail.com",
    "displayPicture": "/uploads/avatars/new_john.jpg",
    "level": 5,
    "vipLevel": 2,
    "role": "USER",
    "isOnline": true,
    "country": "IN",
    "bio": "Audio streamer & PK Enthusiast",
    "gender": "male",
    "dob": "1995-01-15T00:00:00.000Z"
  }
}
```

---

### 1.9 Upload Poster Background
*   **Flow ID:** `PROF-03`
*   **Endpoint:** `/api/user/poster-upload`
*   **HTTP Method:** `POST`
*   **Authentication:** 🔒 Bearer Token Required
*   **Content-Type:** `multipart/form-data`
*   **UI Location:** `UserBasicProfileView` (instant upload banner)
*   **Controller:** `UserBasicProfileController`
*   **Description:** Uploads a custom horizontal room/profile poster background image.

#### Multipart Form Fields
*   `poster` (File, Required) - Horizontal poster image file binary.

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Poster uploaded successfully",
  "data": {
    "posterUrl": "/uploads/posters/john_poster_192.jpg"
  }
}
```

---

### 1.10 Search Active Users
*   **Flow ID:** `PROF-07`
*   **Endpoint:** `/api/user/search`
*   **HTTP Method:** `GET`
*   **Authentication:** 🔒 Bearer Token Required
*   **UI Location:** `DiscoverTabView` (Search Input Overlay)
*   **Controller:** `DiscoverTabController`
*   **Description:** Performs a reactive, debounced query search over all usernames and tags.

#### Query Parameters
*   `query` (String, Required) - E.g. `/api/user/search?query=john`

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Search results",
  "data": [
    {
      "id": "e891c34a-95c1-455b-b9f1-df7418930ff2",
      "name": "John Doe",
      "displayPicture": "/uploads/avatars/john.jpg"
    },
    {
      "id": "a90b8f72-671c-4390-ac99-90f7d54238e8",
      "name": "Johnny Bravo",
      "displayPicture": null
    }
  ]
}
```

---

### 1.11 Follow / Unfollow User
*   **Flow ID:** `PROF-06`
*   **Endpoint:** `/api/user/follow-unfollow`
*   **HTTP Method:** `POST`
*   **Authentication:** 🔒 Bearer Token Required
*   **Content-Type:** `application/json`
*   **UI Location:** `DiscoverTabView` (search items follow CTA)
*   **Controller:** `DiscoverTabController`
*   **Description:** Follows or unfollows the designated target user.

#### Request Payload
```json
{
  "target_id": "a90b8f72-671c-4390-ac99-90f7d54238e8",
  "action": "follow"
}
```
*   `action`: Must be `"follow"` or `"unfollow"`.

#### Success Response (200 OK)
```json
{
  "statusCode": 1,
  "message": "Successfully followed",
  "data": {
    "id": "902d38ff-f12b-42b7-a3a8-482a87b8f99e",
    "followerId": "e891c34a-95c1-455b-b9f1-df7418930ff2",
    "followingId": "a90b8f72-671c-4390-ac99-90f7d54238e8",
    "createdAt": "2026-05-18T10:20:00.000Z"
  }
}
```

---

### 1.12 Create Live Streaming / Audio Room
*   **Flow ID:** `LIVE-04`
*   **Endpoint:** `/api/room/create`
*   **HTTP Method:** `POST`
*   **Authentication:** 🔒 Bearer Token Required
*   **Content-Type:** `application/json`
*   **UI Location:** `LiveRoomCreateView`
*   **Controller:** `LiveRoomCreateController`
*   **Description:** Registers a new live room for active broadcasting. On success, the creator immediately redirects into the host mode view.

#### Request Payload
```json
{
  "name": "Chill Zone & Music",
  "type": "AUDIO",
  "country": "IN",
  "maxSeats": 8,
  "isPrivate": false
}
```
*   `type`: Must be `"AUDIO"` or `"VIDEO"`.

#### Success Response (201 Created)
```json
{
  "statusCode": 1,
  "message": "Room created successfully",
  "data": {
    "id": "c1f7b889-8d76-47b1-b922-a9b098dc71a2",
    "name": "Chill Zone & Music",
    "type": "AUDIO",
    "hostId": "e891c34a-95c1-455b-b9f1-df7418930ff2",
    "country": "IN",
    "maxSeats": 8,
    "isPrivate": false,
    "isLive": true,
    "createdAt": "2026-05-18T10:25:00.000Z"
  }
}
```

---

## 2. Repository-Ready Backend APIs (UI Connection Pending)

The backend code specifications and frontend repository layers are fully written, but the UI controller currently holds a mock overlay. This is the **immediate next target** for integration.

### 2.1 Host Onboarding Application (Multipart)
*   **Flow ID:** `AGENCY-01`
*   **Endpoint:** `/api/agency/host-onboarding`
*   **HTTP Method:** `POST`
*   **Authentication:** ❌ Public
*   **Content-Type:** `multipart/form-data`
*   **UI Location:** `AgencyHostOnboardingView` (forms are currently saved locally as a simulated delay)
*   **Repository Layer:** Implemented inside `AgencyRepo.hostOnboarding` in `lib/repo/agency/agency_repo.dart`.
*   **Description:** Submits a streaming host onboarding application linking to an existing active agency code.

#### Multipart Form Fields
*   `host_real_photo` (File, Required) - Portrait verification image file binary.
*   `agency_code` (String, Required) - Code of the agency they are onboarding to.
*   `name` (String, Required) - Host legal name.
*   `phone` (String, Required) - Contact phone number.

#### Target Success Response (201 Created)
```json
{
  "statusCode": 1,
  "message": "Application submitted successfully",
  "data": {
    "id": "app_982d3h8fb20d",
    "agencyCode": "A1B2C3",
    "name": "Sarah Connor",
    "phone": "9876543210",
    "hostRealPhoto": "/uploads/agency/hosts/sarah.jpg",
    "status": "PENDING",
    "createdAt": "2026-05-18T10:30:00.000Z"
  }
}
```

---

## 3. Roadmapped Backend-Ready APIs (Frontend Mocked / TBD)

These backend endpoints exist inside the system's core specifications (`api_documentation_extracted.txt`) but the corresponding UI flows (like rooms lists, wallets, and messages) are using simulated front-end states. 

**This serves as our tracker to prevent duplicate work and select the next integration tasks.**

### 3.1 Live Rooms & Discovery
*   **GET `/api/room/list?type=AUDIO&country=IN`**
    *   **Purpose:** Fetches active room list based on filters (audio/video categories).
    *   **Corresponds to UI:** `LiveRoomView` (Sab, Shresth, Naya tabs).
*   **POST `/api/room/join`**
    *   **Request:** `{ "room_id": "uuid" }`
    *   **Purpose:** Enters a streaming room as a listener/viewer.
*   **POST `/api/room/mic-action`**
    *   **Request:** `{ "action": "mute", "seat_id": 3 }`
    *   **Purpose:** Host seat control rules (`"lock" \| "unlock" \| "mute" \| "unmute"`).
*   **POST `/api/room/security-sos`**
    *   **Request:** `{ "room_id": "uuid" }`
    *   **Purpose:** Triggers moderator alarm / security alert.

### 3.2 Wallet & Financials
*   **GET `/api/economy/wallet`**
    *   **Purpose:** Returns user's balances of coins, diamonds, and beans.
    *   **Corresponds to UI:** `WalletView` (balances currently static).
*   **GET `/api/economy/history`**
    *   **Purpose:** Fetches user's virtual currency transaction audit logs.
    *   **Corresponds to UI:** `TransactionHistoryView` (Coin/Diamond tabs are currently mocked).
*   **POST `/api/economy/recharge`**
    *   **Request:** `{ "amount": 1000, "method": "razorpay" }`
    *   **Purpose:** Processes standard credit/debit/wallet recharges.

### 3.3 Gift Transactions
*   **GET `/api/economy/gift-list`**
    *   **Purpose:** Fetches all SVGA/JSON animations, prices, and IDs for sending.
    *   **Corresponds to UI:** `GiftsBottomSheet` inside the room.
*   **POST `/api/economy/send-gift`**
    *   **Request:** `{ "receiver_id": "uuid", "gift_id": "uuid", "room_id": "uuid" }`
    *   **Purpose:** Decelerates coins from sender, adds diamonds to receiver, sends real-time alert.

### 3.4 PK Battle & Call Matching
*   **GET `/api/pk/search?room_id=uuid`**
    *   **Purpose:** Finds eligible rooms looking for a PK challenge.
*   **POST `/api/pk/send-request`**
    *   **Request:** `{ "target_room_id": "uuid" }`
    *   **Purpose:** Initiates a live streaming duel.
*   **POST `/api/pk/dating-onboarding`**
    *   **Request:** `{ "interests": [], "lookingFor": "", "aboutMe": "" }`
    *   **Purpose:** Sets call card filter profile tags.
*   **GET `/api/pk/dating-list`**
    *   **Purpose:** Pulls nearby/matching callers list.

### 3.5 Agency Management
*   **POST `/api/agency/register`**
    *   **Request:** `{ "agency_name": "Star Agency" }`
    *   **Purpose:** Allows registering a user as an Agency Owner.
    *   **Corresponds to UI:** `AgencyOwnerRegisterView`.
*   **GET `/api/agency/generate-link?agency_id=uuid`**
    *   **Purpose:** Generates host invite code URL.
    *   **Corresponds to UI:** `AgencyRecruitLinkView`.
*   **GET `/api/agency/host-list?agency_id=uuid`**
    *   **Purpose:** Lists all hosts operating under an agency.
    *   **Corresponds to UI:** `AgencyHostListView`.
