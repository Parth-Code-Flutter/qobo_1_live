# API Endpoints Summary

Generated from `Qobo1live_API_Documentation.docx`.

## 1. POST /api/auth/login-phone

### Request
```json
{
"phone": "9876543210",
"country_code": "91"
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "OTP sent",
"data": {
"message": "OTP sent successfully",
"smsResult": { "return": true, "request_id": "..." }
}
}
```

## 2. POST /api/auth/verify-otp

### Request
```json
{
"phone": "9876543210",
"otp": "1234"
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "OTP verified successfully",
"data": {
"user": {
"id": "uuid",
"name": "string",
"phone": "9876543210",
"email": null,
"displayPicture": null,
"level": 1,
"vipLevel": 0,
"role": "USER",
"isOnline": false,
"country": null,
"bio": null,
"gender": null,
"dob": null,
"createdAt": "2026-04-28T00:00:00.000Z"
},
"token": "eyJhbGciOiJIUzI1NiIs..."
}
}
```

## 3. POST /api/auth/social

### Request
```json
{
"name": "John Doe",
"email": "john@gmail.com",
"phone": "9876543210",
"socialId": "google_uid_123",
"authType": "google",
"displayPicture": "https://..."
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "Login successful",
"data": {
"user": { "...user object..." },
"token": "eyJhbGciOiJIUzI1NiIs..."
}
}
```

## 4. POST /api/auth/firebase-login

### Request
```json
{
"idToken": "firebase_id_token_string"
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "Firebase login successful",
"data": {
"user": { "...user object..." },
"token": "eyJhbGciOiJIUzI1NiIs..."
}
}
```

## 5. GET /api/user/profile

### Request
_No request body mentioned._

### Success Response
```json
{
"statusCode": 1,
"message": "Profile fetched successfully",
"data": {
"id": "uuid",
"name": "John Doe",
"phone": "9876543210",
"email": "john@gmail.com",
"displayPicture": "/uploads/avatars/img.jpg",
"poster": "/uploads/posters/poster.jpg",
"level": 5,
"vipLevel": 2,
"role": "USER",
"isOnline": true,
"country": "IN",
"bio": "Hello world",
"gender": "male",
"dob": "1995-01-15T00:00:00.000Z",
"createdAt": "2026-01-01T00:00:00.000Z"
}
}
```

## 6. PUT /api/user/update

### Request
_No request body mentioned._

### Success Response
```json
{
"statusCode": 1,
"message": "Profile updated successfully",
"data": { "...updated user object..." }
}
```

## 7. POST /api/user/poster-upload

### Request
```json
{
"statusCode": 1,
"message": "Poster uploaded successfully",
"data": {
"posterUrl": "/uploads/posters/filename.jpg"
}
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "Search results",
"data": [
{ "id": "uuid", "name": "John", "displayPicture": "..." },
{ "id": "uuid", "name": "Johnny", "displayPicture": "..." }
]
}
```

## 8. POST /api/user/follow-unfollow

### Request
```json
{
"target_id": "user_uuid",
"action": "follow"
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "Successfully followed",
"data": { "...follow record..." }
}
```

## 9. GET /api/user/patti-style/:user_id

### Request
_No request body mentioned._

### Success Response
```json
{
"statusCode": 1,
"message": "Patti style fetched",
"data": { "...patti style object..." }
}
```

## 10. GET /api/economy/wallet

### Request
_No request body mentioned._

### Success Response
```json
{
"statusCode": 1,
"message": "Wallet fetched",
"data": {
"id": "uuid",
"userId": "uuid",
"coins": 5000,
"diamonds": 1200,
"beans": 300
}
}
```

## 11. POST /api/economy/send-gift

### Request
```json
{
"receiver_id": "user_uuid",
"gift_id": "gift_uuid",
"room_id": "room_uuid"
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "Gift sent successfully",
"data": {
"success": true,
"transactionId": "txn_uuid",
"luckyWin": false,
"rewardAmount": 0
}
}
```

## 12. GET /api/economy/gift-list

### Request
_No request body mentioned._

### Success Response
```json
{
"statusCode": 1,
"message": "Gifts fetched",
"data": [
{
"id": "uuid",
"name": "Rose",
"icon": "rose.png",
"price": 100,
"type": "normal",
"animationUrl": "rose_anim.json",
"soundUrl": null,
"winRate": null,
"categoryId": "uuid"
}
]
}
```

## 13. GET /api/economy/history

### Request
_No request body mentioned._

### Success Response
```json
{
"statusCode": 1,
"message": "History fetched",
"data": [
{
"id": "uuid",
"senderId": "uuid",
"receiverId": "uuid",
"amount": 500,
"type": "GIFT",
"status": "COMPLETED",
"createdAt": "2026-04-28T00:00:00.000Z"
}
]
}
```

## 14. POST /api/economy/recharge

### Request
```json
{
"statusCode": 1,
"message": "Application submitted successfully",
"data": { "...application object..." }
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "Current status",
"data": {
"status": "PENDING",
"createdAt": "2026-04-28T00:00:00.000Z"
}
}
```

## 15. GET /api/agency/revenue?month=2026-04

### Request
```json
{
"email": "admin@qobo1live.com",
"password": "password123"
}
```

### Success Response
```json
{
"statusCode": 1,
"message": "Dashboard statistics fetched",
"data": { "...stats object..." }
}
```
