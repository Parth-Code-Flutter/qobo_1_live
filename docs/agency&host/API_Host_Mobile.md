# Agency Host Flow — API Specification (Mobile)

**Document version:** 1.0  
**Last updated:** 2026-06-05  
**Mobile app:** qobo_one_live (Flutter)  

This file describes request/response contracts for the **Host applicant** flow. It complements `API_Agency_Mobile.md` (agency owner dashboard).

**Source:** Backend team handoff (`API_Agency_Host_Mobile.md`).

---

## 1. General conventions

### Authentication

| Audience | Auth |
|----------|------|
| Host application APIs | **None** (public — applicant may not be logged in) |

### Response envelope (all endpoints)

```json
{
  "statusCode": 1,
  "message": "Human-readable message",
  "data": { }
}
```

| `statusCode` | Meaning |
|--------------|---------|
| `1` | Success |
| `0` | Business failure (validation, not found, rejected agency code, etc.) |

**HTTP status codes:** `200` / `201` for success.

---

## 2. API Endpoints

### 2.1 Submit host application (onboarding)

**`POST /api/agency/host-onboarding`**

| | |
|--|--|
| **Auth** | None |
| **Content-Type** | `multipart/form-data` |
| **Purpose** | Applicant submits host registration under an agency code |

#### Form fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `agency_code` | string | Yes | Invite/recruit code from agency owner. Aliases: `agencyCode` |
| `name` | string | Yes | Full host name. Aliases: `hostName` |
| `phone` | string | Yes | WhatsApp number. Aliases: `whatsapp` |
| `gmail` | string | Yes | Email |
| `type` | string | Yes | Stream type: `audio`, `video`. Aliases: `hostType` |
| `category` | string | Yes | Host interest/talent: `singing`, `dancing`, `gaming`, `chatting`. Aliases: `interests`, `interest` |
| `dob` | string | Yes | Prefer `yyyy-MM-dd`. Aliases: `birthday` |
| `id_no` | string | Yes | Government / host ID number. Aliases: `hostIdNumber` |
| `real_photo` | file | Yes | Portrait photo (JPEG/PNG). **Deployed alias:** `host_real_photo` |

> **Mobile binding:** Sends canonical fields plus aliases. File upload uses `host_real_photo` (verified on staging backend 2026-06-05).

#### Success response — `201 Created`

```json
{
  "statusCode": 1,
  "message": "Host application submitted",
  "data": {
    "id": "application-uuid",
    "hostName": "Priya Sharma",
    "status": "pending",
    "agencyCode": "FUN-CALL-01",
    "phone": "9876543210",
    "createdAt": "2026-06-01T00:00:00.000Z"
  }
}
```

#### Error examples

**Invalid agency code:**

```json
{
  "statusCode": 0,
  "message": "Invalid agency code",
  "data": null
}
```

**Duplicate pending application (same phone):**

```json
{
  "statusCode": 0,
  "message": "An application is already pending for this phone number",
  "data": null
}
```

---

### 2.2 Check host application status

**`GET /api/agency/host-verify-status`**

| | |
|--|--|
| **Auth** | None |
| **Purpose** | Applicant checks pending / approved / rejected status |

#### Query parameters (send **one** lookup key)

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| `application_id` | string | One of | Primary — returned from onboarding |
| `phone` | string | One of | WhatsApp used at apply time |

#### Success response — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Application status fetched",
  "data": {
    "id": "application-uuid",
    "applicationId": "application-uuid",
    "hostId": "HOST-1001",
    "hostName": "Priya Sharma",
    "agencyId": "8f3c2a1b-xxxx-xxxx-xxxx",
    "agencyCode": "FUN-CALL-01",
    "phone": "9876543210",
    "status": "pending",
    "reason": null,
    "createdAt": "2026-06-01T00:00:00.000Z"
  }
}
```

#### Not found — `200 OK`

```json
{
  "statusCode": 0,
  "message": "No host application found",
  "data": null
}
```

*(Not found returns HTTP `200` with `statusCode: 0` — mobile treats this as a normal empty state.)*

---

## 3. Mobile screen binding

| Screen | Route | API |
|--------|-------|-----|
| Host Registration | `/agency-host-onboarding` | `POST /api/agency/host-onboarding` |
| Application Status | `/agency-host-status` | `GET /api/agency/host-verify-status` |

**Repo:** `lib/repo/agency/agency_repo.dart`  
**Controllers:** `AgencyHostOnboardingController`, `AgencyHostStatusController`

---

## 4. Live POST/GET test results (2026-06-05)

**Base URL:** `https://my-backend-api-960q.onrender.com`

| Test | Result |
|------|--------|
| `GET host-verify-status?phone=9999999999` | `200`, `statusCode: 0`, message: No host application found |
| `POST host-onboarding` with `real_photo` field | `500`, Unexpected field — use `host_real_photo` |
| `POST host-onboarding` invalid agency | `200`, `statusCode: 0`, Invalid agency code |
| `POST host-onboarding` agency `STAR01` | `201`, `statusCode: 1`, returns `data.id` + `status: pending` |
| `GET host-verify-status?application_id={id}` | `200`, `statusCode: 1`, full status payload |
| `GET host-verify-status?phone={phone}` | `200`, `statusCode: 1`, same application |
| `POST` duplicate phone | `200`, `statusCode: 0`, pending duplicate message |

**Test application ID:** `3ecb262b-55dc-4dca-8172-35d3381a0da3` (agency `STAR01`, status `pending`).

---

## 5. Related documents

| File | Contents |
|------|----------|
| `docs/agency&host/API_Agency_Mobile.md` | Agency owner dashboard, host-list, revenue |
| `docs/agency&host/README.md` | Full agency + host implementation audit |
