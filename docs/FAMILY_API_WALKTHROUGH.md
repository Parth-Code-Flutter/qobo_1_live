# Walkthrough - Family APIs Implementation & Mobile Specification

Verified and implemented the requested **Family APIs** backend functionality, ensuring zero breaking changes to existing endpoints.

## Key Changes Made

### 1. Database Schema (`FamilyMember`)
- Added optional `parentId String?` field to `FamilyMember` model in [schema.prisma](file:///d:/My-Freelanching-Work/Qobo1live/backend/prisma/schema.prisma) to support sponsor / referral tree tracking.

### 2. Family Gift Sending (`/api/v1/economy/send-gift` & `/api/economy/send-gift`)
- Updated `EconomyController` and `EconomyService`:
  - Accepts `roomId = familyId` with `sessionType: family` / `session_type: family` / `scope: family`.
  - Safely handles family session contexts without failing on audio streaming room checks.
  - Automatically identifies fallback receiver (family creator or member list).
  - Emits real-time `gift_sent` event to the family socket room channel (`roomId`).

### 3. Member Roster (`/api/v1/family/detail/:id` & `/api/v1/family/members/:id`)
- Enhanced `getFamilyDetail` and added `getFamilyMembers` in `FamilyController`:
  - Every member object in the roster array includes explicit `userId`, `user_id`, and `user` object with `id`, `userId`, `user_id`, `name`, `displayPicture`, `avatar`, `level`, `role`, `bio`, `coins`, `diamonds`.
  - Ensures mobile app can directly read `user.id` or `userId` for sending Gifts and DMs.

### 4. Role-Based Tree & Sponsor Tree (`/api/v1/family/tree/:id`)
- Added `getFamilyTree` endpoint in `FamilyController`:
  - Returns `role_tree` hierarchy (`creator`, `coLeaders`, `members`).
  - Returns `sponsor_tree` array prepared with `parentId` nodes for upcoming sponsor tree feature.

---

## Verification & Testing
- Ran `npx prisma db push`: Schema updated successfully.
- Ran `npx tsc --noEmit`: Code compiled with zero TypeScript errors.
- Executed `test-family-apis.ts`: Verified real-time transaction processing, coin deduction, diamond crediting, and response payload formatting for family gift sending.

---

# 📱 Mobile Developer API Specification (Family Module)

Below is the complete API documentation to share with the Mobile Developer:

---

### 1. Send Family Gift
**Endpoint:** `POST /api/v1/economy/send-gift` (or `/api/economy/send-gift`)  
**Headers:** `Authorization: Bearer <TOKEN>`  
**Request Body:**
```json
{
  "roomId": "family-uuid-12345",
  "giftId": "gift-uuid-67890",
  "receiverId": "target-user-uuid-999",
  "sessionType": "family",
  "quantity": 1,
  "clientGiftId": "unique-client-tx-uuid-001"
}
```
*Note:* Both camelCase (`roomId`, `giftId`, `receiverId`, `sessionType`, `clientGiftId`) and snake_case (`room_id`, `gift_id`, `receiver_id`, `session_type`, `client_gift_id`) are accepted.

**Success Response (200 OK):**
```json
{
  "statusCode": 1,
  "message": "Gift sent successfully",
  "data": {
    "transactionId": "tx-uuid-123",
    "roomId": "family-uuid-12345",
    "scope": "family",
    "quantity": 1,
    "coinsBalance": 950.0,
    "sender": {
      "id": "sender-user-uuid",
      "name": "Sender Name",
      "avatar": "http://domain/uploads/profiles/avatar.png"
    },
    "receiver": {
      "id": "target-user-uuid-999",
      "name": "Receiver Name",
      "avatar": "http://domain/uploads/profiles/receiver.png"
    },
    "gift": {
      "id": "gift-uuid-67890",
      "name": "Rose",
      "price": 10.0,
      "thumbnailUrl": "http://domain/uploads/icons/rose.png",
      "animationUrl": "http://domain/uploads/animations/rose.svga",
      "animationType": "svga"
    },
    "createdAt": "2026-08-07T15:40:00.000Z"
  }
}
```

---

### 2. Get Family Member Roster (For Gifts & DM)
**Endpoint:** `GET /api/v1/family/members/:id` (or `/api/family/members/:id`)  
**Headers:** `Authorization: Bearer <TOKEN>`  

**Success Response (200 OK):**
```json
{
  "statusCode": 1,
  "message": "Family member roster fetched",
  "data": [
    {
      "id": "member-relation-id-1",
      "familyId": "family-uuid-12345",
      "userId": "user-uuid-101",
      "user_id": "user-uuid-101",
      "parentId": null,
      "parent_id": null,
      "role": "creator",
      "joinedAt": "2026-08-01T10:00:00.000Z",
      "user": {
        "id": "user-uuid-101",
        "userId": "user-uuid-101",
        "user_id": "user-uuid-101",
        "name": "Leader Name",
        "displayPicture": "http://domain/uploads/profiles/leader.png",
        "avatar": "http://domain/uploads/profiles/leader.png",
        "level": 15,
        "role": "user",
        "bio": "Family Creator",
        "coins": 5000,
        "diamonds": 1200
      }
    },
    {
      "id": "member-relation-id-2",
      "familyId": "family-uuid-12345",
      "userId": "user-uuid-102",
      "user_id": "user-uuid-102",
      "parentId": "user-uuid-101",
      "parent_id": "user-uuid-101",
      "role": "member",
      "joinedAt": "2026-08-02T12:00:00.000Z",
      "user": {
        "id": "user-uuid-102",
        "userId": "user-uuid-102",
        "user_id": "user-uuid-102",
        "name": "Member Name",
        "displayPicture": "http://domain/uploads/profiles/member.png",
        "avatar": "http://domain/uploads/profiles/member.png",
        "level": 3,
        "role": "user",
        "bio": "Family Member",
        "coins": 200,
        "diamonds": 50
      }
    }
  ]
}
```

---

### 3. Get Family Details & Role-Based Tree
**Endpoint:** `GET /api/v1/family/detail/:id` (or `/api/family/detail/:id`)  
**Headers:** `Authorization: Bearer <TOKEN>`  

**Success Response (200 OK):**
```json
{
  "statusCode": 1,
  "message": "Family details fetched",
  "data": {
    "id": "family-uuid-12345",
    "name": "Royal Lions",
    "description": "Welcome to Royal Lions",
    "logo": "http://domain/uploads/logos/default_family.png",
    "creatorId": "user-uuid-101",
    "membersCount": 2,
    "members": [ /* Full roster array as shown above */ ],
    "role_tree": {
      "creator": { /* Creator member object */ },
      "coLeaders": [ /* Co-leader member objects */ ],
      "members": [ /* General member objects */ ]
    },
    "sponsor_tree": [
      {
        "id": "member-relation-id-2",
        "userId": "user-uuid-102",
        "user_id": "user-uuid-102",
        "name": "Member Name",
        "role": "member",
        "parentId": "user-uuid-101",
        "parent_id": "user-uuid-101",
        "user": { /* User details */ }
      }
    ]
  }
}
```

---

### 4. Get Family Tree (Dedicated Endpoint)
**Endpoint:** `GET /api/v1/family/tree/:id` (or `/api/family/tree/:id`)  
**Headers:** `Authorization: Bearer <TOKEN>`  

**Success Response (200 OK):**
```json
{
  "statusCode": 1,
  "message": "Family tree fetched successfully",
  "data": {
    "familyId": "family-uuid-12345",
    "familyName": "Royal Lions",
    "treeType": "role_based",
    "role_tree": {
      "creator": { /* Creator object */ },
      "coLeaders": [ /* Array of co-leaders */ ],
      "members": [ /* Array of members */ ]
    },
    "sponsor_tree": [ /* Roster with parentId nodes */ ]
  }
}
```

---

### 5. Socket Event (Real-Time Family Gift Notification)
**Socket Room Channel to Join:** Socket event `join_live_room` with `familyId` (e.g. `socket.emit('join_live_room', familyId)`)  
**Broadcast Event Name:** `gift_sent`  
**Payload Received by Socket Clients:**
```json
{
  "event": "gift_sent",
  "roomId": "family-uuid-12345",
  "scope": "family",
  "transactionId": "tx-uuid-123",
  "sender": {
    "id": "sender-user-uuid",
    "name": "Sender Name",
    "avatar": "http://domain/uploads/profiles/avatar.png"
  },
  "receiver": {
    "id": "target-user-uuid-999",
    "name": "Receiver Name",
    "seatNo": null,
    "avatar": "http://domain/uploads/profiles/receiver.png"
  },
  "gift": {
    "id": "gift-uuid-67890",
    "name": "Rose",
    "thumbnailUrl": "http://domain/uploads/icons/rose.png",
    "animationUrl": "http://domain/uploads/animations/rose.svga",
    "animationType": "svga"
  },
  "quantity": 1,
  "createdAt": "2026-08-07T15:40:00.000Z"
}
```
