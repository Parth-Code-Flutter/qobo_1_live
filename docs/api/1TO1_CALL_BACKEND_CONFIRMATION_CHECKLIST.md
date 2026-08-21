# 1:1 Call Flow — Backend Confirmation Checklist

**To:** Backend team  
**From:** Mobile (Flutter)  
**App:** Qobo1live — 1:1 voice & video  
**Date:** 2026-08-21  
**Related guide:** `docs/api/1to1_Call_Flow_and_Earning_Mobile_Developer_Guide.md`

---

## Summary

Mobile is implemented against the 1:1 Call Flow & Earning guide:

- Accept → stop ring → `POST /api/call/direct/respond` → active call screen (not ring UI again)
- Caller “Waiting for answer” closes on decline / miss / cancel / local timeout
- Connected call tears down on Firestore `calls/active` clear **and** FCM `call_cancelled`
- Billing starts only after connect (`connectedAt` / peer join), not while ringing

Please confirm the items below are live in this environment. If they already match the guide, **no further mobile API changes are required**.

---

## 1. Firestore `chatRooms/{roomId}/calls/active`

| Event | Expected backend behavior |
|--------|---------------------------|
| A starts call | Create/update doc, `status: ringing` |
| B accepts | `status: accepted` (or `connected` / `active`) **and** set `connectedAt` |
| B declines | Delete doc **or** `status: rejected` |
| Miss / A cancels while ringing | Delete doc **or** `status: missed` / `cancelled` |
| Either party hangs up after connect | Delete doc **or** `status: ended` |

**Rules:** Both caller (A) and callee (B) must be able to **read** this document. Mobile listens on both sides for ring UI and active-call teardown.

---

## 2. When caller (A) hangs up a **connected** call

Mobile expects **both**:

1. Clear / delete `chatRooms/{roomId}/calls/active`
2. Send **data-only** FCM to B (high priority), for example:

```json
{
  "type": "call_cancelled",
  "event": "call_cancelled",
  "category": "INCOMING_CALL",
  "call_id": "vc_chat_...",
  "room_id": "chat_...",
  "reason": "ended",
  "caller_id": "...",
  "callee_id": "..."
}
```

B uses this to leave Zego, stop timers, and close the call UI immediately.

---

## 3. Billing / earning rules

| Rule | Expected |
|------|----------|
| Charge only if call actually connected | Requires `connectedAt` |
| Billable duration | `endedAt − connectedAt` (exclude ringing) |
| Unanswered / declined / cancelled before connect | **0** coins charged, **0** earned |
| Split (example rate 2 coins/sec) | A pays 2/s · B earns 1/s (50%) · platform 1/s (50%) |

Please confirm exact field name: `connectedAt` vs `connected_at` (mobile accepts both).

---

## 4. REST endpoints mobile uses today

Confirm these routes (not only `/api/v1/call/*` unless dual-routed):

| Action | Method + path |
|--------|----------------|
| Start call (A) | `POST /api/call/direct/start` |
| Respond (B) | `POST /api/call/direct/respond` (`action: accept` \| `reject`) |
| End call | `POST /api/call/direct/end` (`reason`, optional `durationSeconds` when connected) |

Auth: Bearer JWT on all three.

---

## 5. Please reply with

- [ ] `calls/active` create / accept+`connectedAt` / clear-on-end — confirmed  
- [ ] Hang-up while connected → Firestore clear **and** FCM `call_cancelled` + `reason: ended` — confirmed  
- [ ] No charge when never connected — confirmed  
- [ ] `/api/call/direct/start|respond|end` — confirmed in this env  
- [ ] Field name for connect time: `connectedAt` / `connected_at` / both  

---

## One-line message you can paste

> Mobile is ready per the 1:1 Call Flow & Earning guide. Please confirm: (1) `connectedAt` on accept, (2) `calls/active` cleared on hang-up, (3) data-only FCM `call_cancelled` with `reason: ended` to the peer, (4) `/api/call/direct/*` live on this environment. If those are already shipped, no further backend work is needed for this guide.
