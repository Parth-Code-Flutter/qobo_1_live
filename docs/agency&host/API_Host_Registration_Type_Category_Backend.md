# Host Registration API Update — Type & Category Split

**Date:** 2026-06-06  
**Mobile app:** qobo_one_live (Flutter)  
**Endpoint:** `POST /api/agency/host-onboarding`  
**Base URL:** `https://my-backend-api-960q.onrender.com`  
**Auth:** None (public host application)

---

## Summary for backend team

Mobile host registration UI now has **two separate fields**:

| UI label | Field name | Values |
|----------|------------|--------|
| **Type** | `type` | `audio`, `video` |
| **Category** (interest dropdown) | `category` | `singing`, `dancing`, `gaming`, `chatting` |

**Breaking change:** Previously mobile sent `category = audio|video`. That value is now sent as **`type`**. The **`category`** field now means host **interest/talent**.

Mobile is already implemented and will send the new shape on the next release.

---

## Request — `POST /api/agency/host-onboarding`

**Content-Type:** `multipart/form-data`

### All form fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `agency_code` | string | Yes | Agency recruit code. Alias: `agencyCode` |
| `name` | string | Yes | Host full name. Alias: `hostName` |
| `phone` | string | Yes | WhatsApp (10 digits). Alias: `whatsapp` |
| `gmail` | string | Yes | Email |
| **`type`** | string | **Yes** | Stream type: `audio` or `video`. Alias: `hostType` |
| **`category`** | string | **Yes** | Interest: `singing`, `dancing`, `gaming`, or `chatting`. Alias: `interest` |
| `dob` | string | Yes | Date of birth `yyyy-MM-dd`. Alias: `birthday` |
| `id_no` | string | Yes | Host ID number. Alias: `hostIdNumber` |
| `host_real_photo` | file | Yes | Portrait photo (JPEG/PNG). Alias: `real_photo` |

### Example multipart body (text fields)

```
agency_code=STAR01
name=Priya Sharma
phone=9876543210
gmail=priya@gmail.com
type=video
category=singing
hostType=video
interest=singing
dob=1998-06-02
id_no=ABCD1234
host_real_photo=<file>
```

### Allowed values

**`type` / `hostType`**

| Value | UI label |
|-------|----------|
| `audio` | Audio |
| `video` | Video |

**`category` / `interest`**

| Value | UI label |
|-------|----------|
| `singing` | Singing |
| `dancing` | Dancing |
| `gaming` | Gaming |
| `chatting` | Chatting |

### Validation (recommended)

- Return `statusCode: 0` + HTTP `400`/`422` if:
  - `type` is missing or not in `audio|video`
  - `category` is missing or not in `singing|dancing|gaming|chatting`
- Keep existing validations (agency code, duplicate phone, photo required, etc.)

---

## Success response — `201 Created`

```json
{
  "statusCode": 1,
  "message": "Host application submitted",
  "data": {
    "id": "application-uuid",
    "applicationId": "application-uuid",
    "hostName": "Priya Sharma",
    "phone": "9876543210",
    "agencyCode": "STAR01",
    "type": "video",
    "category": "singing",
    "status": "pending",
    "createdAt": "2026-06-06T10:00:00.000Z"
  }
}
```

---

## Database / migration

1. Add column **`type`** (`audio` | `video`) if not present.
2. Repurpose **`category`** to store interest (`singing` | `dancing` | `gaming` | `chatting`), **or** add column **`interest`** and map alias `interest` → DB.
3. **Migrate old rows:** where `category IN ('audio','video')`, copy to `type` and set `category`/`interest` to `NULL` or a default until re-applied.

---

## Downstream APIs — return both fields

Please include **`type`** and **`category`** (interest) in responses for:

| Endpoint | Notes |
|----------|-------|
| `GET /api/agency/host-verify-status` | Applicant status screen |
| `GET /api/agency/host-applications` | Agency owner pending review |
| `GET /api/agency/host-applications/{id}` | Application detail |
| `GET /api/agency/host-list` | Host tree / list |
| `GET /api/agency/dashboard` | Dashboard host cards |

Example host/application object:

```json
{
  "applicationId": "uuid",
  "hostName": "Priya Sharma",
  "phone": "9876543210",
  "type": "video",
  "category": "singing",
  "status": "pending"
}
```

---

## Backward compatibility (optional transition)

During rollout, backend may accept **either**:

- **New:** `type` + `category` (interest) — preferred  
- **Legacy:** `category` = `audio|video` only (no interest) — treat as `type`, leave interest empty

Mobile **will not** send legacy `category=audio|video` after this update.

---

## cURL test (after deploy)

```bash
curl -X POST "https://my-backend-api-960q.onrender.com/api/agency/host-onboarding" \
  -F "agency_code=STAR01" \
  -F "name=Test Host" \
  -F "phone=9998887770" \
  -F "gmail=test@example.com" \
  -F "type=video" \
  -F "category=gaming" \
  -F "dob=1999-01-15" \
  -F "id_no=TEST1234" \
  -F "host_real_photo=@/path/to/photo.jpg"
```

---

## Contact / mobile status

- **Mobile:** Implemented — Type chips + Category dropdown on Host Registration screen  
- **Repo reference:** `AgencyRepo.hostOnboarding()` in qobo_one_live  
- **Full host flow doc:** `docs/agency&host/API_Host_Mobile.md`
