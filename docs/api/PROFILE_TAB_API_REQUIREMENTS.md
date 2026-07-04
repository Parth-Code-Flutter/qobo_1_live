# Profile Tab API Requirements

Project: Qobo One Live Flutter client  
Audience: Backend team  
Prepared from mobile code on branch `new-ui`

## Scope

This document covers the Profile tab and every visible Profile module:

- Profile header, stats, edit profile
- Recharge Coins / Wallet
- Agency & Host access for `super_admin`
- Visitors
- User Level
- Backpack
- Family
- SVIP
- Activity
- Mall
- Point Center
- Award
- Call
- Customer Service
- Settings

Recently hidden from Profile grid and therefore not required for current Profile UI:

- Aristocracy Center
- Broadcast Watched

## Common API Rules

Base URL in mobile:

```text
https://my-backend-api-960q.onrender.com
```

All authenticated endpoints should use:

```http
Authorization: Bearer {jwt}
Content-Type: application/json
```

Standard success envelope:

```json
{
  "statusCode": 1,
  "message": "Success",
  "data": {}
}
```

Mobile treats these as success:

```text
statusCode: 1, 200, 201
success: true
```

Standard error envelope:

```json
{
  "statusCode": 0,
  "message": "Human readable error",
  "data": null
}
```

Use stable string IDs everywhere. Mobile can parse both `id` and `_id`, but `id` is preferred.

---

## 1. Profile Home Header

### Purpose

Profile tab header needs user identity, avatar, level chips, visitor/friend/follow counts, wallet role flags, and super admin access state.

### Existing Endpoint

```http
GET /api/user/profile
```

### Request

No body.

### Required Response

```json
{
  "statusCode": 1,
  "message": "Profile fetched",
  "data": {
    "id": "user_123",
    "name": "Parth",
    "username": "parth",
    "displayPicture": "https://cdn.example.com/users/user_123.jpg",
    "poster": "https://cdn.example.com/posters/user_123.jpg",
    "gender": "male",
    "dob": "2000-01-15",
    "age": 26,
    "country": "India",
    "countryId": "IN",
    "state": "Gujarat",
    "stateId": "GJ",
    "role": "user",
    "level": 12,
    "levelBadge": "LV.12",
    "coinsPerSecond": 2,
    "wallet": {
      "coins": 12450,
      "diamonds": 820
    },
    "stats": {
      "visitors": 2000,
      "friends": 1000,
      "following": 1000,
      "followers": 10000
    },
    "isSuperAdmin": false,
    "agencyCode": "",
    "relationshipStatus": "Single",
    "languages": ["English", "Hindi"],
    "currentLocation": "India, Gujarat",
    "interests": ["Travel", "Music"],
    "voiceShow": "Public",
    "linkedAccounts": ["Google"]
  }
}
```

### Notes

- `role: "super_admin"` or equivalent should be returned for users allowed to see Agency & Host management.
- `displayPicture` and `poster` can be absolute URLs or relative paths. Absolute URLs are preferred.
- Profile tab currently shows static stat fallback values; backend should provide live counts through this endpoint or a dedicated stats endpoint below.

### Optional Dedicated Stats Endpoint

```http
GET /api/user/profile/stats
```

Response:

```json
{
  "statusCode": 1,
  "data": {
    "visitors": 2000,
    "friends": 1000,
    "following": 1000,
    "followers": 10000
  }
}
```

---

## 2. Edit / Basic Profile

### Existing Endpoints

```http
GET /api/user/profile
PUT /api/user/update
POST /api/user/poster-upload
GET /api/auth/countries
GET /api/auth/states?countryId={countryId}
GET /api/user/public/{userId}
```

### `PUT /api/user/update`

Content type:

```text
multipart/form-data
```

Form fields:

```json
{
  "name": "Parth",
  "gender": "male",
  "dob": "2000-01-15",
  "relationshipStatus": "Single",
  "languages": "English,Hindi",
  "interests": "Travel,Music",
  "currentLocation": "India, Gujarat",
  "country": "India",
  "countryId": "IN",
  "state": "Gujarat",
  "stateId": "GJ",
  "coinsPerSecond": "2"
}
```

File field:

```text
displayPicture: image file
```

Success response:

```json
{
  "statusCode": 1,
  "message": "Profile updated successfully",
  "data": {
    "id": "user_123",
    "name": "Parth",
    "displayPicture": "https://cdn.example.com/users/user_123.jpg",
    "gender": "male",
    "dob": "2000-01-15",
    "coinsPerSecond": 2,
    "relationshipStatus": "Single",
    "languages": ["English", "Hindi"],
    "interests": ["Travel", "Music"],
    "currentLocation": "India, Gujarat",
    "country": "India",
    "countryId": "IN",
    "state": "Gujarat",
    "stateId": "GJ"
  }
}
```

### `POST /api/user/poster-upload`

Content type:

```text
multipart/form-data
```

File field:

```text
poster: image file
```

Response:

```json
{
  "statusCode": 1,
  "message": "Poster uploaded",
  "data": {
    "posterUrl": "https://cdn.example.com/posters/user_123.jpg"
  }
}
```

### Countries / States

`GET /api/auth/countries`

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "IN",
      "name": "India",
      "code": "IN",
      "phoneCode": "+91"
    }
  ]
}
```

`GET /api/auth/states?countryId=IN`

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "GJ",
      "name": "Gujarat",
      "countryId": "IN"
    }
  ]
}
```

---

## 3. Wallet / Recharge Coins

### Existing Endpoints

```http
GET /api/economy/wallet
GET /api/economy/package-list
POST /api/economy/recharge
GET /api/economy/history
GET /api/withdraw/config
GET /api/withdraw/history
POST /api/withdraw/request
```

### `GET /api/economy/wallet`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "coins": 12450,
    "diamonds": 820,
    "withdrawableBalance": 3000,
    "currency": "INR"
  }
}
```

### `GET /api/economy/package-list`

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "coin_500",
      "name": "500 Coins",
      "amount": 500,
      "price": 99,
      "currency": "INR",
      "bonus": 0,
      "isActive": true,
      "sortOrder": 1
    }
  ]
}
```

### `POST /api/economy/recharge`

Request:

```json
{
  "amount": 500,
  "method": "razorpay"
}
```

Recommended production request with payment reference:

```json
{
  "packageId": "coin_500",
  "amount": 500,
  "method": "razorpay",
  "paymentId": "pay_xxx",
  "orderId": "order_xxx",
  "signature": "razorpay_signature"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Recharge successful",
  "data": {
    "transactionId": "txn_123",
    "coinsAdded": 500,
    "newBalance": 12950
  }
}
```

### `GET /api/economy/history`

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "txn_123",
      "type": "recharge",
      "amount": 500,
      "currency": "coins",
      "status": "success",
      "title": "Recharge Coins",
      "createdAt": "2026-07-04T10:00:00.000Z"
    }
  ]
}
```

### Withdraw Config

`GET /api/withdraw/config`

```json
{
  "statusCode": 1,
  "data": {
    "allowedTiers": [500, 1000, 2000],
    "currencySymbol": "₹",
    "isEligibleThisWeek": true,
    "userBalance": 3000,
    "maxLimit": 2000
  }
}
```

### Withdraw History

`GET /api/withdraw/history`

```json
{
  "statusCode": 1,
  "data": [
    {
      "transactionId": "wd_123",
      "amount": 1000,
      "status": "pending",
      "requestedAt": "2026-07-04T10:00:00.000Z",
      "method": "upi"
    }
  ]
}
```

### Submit Withdraw

`POST /api/withdraw/request`

Request:

```json
{
  "amount": 1000,
  "bank_details": {
    "account_number": "1234567890",
    "ifsc_code": "HDFC0001234",
    "upi_id": "user@upi"
  }
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Withdrawal request submitted",
  "data": {
    "transactionId": "wd_123",
    "status": "pending"
  }
}
```

---

## 4. Agency & Host Access

Visible only for `super_admin` users in Profile.

### Existing Endpoints

```http
POST /api/agency/host-onboarding
GET /api/agency/host-verify-status
POST /api/agency/register
GET /api/agency/dashboard?month=YYYY-MM
GET /api/agency/generate-link?agency_id={agencyId}
GET /api/agency/host-list?agency_id={agencyId}&status=all
GET /api/agency/host-applications?status=pending&page=1&limit=20
POST /api/agency/payout
```

### Host Onboarding

`POST /api/agency/host-onboarding`

Content type:

```text
multipart/form-data
```

Fields:

```json
{
  "agency_code": "AG123",
  "agencyCode": "AG123",
  "name": "Host Name",
  "hostName": "Host Name",
  "phone": "9876543210",
  "whatsapp": "9876543210",
  "gmail": "host@example.com",
  "type": "audio",
  "hostType": "audio",
  "category": "Music",
  "interest": "Music",
  "countryRegion": "India",
  "country_region": "India",
  "countryId": "IN",
  "state": "Gujarat",
  "stateId": "GJ",
  "city": "Ahmedabad",
  "address": "Full address",
  "dob": "2000-01-15",
  "birthday": "2000-01-15",
  "id_no": "ABCDE1234F",
  "hostIdNumber": "ABCDE1234F"
}
```

Files:

```text
host_real_photo: image file
doc_photo_front: image file
doc_photo_back: image file
```

Response:

```json
{
  "statusCode": 1,
  "message": "Host application submitted",
  "data": {
    "applicationId": "host_app_123",
    "status": "pending"
  }
}
```

### Host Status

`GET /api/agency/host-verify-status?application_id=host_app_123`

or

`GET /api/agency/host-verify-status?phone=9876543210`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "applicationId": "host_app_123",
    "status": "pending",
    "reason": "",
    "coinsPerSecond": 2,
    "submittedAt": "2026-07-04T10:00:00.000Z"
  }
}
```

### Register Agency

`POST /api/agency/register`

Request:

```json
{
  "agency_name": "Parth Agency",
  "owner_name": "Parth",
  "owner_whatsapp": "9876543210",
  "logo_url": "https://cdn.example.com/agency/logo.png"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Agency application submitted",
  "data": {
    "agencyId": "agency_123",
    "agencyName": "Parth Agency",
    "agencyCode": "AG123",
    "status": "pending",
    "applicationId": "agency_app_123"
  }
}
```

### Agency Dashboard

`GET /api/agency/dashboard?month=2026-07`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "agencyId": "agency_123",
    "agencyName": "Parth Agency",
    "agencyCode": "AG123",
    "agencyStatus": "active",
    "commissionRate": 20,
    "recruitLink": "https://qobo.app/join/AG123",
    "summary": {
      "totalHosts": 14,
      "activeHosts": 8,
      "pendingHosts": 3,
      "monthlyRevenue": 120000,
      "availablePayout": 18000
    },
    "hosts": [
      {
        "id": "host_1",
        "name": "Host One",
        "displayPicture": "https://cdn.example.com/h1.jpg",
        "status": "active",
        "coinsPerSecond": 2,
        "monthlyRevenue": 10000,
        "rank": 1
      }
    ]
  }
}
```

### Payout

`POST /api/agency/payout`

Request:

```json
{
  "agency_id": "agency_123",
  "amount": 5000,
  "bank_details": {
    "account_number": "1234567890",
    "ifsc_code": "HDFC0001234",
    "upi_id": "agency@upi"
  }
}
```

---

## 5. Visitors

### Existing Endpoint Declared

```http
GET /api/user/visitors
POST /api/user/follow-unfollow
```

### `GET /api/user/visitors`

Query parameters:

```text
page=1
limit=20
```

Response:

```json
{
  "statusCode": 1,
  "data": {
    "items": [
      {
        "id": "visit_1",
        "userId": "user_456",
        "name": "Eve Adams",
        "displayPicture": "https://cdn.example.com/eve.jpg",
        "country": "India",
        "level": 1,
        "isFollowing": false,
        "visitedAt": "2026-07-04T10:00:00.000Z"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

### Follow / Unfollow Visitor

`POST /api/user/follow-unfollow`

Request:

```json
{
  "target_id": "user_456"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Follow state updated",
  "data": {
    "targetId": "user_456",
    "isFollowing": true,
    "followersCount": 41
  }
}
```

---

## 6. User Level

Current screen is mock data. Backend should provide current level, XP progress, perks, and badge history.

### Required Endpoint

```http
GET /api/user/level
```

Response:

```json
{
  "statusCode": 1,
  "data": {
    "currentLevel": 12,
    "currentExp": 4500,
    "nextLevelExp": 10000,
    "progress": 0.45,
    "perks": [
      {
        "title": "Special Avatar Frame",
        "subtitle": "Unlock the silver frame at level 15",
        "requiredLevel": 15,
        "isUnlocked": false
      }
    ],
    "milestones": [
      {
        "level": 10,
        "title": "Silver Knight",
        "description": "Unlock silver chat bubbles",
        "icon": "shield_rounded",
        "color": "#C0C0C0",
        "isUnlocked": true,
        "unlockedAt": "2026-06-01T10:00:00.000Z"
      }
    ]
  }
}
```

---

## 7. Backpack

### Existing Endpoints Declared

```http
GET /api/user/backpack
POST /api/user/backpack/equip
```

### `GET /api/user/backpack`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "categories": [
      {
        "id": 1,
        "name": "Gifts"
      },
      {
        "id": 2,
        "name": "Avatar Frames"
      },
      {
        "id": 3,
        "name": "Entrance Effects"
      },
      {
        "id": 4,
        "name": "Chat Bubbles"
      }
    ],
    "equipped": {
      "frame": "frame_gold",
      "effect": null,
      "bubble": "bubble_ocean"
    },
    "items": [
      {
        "id": "frame_gold",
        "categoryId": 2,
        "name": "Golden Crown",
        "iconUrl": "https://cdn.example.com/icons/frame_gold.svg",
        "thumbnailUrl": "https://cdn.example.com/items/frame_gold.png",
        "quantity": 1,
        "description": "Golden crown frame",
        "isEquipped": true,
        "expiresAt": "2026-08-01T00:00:00.000Z"
      }
    ]
  }
}
```

### `POST /api/user/backpack/equip`

Request:

```json
{
  "id": "frame_gold",
  "itemId": "frame_gold",
  "item_id": "frame_gold",
  "backpack_item_id": "frame_gold",
  "isEquipped": true
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Item equipped",
  "data": {
    "itemId": "frame_gold",
    "categoryId": 2,
    "isEquipped": true,
    "equipped": {
      "frame": "frame_gold",
      "effect": null,
      "bubble": "bubble_ocean"
    }
  }
}
```

---

## 8. Family

### Existing Endpoints Declared

```http
GET /api/family/list
POST /api/family/create
POST /api/family/join
GET /api/family/detail/{id}
```

### Additional Recommended Endpoints

```http
GET /api/family/my
POST /api/family/leave
GET /api/family/search
POST /api/family/join-request/{requestId}/approve
POST /api/family/join-request/{requestId}/reject
```

### `GET /api/family/list`

Query:

```text
page=1
limit=20
search=royal
sort=popular
```

Response:

```json
{
  "statusCode": 1,
  "data": {
    "items": [
      {
        "id": "fam_1",
        "name": "The Royals",
        "description": "Prestigious family",
        "members": 450,
        "maxMembers": 500,
        "level": 5,
        "leader": {
          "id": "user_1",
          "name": "KingArthur"
        },
        "logoUrl": "https://cdn.example.com/families/fam_1.png",
        "isJoined": false,
        "joinStatus": "none"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 40
  }
}
```

### `POST /api/family/create`

Request:

```json
{
  "name": "My Family",
  "description": "A brand new Qobo Live family",
  "logoUrl": "https://cdn.example.com/family/logo.png"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Family created",
  "data": {
    "id": "fam_new",
    "name": "My Family",
    "members": 1,
    "maxMembers": 100,
    "level": 1,
    "role": "Leader"
  }
}
```

### `POST /api/family/join`

Request:

```json
{
  "family_id": "fam_1",
  "message": "Please accept me"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Join request submitted",
  "data": {
    "familyId": "fam_1",
    "status": "pending",
    "requestId": "join_req_123"
  }
}
```

### `GET /api/family/detail/{id}`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "id": "fam_1",
    "name": "The Royals",
    "description": "Prestigious family",
    "announcement": "Welcome to the family",
    "createdDate": "2026-01-10",
    "members": 451,
    "maxMembers": 500,
    "level": 5,
    "xp": 3200,
    "maxXp": 5000,
    "myRole": "Member",
    "memberList": [
      {
        "userId": "user_1",
        "name": "KingArthur",
        "role": "Leader",
        "contribution": 12500,
        "displayPicture": "https://cdn.example.com/u1.jpg",
        "isOnline": true,
        "level": 45
      }
    ]
  }
}
```

### `POST /api/family/leave`

Request:

```json
{
  "family_id": "fam_1"
}
```

---

## 9. SVIP

Current SVIP screen is mock data. Existing repo has VIP APIs.

### Existing Endpoints

```http
GET /api/economy/vip-packages
POST /api/economy/buy-vip
```

### `GET /api/economy/vip-packages`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "isSvipActive": false,
    "activePlan": null,
    "coinsBalance": 12450,
    "privileges": [
      {
        "id": "badge",
        "title": "SVIP Badge",
        "description": "Gold crown emblem on your profile name",
        "icon": "workspace_premium_rounded"
      }
    ],
    "packages": [
      {
        "id": "svip_1m",
        "duration": "1 Month",
        "durationDays": 30,
        "price": 5000,
        "saving": "Standard",
        "isActive": true
      }
    ]
  }
}
```

Mobile can also parse `data` as only a list of packages, but the object shape above is preferred.

### `POST /api/economy/buy-vip`

Request:

```json
{
  "id": "svip_1m",
  "packageId": "svip_1m",
  "package_id": "svip_1m"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "SVIP activated",
  "data": {
    "packageId": "svip_1m",
    "startsAt": "2026-07-04T10:00:00.000Z",
    "expiresAt": "2026-08-03T10:00:00.000Z",
    "coinsBalance": 7450,
    "isSvipActive": true
  }
}
```

---

## 10. Activity

### Existing Endpoint Declared

```http
GET /api/activity/list
```

### Additional Recommended Endpoint

```http
POST /api/activity/join
```

### `GET /api/activity/list`

Query:

```text
placement=profile
status=active
page=1
limit=20
```

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "act_1",
      "title": "Weekly Star Host Arena",
      "description": "Compete against top broadcasters",
      "status": "active",
      "startsAt": "2026-07-01T00:00:00.000Z",
      "endsAt": "2026-07-07T23:59:59.000Z",
      "timeLeft": "3 days left",
      "bannerUrl": "https://cdn.example.com/activity/act_1.png",
      "gradient": ["#E65C00", "#F9D423"],
      "reward": {
        "coins": 50000,
        "badge": "Crown Profile Badge"
      },
      "isJoined": false
    }
  ]
}
```

### `POST /api/activity/join`

Request:

```json
{
  "activity_id": "act_1"
}
```

---

## 11. Mall

### Existing Endpoints

```http
GET /api/economy/mall
POST /api/economy/mall/buy
```

### `GET /api/economy/mall`

Query:

```text
category=avatar_frames
```

Response:

```json
{
  "statusCode": 1,
  "data": {
    "coinsBalance": 12450,
    "categories": [
      {
        "id": 1,
        "key": "avatar_frames",
        "name": "Avatar Frames"
      },
      {
        "id": 2,
        "key": "entrance_effects",
        "name": "Entrance Effects"
      },
      {
        "id": 3,
        "key": "chat_bubbles",
        "name": "Chat Bubbles"
      }
    ],
    "items": [
      {
        "id": "frame_gold",
        "categoryId": 1,
        "name": "Golden Crown",
        "iconUrl": "https://cdn.example.com/icons/frame_gold.svg",
        "previewUrl": "https://cdn.example.com/preview/frame_gold.png",
        "price": 500,
        "duration": "7 days",
        "durationDays": 7,
        "description": "Golden crown frame",
        "isOwned": false,
        "isActive": true
      }
    ]
  }
}
```

### `POST /api/economy/mall/buy`

Request:

```json
{
  "id": "frame_gold",
  "itemId": "frame_gold",
  "item_id": "frame_gold"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Purchase successful",
  "data": {
    "itemId": "frame_gold",
    "coinsSpent": 500,
    "coinsBalance": 11950,
    "backpackItem": {
      "id": "frame_gold",
      "quantity": 1,
      "expiresAt": "2026-07-11T10:00:00.000Z"
    }
  }
}
```

---

## 12. Point Center

### Existing Endpoints Declared

```http
GET /api/user/tasks
POST /api/user/tasks/claim
```

### Additional Recommended Endpoint

```http
POST /api/points/redeem
```

### `GET /api/user/tasks`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "pointsBalance": 2450,
    "tasks": [
      {
        "id": "daily_checkin",
        "title": "Daily Check-in",
        "description": "Open app once today",
        "reward": 100,
        "rewardType": "points",
        "isCompleted": true,
        "isClaimed": true,
        "progress": 1,
        "target": 1
      }
    ],
    "storeItems": [
      {
        "id": "golden_crown_frame",
        "name": "Golden Crown Frame",
        "cost": 1500,
        "duration": "7 Days",
        "iconUrl": "https://cdn.example.com/icons/badge.svg",
        "type": "avatar_frame"
      }
    ]
  }
}
```

### `POST /api/user/tasks/claim`

Request:

```json
{
  "id": "daily_checkin",
  "taskId": "daily_checkin",
  "task_id": "daily_checkin"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Points claimed",
  "data": {
    "taskId": "daily_checkin",
    "pointsAdded": 100,
    "pointsBalance": 2550,
    "isClaimed": true
  }
}
```

### `POST /api/points/redeem`

Request:

```json
{
  "item_id": "golden_crown_frame"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Redemption successful",
  "data": {
    "itemId": "golden_crown_frame",
    "pointsSpent": 1500,
    "pointsBalance": 950,
    "backpackItemId": "frame_gold"
  }
}
```

---

## 13. Award

### Existing Endpoint Declared

```http
GET /api/user/achievements
```

### Additional Recommended Endpoint

```http
POST /api/user/achievements/claim
```

### `GET /api/user/achievements`

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "broadcasting_star",
      "title": "Broadcasting Star",
      "description": "Stream for 10 hours",
      "type": "Streamer",
      "level": 3,
      "isUnlocked": true,
      "isClaimed": false,
      "progress": 1,
      "progressText": "10h / 10h",
      "icon": "star_rounded",
      "points": 500,
      "unlockedAt": "2026-07-01T10:00:00.000Z"
    }
  ]
}
```

### `POST /api/user/achievements/claim`

Request:

```json
{
  "achievement_id": "broadcasting_star"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Reward claimed",
  "data": {
    "achievementId": "broadcasting_star",
    "pointsAdded": 500,
    "pointsBalance": 3000,
    "isClaimed": true
  }
}
```

---

## 14. Call Module

Current module uses PK dating endpoints for call matching.

### Existing Endpoints

```http
POST /api/pk/dating-onboarding
GET /api/pk/dating-list
POST /api/pk/dating-action
```

### `POST /api/pk/dating-onboarding`

Request:

```json
{
  "interests": ["Chat", "Call", "Gaming Partner"],
  "preferredGender": "Female",
  "minAge": 18,
  "maxAge": 35,
  "location": "India",
  "lookingFor": "Call",
  "aboutMe": "Friendly user"
}
```

Note: current mobile omits `aboutMe` because old backend rejected it. Backend should support it when ready.

Response:

```json
{
  "statusCode": 1,
  "message": "Preferences saved",
  "data": {
    "userId": "user_123",
    "isOnboardingDone": true,
    "preferences": {
      "interests": ["Chat", "Call"],
      "preferredGender": "Female",
      "minAge": 18,
      "maxAge": 35,
      "location": "India"
    }
  }
}
```

### `GET /api/pk/dating-list`

Query recommended:

```text
page=1
limit=20
```

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "user_456",
      "name": "Eve Adams",
      "age": 24,
      "location": "Dhaka, Bangladesh",
      "bio": "Hello!",
      "displayPicture": "https://cdn.example.com/eve.jpg",
      "matchPercentage": 90,
      "interests": ["Chat", "Music"],
      "coinsPerSecond": 2,
      "isOnline": true,
      "canCall": true
    }
  ]
}
```

### `POST /api/pk/dating-action`

Request:

```json
{
  "target_id": "user_456",
  "type": "like"
}
```

Allowed `type`:

```text
like, dislike, superlike
```

Response:

```json
{
  "statusCode": 1,
  "message": "Action saved",
  "data": {
    "targetId": "user_456",
    "type": "like",
    "isMatch": true,
    "matchId": "match_123"
  }
}
```

### Paid Call Billing

Existing endpoint:

```http
POST /api/economy/calling/charge
```

Request:

```json
{
  "host_id": "user_456",
  "duration_seconds": 120
}
```

Response:

```json
{
  "statusCode": 1,
  "data": {
    "chargedCoins": 240,
    "newBalance": 1210,
    "callSessionId": "call_123"
  }
}
```

---

## 15. Customer Service

### Existing Endpoints Declared

```http
POST /api/support/ticket
GET /api/support/tickets
```

### Additional Recommended Endpoints

```http
GET /api/support/faqs
GET /api/support/chat/messages
POST /api/support/chat/send
```

### `GET /api/support/faqs`

Query:

```text
category=payments
search=recharge
```

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "faq_1",
      "category": "Payments",
      "question": "Why is my coin recharge delayed?",
      "answer": "Payment processors can take up to 15 minutes.",
      "sortOrder": 1
    }
  ]
}
```

### `POST /api/support/ticket`

Current mobile repo sends:

```json
{
  "subject": "Coin Recharge Delayed",
  "description": "Recharged 5000 Coins but balance not updated."
}
```

Recommended extended request:

```json
{
  "category": "Payments",
  "subject": "Coin Recharge Delayed",
  "description": "Recharged 5000 Coins but balance not updated.",
  "attachments": ["https://cdn.example.com/support/proof.png"],
  "metadata": {
    "transactionId": "txn_123"
  }
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Ticket submitted",
  "data": {
    "id": "TKT-4890",
    "status": "open",
    "createdAt": "2026-07-04T10:00:00.000Z"
  }
}
```

### `GET /api/support/tickets`

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "id": "TKT-4890",
      "subject": "Coin Recharge Delayed",
      "category": "Payments",
      "status": "pending",
      "description": "Recharge not showing",
      "createdAt": "2026-07-04T10:00:00.000Z",
      "updatedAt": "2026-07-04T11:00:00.000Z",
      "lastReply": "We are checking your payment."
    }
  ]
}
```

### `POST /api/support/chat/send`

Request:

```json
{
  "message": "I need help with recharge",
  "ticketId": "TKT-4890"
}
```

Response:

```json
{
  "statusCode": 1,
  "data": {
    "messageId": "msg_123",
    "sender": "user",
    "text": "I need help with recharge",
    "createdAt": "2026-07-04T10:00:00.000Z"
  }
}
```

---

## 16. Settings

### Existing / Declared Endpoints

```http
GET /api/user/block-list
POST /api/user/block
POST /api/user/unblock
DELETE /api/user/delete
```

### Additional Recommended Endpoints

```http
GET /api/settings
PUT /api/settings
GET /api/legal/privacy
GET /api/legal/terms
```

### `GET /api/settings`

Response:

```json
{
  "statusCode": 1,
  "data": {
    "language": "en",
    "notifications": {
      "push": true,
      "messages": true,
      "liveReminders": true
    },
    "privacy": {
      "showOnlineStatus": true,
      "allowMessagesFrom": "everyone"
    }
  }
}
```

### `PUT /api/settings`

Request:

```json
{
  "language": "en",
  "notifications": {
    "push": true,
    "messages": true,
    "liveReminders": false
  },
  "privacy": {
    "showOnlineStatus": false,
    "allowMessagesFrom": "followers"
  }
}
```

### `GET /api/user/block-list`

Response:

```json
{
  "statusCode": 1,
  "data": [
    {
      "userId": "user_456",
      "name": "Blocked User",
      "displayPicture": "https://cdn.example.com/u456.jpg",
      "blockedAt": "2026-07-04T10:00:00.000Z"
    }
  ]
}
```

### `DELETE /api/user/delete`

Request:

No body.

Response:

```json
{
  "statusCode": 1,
  "message": "Account deleted"
}
```

Recommended optional safer request:

```json
{
  "reason": "User requested deletion",
  "confirm": true
}
```

---

## Implementation Priority

### Highest Priority

1. `GET /api/user/profile`
2. `PUT /api/user/update`
3. `GET /api/economy/wallet`
4. `GET /api/economy/package-list`
5. `POST /api/economy/recharge`
6. `GET /api/user/visitors`
7. `GET /api/user/backpack`
8. `GET /api/user/tasks`
9. `GET /api/user/achievements`
10. `GET /api/support/tickets`

### Medium Priority

1. Family APIs
2. Mall APIs
3. SVIP APIs
4. Activity APIs
5. Point redemption
6. Customer Service FAQ/chat

### Existing Integrated / Partially Integrated Areas

- Wallet and withdrawals have repository calls.
- User profile read/update is wired.
- Agency and host flows are wired.
- Call onboarding/list uses PK dating endpoints.
- Backpack/tasks/achievements endpoints are declared but many UI controllers still use mock data.
- Family, SVIP, Activity, Mall, Point Center, Award, and Customer Service need real controller integration after backend APIs are delivered.

## Backend Delivery Checklist

- Provide final endpoint list with method, auth, query params, request body, and response body.
- Keep response envelope consistent: `statusCode`, `message`, `data`.
- Return absolute CDN URLs for images/icons where possible.
- Support pagination on list endpoints.
- Include stable IDs for all items.
- Include `createdAt` / `updatedAt` timestamps for tickets, transactions, visitors, achievements, family requests.
- Return current balances after any purchase, redemption, recharge, VIP purchase, or withdrawal.
- Return user role and super admin status in `GET /api/user/profile`.
- Avoid breaking existing endpoints already referenced by mobile constants.
