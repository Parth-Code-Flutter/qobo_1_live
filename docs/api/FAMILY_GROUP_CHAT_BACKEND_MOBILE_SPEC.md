# Family Group Chat Backend + Mobile Specification

This document defines the new Family module as a group-chat feature for Qobo1Live. It is intended for backend implementation and mobile integration planning.

## Product Scope

Family is a paid or free group community. Any logged-in user can create a Family group, invite or add members, and chat with joined members. There is no group audio call, video call, live stream, or PK battle in this module.

Core roles:

- `admin`: the user who created the group. The admin owns settings, can remove members, and receives all group gift earnings.
- `member`: a user who joined or was added to the group.
- `non_member`: a user who can see discoverable group details and join after paying joining coins.

## Mobile Screens

Mobile will need these screens:

- Family home with two tabs:
  - `My Groups`: groups created by the current user or joined by the current user.
  - `Discover Groups`: groups the current user has not joined.
- Create group form:
  - Group name.
  - Group joining coins.
  - Optional initial members selected from followers and app-wide user search.
- Group chat screen:
  - Realtime messages.
  - Text messages.
  - Emoji messages.
  - Gift messages.
  - Member list / settings entry.
- Group settings:
  - Group details.
  - Member list.
  - Admin-only remove-member action.
  - Leave group for members.

## Economy Rules

- `joiningCoins` is the coin amount a non-member must pay to join a group.
- Backend must validate wallet balance before joining.
- Backend must create an economy transaction for every paid join.
- Recommended rule: joining coins are credited to the group admin wallet. If product wants platform-owned joining fees instead, backend should confirm before implementation.
- All gifts sent inside the group must credit only the group admin, even if the UI visually shows the gift inside the group chat.
- Mobile should never calculate or commit paid actions directly in Firebase. Mobile calls backend APIs; backend performs wallet debit/credit and writes the resulting Firestore message.

## Existing Mobile Context

Current mobile code already has a Family module and some endpoints:

- `POST /api/family/create`
- `GET /api/family/list`
- `GET /api/family/my`
- `GET /api/family/detail/:id`
- `GET /api/family/members/:id`
- `GET /api/family/tree/:id`
- `POST /api/family/join`
- `POST /api/family/leave`

Current mobile also has Firestore direct chat patterns under `chatRooms/{roomId}/messages`, Firebase custom token support, direct gift bottom sheets, emoji catalogs, and wallet APIs. The new Family group chat can reuse those UI patterns but needs new backend authority for group membership, chat writes, and economy.

## Required Backend APIs

### 1. Create Family Group

`POST /api/family/groups`

Request:

```json
{
  "name": "Royal Lions",
  "joiningCoins": 1000,
  "initialMemberIds": ["idc123", "idc456"]
}
```

Backend behavior:

- Validate name length and profanity.
- Validate `joiningCoins >= 0`.
- Create a DB family group record.
- Create Firestore group document.
- Add creator as `admin`.
- Add selected `initialMemberIds` as `member` if allowed.
- Create membership mirror documents for all active members.
- Create a system message like `Royal Lions was created`.

Response:

```json
{
  "statusCode": 1,
  "message": "Family group created",
  "data": {
    "id": "family_uuid",
    "groupId": "family_uuid",
    "name": "Royal Lions",
    "joiningCoins": 1000,
    "adminUserId": "idc_admin",
    "memberCount": 3,
    "isJoined": true,
    "myRole": "admin",
    "firebasePath": "familyGroups/family_uuid",
    "createdAt": "2026-09-02T00:00:00.000Z"
  }
}
```

### 2. My Groups

`GET /api/family/groups/my?page=1&limit=20`

Returns groups where current user has active membership or is admin.

Response:

```json
{
  "statusCode": 1,
  "message": "My family groups fetched",
  "data": {
    "items": [
      {
        "id": "family_uuid",
        "groupId": "family_uuid",
        "name": "Royal Lions",
        "joiningCoins": 1000,
        "adminUserId": "idc_admin",
        "adminName": "Yasmin",
        "adminAvatar": "https://...",
        "memberCount": 24,
        "isJoined": true,
        "myRole": "member",
        "lastMessage": "Hello team",
        "lastMessageAt": "2026-09-02T00:00:00.000Z",
        "unreadCount": 2,
        "firebasePath": "familyGroups/family_uuid"
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 1
  }
}
```

### 3. Discover Groups

`GET /api/family/groups/discover?page=1&limit=20&search=royal`

Returns active groups where current user is not an active member. Search should match group name and optionally admin name.

Response should use the same group item shape as `My Groups`, with `isJoined: false` and `myRole: null`.

### 4. Group Detail

`GET /api/family/groups/:groupId`

Returns group metadata plus current-user membership state.

Required fields:

```json
{
  "id": "family_uuid",
  "groupId": "family_uuid",
  "name": "Royal Lions",
  "joiningCoins": 1000,
  "adminUserId": "idc_admin",
  "adminName": "Yasmin",
  "adminAvatar": "https://...",
  "memberCount": 24,
  "isJoined": true,
  "myRole": "admin",
  "canChat": true,
  "canSendGift": true,
  "canManageMembers": true,
  "firebasePath": "familyGroups/family_uuid"
}
```

### 5. Join Group

`POST /api/family/groups/:groupId/join`

Request:

```json
{
  "clientTransactionId": "join_1788000000000_idc123"
}
```

Backend behavior:

- Validate group exists and is active.
- Validate current user is not already an active member.
- Validate current user is not blocked from the group.
- If `joiningCoins > 0`, debit current user.
- Credit joining coins to admin wallet unless product decides platform-owned joining fees.
- Create transaction rows for payer and receiver/admin.
- Create/update Firestore member document.
- Create/update user membership mirror.
- Increment `memberCount`.
- Add system message.
- Return updated wallet balance.

Failure cases:

- `INSUFFICIENT_COINS`
- `ALREADY_JOINED`
- `GROUP_NOT_FOUND`
- `GROUP_CLOSED`
- `USER_BLOCKED_FROM_GROUP`

### 6. Add Members

`POST /api/family/groups/:groupId/members`

Admin-only endpoint for adding selected users after group creation.

Request:

```json
{
  "userIds": ["idc123", "idc456"]
}
```

Backend behavior:

- Only admin can call.
- Add users as active members.
- Do not charge joining coins for admin-added users unless product decides otherwise.
- Create member docs and user membership mirrors.
- Add system messages.

### 7. Members List

`GET /api/family/groups/:groupId/members?page=1&limit=50&search=jitendra`

Response:

```json
{
  "statusCode": 1,
  "message": "Family members fetched",
  "data": {
    "items": [
      {
        "id": "member_relation_uuid",
        "userId": "idc123",
        "name": "Jitendra",
        "displayPicture": "https://...",
        "avatarFrame": {
          "id": "frame_uuid",
          "image": "https://..."
        },
        "role": "member",
        "status": "active",
        "joinedAt": "2026-09-02T00:00:00.000Z"
      }
    ],
    "page": 1,
    "limit": 50,
    "total": 1
  }
}
```

### 8. Remove Member

`DELETE /api/family/groups/:groupId/members/:userId`

Admin-only endpoint.

Backend behavior:

- Admin cannot remove self from this endpoint.
- Mark member as `removed`.
- Update user membership mirror as `removed`.
- Decrement `memberCount`.
- Add system message.
- Decide whether removed users can rejoin later.

### 9. Leave Group

`POST /api/family/groups/:groupId/leave`

Member endpoint. Admin cannot leave unless ownership is transferred or group is deleted.

### 10. Send Text Message

`POST /api/family/groups/:groupId/messages`

Request:

```json
{
  "type": "text",
  "text": "Hello family",
  "clientMessageId": "msg_1788000000000_idc123"
}
```

Backend behavior:

- Validate sender is active group member.
- Validate message content.
- Write message into Firestore.
- Update group `lastMessage` metadata.
- Update unread counters or membership mirrors if backend owns unread counts.

### 11. Send Emoji Message

`POST /api/family/groups/:groupId/emojis`

Request:

```json
{
  "emojiId": "emoji_uuid",
  "clientMessageId": "emoji_1788000000000_idc123"
}
```

Backend behavior:

- Validate sender is active member.
- Validate emoji exists and is active.
- Write Firestore message with animated media fields, not only thumbnail.

Required emoji message fields:

```json
{
  "type": "emoji",
  "emojiId": "emoji_uuid",
  "emojiName": "Ghost",
  "emojiUrl": "https://.../ghost.gif",
  "emojiAnimationUrl": "https://.../ghost.gif",
  "emojiAnimationType": "gif"
}
```

### 12. Send Group Gift

`POST /api/family/groups/:groupId/gifts`

Request:

```json
{
  "giftId": "gift_uuid",
  "quantity": 1,
  "clientGiftId": "gift_1788000000000_idc123"
}
```

Backend behavior:

- Validate sender is active group member.
- Validate gift exists and is active.
- Debit sender wallet.
- Credit group admin wallet only.
- Create economy transaction records.
- Write Firestore gift message.
- Update group total gift earnings.
- Return updated sender wallet and admin earning summary.

Response:

```json
{
  "statusCode": 1,
  "message": "Gift sent to family",
  "data": {
    "transactionId": "tx_uuid",
    "groupId": "family_uuid",
    "receiverId": "idc_admin",
    "receiverRole": "family_admin",
    "coinsDebited": 100,
    "adminCoinsCredited": 100,
    "senderCoinsBalance": 9900,
    "gift": {
      "id": "gift_uuid",
      "name": "Rose",
      "thumbnailUrl": "https://...",
      "animationUrl": "https://...",
      "animationType": "svga"
    },
    "firestoreMessageId": "message_uuid"
  }
}
```

### 13. Mark Group Read

`POST /api/family/groups/:groupId/read`

Request:

```json
{
  "lastReadMessageId": "message_uuid",
  "lastReadAt": "2026-09-02T00:00:00.000Z"
}
```

Backend or mobile can update read state, but one side should own it consistently.

### 14. Member Search Inputs

Backend should provide or confirm these endpoints:

- `GET /api/user/follow-list?page=1&limit=20&search=ya`
- `GET /api/user/search?query=ya&page=1&limit=20`

Both endpoints should return user id, name, display picture, avatar frame, follow state, and whether the user is already in the target group if `groupId` is supplied.

## Firestore Structure

Backend should use Firebase Admin SDK for authoritative writes. Mobile should listen to Firestore for realtime chat and call REST APIs for create, join, text, emoji, gifts, member removal, and paid actions.

### Group Document

Path:

`familyGroups/{groupId}`

Fields:

```json
{
  "groupId": "family_uuid",
  "name": "Royal Lions",
  "nameLowercase": "royal lions",
  "joiningCoins": 1000,
  "adminUserId": "idc_admin",
  "adminName": "Yasmin",
  "adminAvatar": "https://...",
  "adminAvatarFrameUrl": "https://...",
  "memberCount": 24,
  "status": "active",
  "lastMessage": "Hello family",
  "lastMessageType": "text",
  "lastMessageAt": "serverTimestamp",
  "lastMessageSenderId": "idc123",
  "totalJoinCoins": 12000,
  "totalGiftCoins": 50000,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

### Member Document

Path:

`familyGroups/{groupId}/members/{userId}`

Fields:

```json
{
  "userId": "idc123",
  "name": "Jitendra",
  "displayPicture": "https://...",
  "avatarFrameUrl": "https://...",
  "role": "member",
  "status": "active",
  "joinedAt": "serverTimestamp",
  "removedAt": null,
  "removedBy": null,
  "lastReadAt": "serverTimestamp",
  "mutedUntil": null
}
```

Valid `role` values:

- `admin`
- `member`

Valid `status` values:

- `active`
- `left`
- `removed`
- `blocked`

### Message Document

Path:

`familyGroups/{groupId}/messages/{messageId}`

Fields:

```json
{
  "messageId": "message_uuid",
  "clientMessageId": "msg_1788000000000_idc123",
  "groupId": "family_uuid",
  "type": "text",
  "senderId": "idc123",
  "senderName": "Jitendra",
  "senderAvatar": "https://...",
  "senderAvatarFrameUrl": "https://...",
  "text": "Hello family",
  "emojiId": null,
  "emojiName": null,
  "emojiUrl": null,
  "emojiAnimationUrl": null,
  "giftId": null,
  "giftName": null,
  "giftThumbnailUrl": null,
  "giftAnimationUrl": null,
  "giftCoins": 0,
  "giftQuantity": 0,
  "giftReceiverUserId": null,
  "createdAt": "serverTimestamp",
  "status": "sent"
}
```

Valid `type` values:

- `text`
- `emoji`
- `gift`
- `system`

### User Membership Mirror

Path:

`users/{userId}/familyGroups/{groupId}`

Fields:

```json
{
  "groupId": "family_uuid",
  "name": "Royal Lions",
  "groupAvatar": "https://...",
  "role": "member",
  "status": "active",
  "joinedAt": "serverTimestamp",
  "lastReadAt": "serverTimestamp",
  "lastMessage": "Hello family",
  "lastMessageAt": "serverTimestamp",
  "unreadCount": 0,
  "muted": false,
  "pinned": false
}
```

This mirror helps mobile render `My Groups` quickly and can support unread badges.

## Firestore Security Rules

Recommended rule model:

- Authenticated users can read `familyGroups/{groupId}` only when the group is discoverable or they are active members.
- Authenticated users can read `messages` only when `users/{uid}/familyGroups/{groupId}.status == active`.
- Clients should not create gift messages, emoji messages, member docs, or group docs directly.
- Clients may update only their own read-state mirror if backend approves that approach.
- Backend service account writes all authoritative group, membership, economy, and message data.

Example intent:

```text
allow read messages: if signed in and current user has active membership.
allow create messages: false, because backend writes after REST validation.
allow update own read mirror: if signed in and document id == request.auth.uid.
```

## Mobile Responsibilities

Mobile will:

- Call `My Groups` and `Discover Groups` for the two Family tabs.
- Build group creation UI with name, joining coins, followers picker, and global user search.
- Show coin confirmation before joining a paid group.
- Call backend join API and refresh wallet/group lists on success.
- Open chat only when `canChat == true`.
- Listen to `familyGroups/{groupId}/messages` ordered by `createdAt`.
- Send text, emoji, and gifts through backend REST APIs.
- Render gift/emoji animations from Firestore message media fields.
- Show group settings and member list.
- Show remove-member option only when `myRole == admin`.
- Use existing app toast/snackbar patterns for success and errors.

## Backend Responsibilities

Backend must:

- Own all membership writes.
- Own all paid coin debit/credit logic.
- Own group gift routing so earnings always go to the group admin.
- Write Firestore docs using Firebase Admin SDK after successful API calls.
- Return consistent camelCase keys; snake_case aliases are helpful for older mobile code but should not replace camelCase.
- Include avatar frame fields wherever user avatars are returned.
- Include animated media URLs for emoji and gift messages so mobile can play GIF/SVGA/Lottie instead of static thumbnails.
- Support idempotency using `clientMessageId`, `clientGiftId`, and `clientTransactionId`.

## Edge Cases To Handle

- User has insufficient coins for joining.
- User taps join twice.
- User is removed while chat screen is open.
- User leaves group and then opens old notification.
- Admin tries to remove self.
- Admin account is deleted or suspended.
- Group is closed/deleted while members are chatting.
- Gift is inactive after picker opened.
- Emoji is inactive after picker opened.
- Network retry sends duplicate message or duplicate gift.
- App receives Firestore message before REST response returns.
- Discover list should exclude groups where membership status is `active`; product must decide if `left` users can see and rejoin.

## Backend Confirmations Needed

Please confirm these before final mobile implementation:

- Should `joiningCoins` credit the group admin wallet or platform wallet?
- Can removed users rejoin by paying again?
- Can users leave and rejoin freely?
- What is the maximum group name length?
- What is the maximum joining coin amount?
- What is the maximum group member count?
- Can admins add members after creation without charging joining coins?
- Do groups need privacy modes, or are all groups public in Discover?
- Should group admin ownership transfer be supported?
- Should group chat support message delete/report/mute in this release?

## Suggested Migration Path

1. Keep old Family ranking/tree APIs working during rollout.
2. Add new `/api/family/groups/*` endpoints for the group-chat feature.
3. Backend writes Firestore documents for new groups and messages.
4. Mobile builds the new tabbed Family UI using the new APIs.
5. Once stable, old `/api/family/my`, `/api/family/list`, and `/api/family/tree/:id` can either become compatibility wrappers or remain for ranking features.
