# Audio Room Gift Animation Real-Time Flow

## Goal

When a user sends a gift inside an audio room, the gift should appear in real time for users in the room.

There are two gift cases:

1. Send gift to everyone in the room
2. Send gift to one specific user/seat

The API should handle wallet deduction and transaction creation. Real-time broadcast should handle animation playback on connected clients.

## Recommended Flow

1. User selects a gift in the room.
2. App calls existing API:

```http
POST /api/transactions/send-gift
```

3. Backend validates wallet balance, room membership, gift availability, receiver, and quantity.
4. Backend deducts coins and creates transaction.
5. Backend broadcasts a real-time `gift_sent` event to room users.
6. Mobile app receives the event and plays the gift animation.

## Existing API To Reuse

```http
POST /api/transactions/send-gift
```

### Suggested Request Body

```json
{
  "roomId": "room_uuid",
  "giftId": "gift_uuid",
  "receiverId": "user_uuid_optional",
  "quantity": 1,
  "scope": "room",
  "clientGiftId": "unique_client_generated_uuid"
}
```

### Field Notes

`scope`:

- `room` means gift is sent to everyone in the room.
- `user` means gift is sent to a specific person.

`receiverId`:

- Required when `scope = user`
- Optional or null when `scope = room`

`clientGiftId`:

- Used for duplicate protection.
- If app retries because of network issue, backend should not deduct coins twice for the same `clientGiftId`.

## Suggested Success Response

```json
{
  "statusCode": 1,
  "message": "Gift sent successfully",
  "data": {
    "transactionId": "transaction_uuid",
    "roomId": "room_uuid",
    "scope": "room",
    "quantity": 1,
    "coinsBalance": 199734,
    "sender": {
      "id": "sender_user_id",
      "name": "Parth",
      "avatar": "https://..."
    },
    "receiver": null,
    "gift": {
      "id": "gift_uuid",
      "name": "Tree Love",
      "price": 100,
      "thumbnailUrl": "https://...",
      "animationUrl": "https://.../tree-love.svga",
      "animationType": "svga"
    },
    "createdAt": "2026-07-14T10:00:00.000Z"
  }
}
```

For user-specific gift:

```json
{
  "statusCode": 1,
  "message": "Gift sent successfully",
  "data": {
    "transactionId": "transaction_uuid",
    "roomId": "room_uuid",
    "scope": "user",
    "quantity": 1,
    "coinsBalance": 199734,
    "sender": {
      "id": "sender_user_id",
      "name": "Parth",
      "avatar": "https://..."
    },
    "receiver": {
      "id": "receiver_user_id",
      "name": "Rahul",
      "seatNo": 6,
      "avatar": "https://..."
    },
    "gift": {
      "id": "gift_uuid",
      "name": "Tree Love",
      "price": 100,
      "thumbnailUrl": "https://...",
      "animationUrl": "https://.../tree-love.svga",
      "animationType": "svga"
    },
    "createdAt": "2026-07-14T10:00:00.000Z"
  }
}
```

## Real-Time Event Needed

After successful gift transaction, backend should emit this event to the room.

Event name:

```text
gift_sent
```

### For Gift To Everyone

Broadcast to all users currently joined in the room.

```json
{
  "event": "gift_sent",
  "roomId": "room_uuid",
  "scope": "room",
  "transactionId": "transaction_uuid",
  "sender": {
    "id": "sender_user_id",
    "name": "Parth",
    "avatar": "https://..."
  },
  "receiver": null,
  "gift": {
    "id": "gift_uuid",
    "name": "Tree Love",
    "thumbnailUrl": "https://...",
    "animationUrl": "https://.../tree-love.svga",
    "animationType": "svga"
  },
  "quantity": 1,
  "createdAt": "2026-07-14T10:00:00.000Z"
}
```

### For Gift To Specific User

Broadcast to all users in the room, but include receiver details.

```json
{
  "event": "gift_sent",
  "roomId": "room_uuid",
  "scope": "user",
  "transactionId": "transaction_uuid",
  "sender": {
    "id": "sender_user_id",
    "name": "Parth",
    "avatar": "https://..."
  },
  "receiver": {
    "id": "receiver_user_id",
    "name": "Rahul",
    "seatNo": 6,
    "avatar": "https://..."
  },
  "gift": {
    "id": "gift_uuid",
    "name": "Tree Love",
    "thumbnailUrl": "https://...",
    "animationUrl": "https://.../tree-love.svga",
    "animationType": "svga"
  },
  "quantity": 1,
  "createdAt": "2026-07-14T10:00:00.000Z"
}
```

## Client UI Behavior

### If `scope = room`

All users in the room should:

- Play the gift animation full-screen for 2-3 seconds.
- Show activity text: `Parth sent Tree Love to everyone`
- Optionally show a small gift trail/badge near bottom chat feed.

### If `scope = user`

Recommended behavior:

- All users see the gift event in room activity feed.
- Full-screen animation can play for premium gifts.
- Receiver seat should be highlighted with glow/burst/ring for 2-3 seconds.
- Activity text: `Parth sent Tree Love to Rahul`

If backend/client wants private animation only:

- Emit event only to sender and receiver.
- For live/audio room apps, public room broadcast is recommended because gifts are social engagement moments.

## Real-Time Transport Options

Preferred:

1. Existing room socket
2. Zego custom command/message
3. Any existing WebSocket room channel

Do not rely only on REST API response for room-wide animation. REST response only reaches the sender. Other users need real-time delivery.

## Scale Requirements

Gift sending can happen frequently at scale, so backend should support:

1. Idempotency with `clientGiftId`
2. Wallet transaction locking
3. Duplicate request prevention
4. Per-user rate limit/throttle
5. Room membership validation
6. Receiver validation
7. Gift status validation
8. Efficient room broadcast
9. Lightweight event payload
10. CDN-hosted animation files

## Backend Validation Checklist

Before deducting coins:

- Sender token is valid
- Sender is currently in the room
- Room exists and is active
- Gift exists and is active
- Quantity is valid
- Sender has enough coins
- If `scope = user`, receiver exists and is currently in the room
- If `scope = room`, receiver can be null
- `clientGiftId` has not already been processed

## Gift Asset Requirements

Each gift should include:

```json
{
  "id": "gift_uuid",
  "name": "Tree Love",
  "price": 100,
  "thumbnailUrl": "https://cdn.../tree-love.png",
  "animationUrl": "https://cdn.../tree-love.svga",
  "animationType": "svga",
  "category": "animated",
  "status": "active"
}
```

Supported animation types can be:

- `svga`
- `lottie`
- `gif`
- `image`

For now, app is using SVGA animations.

## Frontend Queue Recommendation

Mobile app should not play unlimited animations at once.

Recommended queue:

- Play one full-screen animation at a time.
- Each animation max 2-3 seconds.
- If multiple gifts arrive, queue them.
- If too many gifts arrive quickly, collapse normal gifts into activity feed and only play premium gifts full-screen.
- Always show transaction/activity feed entry.

## Final Recommendation

Keep existing API:

```http
POST /api/transactions/send-gift
```

Add real-time broadcast after successful transaction:

```text
gift_sent
```

This gives best reliability and scale:

- API handles wallet and transaction.
- Socket/Zego event handles real-time room animation.
- Client plays animation for everyone or highlights receiver based on `scope`.
