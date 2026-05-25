# Qobo One Live — Developer API Handover & Integration Guide

This document catalogs the newly implemented backend capabilities, database schema expansions, WebSocket protocols, and REST API endpoints developed to complete 100% of the screen integrations. Use this guide to coordinate with your mobile, frontend, and backend engineering teams.

---

## 💾 1. Database Schema Extensions (PostgreSQL via Prisma)
The PostgreSQL database has been updated with the following models. All tables are synchronized and generated:

### Social, Backpack & Moderation
- **`Block`**: Handles blocker-blocked relationships for moderation block lists.
- **`BackpackItem`**: Manages virtual items inventory (Patti Styles, Avatar Frames, SVIP Badges, Bubbles) and equipment states.
- **`ProfileVisitor`**: Logs visitor analytics on user profiles (profile visits log).

### Family & Support
- **`Family` & `FamilyMember`**: Supports the Family dashboard, member hierarchies, joining, and search.
- **`HelpTicket`**: Customer service and help ticket logs.

### Events, achievements & Analytics
- **`ActivityEvent`**: Stores details of active events/banners in the activity center.
- **`NoblePackage`**: Renders and stores aristocracy noble packages.
- **`Achievement` & `UserAchievement`**: Maps award achievement badges and daily task reward milestones.
- **`WatchingHistory`**: Keeps a log of recently watched streaming rooms.

---

## ⚡ 2. WebSocket Signal Orchestration (`socketHub.ts`)
Real-time streaming co-host and 1-on-1 private messaging events are fully functional. The socket server handles the following signals:

- **`register_user` (Client Emit)**: Maps a user ID with their socket session ID for direct message delivery.
  - *Payload*: `userId` (string)
- **`join_live_room` (Client Emit)**: Joins the socket.io room for multicast live stream broadcasts.
  - *Payload*: `roomId` (string)
- **`leave_live_room` (Client Emit)**: Leaves the live room channel.
  - *Payload*: `roomId` (string)
- **`audio_stream_signal` (Client Emit / Broadcast)**: Forwards live co-host mic position signals.
  - *Payload*: `{ roomId: string, seatId: number, audioState: any }`
- **`video_stream_signal` (Client Emit / Broadcast)**: Coordinates screen and streaming video bounds.
  - *Payload*: `{ roomId: string, videoState: any }`
- **`send_private_message` (Client Emit)**: Automatically writes message records to PostgreSQL, routes to online receivers, and delivers callback receipts.
  - *Payload*: `{ senderId: string, receiverId: string, content: string, type?: string }`
  - *Receiver Listen Event*: `receive_private_message` -> Returns the saved `Message` object.

---

## 🗺️ 3. REST API Endpoint Reference Catalog

> **Note on Authentication**: All new endpoints require a bearer token passed in the `Authorization` header:
> `Authorization: Bearer <your_jwt_token>`

### Category A: Discover & Live Streaming Rooms

#### 📽️ Video Stream Swiper Feed
- **Endpoint**: `GET /api/room/video-swiper`
- **Description**: Returns all active video streaming rooms (type = video) for the dating-style streamer list.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Video streamer list fetched",
    "data": [
      {
        "id": "room-uuid-1234",
        "title": "Late Night Chat",
        "category": "Bangladesh",
        "type": "video",
        "country": "Bangladesh",
        "seatConfig": 8,
        "isPrivate": false,
        "status": "active"
      }
    ]
  }
  ```

#### 🔑 Agora Broadcast Token Generator
- **Endpoint**: `GET /api/room/agora-token`
- **Description**: Generates secure RTC & RTM token parameters for Zego/Agora host streaming.
- **Query Parameters**:
  - `channel_name` (string, required) — Name of the room channel.
  - `role` (string, required) — `publisher` or `subscriber`.
  - `uid` (number, optional) — Agora numeric user ID.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Agora token generated",
    "data": {
      "token": "bW9ja19hZ29yYV9hcHBfaWRfOTQ0ZmVlODM6bXktY2hhbm5lbDoxMjM0NTY6cHVibGlzaGVy",
      "appId": "mock_agora_app_id_944fee83",
      "channelName": "my-channel",
      "uid": 123456,
      "role": "publisher"
    }
  }
  ```

#### 🚷 Kick Participant from Room
- **Endpoint**: `POST /api/room/kick`
- **Description**: Kicks a participant out of a live audio/video streaming room. Accessible only by the room host.
- **Request Body**:
  ```json
  {
    "room_id": "room-uuid",
    "target_user_id": "user-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "User kicked successfully",
    "data": {
      "success": true,
      "kickedId": "user-uuid",
      "roomId": "room-uuid"
    }
  }
  ```

---

### Category B: 1-on-1 Chat & Messages

#### 📥 Private Conversation Threads List
- **Endpoint**: `GET /api/chat/list`
- **Description**: Returns all private conversation threads for the authenticated user's inbox list. Exposes the last message details, recipient card, and unread counts.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Inbox threads fetched",
    "data": [
      {
        "id": "partner-user-uuid",
        "lastMessage": "Hello there!",
        "lastMessageTime": "2026-05-25T05:12:31.000Z",
        "lastMessageType": "text",
        "unreadCount": 2,
        "recipient": {
          "id": "partner-user-uuid",
          "name": "Jane Doe",
          "displayPicture": "http://localhost:5000/uploads/profiles/jane.png",
          "gender": "female",
          "level": 5
        }
      }
    ]
  }
  ```

#### 💬 1-on-1 Message History
- **Endpoint**: `GET /api/chat/detail`
- **Description**: Fetches message history between two users and automatically marks unread messages as read.
- **Query Parameters**:
  - `target_id` (string, required) — User ID of the chat partner.
  - `page` (number, optional, default: 1) — Pagination page index.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Chat history fetched",
    "data": [
      {
        "id": "message-uuid",
        "senderId": "partner-user-uuid",
        "receiverId": "my-user-uuid",
        "content": "Hello there!",
        "type": "text",
        "isRead": true,
        "createdAt": "2026-05-25T05:12:31.000Z"
      }
    ]
  }
  ```

---

### Category C: User Social, Following & Moderation

#### 👥 Followers & Following Lists
- **Endpoint**: `GET /api/user/follow-list`
- **Description**: Returns complete follower cards and following list cards for any user.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Follow list fetched",
    "data": {
      "followers": [
        {
          "id": "follower-uuid",
          "name": "Alex",
          "displayPicture": "http://localhost:5000/uploads/profiles/alex.png",
          "gender": "male",
          "level": 3
        }
      ],
      "following": []
    }
  }
  ```

#### 🚫 Block User
- **Endpoint**: `POST /api/user/block`
- **Description**: Blocks a user.
- **Request Body**:
  ```json
  {
    "target_id": "user-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "User blocked successfully",
    "data": {
      "id": "block-relationship-uuid",
      "blockerId": "my-user-uuid",
      "blockedId": "user-uuid",
      "createdAt": "2026-05-25T05:13:30.000Z"
    }
  }
  ```

#### 🔓 Unblock User
- **Endpoint**: `POST /api/user/unblock`
- **Description**: Removes a user from the blocker list.
- **Request Body**:
  ```json
  {
    "target_id": "user-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "User unblocked successfully",
    "data": {
      "count": 1
    }
  }
  ```

#### 📝 Block List Screen Feed
- **Endpoint**: `GET /api/user/block-list`
- **Description**: Returns all users currently blocked by the logged-in user.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Block list fetched",
    "data": [
      {
        "id": "blocked-user-uuid",
        "name": "Intruder",
        "displayPicture": "http://localhost:5000/uploads/profiles/intruder.png",
        "gender": "not_specified",
        "level": 1
      }
    ]
  }
  ```

---

### Category D: Economy, VIP Store & Seller Panels

#### 🪙 Official Seller Coin Transfer
- **Endpoint**: `POST /api/economy/seller/transfer`
- **Description**: Exposes coin distribution capabilities for official coin sellers.
- **Request Body**:
  ```json
  {
    "receiver_phone": "+919988776655",
    "amount": 5000
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Coins transferred successfully",
    "data": {
      "success": true,
      "amount": 5000,
      "receiverId": "user-uuid",
      "saleId": "seller-sale-record-uuid"
    }
  }
  ```

#### 👑 VIP Store Packages Catalog
- **Endpoint**: `GET /api/economy/vip-packages`
- **Description**: Returns active VIP packages catalog in store.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "VIP packages fetched",
    "data": [
      {
        "id": "vip-package-uuid",
        "name": "SVIP Monthly Benefit",
        "durationDays": 30,
        "price": 1000,
        "benefits": {
          "roomRibbon": "Golden Patti",
          "badge": "SVIP Badge"
        },
        "status": "active"
      }
    ]
  }
  ```

#### 💳 Purchase VIP Package
- **Endpoint**: `POST /api/economy/buy-vip`
- **Description**: Deducts coins and activates a VIP package. Creates corresponding badges inside the Backpack automatically.
- **Request Body**:
  ```json
  {
    "package_id": "vip-package-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "VIP package purchased successfully",
    "data": {
      "success": true,
      "transactionId": "transaction-uuid",
      "vipLevel": 5
    }
  }
  ```

#### 🛍️ Mall Store Virtual Items Listings
- **Endpoint**: `GET /api/economy/mall`
- **Description**: Lists mall store decorations (Ribbons, Frames, etc.).
- **Query Parameters**:
  - `type` (string, optional) — Filter by type (e.g. `patti`, `frame`).
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Mall items fetched",
    "data": [
      {
        "id": "mall-item-uuid",
        "name": "Dragon Avatar Frame",
        "amount": 1,
        "price": 500,
        "type": "frame",
        "status": "active"
      }
    ]
  }
  ```

#### 💸 Buy Virtual Mall Item
- **Endpoint**: `POST /api/economy/mall/buy`
- **Description**: Deducts coins, completes purchase, and inserts the item in the user's Backpack.
- **Request Body**:
  ```json
  {
    "item_id": "mall-item-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Item purchased successfully",
    "data": {
      "success": true,
      "backpackItem": {
        "id": "backpack-record-uuid",
        "userId": "my-user-uuid",
        "itemType": "AVATAR_FRAME",
        "itemId": "Dragon Avatar Frame",
        "isEquipped": false,
        "expiresAt": "2026-06-24T05:15:56.000Z"
      }
    }
  }
  ```

---

### Category E: Profile Sub-views & Analytics

#### 🎒 Backpack Inventory Feed
- **Endpoint**: `GET /api/user/backpack`
- **Description**: Lists all active decorations, badges, and styles inside the user's backpack.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Backpack inventory fetched",
    "data": [
      {
        "id": "backpack-record-uuid",
        "userId": "my-user-uuid",
        "itemType": "AVATAR_FRAME",
        "itemId": "Dragon Avatar Frame",
        "isEquipped": false,
        "expiresAt": "2026-06-24T05:15:56.000Z"
      }
    ]
  }
  ```

#### ⚡ Equip Backpack Item
- **Endpoint**: `POST /api/user/backpack/equip`
- **Description**: Activates or equips a decoration. If equipping a `PATTI_STYLE`, it seamlessly updates the user's active Patti profile ribbon ribbon style.
- **Request Body**:
  ```json
  {
    "item_id": "backpack-record-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Backpack item status updated",
    "data": {
      "id": "backpack-record-uuid",
      "userId": "my-user-uuid",
      "itemType": "AVATAR_FRAME",
      "itemId": "Dragon Avatar Frame",
      "isEquipped": true
    }
  }
  ```

#### 🏰 Create Family Group
- **Endpoint**: `POST /api/family/create`
- **Description**: Registers a new Family and sets the creator as family owner/leader.
- **Request Body**:
  ```json
  {
    "name": "Superstars Squad",
    "description": "The ultimate team for live broadcasters",
    "logo": "superstars.png"
  }
  ```
- **Response (`201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Family created successfully",
    "data": {
      "family": {
        "id": "family-uuid",
        "name": "Superstars Squad",
        "creatorId": "my-user-uuid"
      },
      "member": {
        "id": "member-relationship-uuid",
        "role": "creator"
      }
    }
  }
  ```

#### 🔍 List/Search Family Groups
- **Endpoint**: `GET /api/family/list`
- **Description**: Lists all active families. Supports filter parameters.
- **Query Parameters**:
  - `query` (string, optional) — Filter families by matching name or description.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Families fetched",
    "data": [
      {
        "id": "family-uuid",
        "name": "Superstars Squad",
        "logo": "superstars.png",
        "_count": {
          "members": 5
        }
      }
    ]
  }
  ```

#### 🤝 Join a Family
- **Endpoint**: `POST /api/family/join`
- **Description**: Registers the user as a standard member of a Family.
- **Request Body**:
  ```json
  {
    "family_id": "family-uuid"
  }
  ```
- **Response (`201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Joined family successfully",
    "data": {
      "id": "member-relationship-uuid",
      "familyId": "family-uuid",
      "userId": "my-user-uuid",
      "role": "member"
    }
  }
  ```

#### 🛡️ Family Dashboard details
- **Endpoint**: `GET /api/family/detail/:id`
- **Description**: Returns comprehensive family details, roster member list cards, and owner details.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Family details fetched",
    "data": {
      "id": "family-uuid",
      "name": "Superstars Squad",
      "members": [
        {
          "id": "member-relationship-uuid",
          "role": "creator",
          "user": {
            "id": "my-user-uuid",
            "name": "Admin",
            "displayPicture": "http://localhost:5000/uploads/profiles/admin_dp.png",
            "level": 10
          }
        }
      ]
    }
  }
  ```

#### 📅 Activity Center Event List
- **Endpoint**: `GET /api/activity/list`
- **Description**: Returns all scheduled and active events/carnivals.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Active events fetched",
    "data": [
      {
        "id": "event-uuid",
        "title": "Summer PK Carnival",
        "description": "Double diamonds on all gifts during battles!",
        "startDate": "2026-06-01T00:00:00.000Z",
        "endDate": "2026-06-07T00:00:00.000Z",
        "status": "active"
      }
    ]
  }
  ```

#### 🤴 Aristocracy noble ranks Catalog
- **Endpoint**: `GET /api/economy/aristocracy/packages`
- **Description**: Returns noble ranks store packages.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Noble ranks fetched",
    "data": [
      {
        "id": "noble-uuid",
        "name": "Viscount",
        "price": 2000,
        "durationDays": 30,
        "status": "active"
      }
    ]
  }
  ```

#### ⚔️ Acquire Nobility Title
- **Endpoint**: `POST /api/economy/aristocracy/buy`
- **Description**: Deducts coins and unlocks noble rank. Inserts noble badges directly in the backpack.
- **Request Body**:
  ```json
  {
    "package_id": "noble-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Noble rank purchased successfully",
    "data": {
      "success": true,
      "backpackItem": {
        "id": "backpack-uuid",
        "itemType": "NOBLE_BADGE",
        "itemId": "Viscount",
        "isEquipped": true
      }
    }
  }
  ```

#### 📋 Daily Task Center Listing
- **Endpoint**: `GET /api/user/tasks`
- **Description**: Lists active daily tasks with the user's completed status.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Daily tasks fetched",
    "data": [
      {
        "id": "task-uuid",
        "title": "Watch a stream for 10 minutes",
        "reward": 50,
        "status": "pending"
      }
    ]
  }
  ```

#### 🎁 Claim Task Point Reward
- **Endpoint**: `POST /api/user/tasks/claim`
- **Description**: Marks task as claimed, rewards user with coins, and updates experience points (XP).
- **Request Body**:
  ```json
  {
    "task_id": "task-uuid"
  }
  ```
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Task reward claimed",
    "data": {
      "success": true,
      "reward": 50
    }
  }
  ```

#### 🎖️ Award Achievements & Badges
- **Endpoint**: `GET /api/user/achievements`
- **Description**: Lists all unlocked achievements and badges for profile display.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Unlocked Achievements fetched",
    "data": [
      {
        "id": "achievement-uuid",
        "name": "First Streamer",
        "description": "Unlock this badge by hosting your first room",
        "badgeIcon": "badge_stream.png",
        "isUnlocked": true,
        "unlockedAt": "2026-05-25T05:14:00.000Z"
      }
    ]
  }
  ```

#### 📺 Broadcast Watched History list
- **Endpoint**: `GET /api/room/watch-history`
- **Description**: Returns user's streaming watch history.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Watch history fetched",
    "data": [
      {
        "id": "watch-history-uuid",
        "roomId": "room-uuid",
        "watchedAt": "2026-05-25T05:15:00.000Z",
        "room": {
          "id": "room-uuid",
          "title": "Main Live Feed",
          "category": "Sab",
          "host": {
            "name": "Broadcaster A"
          }
        }
      }
    ]
  }
  ```

#### 📝 Record Broadcast Watched Action
- **Endpoint**: `POST /api/room/watch-history/record`
- **Description**: Records a watch event whenever a user joins or clicks on a streaming room.
- **Request Body**:
  ```json
  {
    "room_id": "room-uuid"
  }
  ```
- **Response (`201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Watch history recorded",
    "data": {
      "id": "watch-history-uuid",
      "userId": "my-user-uuid",
      "roomId": "room-uuid"
    }
  }
  ```

#### 🎫 Customer Service Ticket Creation
- **Endpoint**: `POST /api/support/ticket`
- **Description**: Creates a customer help ticket.
- **Request Body**:
  ```json
  {
    "subject": "Unable to recharge coins",
    "description": "I tried recharging using Razorpay but my coins were not credited."
  }
  ```
- **Response (`201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Help ticket created successfully",
    "data": {
      "id": "ticket-uuid",
      "userId": "my-user-uuid",
      "subject": "Unable to recharge coins",
      "status": "open"
    }
  }
  ```

#### 📂 Support Ticket History list
- **Endpoint**: `GET /api/support/tickets`
- **Description**: Lists all help tickets submitted by the user.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Support ticket history fetched",
    "data": [
      {
        "id": "ticket-uuid",
        "subject": "Unable to recharge coins",
        "description": "I tried recharging using Razorpay but my coins were not credited.",
        "status": "open",
        "createdAt": "2026-05-25T05:16:11.000Z"
      }
    ]
  }
  ```

#### 👥 Visitors Analytics Feed
- **Endpoint**: `GET /api/user/visitors`
- **Description**: Lists visitors who recently viewed the user's profile card.
- **Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Profile visitors fetched",
    "data": [
      {
        "id": "visit-record-uuid",
        "profileId": "my-user-uuid",
        "visitorId": "visitor-user-uuid",
        "visitedAt": "2026-05-25T05:14:00.000Z",
        "visitor": {
          "id": "visitor-user-uuid",
          "name": "Jane",
          "displayPicture": "http://localhost:5000/uploads/profiles/jane.png",
          "gender": "female",
          "level": 4
        }
      }
    ]
  }
  ```
