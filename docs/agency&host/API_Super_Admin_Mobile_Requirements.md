# Super Admin — Mobile API Requirements (Backend Handover)

**Document version:** 1.0  
**Last updated:** 2026-07-21  
**Mobile app:** qobo_one_live (Flutter)  
**Audience:** Backend team  
**Role required:** `super_admin` (from login / user profile `role`)

This document lists:

1. APIs **already available** and used by mobile  
2. **Missing APIs** required for Agency / Host detail onClick screens  
3. **Additional recommended APIs** to complete the Super Admin mobile shell  

Please implement Priority **P0** first so mobile can ship agency/host detail screens.

---

## 1. General conventions

### Authentication

| Audience | Auth |
|----------|------|
| All Super Admin APIs | **Bearer token** of a user with `role == "super_admin"` |

Unauthorized / wrong role should return `401` / `403`.

### Response envelope (preferred — match existing app APIs)

```json
{
  "statusCode": 1,
  "message": "Human-readable message",
  "data": {}
}
```

| `statusCode` | Meaning |
|--------------|---------|
| `1` | Success |
| `0` | Business failure (not found, validation, forbidden, etc.) |

> Note: Some existing Super Admin responses use `{ "success": true, ... }`.  
> Mobile can support either, but **please standardize on `statusCode` / `message` / `data`** for all new endpoints.

### IDs and dates

- Path IDs: UUID / string IDs already used in list APIs (`agency.id`, `host.id`)
- Dates: ISO-8601 UTC (`2026-07-18T10:15:30.000Z`)
- Money / coins / diamonds: `number` (not string)

---

## 2. Already available Super Admin APIs (reference)

These are already documented in `super_admin_agency_flow_guide` and integrated (or ready) on mobile.

| # | Method | Endpoint | Mobile use |
|---|--------|----------|------------|
| 1 | `GET` | `/api/super-admin/dashboard` | Dashboard tab stats |
| 2 | `GET` | `/api/super-admin/agencies?status=` | Agency tab list + filters |
| 3 | `POST` | `/api/super-admin/agency/process` | Approve / reject agency |
| 4 | `GET` | `/api/super-admin/hosts/track` | Host tab global tracking list |
| 5 | `GET` | `/api/super-admin/agency/generate-link` | Invite Agency CTA on Dashboard |

**Gap:** List APIs only. There is **no detail-by-id** API for Agency or Host, so mobile cannot open a detail screen on card tap.

---

## 3. Missing APIs — required for onClick detail (P0)

### 3.1 Get Agency Detail ⭐ P0

**Needed when:** Super Admin taps an agency card in the Agency tab.

**`GET /api/super-admin/agencies/:agencyId`**

| | |
|--|--|
| **Auth** | Bearer token (`super_admin`) |
| **Purpose** | Full agency details for review / management screen |

#### Path params

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `agencyId` | string | Yes | Same as list item `id` |

#### Success response — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Agency details fetched successfully",
  "data": {
    "id": "agency-uuid-1",
    "name": "Superstar Agency Ltd",
    "code": "XYZ890",
    "logo": "https://...",
    "commissionRate": 0.10,
    "status": "pending",
    "feedback": null,
    "createdAt": "2026-07-18T10:15:30.000Z",
    "updatedAt": "2026-07-18T12:00:00.000Z",
    "address": {
      "country": "India",
      "state": "Gujarat",
      "city": "Ahmedabad",
      "fullAddress": "..."
    },
    "owner": {
      "id": "owner-user-id",
      "name": "John Doe",
      "email": "john@staragency.com",
      "phone": "+1234567890",
      "countryCode": "+91",
      "displayPicture": "https://...",
      "role": "agency"
    },
    "documents": {
      "docPhotoFront": "https://...",
      "docPhotoBack": "https://..."
    },
    "stats": {
      "hostCount": 12,
      "pendingHostsCount": 2,
      "activeHostsCount": 10,
      "totalCommissionEarned": 4500.5,
      "totalDiamonds": 12000,
      "totalCoins": 34000
    },
    "invitedBy": {
      "id": "super-admin-user-id",
      "name": "Super Admin Name",
      "email": "superadmin@qobo.com"
    }
  }
}
```

#### Error cases

| Case | statusCode | message example |
|------|------------|-----------------|
| Agency not found | `0` | `Agency not found` |
| Not super_admin | `0` / HTTP 403 | `Forbidden` |

---

### 3.2 Get Host Detail ⭐ P0

**Needed when:** Super Admin taps a host card in the Host tab.

**`GET /api/super-admin/hosts/:hostId`**

| | |
|--|--|
| **Auth** | Bearer token (`super_admin`) |
| **Purpose** | Full host profile + earnings + agency association |

#### Path params

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `hostId` | string | Yes | Same as list item `id` from `/hosts/track` |

#### Success response — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Host details fetched successfully",
  "data": {
    "id": "host-id",
    "name": "Host Display Name",
    "email": "host@gmail.com",
    "phone": "+1999999999",
    "countryCode": "+91",
    "displayPicture": "https://...",
    "role": "host",
    "status": "active",
    "category": "Singing",
    "dob": "1998-05-12T00:00:00.000Z",
    "gender": "female",
    "country": "India",
    "state": "Maharashtra",
    "city": "Mumbai",
    "address": "…",
    "joinedAt": "2026-06-01T09:00:00.000Z",
    "agency": {
      "id": "agency-uuid-1",
      "name": "Superstar Agency Ltd",
      "code": "XYZ890",
      "status": "approved"
    },
    "earnings": {
      "diamonds": 450.0,
      "coins": 1200.0,
      "totalStreamSeconds": 36000.5,
      "totalCommissionEarned": 120.0,
      "coinsPerSecond": 5
    },
    "documents": {
      "idNo": "ID-900800",
      "docPhotoFront": "https://...",
      "docPhotoBack": "https://...",
      "photo": "https://..."
    },
    "recentActivity": {
      "lastLiveAt": "2026-07-20T18:30:00.000Z",
      "isLiveNow": false,
      "totalSessions": 42
    }
  }
}
```

#### Error cases

| Case | statusCode | message example |
|------|------------|-----------------|
| Host not found | `0` | `Host not found` |
| Not super_admin | `0` / HTTP 403 | `Forbidden` |

---

## 4. Additional recommended APIs (P1 / P2)

These are **not blocking** first detail screens, but mobile will need them soon for a complete Super Admin experience.

### 4.1 List hosts under one agency — P1

**Needed when:** From Agency Detail → “View hosts”.

**`GET /api/super-admin/agencies/:agencyId/hosts`**

#### Query params

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `status` | string | No | `active` \| `pending` \| `rejected` \| `suspended` \| `all` (default `all`) |
| `page` | int | No | Default `1` |
| `limit` | int | No | Default `20` (max `50`) |
| `search` | string | No | Name / phone / email |

#### Success response

```json
{
  "statusCode": 1,
  "message": "Agency hosts fetched successfully",
  "data": {
    "agencyId": "agency-uuid-1",
    "agencyCode": "XYZ890",
    "total": 12,
    "page": 1,
    "limit": 20,
    "hosts": [
      {
        "id": "host-id",
        "name": "Host Display Name",
        "displayPicture": "https://...",
        "phone": "+1999999999",
        "status": "active",
        "diamonds": 450.0,
        "coins": 1200.0,
        "totalStreamSeconds": 36000.5,
        "totalCommissionEarned": 120.0
      }
    ]
  }
}
```

---

### 4.2 Improve Host Track list (filters + pagination + search) — P1

Current: `GET /api/super-admin/hosts/track` returns a flat list with no filters.

**Please extend the same endpoint** (preferred) or add a new one:

**`GET /api/super-admin/hosts/track`**

#### Query params (add)

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `status` | string | No | `active` \| `inactive` \| `suspended` \| `all` |
| `agencyCode` | string | No | Filter by agency code |
| `search` | string | No | Name / phone / email |
| `page` | int | No | Default `1` |
| `limit` | int | No | Default `20` |
| `sortBy` | string | No | `commission` \| `diamonds` \| `streamTime` \| `recent` |
| `sortOrder` | string | No | `asc` \| `desc` (default `desc`) |

#### Success response (paginated shape preferred)

```json
{
  "statusCode": 1,
  "message": "Host tracking data fetched successfully",
  "data": {
    "total": 42,
    "page": 1,
    "limit": 20,
    "hosts": [ /* same host objects as today */ ]
  }
}
```

> If changing response shape is hard, keep returning a raw array for now, but please still add query filters.

---

### 4.3 Improve Agencies list (pagination + search) — P1

**`GET /api/super-admin/agencies`**

#### Query params (add)

| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `status` | string | No | Already exists |
| `search` | string | No | Agency name / code / owner phone / email |
| `page` | int | No | Default `1` |
| `limit` | int | No | Default `20` |

#### Preferred paginated response

```json
{
  "statusCode": 1,
  "message": "Agencies list fetched successfully",
  "data": {
    "total": 5,
    "page": 1,
    "limit": 20,
    "agencies": [ /* same agency objects as today */ ]
  }
}
```

---

### 4.4 Update agency status after approval (suspend / reactivate) — P1

Approve/reject already exists via `POST /api/super-admin/agency/process`.  
Mobile also needs post-approval moderation.

**Option A (preferred — extend existing):**

**`POST /api/super-admin/agency/process`**

Allow `status`:

| status | Meaning |
|--------|---------|
| `approved` | Approve pending application |
| `rejected` | Reject pending application |
| `suspended` | Temporarily disable an approved agency |
| `active` / `approved` | Reactivate a suspended agency |

Request body (same as today):

```json
{
  "agency_id": "agency-uuid-1",
  "status": "suspended",
  "feedback": "Policy violation — temporarily suspended"
}
```

**Option B (new endpoint):**

**`POST /api/super-admin/agencies/:agencyId/status`**

```json
{
  "status": "suspended",
  "feedback": "Policy violation — temporarily suspended"
}
```

---

### 4.5 Suspend / reactivate host (Super Admin override) — P1

Agency owners manage host applications; Super Admin needs a global override.

**`POST /api/super-admin/hosts/:hostId/status`**

```json
{
  "status": "suspended",
  "reason": "Spam / fake streaming activity"
}
```

Allowed `status` values:

| status | Meaning |
|--------|---------|
| `active` | Reactivate |
| `suspended` | Block from going live / earning |
| `inactive` | Soft disable (optional) |

#### Success response

```json
{
  "statusCode": 1,
  "message": "Host status updated successfully",
  "data": {
    "id": "host-id",
    "status": "suspended",
    "reason": "Spam / fake streaming activity",
    "updatedAt": "2026-07-21T04:30:00.000Z"
  }
}
```

---

### 4.6 Update agency commission rate — P2

**`PATCH /api/super-admin/agencies/:agencyId/commission`**

```json
{
  "commissionRate": 0.12
}
```

```json
{
  "statusCode": 1,
  "message": "Commission rate updated",
  "data": {
    "id": "agency-uuid-1",
    "commissionRate": 0.12
  }
}
```

---

### 4.7 Dashboard enhancements (optional) — P2

Current dashboard returns:

```json
{
  "totalAgencies": 5,
  "activeHosts": 42,
  "pendingAgencies": 2,
  "pendingHosts": 4,
  "totalCommissions": 12500.5
}
```

**Nice-to-have additions:**

```json
{
  "totalAgencies": 5,
  "activeAgencies": 4,
  "suspendedAgencies": 1,
  "activeHosts": 42,
  "pendingAgencies": 2,
  "pendingHosts": 4,
  "liveHostsNow": 7,
  "totalCommissions": 12500.5,
  "commissionsThisMonth": 2100.25,
  "topAgencies": [
    {
      "id": "agency-uuid-1",
      "name": "Superstar Agency Ltd",
      "code": "XYZ890",
      "totalCommissionEarned": 3200.5
    }
  ],
  "recentPendingAgencies": [
    {
      "id": "agency-uuid-2",
      "name": "New Agency",
      "code": "NEW123",
      "createdAt": "2026-07-20T10:00:00.000Z"
    }
  ]
}
```

Mobile can keep working with the current 5 fields; extras improve the Dashboard UI later.

---

## 5. Priority summary for backend

| Priority | Endpoint | Why mobile needs it |
|----------|----------|---------------------|
| **P0** | `GET /api/super-admin/agencies/:agencyId` | Agency card onClick → detail screen |
| **P0** | `GET /api/super-admin/hosts/:hostId` | Host card onClick → detail screen |
| **P1** | `GET /api/super-admin/agencies/:agencyId/hosts` | Agency detail → hosts under agency |
| **P1** | Extend `GET /hosts/track` with filters / pagination / search | Host tab usability |
| **P1** | Extend `GET /agencies` with pagination / search | Agency tab usability |
| **P1** | Agency suspend / reactivate | Moderation after approval |
| **P1** | Host suspend / reactivate | Global host moderation |
| **P2** | Update commission rate | Agency management |
| **P2** | Richer dashboard stats | Better Dashboard UI |

---

## 6. Mobile UX mapping (for context)

```text
Super Admin Bottom Nav
  ├── Dashboard
  │     ├── GET /dashboard
  │     └── GET /agency/generate-link
  ├── Agency
  │     ├── GET /agencies?status=
  │     ├── POST /agency/process          (approve / reject)
  │     └── TAP agency card
  │           └── GET /agencies/:id       ← MISSING (P0)
  │                 └── GET /agencies/:id/hosts  ← recommended (P1)
  ├── Host
  │     ├── GET /hosts/track
  │     └── TAP host card
  │           └── GET /hosts/:id          ← MISSING (P0)
  └── Settings
        └── Local session / logout (no new API)
```

---

## 7. Acceptance checklist

Please confirm when ready:

- [ ] `GET /api/super-admin/agencies/:agencyId` returns full detail including owner + documents + stats  
- [ ] `GET /api/super-admin/hosts/:hostId` returns full detail including agency + earnings + documents  
- [ ] Both endpoints reject non-`super_admin` users  
- [ ] Both endpoints return clear `statusCode: 0` + message when ID not found  
- [ ] Document / image URLs are absolute HTTPS URLs usable in the app  
- [ ] Response envelope documented (`statusCode` / `message` / `data`)  
- [ ] (Optional P1) Agency hosts list + list filters/pagination added  

Once P0 APIs are live, mobile will implement:

1. Agency detail screen on agency card tap  
2. Host detail screen on host card tap  

---

## 8. Contact / questions for backend

If any field names must differ from this draft, please reply with the final JSON keys so mobile can map them exactly.

**Minimum needed to unblock detail screens:** only **§3.1** and **§3.2**.
