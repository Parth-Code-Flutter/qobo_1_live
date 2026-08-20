# 1-on-1 Call Charging — 50/50 Revenue Split

## Rule

| Party | Per second (rate = 2 coins/sec) |
|-------|----------------------------------|
| **Caller A** | Debited **2 coins** |
| **Callee B** | Credited **1 diamond** (50%) |
| **Platform** | Retains **1 coin** commission (50%) |

Example: **10 seconds** at 2 coins/sec → **20** debited, **10** to callee, **10** commission.

## Endpoints

### Primary — auto charge on hangup

```http
POST /api/call/direct/end
Authorization: Bearer <JWT>
```

```json
{
  "callId": "vc_chat_...",
  "reason": "user_hangup",
  "durationSeconds": 10,
  "hostId": "9587736762"
}
```

When `durationSeconds > 0`, the backend runs `CallingService.chargeCall` automatically. **Do not** also call `/api/economy/calling/charge` for the same session.

### Manual / legacy — explicit charge

```http
POST /api/economy/calling/charge
Authorization: Bearer <JWT>
```

```json
{
  "hostId": "9587736762",
  "durationSeconds": 10
}
```

Use only when there is **no** server `callId` (legacy Firestore-only ring).

## Mobile integration (this app)

| Step | Behaviour |
|------|-----------|
| Call start | `POST /api/call/direct/start` → store `callId` / `zegoCallId` on call screen |
| During call | UI shows caller **2 coins/s** spend, callee **1 diamond/s** earn (local preview) |
| Hangup | `ChatVoiceCallController.finishCall()` → `POST /api/call/direct/end` with duration + callee `hostId` |
| Billing parse | `CallingChargeParser` reads `totalCoinsDeducted`, `hostEarnedDiamonds`, `platformCommission` from end/charge response |
| Wallet refresh | Both sides reload wallet after settle |

## Verification example

| | Before | After 1s call (2 coins/sec) |
|--|--------|------------------------------|
| Caller A coins | 100 | 98 (−2) |
| Callee B diamonds | 9002 | 9003 (+1) |
| Platform | — | 1 coin commission |

## Files

- `lib/repo/calling/calling_repo.dart` — explicit charge
- `lib/repo/call/call_repo.dart` — direct/end with duration
- `lib/repo/calling/calling_charge_utils.dart` — response parser
- `lib/app/user_flow/messages/chat_voice_call/controllers/chat_voice_call_controller.dart` — settle on hangup
