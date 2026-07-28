# Coins Seller Module — Mobile Integration Guide

**App:** qobo_one_live (Flutter)  
**Audience:** Mobile Developer  
**Date:** 2026-07-28

The backend for the **Coins Seller Portal** is fully developed. Below is the API contract and the expected mobile integration flow.

---

## 1. Seller Login

Authenticates a seller (merchant) and returns a secure access token.

* **Method**: `POST`
* **Endpoint**: `/api/admin/login`
* **Request Body**:

```json
{
  "email": "seller@example.com",
  "password": "SellerPassword123"
}
```

* **Response `200 OK`**:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt-token-string",
    "admin": {
      "id": "seller-uuid",
      "email": "seller@example.com",
      "role": "seller_admin",
      "coinsBalance": 15000
    }
  }
}
```

**Mobile requirement:** Build a secure entry / login screen for sellers. On success, save the seller JWT separately from the end-user token and navigate to the seller dashboard (isolated from the regular user app experience).

**App notes:**

* Seller token is stored via `LocalStorage.saveSellerSession` (`kStorageSellerToken` / `kStorageSellerAdmin`).
* Logout clears **only** the seller session — it does not wipe the end-user token.
* Seller API calls use `skipUnauthorizedHandling: true` so a seller 401 does not force end-user logout.

---

## 2. Seller Dashboard Data

Fetches the seller's current coin balance, aggregate sales metrics, and transaction history.

* **Method**: `GET`
* **Endpoint**: `/api/admin/seller-portal/dashboard`
* **Auth**: Seller JWT (`Authorization: Bearer <token>`)
* **Response `200 OK`**:

```json
{
  "success": true,
  "message": "Dashboard fetched successfully",
  "data": {
    "coinsBalance": 15000,
    "metrics": {
      "totalRevenue": 2500,
      "totalCoinsSold": 10000,
      "totalTransactions": 45
    },
    "recentSales": [
      {
        "id": "sale-uuid-1",
        "userId": "user-uuid",
        "amount": 500,
        "price": 100,
        "currency": "INR",
        "createdAt": "2026-07-24T12:00:00Z",
        "user": {
          "id": "user-uuid",
          "name": "John Doe",
          "email": "john@example.com",
          "displayPicture": "url-to-pic"
        }
      }
    ]
  }
}
```

**Mobile requirement:**

* Show current stock (`coinsBalance`) prominently at the top.
* Show summary metrics below it.
* List `recentSales` with user avatar, name, coins amount, price, and date.
* Support pull-to-refresh.

---

## 3. Sell Coins to User

Transfers coins from the seller's stock to a user's wallet. The backend deducts seller stock and credits the user wallet.

* **Method**: `POST`
* **Endpoint**: `/api/admin/seller-portal/sell`
* **Auth**: Seller JWT (`Authorization: Bearer <token>`)
* **Request Body**:

```json
{
  "userId": "user-uuid-or-email",
  "amount": 500,
  "price": 100
}
```

* **Response `200 OK`**:

```json
{
  "success": true,
  "message": "Coins transferred successfully",
  "data": {
    "id": "sale-uuid-new",
    "sellerId": "seller-uuid",
    "userId": "user-uuid",
    "amount": 500,
    "price": 100,
    "currency": "INR"
  }
}
```

**Notes:**

* `userId` may be the user's UUID, registered email, or phone number.
* On success: show a success animation, clear the form, and refresh dashboard data so `coinsBalance` reflects the new stock.

---

## Flutter mapping

| Concern | Location |
| --- | --- |
| Endpoints | `SellerPortalEndpoints` in `lib/services/api_constants.dart` |
| HTTP | `lib/repo/coin_seller/coin_seller_repo.dart` |
| Models | `lib/app/user_flow/coin_seller/models/` |
| UI / state | `CoinSellerView` / `CoinSellerController` |
| Route | `/coin-seller` (`AppRoutes.COIN_SELLER`) |

Response envelopes may use `success: true` **or** body `statusCode` of `1` / `200` / `201`. Models also accept common snake_case aliases (`coins_balance`, `recent_sales`, `display_picture`, etc.).
