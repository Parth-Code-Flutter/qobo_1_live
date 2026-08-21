# 1:1 Voice/Video Call — Caller UI Close When Callee Declines

**Audience:** Backend / Firebase  
**App:** qobo_one_live  
**Scope:** One-to-one voice & video calls only (not rooms / live / PK)  
**Date:** 2026-08-21  
**Priority:** High — Product gap: Person A stays on “Waiting for answer” after Person B declines  

---

## 1. Problem (what mobile sees today)

| Step | Expected | Actual |
|------|----------|--------|
| A calls B | A sees outgoing call UI (“Waiting for answer”) | OK |
| B declines | A’s outgoing UI closes + toast e.g. “Call declined” | **A’s UI stays open** until A hangs up manually |

### Why it fails (mobile analysis)

- **Callee (B)** already calls `POST /api/call/direct/respond` with `action: "reject"` and clears Firestore ring docs.
- **Caller (A)** only detects “answered” via **Zego peer joined**.  
  A does **not** yet get a reliable “B declined” signal while waiting.
- Mobile will implement a **Firestore listener on A’s call screen** + local ring timeout.  
  That only works if backend / Firebase guarantees the contracts below.

---

## 2. Goal (end-to-end)

```text
A starts call
  → Firestore calls/active status = ringing (+ FCM incoming_call to B)
  → A opens “Waiting for answer” and LISTENS to calls/active

B declines
  → POST /api/call/direct/respond { action: "reject" }
  → Firestore active call CLEARED (or status = rejected)
  → Optional: FCM call_cancelled to A with reason = rejected

A’s listener (or FCM)
  → Close outgoing UI + show “Call declined”
```

Same idea for: B never answers (missed), A cancels, server timeout.

---

## 3. Must-have requirements (blocking)

### 3.1 Firestore security rules — caller must READ active call

**Document:** `chatRooms/{roomId}/calls/active`

| Role | Read | Write |
|------|:----:|:-----:|
| Caller (A) — participant of `roomId` | **Yes** | Yes (ring / end) |
| Callee (B) — participant of `roomId` | **Yes** | Yes (accept / reject / end) |
| Non-participants | No | No |

Also ensure related paths used by ring are consistent:

| Path | Purpose |
|------|---------|
| `chatRooms/{roomId}/calls/active` | Ephemeral ring / accept / end state (**primary signal for A**) |
| `userIncomingCalls/{calleeUserId}` | Fast ring lookup for B (clear on accept/reject/end) |

**Critical:** Mobile already sees `permission-denied` on ring writes (“Ring signal blocked — publish Firestore rules”).  
If **caller cannot read** `calls/active`, A will never learn that B declined via Firestore.

Please publish rules that allow both participants of the chat room to **read and write** the active call doc for that room.

---

### 3.2 On `POST /api/call/direct/respond` with `action: "reject"`

**Endpoint (existing — no new API):**

```http
POST /api/call/direct/respond
Authorization: Bearer <CALLEE_JWT>
Content-Type: application/json

{
  "callId": "vc_chat_...",
  "roomId": "chat_...",
  "action": "reject"
}
```

**Server must (idempotent):**

1. Validate callee is the intended callee for that `callId` / `roomId`.
2. Clear ring state in Firestore (Admin SDK preferred, even if client also deletes):
   - **Delete** `chatRooms/{roomId}/calls/active`  
     **OR** set `status: "rejected"` then delete within a few seconds  
   - **Delete** `userIncomingCalls/{calleeUserId}` (if present)
3. Record call history / missed-call outcome as you already do (`rejected` / missed).
4. Return success envelope (`statusCode: 1`).

**Why Admin SDK clear matters:** If B’s app crashes after API success but before client Firestore delete, A would still hang without server-side cleanup.

---

### 3.3 Document shape while ringing (for A’s listener)

While ringing, `chatRooms/{roomId}/calls/active` should include at least:

```json
{
  "callId": "vc_chat_...",
  "roomId": "chat_...",
  "callerId": "user_a",
  "calleeId": "user_b",
  "callerName": "Person A",
  "type": "voice",
  "status": "ringing",
  "startedAt": "<timestamp>",
  "updatedAt": "<timestamp>"
}
```

| `status` values mobile will handle | Meaning |
|------------------------------------|---------|
| `ringing` | Keep showing “Waiting for answer” |
| `accepted` | Optional; Zego peer-join still marks answered |
| `rejected` / `cancelled` / `ended` / `missed` | Close A’s UI |
| **Document deleted / missing** | Treat as call over → close A’s UI (decline / cancel / timeout) |

**Preferred on reject:** **delete** the active doc (simplest for mobile).  
Status-then-delete is also fine.

---

## 4. Strongly recommended (reliability)

### 4.1 FCM to **caller (A)** when B rejects (backup channel)

Today `call_cancelled` is mainly used to dismiss **B’s** ring UI.  
Please also send the same (or similar) push to **A** when B rejects.

```json
{
  "type": "call_cancelled",
  "event": "call_cancelled",
  "category": "INCOMING_CALL",
  "notification_id": "<same history / call uuid>",
  "call_id": "vc_chat_...",
  "room_id": "chat_...",
  "reason": "rejected",
  "caller_id": "user_a",
  "callee_id": "user_b"
}
```

| `reason` | When |
|----------|------|
| `rejected` | B tapped Decline |
| `cancelled` | A hung up before answer |
| `missed` | Ring timed out / no answer |
| `accepted` | Answered on another of B’s devices (dismiss other devices) |

**Mobile use:** If A is on outgoing call screen and receives `reason: rejected|cancelled|missed` for matching `call_id` → close UI.  
This covers cases where Firestore listen fails (rules, offline briefly, etc.).

> Prefer **data-only** for this cancel push (same as incoming_call), so OS does not show a useless tray banner to A.

---

### 4.2 Server-side ring timeout (45–60 seconds)

If `status` stays `ringing` longer than **45–60s**:

1. Mark outcome **missed** (or cancelled).
2. Delete `chatRooms/{roomId}/calls/active`.
3. Delete `userIncomingCalls/{calleeId}`.
4. Send FCM:
   - `call_cancelled` / `call_missed` to **B** (dismiss ring)
   - `call_cancelled` with `reason: "missed"` to **A** (close waiting UI)

Mobile will also run a **local** timeout, but server timeout is required so both sides stay consistent if a client dies.

---

### 4.3 Same cleanup on related events

Apply the same Firestore clear (+ optional FCM to the other party):

| Event | Who triggers | Clear `calls/active` | Notify other party |
|-------|--------------|:--------------------:|--------------------|
| B rejects | `respond` reject | Yes | A: `reason=rejected` |
| A cancels before answer | `direct/end` or client clear | Yes | B: `call_cancelled` |
| B accepts | `respond` accept | Keep until in-call end; clear `userIncomingCalls` | Other B devices: cancel ring |
| Either hangs up after connect | `direct/end` | Yes | Peer leaves Zego (existing) |
| Server timeout | Cron / worker | Yes | Both |

---

## 5. Existing APIs (confirm behavior — no new endpoints required)

### Start (A)

```http
POST /api/call/direct/start
```

Confirm: creates/validates call session; FCM `incoming_call` to B; Firestore ring docs exist (mobile and/or server).

### Respond (B)

```http
POST /api/call/direct/respond
{ "callId": "...", "roomId": "...", "action": "accept" | "reject" }
```

Confirm reject path fulfills §3.2 and preferably §4.1.

### End

```http
POST /api/call/direct/end
{ "callId": "...", "reason": "completed|cancelled|rejected|missed|failed" }
```

Confirm clears Firestore active + notifies other party to dismiss ring if still ringing.

---

## 6. What mobile will implement (for alignment)

| Side | Behavior |
|------|----------|
| **Caller A** | While “Waiting for answer”, listen to `chatRooms/{roomId}/calls/active`. On delete / rejected / cancelled / missed → toast + leave call screen. Local ~45s timeout as fallback. |
| **Caller A** | Handle FCM `call_cancelled` with `reason` rejected/cancelled/missed → same close (backup). |
| **Callee B** | Unchanged decline path: `respond` reject + dismiss ring/CallKit (already done). |

Mobile **does not** need a new REST “poll call status” API if Firestore + optional FCM work.

---

## 7. Acceptance checklist (backend)

- [ ] Firestore rules: **caller and callee** can **read** `chatRooms/{roomId}/calls/active`
- [ ] Firestore rules: participants can write ring / accept / reject / end (fix current `permission-denied` on ring if still broken)
- [ ] `respond` + `reject` → active doc **deleted** (or `status=rejected` then deleted) via **Admin SDK**
- [ ] `userIncomingCalls/{calleeId}` cleared on reject / accept / end / timeout
- [ ] Optional but recommended: FCM `call_cancelled` + `reason: "rejected"` to **caller A**
- [ ] Server ring timeout 45–60s clears docs + notifies both sides
- [ ] A cancel before answer still sends `call_cancelled` to B (dismiss B’s ring)
- [ ] No breaking changes to existing `incoming_call` / `direct/start` / `direct/respond` / `direct/end` contracts used by current app builds

---

## 8. Smoke test script (please run and confirm)

1. A and B both logged in; **A’s app open** on outgoing call screen.  
2. A starts 1:1 voice (or video) to B.  
3. Confirm Firestore: `chatRooms/{roomId}/calls/active` exists with `status: "ringing"`.  
4. B taps **Decline**.  
5. Confirm within ~1–2s:
   - Active doc is **gone** (or status rejected).  
   - `userIncomingCalls/{B}` is gone.  
   - (If implemented) A receives FCM `call_cancelled` / `reason=rejected`.  
6. A’s waiting UI closes (after mobile ships listener).  
7. Repeat with B **not answering** for 60s → missed cleanup.  
8. Repeat with A **hanging up** while ringing → B’s ring dismisses.

### Quick Firestore check

```text
chatRooms/{roomId}/calls/active     ← must disappear (or leave ringing) after B reject
userIncomingCalls/{calleeUserId}    ← must disappear after B reject
```

### Optional FCM check (caller token)

```bash
# After B rejects, caller device should receive data roughly like:
# type=call_cancelled, reason=rejected, call_id=..., room_id=...
```

---

## 9. Out of scope

- Audio / video **rooms**, live streaming, PK battle  
- Changing Zego join tokens  
- Changing 50/50 call charging (only applies after call is answered)  

---

## 10. Summary for backend

| Priority | Requirement |
|----------|-------------|
| **P0** | Firestore rules: caller **read** (+ write) on `calls/active` |
| **P0** | On reject: clear `calls/active` + `userIncomingCalls` (Admin SDK) |
| **P1** | FCM `call_cancelled` / `reason=rejected` to **caller** |
| **P1** | Server ring timeout 45–60s with same cleanup + notifies |
| **P2** | Confirm A-cancel and multi-device cancel paths still dismiss B’s ring |

**No new mobile-facing REST endpoint is required** if P0 is done.  
P1 makes the feature robust when Firestore is unavailable.

Questions / confirmation reply appreciated on: rules published? Admin clear on reject? caller FCM + timeout planned?
