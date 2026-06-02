# 🧪 Qobo One Live — Client Testing Guide

This document lists the exact features and flows that are **100% Fully Integrated and Working Perfectly** (connected end-to-end to the backend API). These are the parts of the mobile app you can confidently test today with real data.

> **Note to Client / Tester:**
> Features not on this list (e.g., Wallet Checkout, PK Battles, Call Swiping) have premium UI screens designed, but are using simulated "mock" data to show you how they will feel before the backend connects.

---

## ✅ 1. Authentication & Security Flows
*All login and registration routes are fully secure and store live session tokens.*

*   **Email & Password Login:** Test logging in with an existing account.
*   **Sign-Up / Registration:** Test creating a brand new account using the email & password form.
*   **Google Sign-In:** Test the one-tap Google login/registration button.
*   **Facebook Sign-In:** Test the Facebook native login overlay.
*   **Phone OTP Login:** Request an SMS OTP to a phone number and log in instantly without a password.
*   **Forgot Password:** Test the forgot password recovery flow (Request OTP via phone -> Verify OTP -> Set New Password).

## ✅ 2. Profile Management
*Any changes made here are saved to the backend database instantly.*

*   **Upload Profile Avatar:** Tap the profile picture placeholder to open the gallery/camera, crop a photo, and upload it to the server.
*   **Update Personal Details:** Change your Nickname, Gender, and use the custom scrolling wheel to update your Date of Birth.
*   **Upload Profile Poster:** In your profile settings, click the "Upload Poster" button to apply a custom horizontal background image to your profile banner.
*   **Entrance Patti Display:** View the entrance styles and level ribbons on the profile header.

## ✅ 3. Discovery & Social Engine
*Real-time interactions with other users on the platform.*

*   **Live User Search:** In the Discover Tab, click the search bar. As you type a username, it actively queries the server and displays matching users.
*   **Follow / Unfollow System:** On the search results screen, tap the "Follow" or "Following" button next to a user. It instantly synchronizes this relationship with the backend.

## ✅ 4. Live Room Creation
*Creating real broadcasting spaces on the server.*

*   **Go Live Configuration:** Tap the red Heart/Live Center button. Select between **Audio Live** and **Video Live**.
*   **Create Room Instance:** Configure the room title and select maximum seat limits (4, 8, etc.). Tapping "Go Live" officially registers this room in the backend database and transitions you to host view.

## ✅ 5. Agency Operations
*Real forms submitted directly to the agency management systems.*

*   **Host Onboarding Application:** Click the "Agency Host Onboarding" banner in the Discover tab. Fill out your legal name, WhatsApp number, select a category, and upload your real verification portrait photo. Submit the application to the backend.
*   **Host Application Status:** Enter your phone number and Application ID to query the server and see whether your application is `PENDING`, `APPROVED`, or `REJECTED`.

---

**End of Testable Features List**
*If you find any bugs within these specific flows, please log them as they are considered production-ready. All other screens are awaiting their backend endpoints to be finalized!*
