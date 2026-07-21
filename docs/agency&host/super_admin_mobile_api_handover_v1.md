# Super Admin — Mobile API Handover & Specification Guide (v1.1)

**Document version:** 1.1  
**Last updated:** 2026-07-21  
**Mobile App:** `qobo_one_live` (Flutter)  
**Status:** **Fully Implemented & Live in Backend**  
**Role Required:** `super_admin`

---

## 1. Response Envelope Standard

All endpoints follow the requested standardized response format:

```json
{
  "statusCode": 1,
  "message": "Human-readable response message",
  "data": {}
}
```

* **`statusCode == 1`**: Request succeeded.
* **`statusCode == 0`**: Business logic exception (e.g. Record not found, invalid role, or validation error).

---

## 2. API Endpoint Matrix

| Priority | Method | Endpoint | Description |
|---|---|---|---|
| **P0** | `GET` | `/api/super-admin/agencies/:agencyId` | Fetch single agency details for onClick screen |
| **P0** | `GET` | `/api/super-admin/hosts/:hostId` | Fetch single host profile & earnings for onClick screen |
| **P1** | `GET` | `/api/super-admin/agencies/:agencyId/hosts` | List hosts belonging to a specific agency |
| **P1** | `GET` | `/api/super-admin/agencies` | List agencies (supports `status`, `search`, `page`, `limit`) |
| **P1** | `GET` | `/api/super-admin/hosts/track` | Track hosts globally (supports `status`, `agencyCode`, `search`, `page`, `limit`, `sortBy`, `sortOrder`) |
| **P1** | `POST` | `/api/super-admin/agency/process` | Update agency status (`approved`, `rejected`, `suspended`, `active`) |
| **P1** | `POST` | `/api/super-admin/hosts/:hostId/status` | Suspend or reactivate a host (`active`, `suspended`, `inactive`) |
| **P2** | `PATCH` | `/api/super-admin/agencies/:agencyId/commission` | Update agency commission rate |
| **P2** | `GET` | `/api/super-admin/dashboard` | Dashboard analytics with live metrics & top agency highlights |
| **P2** | `GET` | `/api/super-admin/agency/generate-link` | Generate recruitment WhatsApp link |

---

## 3. Priority P0: Detail Endpoints

### 3.1 Get Agency Detail (`GET /api/super-admin/agencies/:agencyId`)

* **Headers**: `Authorization: Bearer <super_admin_token>`
* **Response (`200 OK`)**:
  ```json
  {
    "statusCode": 1,
    "message": "Agency details fetched successfully",
    "data": {
      "id": "agency-uuid-1",
      "name": "Superstar Agency Ltd",
      "code": "XYZ890",
      "logo": "https://my-backend-api-960q.onrender.com/uploads/...",
      "commissionRate": 0.10,
      "status": "approved",
      "feedback": null,
      "createdAt": "2026-07-18T10:15:30.000Z",
      "updatedAt": "2026-07-18T12:00:00.000Z",
      "address": {
        "country": "India",
        "state": "Gujarat",
        "city": "Ahmedabad",
        "fullAddress": "123 Business Hub"
      },
      "owner": {
        "id": "owner-user-id",
        "name": "John Doe",
        "email": "john@staragency.com",
        "phone": "+1234567890",
        "countryCode": "+91",
        "displayPicture": "https://my-backend-api-960q.onrender.com/uploads/...",
        "role": "agency"
      },
      "documents": {
        "docPhotoFront": "https://my-backend-api-960q.onrender.com/uploads/...",
        "docPhotoBack": "https://my-backend-api-960q.onrender.com/uploads/..."
      },
      "stats": {
        "hostCount": 12,
        "pendingHostsCount": 2,
        "activeHostsCount": 10,
        "totalCommissionEarned": 4500.5,
        "totalDiamonds": 0,
        "totalCoins": 0
      },
      "invitedBy": {
        "id": "super-admin-user-id",
        "name": "Super Admin Name",
        "email": "superadmin@qobo.com"
      }
    }
  }
  ```

---

### 3.2 Get Host Detail (`GET /api/super-admin/hosts/:hostId`)

* **Headers**: `Authorization: Bearer <super_admin_token>`
* **Response (`200 OK`)**:
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
      "displayPicture": "https://my-backend-api-960q.onrender.com/uploads/...",
      "role": "host",
      "status": "active",
      "category": "Singing",
      "dob": "1998-05-12T00:00:00.000Z",
      "gender": "female",
      "country": "India",
      "state": "Maharashtra",
      "city": "Mumbai",
      "address": "123 Street",
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
        "docPhotoFront": "https://my-backend-api-960q.onrender.com/uploads/...",
        "docPhotoBack": "https://my-backend-api-960q.onrender.com/uploads/...",
        "photo": "https://my-backend-api-960q.onrender.com/uploads/..."
      },
      "recentActivity": {
        "lastLiveAt": "2026-07-20T18:30:00.000Z",
        "isLiveNow": false,
        "totalSessions": 42
      }
    }
  }
  ```

---

## 4. Priority P1 & P2: Extended Management Endpoints

### 4.1 List Hosts Under Agency (`GET /api/super-admin/agencies/:agencyId/hosts`)

* **Query Params**: `status`, `page`, `limit`, `search`
* **Response (`200 OK`)**:
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
          "status": "approved",
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

### 4.2 Paginated Agency List (`GET /api/super-admin/agencies`)

* **Query Params**: `status` (`all` | `pending` | `approved` | `suspended`), `search`, `page`, `limit`
* **Response (`200 OK`)**:
  ```json
  {
    "statusCode": 1,
    "message": "Agencies list fetched successfully",
    "data": {
      "total": 5,
      "page": 1,
      "limit": 20,
      "agencies": [
        {
          "id": "agency-uuid-1",
          "name": "Superstar Agency Ltd",
          "code": "XYZ890",
          "commissionRate": 0.10,
          "status": "approved",
          "hostCount": 12,
          "pendingHostsCount": 2,
          "owner": {
            "id": "owner-user-id",
            "name": "John Doe",
            "email": "john@staragency.com",
            "displayPicture": "https://..."
          }
        }
      ]
    }
  }
  ```

---

### 4.3 Paginated Host Track List (`GET /api/super-admin/hosts/track`)

* **Query Params**: `status`, `agencyCode`, `search`, `page`, `limit`, `sortBy`, `sortOrder`
* **Response (`200 OK`)**:
  ```json
  {
    "statusCode": 1,
    "message": "Host tracking data fetched successfully",
    "data": {
      "total": 42,
      "page": 1,
      "limit": 20,
      "hosts": [
        {
          "id": "host-id",
          "name": "Host Display Name",
          "email": "host@gmail.com",
          "phone": "+1999999999",
          "displayPicture": "https://...",
          "agencyCode": "XYZ890",
          "diamonds": 450.0,
          "coins": 1200.0,
          "totalStreamSeconds": 36000.5,
          "totalCommissionEarned": 120.0,
          "status": "active"
        }
      ]
    }
  }
  ```

---

### 4.4 Update Host Status (`POST /api/super-admin/hosts/:hostId/status`)

* **Request Body**:
  ```json
  {
    "status": "suspended", // "active" | "suspended" | "inactive"
    "reason": "Policy violation"
  }
  ```
* **Response (`200 OK`)**:
  ```json
  {
    "statusCode": 1,
    "message": "Host status updated successfully",
    "data": {
      "id": "host-id",
      "status": "suspended",
      "reason": "Policy violation",
      "updatedAt": "2026-07-21T04:30:00.000Z"
    }
  }
  ```

---

### 4.5 Update Agency Commission Rate (`PATCH /api/super-admin/agencies/:agencyId/commission`)

* **Request Body**:
  ```json
  {
    "commissionRate": 0.12
  }
  ```
* **Response (`200 OK`)**:
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

### 4.6 Enhanced Dashboard Stats (`GET /api/super-admin/dashboard`)

* **Response (`200 OK`)**:
  ```json
  {
    "statusCode": 1,
    "message": "Dashboard stats fetched successfully",
    "data": {
      "totalAgencies": 5,
      "activeAgencies": 4,
      "suspendedAgencies": 1,
      "activeHosts": 42,
      "pendingAgencies": 2,
      "pendingHosts": 4,
      "liveHostsNow": 0,
      "totalCommissions": 12500.5,
      "commissionsThisMonth": 2100.25,
      "topAgencies": [],
      "recentPendingAgencies": []
    }
  }
  ```
