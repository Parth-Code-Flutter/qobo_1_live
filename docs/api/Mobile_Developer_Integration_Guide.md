# 📱 Qobo One Live - Mobile Developer Integration Guide

This document contains the complete integration specifications for:
1. **Referral Code System** (Profile screen, Signup screen verification, and Invite Friends screen with stats & history).
2. **1-to-1 Audio & Video Calling with FCM Push Notifications & 50/50 Call Charge Split** (Ringing FCM push payload, Single push deduplication fix, Start Call, Accept/Reject Call, Call Charging & End Call).
3. **Audio/Video Room Host Session Earnings & 20% Gift Commission Flow**.

---

## 📡 Base URLs

- **Live Production Server**: `https://my-backend-api-960q.onrender.com`
- **Local Development**: `http://localhost:5000`

---

# 🎁 SECTION 1: REFERRAL CODE SYSTEM

## 1️⃣ Generate Referral Code (Profile Screen)
Generates or retrieves the active 8-character referral code for the logged-in user.

- **Endpoint**: `POST /api/user/referral/generate`
- **Headers**:
  - `Authorization: Bearer <USER_JWT_TOKEN>`
  - `Content-Type: application/json`

### Success Response (200 / 201)
```json
{
  "statusCode": 1,
  "message": "Referral code generated successfully",
  "data": {
    "code": "QOBOX5WX",
    "activeCode": "QOBOX5WX",
    "status": "ACTIVE",
    "shareMessage": "Use my referral code QOBOX5WX on Qobo One Live to get bonus coins on signup!",
    "createdAt": "2026-08-20T10:00:00.000Z"
  }
}
```

---

## 2️⃣ Get Referral Details & Invite Friends Screen Data
Fetches user stats (Total Friends Joined, Total Coins Earned), active referral code, share text, and history list.

- **Endpoint**: `GET /api/user/referral/my-code`
- **Headers**:
  - `Authorization: Bearer <USER_JWT_TOKEN>`

### Success Response (200)
```json
{
  "statusCode": 1,
  "message": "Referral details fetched successfully",
  "data": {
    "code": "QOBOX5WX",
    "activeCode": "QOBOX5WX",
    "shareMessage": "Use my referral code QOBOX5WX on Qobo One Live to get bonus coins on signup!",
    "totalFriendsJoined": 2,
    "totalCoinsEarned": 300,
    "friendsJoined": [
      {
        "id": "ref_001",
        "code": "QOBOX5WX",
        "usedBy": {
          "id": "usr_9912",
          "name": "Alex Johnson",
          "displayPicture": "https://my-backend-api-960q.onrender.com/uploads/profile1.jpg",
          "avatarUrl": "https://my-backend-api-960q.onrender.com/uploads/profile1.jpg",
          "createdAt": "2026-08-20T08:30:00.000Z"
        },
        "coinsEarned": 150,
        "amount": 150,
        "usedAt": "2026-08-20T08:30:00.000Z"
      }
    ]
  }
}
```

---

## 3️⃣ Verify Referral Code (Signup Screen - "Verify" Button)
Public endpoint called when a new user enters a referral code on the signup screen and taps **"Verify"**.

- **Endpoint**: `POST /api/auth/verify-referral-code`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
```json
{
  "code": "QOBOX5WX"
}
```

### Success Response (200) - Code is Valid & Active
```json
{
  "statusCode": 1,
  "message": "Referral code verified successfully",
  "data": {
    "valid": true,
    "code": "QOBOX5WX",
    "rewardCoins": 150,
    "referrerName": "Jitendra",
    "message": "Valid referral code! You will earn 150 bonus coins upon completing signup."
  }
}
```

### Error Response (400) - Code Invalid or Used
```json
{
  "statusCode": 0,
  "message": "This referral code has already been used"
}
```

---

## 4️⃣ Register Account with Referral Code
Pass `"referralCode"` in the registration request body.

- **Endpoint**: `POST /api/auth/register` (or `verify-otp` / `social`)
- **Headers**: `Content-Type: application/json`
- **Request Body**:
```json
{
  "name": "Friend User",
  "email": "friend@example.com",
  "phone": "+919876543999",
  "password": "Password123!",
  "referralCode": "QOBOX5WX"
}
```

---

## 5️⃣ Get Referral History ("Earnings" & "Friends Joined" Tabs)
Returns earnings list for the "Earnings" tab and friend list for the "Friends joined" tab on the Invite Friends screen.

- **Endpoint**: `GET /api/user/referral/history`
- **Headers**:
  - `Authorization: Bearer <USER_JWT_TOKEN>`

### Success Response (200)
```json
{
  "statusCode": 1,
  "message": "Referral history fetched successfully",
  "data": [
    {
      "id": "tx_88123",
      "title": "Referral reward",
      "type": "REFERRAL_EARNING",
      "amount": 150,
      "coins": 150,
      "coinsEarned": 150,
      "formattedAmount": "+150",
      "description": "Earned 150 coins from referral",
      "referralCode": "QOBOX5WX",
      "otherUser": {
        "id": "usr_9912",
        "name": "Alex Johnson",
        "displayPicture": "https://my-backend-api-960q.onrender.com/uploads/profile1.jpg",
        "avatarUrl": "https://my-backend-api-960q.onrender.com/uploads/profile1.jpg"
      },
      "createdAt": "2026-08-20T08:30:00.000Z"
    }
  ]
}
```

---

# 📞 SECTION 2: 1-TO-1 AUDIO & VIDEO CALLING WITH FCM PUSH NOTIFICATIONS & CALL CHARGING SPLIT

## 1️⃣ Start Call & Send FCM Ringing Push Notification
Initiates a 1-on-1 audio or video call and sends 1 single high-priority ringing push notification to the callee device.

- **Endpoint**: `POST /api/call/direct/start`
- **Headers**:
  - `Authorization: Bearer <CALLER_JWT_TOKEN>` (User A Token)
  - `Content-Type: application/json`
- **Request Body (User A calling User B `idc4658315`)**:
```json
{
  "calleeUserId": "idc4658315",
  "callType": "voice"
}
```
*(Note: `calleeUserId` accepts either User B's **User ID** `idc4658315` or **Phone Number** `9587736762`. For video calls, pass `"callType": "video"`).*

### Success Response (200)
```json
{
  "statusCode": 1,
  "message": "Ringing",
  "data": {
    "callId": "vc_chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
    "roomId": "chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
    "zegoCallId": "vc_chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
    "historyDocId": "4963a46b-a30b-4fd9-b99a-c094eaadd09f",
    "expiresAt": "2026-08-20T06:28:23.693Z",
    "coinsPerSecond": 2,
    "callerPays": true
  }
}
```

---

## 2️⃣ FCM Push Notification Payload & Single Push Guarantee
When `POST /api/call/direct/start` is triggered, FCM sends **1 single high-priority push notification** to the callee's active device (tokens are automatically deduplicated and limited to 1 per user).

### Android FCM Settings
- **Priority**: `high`
- **Sound**: `ringtone`
- **Channel ID**: `incoming_call_channel`
- **Priority Max & Visibility Public**: Included
- **Click Action**: `FLUTTER_NOTIFICATION_CLICK`

### iOS APNs Settings
- **Header**: `apns-priority: 10`, `apns-push-type: alert`
- **APS Payload**: `category: "INCOMING_CALL"`, `sound: "ringtone.caf"`, `interruption-level: "time-sensitive"`

### Data Payload Received by App:
```json
{
  "type": "incoming_call",
  "event": "incoming_call",
  "category": "INCOMING_CALL",
  "call_type": "voice",
  "callType": "voice",
  "call_id": "vc_chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
  "zego_call_id": "vc_chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
  "room_id": "chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
  "caller_id": "444a2f6f-1a84-4170-ad92-a868caaf6513",
  "caller_name": "Test Agency 123456",
  "caller_avatar": "https://my-backend-api-960q.onrender.com/uploads/profile.jpg",
  "callee_id": "idc4658315",
  "title": "Incoming Voice Call",
  "body": "Test Agency 123456 is calling you...",
  "sound": "ringtone",
  "channel_id": "incoming_call_channel"
}
```

---

## 3️⃣ Respond to Call (Accept / Reject)
- **Endpoint**: `POST /api/call/direct/respond`
- **Headers**:
  - `Authorization: Bearer <CALLEE_JWT_TOKEN>` (User B Token)
  - `Content-Type: application/json`
- **Request Body (Accept Call)**:
```json
{
  "callId": "vc_chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
  "roomId": "chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
  "action": "accept"
}
```
*(To reject: pass `"action": "reject"`)*

### Success Response (200)
```json
{
  "statusCode": 1,
  "message": "Accepted",
  "data": { "callId": "vc_chat_...", "status": "accepted" }
}
```

---

## 4️⃣ Charge Call (50/50 Revenue Split Rule)
Debits Caller A's wallet and credits 50% to Callee B's wallet (diamonds) while retaining 50% company commission.

- **Endpoint**: `POST /api/economy/calling/charge`
- **Headers**:
  - `Authorization: Bearer <CALLER_JWT_TOKEN>` (User A Token)
  - `Content-Type: application/json`
- **Request Body**:
```json
{
  "hostId": "idc4658315",
  "durationSeconds": 10
}
```

### Revenue Split Calculation:
- **Caller A**: Debited 2 coins/sec (100% total rate).
- **Callee B**: Credited 1 coin/sec (50% recipient earnings as diamonds).
- **Company / Platform**: Retains 1 coin/sec (50% platform fee).

### Success Response (200)
```json
{
  "statusCode": 1,
  "message": "Call charged successfully",
  "data": {
    "success": true,
    "totalCoinsDeducted": 20,
    "hostEarnedDiamonds": 10,
    "agencyEarnedCoins": 10,
    "transactionId": "tx_call_9901"
  }
}
```

---

## 5️⃣ End Call
Calling `POST /api/call/direct/end` automatically calculates call duration and executes call charging if not already charged.

- **Endpoint**: `POST /api/call/direct/end`
- **Headers**:
  - `Authorization: Bearer <JWT_TOKEN>`
  - `Content-Type: application/json`
- **Request Body**:
```json
{
  "callId": "vc_chat_444a2f6f-1a84-4170-ad92-a868caaf6513_idc4658315",
  "reason": "user_hangup"
}
```

---

# 💎 SECTION 3: AUDIO/VIDEO ROOM SESSION EARNINGS & 20% GIFT COMMISSION

## 1️⃣ Get Host Session Earnings
- **Endpoint**: `GET /api/room/session-earnings?room_id=<ROOM_ID>&session_type=audio_room`
- **Headers**: `Authorization: Bearer <JWT_TOKEN>`

### Rules & Calculations:
- **Host Self-Sent Gifts Exclusion**: Any gifts sent by the room's host (`senderId === hostId`) are strictly **excluded** from `sessionCoinsEarned`, `hostSessionCoins`, `sessionDiamondsEarned`, and `giftCount`. Host earnings only include gifts received from other room audience members.
- **20% Platform Fee**: 20% company commission is deducted from all gifts sent in the room. Recipient receives 80% net pool.
- **"Send to All" Gifts**: Sender is excluded from receiving gifts from self. The 80% net pool is divided equally among remaining audience members.

### Success Response (200)
```json
{
  "statusCode": 1,
  "message": "Session earnings fetched successfully",
  "data": {
    "room_id": "60e1115d-0c08-4dce-a8e6-43a82d74c410",
    "host_user_id": "6aae455a-9bc0-41e3-88dc-a0e86fc2c6f7",
    "sessionCoinsEarned": 1200,
    "session_coins_earned": 1200,
    "hostSessionCoins": 1200,
    "host_session_coins": 1200,
    "giftCoinsEarned": 1500,
    "gift_coins_earned": 1500,
    "sessionDiamondsEarned": 1200,
    "session_diamonds_earned": 1200,
    "dollars": 1.2,
    "formattedDollars": "$1.20",
    "giftCount": 3
  }
}
```
