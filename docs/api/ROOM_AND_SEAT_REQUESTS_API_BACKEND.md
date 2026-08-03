# Qobo Live — Room & Seat Requests API Updates

This document outlines the API endpoints, socket events, and logic changes introduced for the **Floor Audience** and **Seat Request** mechanics in Audio and Video party rooms.

---

## 1. Core Logic Changes

- **Room Join Bypass:** Users joining `audio` or `video` rooms no longer require `joinApprovalRequired`. They bypass approval and enter the room immediately.
- **Floor Audience:** When a user enters the room but is not seated, they are added to the `floor_audience`. 
  - Sitting down removes them from the floor.
  - Leaving/getting removed from a seat puts them back on the floor.
- **Follower Gate:** A user **must** follow the host to take a seat (`take_seat`, `sit`, `join_seat`). If they don't, the API will return a `FOLLOW_REQUIRED_FOR_SEAT` error code.
- **Room Gifts:** Sending a gift with `scope: "room"` now **only credits seated users**. The sender pays `gift.price * quantity * numberOfSeatedUsers`. The `floor_audience` receives no share.

---

## 2. API Endpoints

### 2.1 Get Room Seats Details
The existing room seats endpoint now returns additional context for the client.

**`GET /api/rooms/seats?roomId=<ROOM_ID>`**

**New Fields in Response:**
- `floor_audience`: Array of users currently in the room but not on a seat.
- `pending_seat_requests`: Array of pending seat requests (Useful for the Host).
- `viewer_follows_host`: `boolean` — `true` if the requesting user follows the host.
- `my_placement`: `string` — Either `"seat"` or `"floor"`.

**Response Example:**
```json
{
  "room_id": "uuid",
  "host_id": "uuid",
  "viewer_follows_host": true,
  "my_placement": "floor",
  "seatConfig": 8,
  "seats": [
    // ... normal seats array
  ],
  "floor_audience": [
    {
      "userId": "uuid",
      "name": "User Name",
      "avatarUrl": "https://...",
      "avatarFrame": null,
      "isVIP": false,
      "vipFrameUrl": null
    }
  ],
  "pending_seat_requests": [
    {
      "id": "req-uuid",
      "seatId": 2,
      "userId": "uuid",
      "name": "Requester Name",
      "avatarUrl": "https://...",
      "createdAt": "2026-08-02T12:00:00Z"
    }
  ]
}
```

---

### 2.2 Create Seat Request (User)
Users can request to be placed on a specific empty seat.

**`POST /api/rooms/seat-request`**

**Request Body:**
```json
{
  "roomId": "uuid",
  "seatId": 2
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "request": {
    "id": "req-uuid",
    "roomId": "uuid",
    "seatId": 2,
    "userId": "uuid",
    "status": "pending"
  }
}
```
*Note: This triggers a `seat_request` socket event to the host.*

---

### 2.3 Respond to Seat Request (Host Only)
The host can approve or reject pending requests.

**`POST /api/rooms/seat-request/respond`**

**Request Body:**
```json
{
  "roomId": "uuid",
  "requestId": "req-uuid",
  "action": "approve" // or "reject"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "action": "approve"
}
```
*Note: If approved, the user is automatically placed on the requested seat. This triggers `seat_request_approved` (or `seat_request_rejected`) to the requesting user.*

---

### 2.4 Cancel Seat Request (User)
A user can cancel their own pending seat request.

**`POST /api/rooms/seat-request/cancel`**

**Request Body:**
```json
{
  "roomId": "uuid",
  "requestId": "req-uuid"
}
```

**Response (200 OK):**
```json
{
  "success": true
}
```
*Note: Triggers `seat_request_cancelled` to the host.*

---

### 2.5 Get Pending Seat Requests (Host Only)
Host can fetch all active seat requests for their room.

**`GET /api/rooms/seat-requests?roomId=<ROOM_ID>`**

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "req-uuid",
      "seatId": 2,
      "userId": "uuid",
      "name": "Requester Name",
      "avatarUrl": "https://...",
      "createdAt": "2026-08-02T12:00:00Z"
    }
  ]
}
```

---

## 3. Real-time Socket Events

### 3.1 Floor Audience Updated
Broadcast to everyone in the room when a user joins the floor, sits down, or leaves entirely.

- **Event Name:** `floor_audience_updated`
- **Payload:**
```json
{
  "room_id": "uuid"
}
```
*Action for Mobile:* Refresh the room seats data (`GET /api/rooms/seats`) to update the floor audience UI.

### 3.2 Seat Request (To Host)
Sent to everyone in the room (primarily for the Host UI to show a popup/badge).

- **Event Name:** `seat_request`
- **Payload:**
```json
{
  "event": "seat_request",
  "room_id": "uuid",
  "request_id": "req-uuid",
  "seatId": 2,
  "userId": "uuid",
  "name": "User Name",
  "avatarUrl": "https://...",
  "createdAt": "2026-08-02T12:00:00Z"
}
```

### 3.3 Seat Request Approved (To Requester)
Direct push to the requesting user when the host approves.

- **Event Name:** `seat_request_approved`
- **Payload:**
```json
{
  "room_id": "uuid",
  "seatId": 2
}
```
*Action for Mobile:* Auto-enable mic / update UI to show they are now seated.

### 3.4 Seat Request Rejected (To Requester)
Direct push to the requesting user when the host rejects.

- **Event Name:** `seat_request_rejected`
- **Payload:**
```json
{
  "room_id": "uuid",
  "seatId": 2
}
```

### 3.5 Seat Request Cancelled (To Host)
Broadcast to room when a user cancels their pending request.

- **Event Name:** `seat_request_cancelled`
- **Payload:**
```json
{
  "room_id": "uuid",
  "request_id": "req-uuid",
  "userId": "uuid"
}
```

### 3.6 Gift Sent (Updated for Room Scope)
When `scope: "room"`, the `gift_sent` event now explicitly tells the client who received the split.

- **Event Name:** `gift_sent`
- **New Payload Fields (when scope="room"):**
```json
{
  "scope": "room",
  "credited_user_ids": ["user-id-1", "user-id-2"],
  "amount_each": 150,
  // ... existing fields
}
```
*Action for Mobile:* Only play receive animations/credit UI for users in `credited_user_ids`.
