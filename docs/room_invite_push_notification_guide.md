# Room Invite Push Notifications — Mobile Integration Guide

This document defines the backend contract and mobile requirements for actionable **Room Invite Push Notifications** (supporting both Join and Reject behaviors).

---

## **Required Backend Decisions & System Design**

### **1. Invitation Nature & Flow**
* **Direct Invitations (`type: "room_invite"`)**: These are targeted direct invitations to specific users, which carry an `invitation_id` and allow the user to **Join** (calls join API) or **Reject** (notifies the server to mark it rejected).
* **General Broadcast Alerts (`type: "room_created"`)**: Sent when a followed host starts streaming. These only support **Join** and **Dismiss** (purely local client dismiss).

### **2. Expiration Rules**
* Every `room_invite` is valid for exactly **5 minutes** from the moment of dispatch. 
* The expiration time is calculated on the server and sent inside the `expires_at` property as an ISO-8601 string. The mobile app must block join actions if current time exceeds `expires_at`.

### **3. Private Rooms & Tokens**
* For private rooms, the invitation acts as a bypass pass. The backend automatically associates the invitation record with permission to enter, eliminating the need to transmit raw private room passwords over FCM.

### **4. FCM Data Values**
* **IMPORTANT**: All key-value pairs inside the FCM `data` block are guaranteed to be serialized as string types.

---

## **FCM Push Payloads**

### **1. Android Payload (Data-only, High Priority)**
Android notifications are dispatched as **data-only** messages to allow the Flutter/native app to wake up in any state (terminated, background, or foreground) and build a custom local notification containing custom action buttons.

```json
{
  "token": "<device-fcm-token>",
  "data": {
    "type": "room_invite",
    "notification_id": "notif_7f8a9e0b1c2d3e4f",
    "invitation_id": "cfc56941-6a51-44f3-bc8f-3c265f436e72",
    "room_id": "e48f83fd-5559-4f31-8df7-c23355de0a52",
    "room_type": "audio",
    "room_title": "Yasmin's Lounge",
    "host_id": "idc6717895",
    "host_name": "Yasmin",
    "expires_at": "2026-07-16T18:05:00.000Z"
  },
  "android": {
    "priority": "high",
    "ttl": 300000
  }
}
```

### **2. iOS/APNs Payload (Visual Alert + Category)**
iOS messages include a top-level alert body for OS rendering and specify the `aps.category` as `ROOM_INVITE` so the system registers the preset Join and Reject actions.

```json
{
  "token": "<device-fcm-token>",
  "notification": {
    "title": "Room Invitation",
    "body": "Yasmin invited you to join \"Yasmin's Lounge\""
  },
  "data": {
    "type": "room_invite",
    "notification_id": "notif_7f8a9e0b1c2d3e4f",
    "invitation_id": "cfc56941-6a51-44f3-bc8f-3c265f436e72",
    "room_id": "e48f83fd-5559-4f31-8df7-c23355de0a52",
    "room_type": "audio",
    "room_title": "Yasmin's Lounge",
    "host_id": "idc6717895",
    "host_name": "Yasmin",
    "expires_at": "2026-07-16T18:05:00.000Z"
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

---

## **API Contracts (Join / Reject)**

### **1. Join Room Endpoint**
Called when the user clicks the "Join" action button or clicks the notification.

* **Endpoint**: `POST /api/room/join`
* **Headers**: `Authorization: Bearer <user-token>`, `Content-Type: application/json`
* **Request Body**:
  ```json
  {
    "room_id": "e48f83fd-5559-4f31-8df7-c23355de0a52",
    "invitation_id": "cfc56941-6a51-44f3-bc8f-3c265f436e72"
  }
  ```
* **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Joined room",
    "data": {
      "room_id": "e48f83fd-5559-4f31-8df7-c23355de0a52",
      "zegoLiveId": "live_e48f83fd55594f318df_1784093198",
      "channelName": "live_e48f83fd55594f318df_1784093198",
      "room": {
        "id": "e48f83fd-5559-4f31-8df7-c23355de0a52",
        "title": "Yasmin's Lounge",
        "type": "audio",
        "status": "active",
        "hostId": "idc6717895",
        "hostName": "Yasmin",
        "coverImage": "https://res.cloudinary.com/.../cover.png",
        "zegoStreaming": {
          "token": "generated-zego-token-string",
          "appId": 12345678,
          "serverSecret": "secret-credentials-key"
        },
        "seats": [
          {
            "seatNo": 1,
            "userId": "idc6717895",
            "name": "Yasmin",
            "role": "host",
            "isMuted": false,
            "isLocked": false
          }
        ]
      },
      "seatId": 2,
      "userId": "joining-user-uuid"
    }
  }
  ```
* **Error Response (`400 Bad Request`)**:
  ```json
  {
    "success": false,
    "error": "This invitation has expired"
  }
  ```

---

### **2. Reject Invitation Endpoint**
Called when the user clicks the "Reject" action button.

* **Endpoint**: `POST /api/room/invite/respond`
* **Headers**: `Authorization: Bearer <user-token>`, `Content-Type: application/json`
* **Request Body**:
  ```json
  {
    "invitation_id": "cfc56941-6a51-44f3-bc8f-3c265f436e72",
    "action": "reject"
  }
  ```
* **Success Response (`200 OK`)**:
  ```json
  {
    "statusCode": 1,
    "message": "Invite response processed",
    "data": {
      "invite_id": "cfc56941-6a51-44f3-bc8f-3c265f436e72",
      "room_id": "e48f83fd-5559-4f31-8df7-c23355de0a52",
      "seat_id": 2,
      "status": "rejected",
      "seat": null
    }
  }
  ```
