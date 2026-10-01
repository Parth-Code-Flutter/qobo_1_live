# PK Battle — Duration Selection (Backend Requirements)

**App:** `qobo_one_live` (Flutter)  
**Audience:** Backend team  
**Feature:** Challenger picks battle length **before** sending a PK challenge  
**Date:** 2026-09-21  
**Related contracts:**  
- Host-vs-host v1: `POST /api/v1/pk/invitations` (`durationSec`)  
- Legacy room PK: `POST /api/pk/send-request` (`duration`)  
- Live handoff: `docs/api/PK_BATTLE_API_AND_MOBILE_HANDOFF.md`

---

## 1. Product requirement

When **Person A** challenges **Person B** for a PK battle, **before** the challenge is sent, Person A must choose how long the battle should run:

| UI option | Duration |
|-----------|----------|
| **2 min** | 120 seconds |
| **5 min** | 300 seconds |
| **10 min** | 600 seconds |
| **Custom** | Integer **minutes** typed by user (digits only on mobile) |

That chosen duration must:

1. Be sent on the **challenge / invitation create** API.
2. Be stored on the **invitation** and on the **active PK session**.
3. Be shown to **Person B** on the incoming challenge (socket / FCM / invite payload).
4. Drive the **server-authoritative countdown** once the battle starts (auto-end when time expires).

Mobile will implement the picker dialog; backend must **accept, validate, persist, echo, and enforce** the duration.

---

## 2. What mobile already sends today

### 2.1 PK Battle v1 (preferred)

`POST /api/v1/pk/invitations`

```json
{
  "targetUserId": "<user-uuid>",
  "mode": "ONE_VS_ONE",
  "durationSec": 180
}
```

- Field name: **`durationSec`** (integer, **seconds**).
- Current mobile default if no picker: `180` (3 min). After this feature: value comes from the picker (120 / 300 / 600 / custom×60).

### 2.2 Legacy room PK (fallback)

`POST /api/pk/send-request`

```json
{
  "room_id": "<challenger-room-uuid>",
  "target_room_id": "<opponent-room-uuid>",
  "duration": 300
}
```

- Field name: **`duration`** (integer, **seconds**).
- Keep supporting this for older clients / fallback path.

### 2.3 Units (important)

- **API always uses seconds** (`durationSec` / `duration`).
- Mobile UI shows **minutes**; mobile converts `minutes → seconds` before the request.
- Backend must **not** expect minutes in the API body.

---

## 3. Backend changes required

### 3.1 Validate duration on challenge create

On both:

- `POST /api/v1/pk/invitations`
- `POST /api/pk/send-request`

Apply the same rules:

| Rule | Value | Notes |
|------|-------|--------|
| Type | Integer seconds | Reject strings that are not parseable as int |
| Required | Yes (recommended) | If missing, default to **300** (5 min) for backward compatibility |
| Minimum | **60** (1 min) | Matches custom field allowing small values; confirm with product if you want min = 120 |
| Maximum | **1800** (30 min) | Suggested cap; confirm with product |
| Allowed presets | 120, 300, 600 | Not exclusive — custom any int in `[min, max]` is allowed |

**Reject example** (out of range / invalid):

```json
{
  "success": false,
  "statusCode": 0,
  "message": "Invalid PK duration. Use 60–1800 seconds.",
  "data": null
}
```

### 3.2 Persist on invitation + session

Store the challenger’s duration on:

1. **Invitation / request record** (pending challenge).
2. **Active PK session / battle** when B accepts (copy from invitation; do **not** let acceptor change duration).

Suggested DB fields:

| Entity | Field | Type | Example |
|--------|-------|------|---------|
| Invitation | `duration_sec` | int | `600` |
| Session / battle | `duration_sec` | int | `600` |
| Session / battle | `started_at` | timestamp | used with duration for `ends_at` / `remainingSeconds` |
| Session / battle | `ends_at` *(optional)* | timestamp | `started_at + duration_sec` |

### 3.3 Echo duration in create / accept / get responses

Always return duration in seconds under both casings if you already mix styles:

```json
{
  "success": true,
  "message": "Invitation sent",
  "data": {
    "invitationId": "...",
    "status": "PENDING",
    "durationSec": 600,
    "duration": 600
  }
}
```

On accept / session payload:

```json
{
  "pkId": "...",
  "status": "ACTIVE",
  "durationSec": 600,
  "duration": 600,
  "remainingSeconds": 600,
  "startedAt": "2026-09-21T12:00:00.000Z"
}
```

Mobile parsers already look for: `durationSec`, `duration_sec`, `duration`.

### 3.4 Enforce timer server-side

When battle becomes **ACTIVE**:

1. Start countdown from **`durationSec` from the invitation** (not a hardcoded 180/300).
2. Emit periodic remaining time (socket) if you already do.
3. On expiry → auto-complete battle, compute winner, emit `pk_completed` / v1 equivalent with final scores.
4. `remainingSeconds` on status/poll must match `max(0, ends_at - now)`.

### 3.5 Deliver duration to Person B (incoming challenge)

Person B must see how long the battle will be before accepting.

Include duration in:

| Channel | Suggested keys |
|---------|----------------|
| Socket invite event | `durationSec` / `duration` |
| FCM data payload | `battle_duration` (string seconds) **and/or** `durationSec` |
| `GET` invitations list | `durationSec` on each pending invite |

**Incoming invite example (socket / push data):**

```json
{
  "type": "pk_request",
  "invitationId": "...",
  "fromUserId": "...",
  "fromUserName": "Person A",
  "durationSec": 600,
  "battle_duration": "600"
}
```

### 3.6 Do **not** allow B to change duration on accept

`POST /api/v1/pk/invitations/{id}/accept`  
`POST /api/pk/accept-reject` with `action=accept`

- Ignore any duration field on accept body (if sent).
- Session duration = invitation’s stored `duration_sec` only.

---

## 4. API checklist (backend)

| # | Item | Status needed |
|---|------|----------------|
| 1 | Accept `durationSec` on `POST /api/v1/pk/invitations` | Validate + persist |
| 2 | Accept `duration` on `POST /api/pk/send-request` | Validate + persist |
| 3 | Default when omitted | `300` seconds |
| 4 | Min / max clamp or reject | Confirm **60–1800** |
| 5 | Echo on invite create response | Required |
| 6 | Include on socket + FCM to opponent | Required |
| 7 | Copy into session on accept | Required |
| 8 | Server timer uses stored duration | Required |
| 9 | Status / active endpoints return `durationSec` + `remainingSeconds` | Required |
| 10 | History / result may include `durationSec` | Nice to have |

---

## 5. Mobile UI plan (for context — not backend work)

Challenger flow:

1. Person A taps challenge on Person B.
2. Dialog opens with chips: **2 min / 5 min / 10 min**.
3. Custom `TextField` — **digits only**, unit = **minutes**.
4. Confirm → convert to seconds → call invite API with `durationSec`.
5. Person B invite UI shows e.g. “Battle length: 10 min”.

Suggested mobile validation before API call:

- Custom empty → require selecting a preset or entering minutes.
- Custom `0` / non-digit → blocked on client.
- Client also clamps to same min/max as backend.

---

## 6. Open questions for backend / product

Please confirm and reply on these so mobile can match:

1. **Min custom minutes** — keep **1** (60s) or force minimum **2** (120s)?
2. **Max custom minutes** — propose **30**; OK?
3. If `durationSec` is **missing**, is default still **300**?
4. Should invalid duration **reject** the request (preferred) or **clamp** to nearest allowed value?
5. Does follower PK (`/api/pk/follower/*`) need the same picker, or **host-vs-host only** for this release?

---

## 7. Acceptance criteria

- [ ] Challenger can send invite with 120 / 300 / 600 / custom×60 seconds.
- [ ] Backend rejects or clamps invalid durations consistently.
- [ ] Opponent invite payload shows the same duration.
- [ ] After accept, battle ends automatically after exactly that many seconds (±1–2s network skew).
- [ ] Status / socket remaining time matches chosen duration.
- [ ] Accepting host cannot override duration.

---

## 8. Suggested backend response for mobile

Once implemented, please reply with:

1. Confirmed min/max and default.  
2. Exact field names on invite create + socket + FCM.  
3. Sample JSON for: create invite, incoming socket, accept → active session.  
4. Whether legacy `/api/pk/send-request` and v1 `/api/v1/pk/invitations` both support the same rules.

Mobile will then ship the duration picker dialog and wire it to these fields.
