# Qobo Audio Room API Requirements

This document describes the backend APIs required for the current Audio Room UI/UX.

The mobile app currently uses Zego for real-time audio, but backend APIs are still required for room lifecycle, seats, moderation, invites, gifts, room sharing, and history.

## Common Requirements

All protected APIs must use:

```http
Authorization: Bearer <token>
Content-Type: application/json
```

Recommended response format:

```json
{
  "statusCode": 1,
  "message": "Success",
  "data": {}
}
```

Recommended error format:

```json
{
  "statusCode": 0,
  "message": "Unable to complete request",
  "error": {
    "code": "ROOM_NOT_FOUND",
    "details": "Room does not exist or already ended"
  }
}
```

## 1. Create Audio Room

`POST /api/rooms`

Creates a new audio room for the host.

Request:

```json
{
  "title": "Test Audio",
  "name": "Test Audio",
  "type": "audio",
  "country": "IN",
  "category": "Just Chat",
  "maxSeats": 16,
  "seatConfig": 16,
  "isPrivate": false,
  "password": null,
  "coverImage": null
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Room created",
  "data": {
    "room_id": "backend-room-id",
    "id": "backend-room-id",
    "zegoLiveId": "zego_audio_room_id",
    "channelName": "zego_audio_room_id",
    "title": "Test Audio",
    "name": "Test Audio",
    "type": "audio",
    "country": "IN",
    "category": "Just Chat",
    "seatConfig": 16,
    "isPrivate": false,
    "status": "active",
    "heatScore": 0,
    "listenerCount": 1,
    "host": {
      "id": "host-user-id",
      "name": "Parth",
      "avatarUrl": "https://example.com/avatar.png"
    },
    "seats": [
      {
        "seatNo": 1,
        "userId": "host-user-id",
        "name": "Parth",
        "avatarUrl": "https://example.com/avatar.png",
        "role": "host",
        "isMuted": false,
        "isLocked": false,
        "diamonds": 28
      }
    ]
  }
}
```

Notes:

- `zegoLiveId` or `channelName` is required for Zego room join.
- `room_id` is required for backend APIs.
- Seat `1` should represent the host.

## 2. List Active Audio Rooms

`GET /api/room/list?type=audio&page=1&limit=20&country=IN&category=Just%20Chat`

Returns audio rooms for the Rooms tab.

Response:

```json
{
  "statusCode": 1,
  "message": "Rooms fetched",
  "data": {
    "rooms": [
      {
        "room_id": "room-id",
        "id": "room-id",
        "title": "Test Audio",
        "name": "Test Audio",
        "type": "audio",
        "country": "IN",
        "category": "Just Chat",
        "seatConfig": 16,
        "listenerCount": 12,
        "heatScore": 73,
        "status": "active",
        "isPrivate": false,
        "zegoLiveId": "zego_audio_room_id",
        "channelName": "zego_audio_room_id",
        "host": {
          "id": "host-id",
          "name": "Parth",
          "avatarUrl": "https://example.com/avatar.png"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "hasMore": true
    }
  }
}
```

## 3. Join Audio Room

`POST /api/room/join`

Request:

```json
{
  "room_id": "room-id",
  "roomId": "room-id",
  "password": "optional"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Joined room",
  "data": {
    "room_id": "room-id",
    "zegoLiveId": "zego_audio_room_id",
    "channelName": "zego_audio_room_id",
    "role": "listener",
    "user": {
      "id": "user-id",
      "name": "Rahul",
      "avatarUrl": "https://example.com/avatar.png"
    },
    "room": {
      "title": "Test Audio",
      "type": "audio",
      "seatConfig": 16,
      "status": "active",
      "host": {
        "id": "host-id",
        "name": "Parth",
        "avatarUrl": "https://example.com/avatar.png"
      },
      "participants": [
        {
          "userId": "host-id",
          "name": "Parth",
          "avatarUrl": "https://example.com/avatar.png",
          "role": "host",
          "seatNo": 1,
          "isMuted": false
        }
      ]
    }
  }
}
```

## 4. Leave Audio Room

`POST /api/room/leave`

Request:

```json
{
  "room_id": "room-id"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Left room",
  "data": {
    "room_id": "room-id",
    "userId": "user-id"
  }
}
```

## 5. End Audio Room

Host only.

`POST /api/room/end`

Request:

```json
{
  "room_id": "room-id"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Room ended",
  "data": {
    "room_id": "room-id",
    "status": "ended"
  }
}
```

## 6. Get Current Room Seats

`GET /api/room/seats?room_id=room-id`

Required for refreshing the custom audio-room stage.

Response:

```json
{
  "statusCode": 1,
  "message": "Seats fetched",
  "data": {
    "room_id": "room-id",
    "seatConfig": 16,
    "seats": [
      {
        "seatNo": 1,
        "userId": "host-id",
        "name": "Parth",
        "avatarUrl": "https://example.com/avatar.png",
        "role": "host",
        "isMuted": false,
        "isLocked": false,
        "diamonds": 28,
        "isAdmin": true
      },
      {
        "seatNo": 2,
        "userId": null,
        "name": null,
        "avatarUrl": null,
        "role": "empty",
        "isMuted": false,
        "isLocked": false,
        "diamonds": 0,
        "isAdmin": false
      },
      {
        "seatNo": 6,
        "userId": "user-id",
        "name": "Rahul",
        "avatarUrl": "https://example.com/avatar.png",
        "role": "speaker",
        "isMuted": false,
        "isLocked": false,
        "diamonds": 23,
        "isAdmin": false
      }
    ]
  }
}
```

## 7. Seat / Mic Actions

`POST /api/room/mic-action`

Used for mute, unmute, lock, unlock, approving speaker, removing from seat.

Request:

```json
{
  "room_id": "room-id",
  "seat_id": 6,
  "target_user_id": "user-id",
  "action": "mute"
}
```

Allowed actions:

- `mute`
- `unmute`
- `lock`
- `unlock`
- `request_to_speak`
- `approve_speaker`
- `remove_from_seat`

Response:

```json
{
  "statusCode": 1,
  "message": "Seat updated",
  "data": {
    "room_id": "room-id",
    "seat": {
      "seatNo": 6,
      "userId": "user-id",
      "isMuted": true,
      "isLocked": false
    }
  }
}
```

## 8. Kick Participant

Host/admin only.

`POST /api/room/kick`

Request:

```json
{
  "room_id": "room-id",
  "target_user_id": "user-id",
  "reason": "Host removed user"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "User removed from room",
  "data": {
    "room_id": "room-id",
    "target_user_id": "user-id"
  }
}
```

## 9. Make / Remove Room Admin

Host only.

`POST /api/room/admin-action`

Request:

```json
{
  "room_id": "room-id",
  "target_user_id": "user-id",
  "action": "make_admin"
}
```

Allowed actions:

- `make_admin`
- `remove_admin`

Response:

```json
{
  "statusCode": 1,
  "message": "Admin updated",
  "data": {
    "room_id": "room-id",
    "target_user_id": "user-id",
    "isAdmin": true
  }
}
```

## 10. Invite Candidates For Empty Seat

When host taps an empty seat, app should show followers who are not already joined.

`GET /api/room/invite-candidates?room_id=room-id&page=1&limit=20&search=rahul`

Backend must exclude:

- users already in the room
- blocked users
- deleted or suspended users

Response:

```json
{
  "statusCode": 1,
  "message": "Invite candidates fetched",
  "data": {
    "users": [
      {
        "id": "user-id",
        "name": "Rahul",
        "avatarUrl": "https://example.com/avatar.png",
        "isOnline": true,
        "isFollower": true,
        "isInRoom": false
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "hasMore": true
    }
  }
}
```

## 11. Invite User To Seat

Host invites a follower to join a specific empty seat.

`POST /api/room/invite`

Request:

```json
{
  "room_id": "room-id",
  "target_user_id": "user-id",
  "seat_id": 2,
  "message": "Parth invited you to join the mic"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Invite sent",
  "data": {
    "invite_id": "invite-id",
    "room_id": "room-id",
    "target_user_id": "user-id",
    "seat_id": 2,
    "status": "pending",
    "expiresAt": "2026-07-07T12:00:00.000Z"
  }
}
```

## 12. Respond To Room Invite

`POST /api/room/invite/respond`

Request:

```json
{
  "invite_id": "invite-id",
  "room_id": "room-id",
  "seat_id": 2,
  "action": "accept"
}
```

Allowed actions:

- `accept`
- `reject`
- `expired`

Response:

```json
{
  "statusCode": 1,
  "message": "Invite accepted",
  "data": {
    "invite_id": "invite-id",
    "room_id": "room-id",
    "seat_id": 2,
    "status": "accepted",
    "seat": {
      "seatNo": 2,
      "userId": "user-id",
      "name": "Rahul",
      "avatarUrl": "https://example.com/avatar.png",
      "role": "speaker",
      "isMuted": false,
      "isLocked": false
    }
  }
}
```

## 13. Gift Catalog

`GET /api/economy/gift-list`

Response:

```json
{
  "statusCode": 1,
  "message": "Gift list fetched",
  "data": [
    {
      "id": "gift-id",
      "name": "Flower",
      "price": 10,
      "icon": "🌸",
      "imageUrl": null,
      "category": "Popular"
    }
  ]
}
```

## 14. Send Gift

`POST /api/transactions/send-gift`

Individual gift payload:

```json
{
  "receiverId": "target-user-id",
  "roomId": "room-id",
  "giftId": "gift-id",
  "quantity": 1,
  "scope": "user"
}
```

Room-wide gift payload:

```json
{
  "receiverId": "host-id",
  "roomId": "room-id",
  "giftId": "gift-id",
  "quantity": 1,
  "scope": "room"
}
```

Response:

```json
{
  "statusCode": 1,
  "message": "Gift sent",
  "data": {
    "transactionId": "txn-id",
    "coinsBalance": 900,
    "scope": "user",
    "gift": {
      "id": "gift-id",
      "name": "Flower",
      "icon": "🌸"
    },
    "receiver": {
      "id": "target-user-id",
      "name": "Rahul"
    }
  }
}
```

## 15. Share Room

`GET /api/room/share?room_id=room-id`

Response:

```json
{
  "statusCode": 1,
  "message": "Share data fetched",
  "data": {
    "room_id": "room-id",
    "shareUrl": "https://qobo.live/room/room-id",
    "title": "Test Audio",
    "description": "Join Test Audio on Qobo"
  }
}
```

## 16. Zego Token

`GET /api/room/zego-token?room_id=room-id`

Response:

```json
{
  "statusCode": 1,
  "message": "Token generated",
  "data": {
    "room_id": "room-id",
    "zegoLiveId": "zego_audio_room_id",
    "token": "zego-token",
    "userId": "user-id",
    "userName": "Rahul",
    "expiresAt": "2026-07-07T12:00:00.000Z"
  }
}
```

## 17. Real-Time Events

Backend/Zego/socket should broadcast room changes to all users in room.

Required events:

- `user_joined`
- `user_left`
- `seat_updated`
- `user_kicked`
- `admin_updated`
- `gift_sent`
- `invite_received`
- `invite_responded`
- `room_ended`

Example:

```json
{
  "event": "seat_updated",
  "room_id": "room-id",
  "seat": {
    "seatNo": 6,
    "userId": "user-id",
    "name": "Rahul",
    "avatarUrl": "https://example.com/avatar.png",
    "isMuted": true,
    "isLocked": false,
    "role": "speaker"
  }
}
```

Gift event:

```json
{
  "event": "gift_sent",
  "room_id": "room-id",
  "scope": "user",
  "sender": {
    "id": "sender-id",
    "name": "Pooja"
  },
  "receiver": {
    "id": "receiver-id",
    "name": "Rahul"
  },
  "gift": {
    "id": "gift-id",
    "name": "Flower",
    "icon": "🌸",
    "quantity": 1
  }
}
```

Invite event:

```json
{
  "event": "invite_received",
  "room_id": "room-id",
  "invite_id": "invite-id",
  "seat_id": 2,
  "from": {
    "id": "host-id",
    "name": "Parth"
  },
  "to": {
    "id": "user-id",
    "name": "Rahul"
  },
  "message": "Parth invited you to join the mic"
}
```

## API Gaps Needed For Full Audio Room Feature

The current app already has partial support for room create/list/join/leave/end, gift list, send gift, kick, share, and zego token.

Backend should add or confirm:

1. `GET /api/room/seats`
2. `GET /api/room/invite-candidates`
3. `POST /api/room/invite`
4. `POST /api/room/invite/respond`
5. `POST /api/room/admin-action`
6. Extend `POST /api/room/mic-action` with `target_user_id`
7. Extend `POST /api/transactions/send-gift` with `scope: "user" | "room"`
8. Real-time room events for seats, invites, gifts, kick, admin, and room end

