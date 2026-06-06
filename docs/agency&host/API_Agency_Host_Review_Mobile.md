# Agency Host Review & Access Control — API Specification (Mobile)

**Document version:** 1.0  
**Last updated:** 2026-06-06  
**Mobile app:** qobo_one_live (Flutter)  
**Audience:** Backend & Mobile Teams  

This document defines APIs needed for **agency owners** to review host applications, accept or reject them, and view their comprehensive host lists.

---

## 1. General conventions

| Item | Value |
|------|--------|
| Auth | **Bearer token** (logged-in agency owner) |
| Envelope | `{ statusCode, message, data }` |
| `statusCode: 1` | Success |
| `statusCode: 0` | Business failure |

---

## 2. API Endpoints

### 2.1 List pending host applications

**`GET /api/agency/host-applications`**

| | |
|--|--|
| **Auth** | Bearer token |
| **Purpose** | Agency owner lists applications |

#### Query parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| `status` | string | No | `pending`, `active`, `rejected`, `all`. (Default: `pending`) |
| `page` | int | No | Default `1` |
| `limit` | int | No | Default `20` |

#### Success — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Host applications fetched",
  "data": {
    "agencyId": "uuid...",
    "agencyCode": "STAR01",
    "total": 1,
    "applications": [
      {
        "applicationId": "uuid...",
        "hostId": null,
        "hostName": "Priya Sharma",
        "phone": "9876543210",
        "gmail": "priya@gmail.com",
        "category": "video",
        "dob": "1998-06-02T00:00:00.000Z",
        "idNo": "ABCD1234",
        "photo": "https://qobo1live.com/uploads/...",
        "agencyCode": "STAR01",
        "status": "pending",
        "reason": null,
        "coinsPerSecond": 5,
        "createdAt": "2026-06-05T10:02:44.799Z",
        "updatedAt": "2026-06-05T10:02:44.799Z"
      }
    ]
  }
}
```

---

### 2.2 Get single host application detail

**`GET /api/agency/host-applications/{id}`**

| | |
|--|--|
| **Auth** | Bearer token |
| **Purpose** | Full detail when owner taps one pending host |

#### Success — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Host application fetched",
  "data": {
    "applicationId": "uuid...",
    "hostId": "HOST-1002",
    "hostName": "Parth Host",
    "phone": "9876543210",
    "gmail": "parth@gmail.com",
    "category": "audio",
    "dob": "1999-03-10T00:00:00.000Z",
    "idNo": "ID998877",
    "photo": "https://qobo1live.com/uploads/...",
    "agencyId": "uuid...",
    "agencyCode": "STAR01",
    "status": "pending",
    "reason": null,
    "coinsPerSecond": 5,
    "totalEarnings": 0,
    "totalGifts": 0,
    "totalCallingSpend": 0,
    "callingMinutes": 0,
    "lastViewer": null,
    "createdAt": "2026-06-05T10:02:44.799Z",
    "updatedAt": "2026-06-05T10:02:44.799Z",
    "reviewedAt": null,
    "reviewedBy": null
  }
}
```

---

### 2.3 Approve host application

**`POST /api/agency/host-applications/{id}/approve`**

| | |
|--|--|
| **Auth** | Bearer token |
| **Purpose** | Agency owner accepts host, instantly auto-creating User record |

#### Request body

```json
{
  "coins_per_second": 5,
  "note": "Welcome to the agency"
}
```

#### Success — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Host application approved",
  "data": {
    "applicationId": "uuid...",
    "hostId": "uuid... (Generated User ID)",
    "hostName": "Priya Sharma",
    "status": "active",
    "coinsPerSecond": 5,
    "approvedAt": "2026-06-05T12:00:00.000Z"
  }
}
```

---

### 2.4 Reject host application

**`POST /api/agency/host-applications/{id}/reject`**

| | |
|--|--|
| **Auth** | Bearer token |
| **Purpose** | Agency owner rejects pending host |

#### Request body

```json
{
  "reason": "Photo does not meet verification requirements"
}
```

*(Note: `reason` is **required**.)*

#### Success — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Host application rejected",
  "data": {
    "applicationId": "uuid...",
    "hostName": "Priya Sharma",
    "status": "rejected",
    "reason": "Photo does not meet verification requirements",
    "rejectedAt": "2026-06-05T12:05:00.000Z"
  }
}
```

---

### 2.5 Updated `host-list` filtering

**`GET /api/agency/host-list?status=all`**

| Query Param | Required | Notes |
|-------------|----------|-------|
| `status` | No | `pending`, `active`, `approved`, `all` (Default: `all`) |

Returns the array of mapped hosts matching the requested status.

---

### 2.6 Updated `dashboard`

**`GET /api/agency/dashboard`**

The `summary` object now contains `pendingHostApplications` count.
The root object now contains a `pendingApplications` array (max length 3) for quick preview:

```json
{
  "statusCode": 1,
  "data": {
    "summary": {
      "pendingHostApplications": 3
    },
    "pendingApplications": [
      {
        "applicationId": "uuid...",
        "hostName": "Priya Sharma",
        "photo": "https://qobo1live.com/uploads/...",
        "status": "pending",
        "createdAt": "2026-06-05T10:02:44.799Z"
      }
    ]
  }
}
```
