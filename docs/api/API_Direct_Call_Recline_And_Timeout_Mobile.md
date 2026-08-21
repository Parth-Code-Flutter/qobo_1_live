# 1:1 Voice/Video Call — Caller UI Close When Callee Declines (Mobile Developer Guide)

**Target Audience:** Mobile Developers (iOS / Android / Flutter)  
**App:** qobo_one_live (1:1 Direct Voice & Video Calls)  
**Status:** Implemented & Verified  
**Date:** 2026-08-21  

---

## 1. Summary of Backend & Firestore Updates

When Callee (User B) declines a 1:1 voice or video call:
1. **Firestore Active Document Cleared**: `chatRooms/{roomId}/calls/active` and `userIncomingCalls/{calleeUserId}` are deleted via Firebase Admin SDK.
2. **Caller FCM Push Notification**: High-priority data-only FCM push notification (`type: "call_cancelled"`, `reason: "rejected"`) is dispatched directly to **Caller A**.
3. **Firestore Security Rules**: Security rules for `chatRooms/{roomId}/calls/{callDoc}` and `userIncomingCalls/{userId}` allow authenticated callers & callees to read and write ring status.
4. **45s Ring Timeout Worker**: Server automatically cleans up unanswered ringing calls after 45 seconds, sets history to `missed`, and sends data-only FCM `call_cancelled` (`reason: "missed"`) to both caller and callee.

---

## 2. Updated Firestore Security Rules

Publish these updated rules to Firebase Console $\rightarrow$ **Firestore Database** $\rightarrow$ **Rules**:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isMember(roomId) {
      return request.auth != null
        && request.auth.uid in get(/databases/$(database)/documents/chatRooms/$(roomId)).data.memberIds;
    }

    match /chatRooms/{roomId} {
      allow read: if isMember(roomId) || request.auth != null;
      allow create, update: if false; // Admin SDK only

      match /messages/{messageId} {
        allow read: if isMember(roomId);
        allow create: if isMember(roomId)
          && request.resource.data.senderId == request.auth.uid;
        allow update: if isMember(roomId);
      }

      match /typing/{userId} {
        allow read: if isMember(roomId);
        allow write: if request.auth.uid == userId && isMember(roomId);
      }

      // Active 1:1 call ring state document rule
      match /calls/{callDoc} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }

    match /userChats/{userId}/rooms/{roomId} {
      allow read, update: if request.auth.uid == userId;
      allow create: if false; // Admin SDK only
    }

    match /users/{userId}/presence/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    match /userIncomingCalls/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

## 3. Mobile Implementation Guide

### A. Caller (User A) — Firestore Listener on Outgoing Call Screen

While User A is on the "Waiting for answer" outgoing call UI, attach a listener to `chatRooms/{roomId}/calls/active`:

```dart
// Flutter / Dart Example
FirebaseFirestore.instance
    .collection('chatRooms')
    .doc(roomId)
    .collection('calls')
    .doc('active')
    .snapshots()
    .listen((snapshot) {
  if (!snapshot.exists) {
    // Document deleted -> Call was declined / cancelled / timed out
    closeCallScreen(reason: "Call declined / ended");
  } else {
    final data = snapshot.data();
    final status = data?['status'];
    if (status == 'rejected' || status == 'cancelled' || status == 'ended' || status == 'missed') {
      closeCallScreen(reason: "Call $status");
    }
  }
});
```

### B. Backup Channel — FCM `call_cancelled` Push Payload

When Callee B rejects or ring times out, the server dispatches a data-only FCM push to Caller A:

```json
{
  "type": "call_cancelled",
  "event": "call_cancelled",
  "category": "INCOMING_CALL",
  "notification_id": "history_uuid",
  "call_id": "vc_chat_userA_userB",
  "room_id": "chat_userA_userB",
  "reason": "rejected",
  "caller_id": "user_a",
  "callee_id": "user_b"
}
```

Handle `reason` values in background / foreground FCM handler:
- `rejected` $\rightarrow$ Close outgoing screen + show toast `"Call declined"`
- `cancelled` $\rightarrow$ Close call UI
- `missed` $\rightarrow$ Close outgoing screen + show toast `"No answer"`

---

## 4. API Endpoints Reference (Unchanged Contracts)

### Start Call (Caller A)
```http
POST /api/call/direct/start
Authorization: Bearer <CALLER_JWT>

{
  "calleeUserId": "user_b",
  "callType": "voice"
}
```

### Respond to Call (Callee B)
```http
POST /api/call/direct/respond
Authorization: Bearer <CALLEE_JWT>

{
  "callId": "vc_chat_...",
  "roomId": "chat_...",
  "action": "reject"
}
```

### End Call (Caller or Callee)
```http
POST /api/call/direct/end
Authorization: Bearer <JWT>

{
  "callId": "vc_chat_...",
  "reason": "cancelled"
}
```
