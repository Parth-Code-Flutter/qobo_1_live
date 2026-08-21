# 1:1 Voice & Video Call Flow & Earning Developer Guide (Mobile App)

**Target Audience:** Mobile Developers (Android / iOS / Flutter)  
**App:** Qobo1live 1-on-1 Voice & Video Calling  
**Status:** Updated & Backend Verified  
**Date:** 2026-08-21  

---

## Executive Summary & Root Causes Resolved

1. **Background Ringing on Accept Fixed**:
   - Previously, accepting a call from a background notification did not immediately stop the local ringtone player, and opening the app sometimes triggered the incoming call UI again.
   - **Fix**: Instructions for immediately stopping local audio players, cancelling notification banners, and routing directly to the active call screen.
2. **Call Disconnect & Unanswered Call Coin Deductions Fixed**:
   - Backend now tracks `connectedAt` strictly when User B accepts the call.
   - If User A disconnects during ringing (or call is cancelled/missed/rejected), **0 coins are charged** and **0 coins are earned**.
   - Duration is calculated strictly from `connectedAt` (excluding ringing time).
   - When User A disconnects an active call, backend deletes the Firestore active call document AND sends a high-priority FCM push notification (`type: 'call_cancelled'`, `reason: 'ended'`) to User B so User B's mobile app immediately terminates ZEGOCLOUD audio/video stream, closes the call UI, and stops duration timers.
3. **Coin Deduction Split Rules**:
   - Total Rate: 2 coins per rate unit (or configured `coinsPerSecond` rate).
   - User A pays: 2 coins.
   - Company gets: 1 coin (50% commission).
   - User B earns: 1 coin (50% host share in diamonds).

---

## 1. Handling Incoming Call & Accept (Background / Foreground)

### A. When Incoming Call Push Notification Arrives
1. Display top notification banner with "Accept" and "Decline" actions.
2. Play local ringing sound using local ringtone player (or CallKit / ConnectionService).

### B. When User Taps "Accept Call" (Notification Banner or Screen)
1. **IMMEDIATELY Stop Ringtone Player**:
   ```dart
   // Flutter Example
   await RingtonePlayer.stop(); // Stop ringing sound immediately
   await flutterLocalNotificationsPlugin.cancel(notificationId); // Dismiss notification banner
   ```
2. **Send Accept Response to Backend**:
   - Endpoint: `POST /api/v1/call/respond` (or `/api/call/direct/respond`)
   - Body:
     ```json
     {
       "callId": "vc_chat_userA_userB",
       "roomId": "chat_userA_userB",
       "action": "accept"
     }
     ```
3. **Direct Navigation**:
   - **DO NOT** display or route to the Incoming Ringing Screen.
   - Route directly to `ActiveCallScreen` / `ZegoCallRoomScreen` with `callId` and `roomId`.

---

## 2. Real-Time Disconnect & Earning Timer Teardown (Callee / User B)

To ensure User B does NOT continue earning coins after User A disconnects:

### A. Firestore Real-Time Listener on Call Screen
Attach a listener to `chatRooms/{roomId}/calls/active`:

```dart
// Flutter / Dart Firestore Listener
StreamSubscription? _callSubscription;

void listenToActiveCall(String roomId) {
  _callSubscription = FirebaseFirestore.instance
      .collection('chatRooms')
      .doc(roomId)
      .collection('calls')
      .doc('active')
      .snapshots()
      .listen((snapshot) {
    if (!snapshot.exists) {
      // Call document deleted -> User A hung up or call ended
      terminateCallSession(reason: "Call ended by caller");
    } else {
      final status = snapshot.data()?['status'];
      if (status == 'ended' || status == 'cancelled' || status == 'rejected') {
        terminateCallSession(reason: "Call $status");
      }
    }
  });
}

void terminateCallSession({required String reason}) {
  _callSubscription?.cancel();
  // 1. Leave ZEGOCLOUD Audio/Video room immediately
  ZegoExpressEngine.instance.logoutRoom();
  // 2. Stop local call duration timer & local charge API calls
  callTimer?.cancel();
  // 3. Pop call screen and return to main screen
  Navigator.of(context).pop();
  showToast("Call ended");
}
```

### B. FCM `call_cancelled` Data-Only Push Handler
In your background / foreground FCM payload listener:

```json
{
  "type": "call_cancelled",
  "event": "call_cancelled",
  "category": "INCOMING_CALL",
  "notification_id": "call_history_uuid",
  "call_id": "vc_chat_123_456",
  "room_id": "chat_123_456",
  "reason": "ended",
  "caller_id": "user_a",
  "callee_id": "user_b"
}
```

- When payload `type == 'call_cancelled'` is received:
  1. Cancel local ringing notification if active.
  2. If on the call screen, trigger `terminateCallSession(reason: payload['reason'])`.

---

## 3. Endpoints Reference

### Start Direct Call (Caller A)
```http
POST /api/v1/call/start
Authorization: Bearer <CALLER_JWT>
Content-Type: application/json

{
  "calleeUserId": "user_b_id",
  "callType": "voice"
}
```

### Respond to Call (Callee B)
```http
POST /api/v1/call/respond
Authorization: Bearer <CALLEE_JWT>
Content-Type: application/json

{
  "callId": "vc_chat_userA_userB",
  "roomId": "chat_userA_userB",
  "action": "accept"
}
```

### End Direct Call (Caller or Callee)
```http
POST /api/v1/call/end
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "callId": "vc_chat_userA_userB",
  "reason": "user_hangup"
}
```
