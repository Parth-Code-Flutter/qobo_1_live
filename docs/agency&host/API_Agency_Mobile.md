# Agency Owner Dashboard — API Specification (Mobile)

**Document version:** 1.0  
**Last updated:** 2026-06-04  
**Mobile app:** qobo_one_live (Flutter)  

This file describes request/response contracts for the Agency Owner Dashboard.

---

## 1. General conventions

### Authentication

| Audience | Auth |
|----------|------|
| Agency owner APIs | **Bearer token** (normal app user login). No separate agency password. |

### Response envelope (all agency endpoints)

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
| `0` | Business failure (empty data, not found, validation, etc.) |

**HTTP status codes:** `200` / `201` for success. `401` / `403` / `404` for auth and not-found.

### IDs and dates

- `month` query param: **`YYYY-MM`** (e.g. `2026-06`). Mobile can send current month if omitted on optional endpoints.

---

## 2. API Endpoints

### 2.1 Full Dashboard (Recommended for Mobile)

**`GET /api/agency/dashboard`**

| | |
|--|--|
| **Auth** | Bearer token |
| **Purpose** | Full owner dashboard: agency info, owner info, monthly summary, latest call, host list, recruit link |

#### Query parameters

| Parameter | Type | Required | Example | Notes |
|-----------|------|----------|---------|-------|
| `month` | string | No | `2026-06` | Defaults to current month |

#### Success response — `200 OK`

```json
{
  "statusCode": 1,
  "message": "Agency dashboard fetched",
  "data": {
    "agency": {
      "id": "8f3c2a1b-xxxx-xxxx-xxxx",
      "name": "Fun Call",
      "code": "FUN-CALL-01",
      "status": "active",
      "commissionRate": 0.1
    },
    "owner": {
      "id": "user-uuid",
      "name": "Jitendra Joshi",
      "coinsPerSecond": 2
    },
    "month": "2026-06",
    "summary": {
      "totalAgencyEarnings": 3160,
      "availableForPayout": 2840,
      "activeHosts": 2,
      "totalTalkMinutes": 0,
      "totalCallingGross": 0,
      "companyShare": 0,
      "hostCallShare": 0,
      "ownerCommissionCoins": 1080,
      "totalGiftsVolume": 730,
      "pendingCommissionCount": 2,
      "payoutStatus": "ready"
    },
    "latestCall": null,
    "hosts": [
      {
        "id": "HOST-1001",
        "name": "Monika",
        "status": "active",
        "photo": "https://cdn.example.com/monika.jpg",
        "coinsPerSecond": 5,
        "totalEarnings": 1170,
        "totalGifts": 420,
        "totalCallingSpend": 0,
        "callingMinutes": 0,
        "lastViewer": "Unknown"
      }
    ],
    "recruitLink": "https://qobo1live.com/recruit?agency=FUN-CALL-01"
  }
}
```

---

### 2.2 Register agency

**`POST /api/agency/register`**

**Request body:**

```json
{
  "agency_name": "Fun Call",
  "owner_name": "Jitendra Joshi",
  "owner_whatsapp": "+91...",
  "logo_url": "https://..."
}
```
*(All fields except `agency_name` are optional).*

**Success — `201 Created`:**

```json
{
  "statusCode": 1,
  "message": "Agency registered successfully",
  "data": {
    "id": "8f3c2a1b-xxxx-xxxx-xxxx",
    "name": "Fun Call",
    "ownerId": "user-uuid",
    "code": "FUN-CALL-01",
    "commissionRate": 0.1,
    "status": "active"
  }
}
```

---

### 2.3 Host list

**`GET /api/agency/host-list?agency_id={uuid}`**

**Success — `200 OK`:**

```json
{
  "statusCode": 1,
  "message": "Host list fetched",
  "data": [
    {
      "id": "HOST-1001",
      "name": "Monika",
      "phone": "9876543210",
      "gmail": "monika@gmail.com",
      "photo": "https://cdn.example.com/photo.jpg",
      "category": "General",
      "status": "active",
      "coinsPerSecond": 5,
      "totalGifts": 420,
      "totalEarnings": 1170,
      "totalCallingSpend": 0,
      "callingMinutes": 0,
      "lastViewer": "Unknown",
      "createdAt": "2026-06-01T00:00:00.000Z"
    }
  ]
}
```

---

### 2.4 Revenue stats

**`GET /api/agency/revenue?month={YYYY-MM}`**

**Success — `200 OK`:**

```json
{
  "statusCode": 1,
  "message": "Revenue stats fetched",
  "data": {
    "month": "2026-06",
    "agencyCode": "FUN-CALL-01",
    "commissionRate": 0.1,
    "totalRevenue": 3160,
    "totalGifts": 730,
    "totalCallingGross": 0,
    "companyShare": 0,
    "hostCallShare": 0,
    "ownerCommissionCoins": 1080,
    "availableForPayout": 2840,
    "totalEarnedCommissions": 1080,
    "pendingCommissionAmount": 2840,
    "pendingCommissionCount": 2,
    "hostsCount": 2,
    "payoutStatus": "ready",
    "owner": {
      "name": "Jitendra Joshi",
      "coinsPerSecond": 2
    },
    "latestCall": null,
    "history": [
      {
        "date": "2026-06-01",
        "title": "Owner commission",
        "amount": 1080,
        "amountLabel": "+1080",
        "subtitle": "Commission on agency talk time",
        "type": "owner"
      }
    ]
  }
}
```

---

### 2.5 Generate recruitment link

**`GET /api/agency/generate-link?agency_id={uuid}`**

**Success — `200 OK`:**

```json
{
  "statusCode": 1,
  "message": "Recruitment link generated",
  "data": {
    "link": "https://qobo1live.com/recruit?agency=FUN-CALL-01",
    "code": "FUN-CALL-01"
  }
}
```

---

### 2.6 Request payout

**`POST /api/agency/payout`**

**Request body:**

```json
{
  "amount": 2840
}
```

**Success — `200 OK`:**

```json
{
  "statusCode": 1,
  "message": "Payout request submitted",
  "data": {
    "payoutId": "payout-uuid",
    "amount": 2840,
    "status": "pending",
    "processedCount": 2
  }
}
```

**Insufficient balance:**

```json
{
  "statusCode": 0,
  "message": "Insufficient available balance for payout",
  "data": null
}
```
