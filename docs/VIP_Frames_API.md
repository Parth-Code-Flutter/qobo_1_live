# VIP Frames API & Socket Documentation

This document explains the mobile implementation for the VIP Frames feature.
The backend handles the automatic activation and deactivation of VIP frames, so mobile developers simply need to call the existing frame purchase API and listen for a new socket event when users join a room.

## 1. Purchasing a VIP Frame
VIP Frames are purchased using the existing Avatar Frame purchase API. The backend automatically detects if the frame's `category` is `"VIP"`. 

- **Endpoint**: `POST /api/frame/buy-frame`
- **Request Body**:
  ```json
  {
    "frame_id": "uuid-of-the-vip-frame"
  }
  ```
- **Backend Behavior**:
  - Automatically deducts coins.
  - Automatically sets the new VIP frame's `isEquipped = true`.
  - Automatically sets all previous VIP frames owned by this user to `isEquipped = false`.
  - The user is **not allowed** to manually equip or unequip VIP frames using the `/api/frame/equip` endpoint. It is fully automated.

## 2. VIP User Joins Room (Socket Event)
When a user successfully joins an audio room, video room, or live stream, the backend automatically checks if they have an active VIP Frame. If they do, the backend emits a real-time Socket.IO event to all users in that room.

- **Event Name**: `vip_user_joined`
- **Payload**:
  ```json
  {
    "event": "vip_user_joined",
    "room_id": "current-room-uuid",
    "user_id": "user-uuid",
    "user_name": "John Doe",
    "avatar": "https://api.qobo1live.com/uploads/profiles/...",
    "vip_frame_url": "https://api.qobo1live.com/uploads/frames/vip_dragon.svga"
  }
  ```
- **Mobile Responsibility**:
  - Listen for the `vip_user_joined` socket event.
  - When this event is received, display an animated VIP Entrance UI over the room (e.g. playing the SVGA frame animation, showing the user's name and avatar entering the room).

## 3. Admin Panel Management
Administrators can add VIP Frames through the **Avatar Frames** section of the Admin Panel. They just need to select **"VIP"** from the Category dropdown and upload the SVGA or image file, along with setting the price and duration. No extra configuration is needed on mobile.
