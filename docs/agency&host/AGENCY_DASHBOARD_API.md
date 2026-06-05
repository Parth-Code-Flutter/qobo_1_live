# Agency Owner Dashboard — API Specification (Mobile)

**Document version:** 1.0  
**Last updated:** 2026-06-02  
**Mobile app:** qobo_one_live (Flutter)  
**Primary screens:** `AgencyOwnerDashboardView` (`/agency-owner`), `AgencyRevenueView` (`/agency-revenue`), heart-tab host map  

Share this file with the backend team. It describes request/response contracts needed to replace current **demo/mock** data in the agency owner dashboard.

---

## 1. General conventions

### Authentication

| Audience | Auth |
|----------|------|
| Agency owner APIs | **Bearer token** (normal app user login). No separate agency password. |
| Host onboarding / status | Public (no token) — documented in `README.md`, not repeated here. |

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

**HTTP status codes:** Use `200` / `201` for success. Use `401` / `403` / `404` for auth and not-found. **Do not return HTTP 500** for cases like “user has no agency” or “application not found”.

### IDs and dates

- `agency_id`, `ownerId`, host `id`: UUID strings.
- `month` query param: **`YYYY-MM`** (e.g. `2026-06`). Mobile can send current month if omitted on optional endpoints.

---

## 2. Revenue & commission rules (product)

These rules match the current mobile **demo** (agency **Fun Call**, owner **Jitendra Joshi**). Backend should implement the same logic for live data.

| Rule | Description |
|------|-------------|
| Call billing | `grossCoins = hostCoinsPerSecond × durationSeconds` |
| Call revenue split | **50% platform (company)**, **50% host** of call gross |
| Owner commission | `ownerCoinsPerSecond × totalTalkSeconds` summed across all agency calls in the period |
| Gifts | Gift coin volume tracked separately; included in agency totals |
| **Total agency earnings** (dashboard hero) | `hostCallShare + totalGiftsVolume + ownerCommissionCoins` |

### Example call (reference)

| Field | Value |
|-------|-------|
| Host | Monika @ 5 coins/sec |
| Viewer | Parth |
| Duration | 300 sec (5 min) |
| Gross | 1,500 |
| Company share | 750 |
| Host share | 750 |
| Gifts during call | 120 |

### Example agency month (reference)

| Metric | Coins |
|--------|-------|
| Total calling gross | 2,700 |
| Company share | 1,350 |
| Host call share | 1,350 |
| Owner commission (2 coins/sec × 540 sec talk) | 1,080 |
| Gifts volume | 730 |
| **Total agency earnings** | 3,160 |
| Available for payout | 2,840 |
| Active hosts | 2 |

---

## 3. Recommended: single dashboard endpoint

**Preferred for mobile:** one request when the owner opens the dashboard (and to refresh).

### `GET /api/agency/dashboard`

| | |
|--|--|
| **Method** | `GET` |
| **Auth** | Bearer token |
| **Purpose** | Full owner dashboard: agency info, owner info, monthly summary, latest call, host list, recruit link |

#### Query parameters

| Parameter | Type | Required | Example | Notes |
|-----------|------|----------|---------|-------|
| `agency_id` | string (UUID) | Yes* | `8f3c2a1b-...` | From register response or owner session |
| `month` | string | No | `2026-06` | Defaults to current month |

\*If the authenticated user owns exactly one agency, backend may resolve `agency_id` from the token and treat the query param as optional.

#### Request example

```http
GET /api/agency/dashboard?agency_id=8f3c2a1b-xxxx-xxxx-xxxx&month=2026-06
Authorization: Bearer <user_jwt>
Accept: application/json
```

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
      "totalTalkMinutes": 9,
      "totalCallingGross": 2700,
      "companyShare": 1350,
      "hostCallShare": 1350,
      "ownerCommissionCoins": 1080,
      "totalGiftsVolume": 730,
      "pendingCommissionCount": 2,
      "payoutStatus": "ready"
    },
    "latestCall": {
      "hostName": "Monika",
      "viewerName": "Parth",
      "durationSeconds": 300,
      "coinsPerSecond": 5,
      "grossCoins": 1500,
      "companyCoins": 750,
      "hostCoins": 750,
      "giftsDuringCall": 120
    },
    "hosts": [
      {
        "id": "HOST-1001",
        "name": "Monika",
        "status": "active",
        "photo": "https://cdn.example.com/monika.jpg",
        "coinsPerSecond": 5,
        "totalEarnings": 1170,
        "totalGifts": 420,
        "totalCallingSpend": 1500,
        "callingMinutes": 5,
        "lastViewer": "Parth"
      },
      {
        "id": "HOST-1002",
        "name": "Jui",
        "status": "active",
        "photo": "https://cdn.example.com/jui.jpg",
        "coinsPerSecond": 5,
        "totalEarnings": 890,
        "totalGifts": 310,
        "totalCallingSpend": 1200,
        "callingMinutes": 4,
        "lastViewer": "Parth"
      }
    ],
    "recruitLink": "https://qobo1live.com/recruit?agency=FUN-CALL-01"
  }
}
```

#### Field reference — `data` object

| JSON path | Type | UI usage |
|-----------|------|----------|
| `agency.id` | string | Stored in app session |
| `agency.name` | string | Dashboard header |
| `agency.code` | string | Dashboard header chip |
| `agency.status` | string | `active` / `suspended` |
| `agency.commissionRate` | number | e.g. `0.1` = 10% |
| `owner.name` | string | Owner card |
| `owner.coinsPerSecond` | int | Owner rate label |
| `summary.totalAgencyEarnings` | int | Hero “Total agency earnings” |
| `summary.availableForPayout` | int | “Payout ready” |
| `summary.activeHosts` | int | “Active hosts” |
| `summary.companyShare` | int | Revenue split bar |
| `summary.hostCallShare` | int | Revenue split bar “Hosts (calls)” |
| `summary.ownerCommissionCoins` | int | Revenue split bar “Owner commission” |
| `summary.totalGiftsVolume` | int | Revenue split bar “Gifts volume” |
| `latestCall` | object | Sample / latest call card |
| `hosts[]` | array | Host carousel; also **heart-tab host map** |
| `recruitLink` | string | Recruit quick action (optional if separate generate-link is used) |

#### Error responses

**User has no agency / wrong owner — `403` or `404`:**

```json
{
  "statusCode": 0,
  "message": "Agency not found or access denied",
  "data": null
}
```

**Invalid month — `400`:**

```json
{
  "statusCode": 0,
  "message": "Invalid month format. Use YYYY-MM.",
  "data": null
}
```

---

## 4. Alternative: existing endpoints (if dashboard API is delayed)

Mobile can call these **three** endpoints after login + register. Paths already exist in the mobile repo (`lib/repo/agency/agency_repo.dart`).

### 4.1 Register agency

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `/api/agency/register` |
| **Auth** | Bearer token |

**Request body:**

```json
{
  "agency_name": "Fun Call"
}
```

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

**Optional future fields** (UI collects but not required for v1):

```json
{
  "agency_name": "Fun Call",
  "owner_name": "Jitendra Joshi",
  "owner_whatsapp": "+91...",
  "logo_url": "https://..."
}
```

---

### 4.2 Host list

| | |
|--|--|
| **Method** | `GET` |
| **URL** | `/api/agency/host-list?agency_id={uuid}` |
| **Auth** | Bearer token |

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
      "category": "Music",
      "status": "approved",
      "coinsPerSecond": 5,
      "totalGifts": 420,
      "totalEarnings": 1170,
      "totalCallingSpend": 1500,
      "callingMinutes": 5,
      "lastViewer": "Parth",
      "createdAt": "2026-06-01T00:00:00.000Z"
    }
  ]
}
```

**Notes for backend:**

- Map application status `approved` → mobile displays as **`active`**.
- Fields marked **required for dashboard UI**: `coinsPerSecond`, `totalCallingSpend`, `callingMinutes`, `lastViewer`, `photo`, `totalEarnings`, `totalGifts`.

**Empty list:**

```json
{
  "statusCode": 1,
  "message": "Host list fetched",
  "data": []
}
```

---

### 4.3 Revenue stats (dashboard + revenue screen)

| | |
|--|--|
| **Method** | `GET` |
| **URL** | `/api/agency/revenue?agency_id={uuid}&month={YYYY-MM}` |
| **Auth** | Bearer token |

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
    "totalCallingGross": 2700,
    "companyShare": 1350,
    "hostCallShare": 1350,
    "ownerCommissionCoins": 1080,
    "availableForPayout": 2840,
    "totalEarnedCommissions": 1080,
    "pendingCommissionAmount": 1200,
    "pendingCommissionCount": 2,
    "hostsCount": 2,
    "payoutStatus": "ready",
    "owner": {
      "name": "Jitendra Joshi",
      "coinsPerSecond": 2
    },
    "latestCall": {
      "hostName": "Monika",
      "viewerName": "Parth",
      "durationSeconds": 300,
      "coinsPerSecond": 5,
      "grossCoins": 1500,
      "companyCoins": 750,
      "hostCoins": 750,
      "giftsDuringCall": 120
    },
    "history": [
      {
        "date": "2026-06-04",
        "title": "Call — Monika × Parth",
        "amount": 1500,
        "amountLabel": "+1,500",
        "subtitle": "5 min · 5 coins/sec · 750 host / 750 company",
        "type": "call"
      },
      {
        "date": "2026-06-03",
        "title": "Gifts — Monika",
        "amount": 420,
        "amountLabel": "+420",
        "subtitle": "Viewer gifts during live",
        "type": "gift"
      },
      {
        "date": "2026-06-02",
        "title": "Call — Jui × Parth",
        "amount": 1200,
        "amountLabel": "+1,200",
        "subtitle": "4 min · 5 coins/sec · 600 host / 600 company",
        "type": "call"
      },
      {
        "date": "2026-06-01",
        "title": "Owner commission",
        "amount": 1080,
        "amountLabel": "+1,080",
        "subtitle": "2 coins/sec on agency talk time",
        "type": "owner"
      }
    ]
  }
}
```

**`history[].type` enum:** `call` | `gift` | `owner` | `payout`

**`payoutStatus` examples:** `ready` | `pending` | `paid` | `action_required`

---

### 4.4 Generate recruitment link

| | |
|--|--|
| **Method** | `GET` |
| **URL** | `/api/agency/generate-link?agency_id={uuid}` |
| **Auth** | Bearer token |

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

### 4.5 Request payout

| | |
|--|--|
| **Method** | `POST` |
| **URL** | `/api/agency/payout` |
| **Auth** | Bearer token |

**Request body (recommended):**

```json
{
  "agency_id": "8f3c2a1b-xxxx-xxxx-xxxx",
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

---

## 5. Mobile screen → API mapping

| User action | Screen | API |
|-------------|--------|-----|
| Open Agency Owner Dashboard | `/agency-owner` | `GET /api/agency/dashboard` **or** `host-list` + `revenue` |
| Pull to refresh dashboard | `/agency-owner` | Same as above |
| Tap **Revenue** | `/agency-revenue` | `GET /api/agency/revenue?month=` |
| Change month on revenue | `/agency-revenue` | `GET /api/agency/revenue?month=` |
| Tap **Recruit link** | `/agency-recruit-link` | `GET /api/agency/generate-link` |
| Tap **Hosts** / host card | Heart tab map | Uses `hosts[]` from dashboard (no extra API if cached) |
| Tap **Request payout** | `/agency-revenue` | `POST /api/agency/payout` |
| First-time owner | Register flow | `POST /api/agency/register` |

---

## 6. TypeScript-style schema (quick reference)

```typescript
interface ApiEnvelope<T> {
  statusCode: 0 | 1;
  message: string;
  data: T | null;
}

interface AgencyDashboardData {
  agency: {
    id: string;
    name: string;
    code: string;
    status: "active" | "suspended";
    commissionRate: number;
  };
  owner: {
    id: string;
    name: string;
    coinsPerSecond: number;
  };
  month: string; // YYYY-MM
  summary: {
    totalAgencyEarnings: number;
    availableForPayout: number;
    activeHosts: number;
    totalTalkMinutes: number;
    totalCallingGross: number;
    companyShare: number;
    hostCallShare: number;
    ownerCommissionCoins: number;
    totalGiftsVolume: number;
    pendingCommissionCount: number;
    payoutStatus: string;
  };
  latestCall: CallSample | null;
  hosts: AgencyHost[];
  recruitLink?: string;
}

interface AgencyHost {
  id: string;
  name: string;
  status: "active" | "inactive";
  photo: string;
  coinsPerSecond: number;
  totalEarnings: number;
  totalGifts: number;
  totalCallingSpend: number;
  callingMinutes: number;
  lastViewer: string;
}

interface CallSample {
  hostName: string;
  viewerName: string;
  durationSeconds: number;
  coinsPerSecond: number;
  grossCoins: number;
  companyCoins: number;
  hostCoins: number;
  giftsDuringCall: number;
}

interface RevenueHistoryLine {
  date: string;       // ISO date or display date
  title: string;
  amount: number;
  amountLabel: string;  // e.g. "+1,500"
  subtitle: string;
  type: "call" | "gift" | "owner" | "payout";
}
```

---

## 7. Agency owner status — what exists in `Qobo1live_API_Documentation` (mobile integrated)

**Checked against:** `Qobo1live_API_Documentation (1).docx` (section 7 — `/api/agency`).

| Endpoint in doc | Exists? | Used for agency owner status? |
|-----------------|---------|-------------------------------|
| `POST /api/agency/register` | Yes | **Submit** agency (body: `agency_name` only) |
| `GET /api/agency/revenue?month=YYYY-MM` | Yes | **Check** if logged-in user has an active agency |
| `GET /api/agency/host-verify-status` | Yes | **Host onboarding only** — not agency owner |
| `POST /api/agency/apply` | **No** | — |
| `GET /api/agency/application-status` | **No** | — |

### 7.1 Mobile integration (current app)

| User action | API called |
|-------------|------------|
| Apply / register agency | `POST /api/agency/register` with `{ "agency_name": "..." }` |
| Check agency status (owner screen) | `GET /api/agency/revenue?month=2026-06` (Bearer). Success → agency active → dashboard unlocked |
| Check host application status | `GET /api/agency/host-verify-status` (separate screen `/agency-host-status`) |

If `register` fails or revenue returns no agency, the app keeps a **local pending** reference ID until backend adds a real application-status API.

### 7.2 Backend request — add agency application status (recommended)

For super-admin approval flow, backend should add:

```http
POST /api/agency/apply
GET /api/agency/application-status?application_id=...|phone=...|me=1
```

Until then, mobile uses **register + revenue** only.

### 7.3 Register agency (documented)

```http
POST /api/agency/register
Authorization: Bearer <token>
Content-Type: application/json

{ "agency_name": "Fun Call" }
```

**Success (typical):**

```json
{
  "statusCode": 1,
  "message": "Agency registered successfully",
  "data": {
    "id": "uuid",
    "name": "Fun Call",
    "code": "FUN01",
    "commissionRate": 0.1,
    "status": "active"
  }
}
```

### 7.4 Check active agency via revenue (documented)

```http
GET /api/agency/revenue?month=2026-06
Authorization: Bearer <token>
```

**Success** → user owns an agency (`agencyCode`, `commissionRate`, etc. in `data`).

**Failure / not found** → no agency for this account (mobile shows pending or not registered).

---

## 8. Open questions for backend

| # | Question |
|---|----------|
| 1 | Will you ship **`GET /api/agency/dashboard`** or should mobile combine `host-list` + `revenue`? |
| 2 | Confirm **`month`** format: `YYYY-MM` only? |
| 3 | Is **`owner.coinsPerSecond`** fixed per agency or per user profile? |
| 4 | Should **`POST /api/agency/register`** accept `owner_name`, WhatsApp, logo? |
| 5 | **`POST /api/agency/payout`**: minimum amount, idempotency, async job? |
| 6 | Confirm all agency routes use the same **`{ statusCode, message, data }`** envelope. |
| 7 | When admin approves a host, should backend auto-link a **live host user account**? |

---

## 9. Related mobile files (for engineers)

| Area | Path |
|------|------|
| Demo data (replace with API) | `lib/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart` |
| Dashboard controller | `lib/app/user_flow/agency_owner_dashboard/controllers/agency_owner_dashboard_controller.dart` |
| Revenue controller | `lib/app/user_flow/agency_revenue/controllers/agency_revenue_controller.dart` |
| API repo | `lib/repo/agency/agency_repo.dart` |
| Endpoints | `lib/services/api_constants.dart` → `AgencyEndpoints` |
| Agency session state | `lib/services/agency_session_controller.dart` |
| Agency application status UI | `lib/app/user_flow/agency_owner_status/` |
| Broader agency flow | `docs/agency&host/README.md` |

---

**Contact:** Mobile team will bind APIs in `AgencyRepo` once contracts are confirmed. Prefer announcing breaking changes to `data` shape before production deploy.
