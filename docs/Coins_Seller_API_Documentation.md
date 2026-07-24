# Coins Seller Module - API Documentation

This document describes the API endpoints required for the **Coins Seller Portal** within the mobile application. These APIs allow independent sellers (merchants) to log in, view their inventory, and distribute coins to end-users.

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

---

## 2. Seller Dashboard Data
Fetches the seller's current coin balance, aggregate sales metrics, and transaction history.
* **Method**: `GET`
* **Endpoint**: `/api/admin/seller-portal/dashboard`
* **Auth**: Seller JWT Token (`Authorization: Bearer <token>`)
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

---

## 3. Sell Coins to User
Transfers coins from the seller's stock to a user's wallet. The backend handles the ledger math to ensure the seller has enough stock.
* **Method**: `POST`
* **Endpoint**: `/api/admin/seller-portal/sell`
* **Auth**: Seller JWT Token (`Authorization: Bearer <token>`)
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

*Note: The `userId` field can accept the user's UUID, their registered Email address, or Phone Number.*
