# Mobile Developer Guide: Call Notifications & Background Call Handling

## Root Cause Identified & Backend Fix Applied
1. **Duplicate Notifications Bug**:
   - Previously, when a user started a 1:1 call, the backend API (`POST /api/v1/call/start`) sent an FCM push notification directly AND the Firestore `userIncomingCalls` listener fired a duplicate FCM notification.
   - **Backend Fix Applied**: Added `fcmSent: true` flag check to deduplicate FCM push triggers so only **1 high-priority incoming call notification** is dispatched per call.

---

## Mobile Developer Instructions (Flutter / Native Android & iOS)

To ensure smooth handling when a call comes while the app is in the background or killed, follow these rules in the mobile application code:

### 1. Push Notification Deduplication (Android & iOS)
- Ensure your local notification manager uses `notification_id` or `call_id` as the **tag / notification ID**:
  ```dart
  // Example in Flutter:
  final int notificationId = payload['notification_id'].hashCode;
  flutterLocalNotificationsPlugin.show(
    notificationId, // Uses hash of notification_id so duplicate FCM updates replace the banner
    title,
    body,
    notificationDetails,
  );
  ```
- When a `type: 'call_cancelled'` or `type: 'call_missed'` FCM push arrives, dismiss the notification using:
  ```dart
  flutterLocalNotificationsPlugin.cancel(notificationId);
  ```

### 2. Accepting Call from Background / System Notification
When the user taps **"Accept Call"** from the top notification banner or lock screen:
1. **Call Accept API**:
   - Immediately call `POST /api/v1/call/respond` (Qobo: `POST /api/call/direct/respond`):
     ```json
     {
       "callId": "vc_chat_userA_userB",
       "action": "accept"
     }
     ```
2. **Direct Navigation**:
   - Navigate the app directly to the **Active Call / ZEGOCLOUD Room Screen**.
   - **DO NOT** push or display the "Incoming Call / Ringing Screen" again when opening the app from an Accept tap.
   - **DO NOT** trigger `POST /api/v1/call/start` when answering/accepting a call (only the caller triggers `start`).

### 3. Handling Firebase Messaging `onMessageOpenedApp` & `getInitialMessage`
- When opening the app from a notification tap, inspect `message.data`:
  ```dart
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['type'] == 'incoming_call' || message.data['category'] == 'INCOMING_CALL') {
      final String callId = message.data['call_id'] ?? message.data['callId'];
      final String roomId = message.data['room_id'] ?? message.data['roomId'];
      
      if (userPressedAccept) {
        // 1. Respond accept to backend
        CallApi.respondCall(callId: callId, action: 'accept');
        // 2. Navigate straight to call room
        Navigator.pushNamed(context, '/call_room', arguments: {'callId': callId, 'roomId': roomId});
      }
    }
  });
  ```

### 4. FCM Payload Reference Sent by Backend
```json
{
  "type": "incoming_call",
  "event": "incoming_call",
  "category": "INCOMING_CALL",
  "notification_id": "call_history_uuid",
  "call_id": "vc_chat_123_456",
  "room_id": "chat_123_456",
  "caller_id": "user123",
  "caller_name": "John Doe",
  "caller_avatar": "https://.../avatar.jpg",
  "callee_id": "user456",
  "call_type": "voice",
  "zego_call_id": "vc_chat_123_456",
  "expires_at": "2026-08-21T00:15:00.000Z"
}
```

---

## Qobo mobile implementation notes (pk-battle)

| Scenario | Behavior |
|----------|----------|
| Foreground ring | In-app WhatsApp-style UI only (no local Accept/Reject tray) |
| Background / killed | `flutter_callkit_incoming` full-screen ring |
| Open app while CallKit is ringing | Keep CallKit; **do not** open a second in-app ring (Firestore + FCM tap suppressed via `activeCalls`) |
| Accept from CallKit | `POST /api/call/direct/respond` + navigate to Zego room — no ringing screen |
| Body-tap notification (no Accept) | Do not re-show ringing if CallKit already owns the call |
| Cancel / miss | Cancel by `notification_id` / `call_id` + end CallKit + dismiss in-app |
