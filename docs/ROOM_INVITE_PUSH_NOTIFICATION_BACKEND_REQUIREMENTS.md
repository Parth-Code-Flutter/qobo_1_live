# Room Invite Push Notification — Backend Requirements

## Goal

Show **Join** and **Reject** actions on audio/video room push notifications.

The mobile app must support these actions while it is:

- Open in the foreground
- Running in the background
- Fully terminated

## Current Payload

The app currently receives:

```json
{
  "room_id": "e48f83fd-5559-4f31-8df7-c23355de0a52",
  "type": "room_created",
  "host_name": "Yasmin",
  "host_id": "idc6717895",
  "room_type": "audio"
}
```

This identifies a room, but it does not define an invitation, expiration, deduplication ID, or server-side reject behavior.

## Required Backend Decisions

Please confirm:

1. Is this notification a general room-created alert or a direct invitation?
2. Should **Reject** only dismiss the notification locally?
3. If Reject must update the backend, which endpoint and request body should mobile use?
4. Does `POST /api/room/join` return all room and Zego connection details needed to open the room?
5. How long is an invitation valid?
6. Who receives it: all users, followers, friends, or selected users?

For a general broadcast alert, use **Join** and **Dismiss**.  
Use **Join** and **Reject** only for a direct invitation.

## Required FCM Data

All FCM `data` values must be strings.

```json
{
  "type": "room_invite",
  "notification_id": "unique-notification-or-event-id",
  "invitation_id": "unique-invitation-id",
  "room_id": "room-uuid",
  "room_type": "audio",
  "room_title": "Test",
  "host_id": "host-user-id",
  "host_name": "Yasmin",
  "expires_at": "2026-07-15T18:00:00.000Z",
  "zego_call_id": "optional-if-join-api-already-returns-it"
}
```

### Field Requirements

| Field | Required | Purpose |
|---|---:|---|
| `type` | Yes | Must be `room_invite` for actionable invitations |
| `notification_id` | Yes | Deduplicates repeated FCM delivery |
| `invitation_id` | For server-side Reject | Identifies the invitation to accept/reject |
| `room_id` | Yes | Passed to `/api/room/join` |
| `room_type` | Yes | `audio` or `video` |
| `room_title` | Yes | Notification body and loading UI |
| `host_id` | Yes | Identifies the room host |
| `host_name` | Yes | Notification title/body |
| `expires_at` | Yes | Prevents joining expired invitations |
| `zego_call_id` | Conditional | Required only when `/api/room/join` does not return it |

For private rooms, do not send the room password. Send a short-lived, single-use `invite_token` instead.

## Android FCM Requirements

Send a **data-only**, high-priority message. Android system-rendered `notification` messages cannot reliably receive Flutter-defined action buttons in every app state.

Firebase Admin SDK example:

```json
{
  "token": "<device-fcm-token>",
  "data": {
    "type": "room_invite",
    "notification_id": "event-uuid",
    "invitation_id": "invite-uuid",
    "room_id": "room-uuid",
    "room_type": "audio",
    "room_title": "Test",
    "host_id": "host-id",
    "host_name": "Yasmin",
    "expires_at": "2026-07-15T18:00:00.000Z"
  },
  "android": {
    "priority": "high",
    "ttl": 300000
  }
}
```

Do not include the top-level FCM `notification` object for the Android data-only version. The mobile app will render the local notification with `JOIN_ROOM` and `REJECT_ROOM` actions.

## iOS/APNs Requirements

iOS requires a visible alert and the registered action category:

```json
{
  "token": "<device-fcm-token>",
  "notification": {
    "title": "Room Invitation",
    "body": "Yasmin invited you to join \"Test\""
  },
  "data": {
    "type": "room_invite",
    "notification_id": "event-uuid",
    "invitation_id": "invite-uuid",
    "room_id": "room-uuid",
    "room_type": "audio",
    "room_title": "Test",
    "host_id": "host-id",
    "host_name": "Yasmin",
    "expires_at": "2026-07-15T18:00:00.000Z"
  },
  "apns": {
    "headers": {
      "apns-priority": "10"
    },
    "payload": {
      "aps": {
        "category": "ROOM_INVITE",
        "sound": "default"
      }
    }
  }
}
```

The mobile app will register the `ROOM_INVITE` category with `JOIN_ROOM` and `REJECT_ROOM` actions.

## Join Contract

When the user taps Join, mobile will call:

```http
POST /api/room/join
Authorization: Bearer <user-token>
Content-Type: application/json
```

```json
{
  "room_id": "room-uuid",
  "invitation_id": "invite-uuid"
}
```

The success response should include:

- Canonical room ID
- Room type
- Room title/name
- Host details
- Zego call/room ID
- Any Zego token required by the project
- Current room status
- Seat configuration
- Whether the joining user is allowed to enter

The API must reject rooms that are ended, expired, full, blocked, or inaccessible.

## Reject Contract

If Reject is server-side, please provide an endpoint such as:

```http
POST /api/room/invite/respond
Authorization: Bearer <user-token>
Content-Type: application/json
```

```json
{
  "invitation_id": "invite-uuid",
  "room_id": "room-uuid",
  "action": "reject"
}
```

The endpoint must be idempotent. Repeated Reject requests should not produce an error or duplicate side effects.

If Reject only dismisses the notification locally, confirm that no backend request is required.

## Delivery Rules

Backend should:

1. Generate a unique `notification_id`.
2. Generate an `invitation_id` for direct invitations.
3. Avoid notifying the room host about their own room.
4. Avoid sending duplicate active invitations to the same user.
5. Set a short TTL matching `expires_at`.
6. Stop sending notifications after the room ends.
7. Ensure `room_id` matches the ID accepted by `/api/room/join`.
8. Return an idempotent response for Join and Reject.
9. Send `audio`/`video` consistently in lowercase.
10. Provide sample real payloads for both Android and iOS.

## Backend Deliverables

Please share:

- Final Android FCM payload
- Final iOS FCM/APNs payload
- Join API request and complete success/error responses
- Reject behavior and API contract
- Invitation expiration rules
- Recipient targeting rules
- Whether private rooms use `invite_token`
- Confirmation that all `data` values are strings

