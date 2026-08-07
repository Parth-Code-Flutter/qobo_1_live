# Qobo One Live — Client Working Checklist

**App:** Qobo One Live (Flutter)  
**Purpose:** Features that are working on the client app (ready to share with client)  
**Updated:** 7 Aug 2026

---

## Auth
- [x] Splash → login or home by token
- [x] Email / phone + password login
- [x] Google login
- [x] Facebook login
- [x] Sign up + OTP verify
- [x] Phone OTP login
- [x] Forgot password OTP + reset password
- [x] Onboarding profile update (avatar / details)
- [x] Country / state pickers
- [x] FCM push token register after login

## Discover
- [x] Discover user grid with country filter
- [x] User search
- [x] Follow / unfollow
- [x] Favourite / unfavourite
- [x] Public profile view + visit record
- [x] Message from Discover / profile
- [x] Active rooms shown on Discover

## Rooms (Audio / Video)
- [x] Bottom nav: Discover · Rooms · Go Live · Messages · Profile
- [x] Rooms list (audio + video)
- [x] Room filters (type / region / trending)
- [x] Create audio party room
- [x] Create video party room
- [x] Host Go Live (Zego)
- [x] Join live / party room (Zego)
- [x] Leave room / end room
- [x] In-room chat
- [x] Send / receive gifts in room
- [x] Audio seats + seat request / invite / respond
- [x] Mic mute / lock
- [x] Kick / room admin actions
- [x] Session earnings for host
- [x] Change room background
- [x] Share room link
- [x] Room PK (search / send / accept / status)
- [x] Audio follower PK battle
- [x] Join-request approve / reject
- [x] Push handlers for room invite / join request / PK

## Messages / Calls
- [x] Messages inbox
- [x] New Match / discover users strip
- [x] 1:1 chat (text)
- [x] Chat contact profile
- [x] Block / unblock user
- [x] Block list screen
- [x] 1:1 voice call (Zego)
- [x] 1:1 video call (Zego)
- [x] Incoming call handling
- [x] Call history in chat
- [x] Call charge / wallet for paid calls
- [x] In-call gifts
- [x] Call hub: history, search, start voice/video, browse rooms

## Profile / Economy
- [x] Profile tab (hero + stats)
- [x] Edit basic profile + poster upload
- [x] Friends / Following / Followers lists
- [x] Visitors list
- [x] User level
- [x] Settings + delete account
- [x] Backpack (frames / backgrounds / equip)
- [x] Mall buy frames / backgrounds / items
- [x] SVIP packages + buy
- [x] VIP Frames store + buy / equip
- [x] Activity list + join
- [x] Awards / achievements + claim
- [x] Wallet balances
- [x] Coin packages + Razorpay recharge
- [x] Withdraw request / history
- [x] Transaction history
- [x] Coin seller apply + sell + transactions
- [x] Customer service FAQs / tickets / chat

## Agency
- [x] Agency access hub (host / owner)
- [x] Host onboarding form
- [x] Host application status
- [x] Owner register + status
- [x] Owner dashboard
- [x] Recruit link / invite code
- [x] Host list
- [x] Pending hosts approve / reject
- [x] Agency revenue + payout request
- [x] Agency UI themed with main-app background

## Super Admin
- [x] Super Admin bottom nav (Dashboard / Agencies / Hosts / Settings)
- [x] Dashboard stats
- [x] Agencies list + detail
- [x] Commission update
- [x] Agency approve / reject
- [x] Hosts list + detail + status update
- [x] Create agency / host + generate link
- [x] Super Admin UI themed with main-app background

## Family
- [x] Family Honor ranking browse
- [x] Create / join / leave family
- [x] My Family dashboard
- [x] Family tree (Leader → Officers → Members)
- [x] Tap member → Message
- [x] Tap member → Send Gift sheet
- [x] Premium glass dialogs (create / join / leave)
- [x] Create Family works with keyboard open

## Shared UI
- [x] Premium glass dialogs app-wide
- [x] Dating-app style cards / glass sheets on key flows

---

*Client-side checklist only. Backend-dependent edge cases (e.g. family gift outside a live room) may need API confirmation separately.*
