# Google Play Console — Qobo1live Listing Fill Guide

**App name (display):** Qobo1live  
**Package name / Application ID:** `com.qobo1live.live`  
**Version (pubspec):** `1.0.0+1` → versionName `1.0.0`, versionCode `1`  
**Last updated:** 2026-08-02  

Use this as copy-paste text for Play Console. Replace `[ ]` placeholders with your real company/contact/URLs.

> **Keep private:** Floor-audience / seat-request API doc stays in repo for backend; this file is for store publishing only.

---

## 0. Before you open Play Console (blockers)

| Item | Status / action |
|------|------------------|
| Developer account | Need paid Google Play Console account |
| App signing | **Critical:** `android/app/build.gradle.kts` still uses **debug** signing for release. Create a **release keystore** and configure `signingConfigs` before upload. |
| AAB build | `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` |
| Privacy Policy URL | **Required** (public HTTPS page). App has legal routes; host a real page. |
| Package on Zego | `com.qobo1live.live` registered on Live / Call / Rooms AppIDs |
| Screenshots | Phone: min **2**, recommend **4–8** (1080×1920 or similar). Feature graphic **1024×500**. |
| Content rating | Complete IARC questionnaire (dating + UGC + live chat) |

---

## 1. Create app

| Field | Value |
|-------|--------|
| App name | `Qobo1live` |
| Default language | English (United States) — or English (India) if primary market is IN |
| App or game | **App** |
| Free or paid | **Free** |
| Declarations | Accept Play policies / US export laws as applicable |

---

## 2. Store listing (Main store listing)

### App name
```
Qobo1live
```
(Max 30 characters — fits.)

### Short description (max 80 characters)
```
Live audio & video rooms, gifts, chat & dating calls — connect on Qobo1live.
```
(Count ≈ 78)

**Alt short (India focus):**
```
Go live, join audio rooms, gift coins & meet people on Qobo1live.
```

### Full description (max 4000 characters) — copy:

```
Qobo1live is a social live app where you can go live, join audio and video rooms, chat, send gifts, and connect with people in real time.

WHAT YOU CAN DO
• Go Live — start live streaming and interact with your audience
• Audio & Video Rooms — join party rooms, take a seat, chat and react
• Gifts & Coins — send virtual gifts to hosts and friends
• Chat & Calls — message matches and enjoy voice/video calling
• Discover — explore rooms and people near you or worldwide
• Profile & Wallet — manage your profile, coins, and withdrawals
• Agency & Host tools — for creators and agencies (where enabled)

WHY QOBO1LIVE
• Smooth live and room experience powered by realtime media
• Fun social features — gifts, seats, reactions, and invites
• Built for creators, hosts, and everyday users

GET STARTED
1. Sign up with your phone or social login
2. Complete your profile
3. Discover a room or go live
4. Follow hosts, send gifts, and enjoy the community

NOTES
• Some features require coins or an approved host/agency role
• Please follow community guidelines — be respectful and keep content appropriate
• Virtual items and coins have no real-world cash value unless stated in-app for withdrawals where available

Download Qobo1live and start connecting today.
```

### App icon
- **512 × 512** PNG, 32-bit, no transparency (Play requirement for high-res icon).
- Use your launcher icon upscaled if needed.

### Feature graphic
- **1024 × 500** PNG/JPEG  
- Text suggestion: large **Qobo1live** wordmark + “Live · Rooms · Chat” on brand gradient.

### Phone screenshots (required)
Capture from a real device / emulator (portrait):

1. Discover / rooms list  
2. Audio room (seats + chat) — like your current room UI  
3. Live streaming  
4. Chat / messages  
5. Profile / wallet  
6. Gift sheet (optional)

Min 2; aim for 6–8.

### Category
- **Primary:** Social  
- **Secondary (optional):** Dating (only if you want dating positioning; otherwise leave Social only)

### Tags / contact
| Field | Suggested |
|-------|-----------|
| Email (required) | `[support@yourdomain.com]` |
| Phone | Optional |
| Website | `[https://yourdomain.com]` |
| Privacy policy | **`[https://yourdomain.com/privacy]`** — required |

---

## 3. App content declarations (answer carefully)

### Privacy policy
Paste public URL. Must cover: account data, photos, mic/camera, location (if used), chat, payments/coins, third parties (Firebase, Zego, Facebook/Google login).

### Ads
- If you show ads → Yes + AdMob / network details  
- If none → **No, my app does not contain ads**

### In-app purchases / digital goods
- Coins / gifts / VIP → declare **Yes** (Play Billing if selling on Android; if coins only via external/seller, still disclose virtual currency carefully).  
- Complete **Financial features** / **Play billing** questionnaires as shown in Console.

### Content ratings (IARC)
Expect questions about:

| Topic | Likely answer for Qobo1live |
|-------|-----------------------------|
| User-generated content | Yes |
| Users can communicate | Yes (chat, rooms, live) |
| Sharing location | Answer based on real app (Discover geo?) |
| Violence / sexual content | No graphic violence; dating/social — answer honestly |
| Dating features | Yes if Qobo Call / match is live |
| Purchases | Yes if coins |

Complete all steps until you get a rating certificate.

### Target audience
- Age: typically **18+** for dating + live social with gifts.  
- Do **not** target children.

### News app
No (unless you are a news publisher).

### COVID-19
No (unless applicable).

### Data safety (Data safety form)
Declare data you collect/share. Typical for this app:

| Data type | Collected? | Shared? | Purpose |
|-----------|------------|---------|---------|
| Name, email, phone | Yes | Maybe (auth providers) | Account |
| Photos / avatar | Yes | Yes (shown to others) | Profile |
| Messages | Yes | Yes (to chat peers) | Chat |
| Approximate location | If used | Check | Discover |
| App activity / interactions | Yes | Analytics if any | App functionality |
| Device IDs | Yes (FCM, crash) | Firebase | Push / diagnostics |
| Financial info | Coins/wallet | Backend | Purchases |

Encryption in transit: **Yes** (HTTPS).  
Users can request deletion: declare if you support delete-account (link policy).

### Government apps
No.

---

## 4. Countries / pricing
- Free app  
- Distribute to: start with **India** (+ other countries you support)  
- No pricing template needed if free (IAP separate)

---

## 5. Release → Testing tracks (recommended path)

1. **Internal testing** — upload AAB, add tester emails, share link  
2. **Closed testing** — required before production for many new personal accounts  
3. **Open testing** (optional)  
4. **Production**

### Release name
```
1.0.0 (1) — Initial Play release
```

### Release notes (en-US) — What\'s new
```
Initial release of Qobo1live.
• Live streaming and audio/video rooms
• Gifts, chat, and social discovery
• Profile, wallet, and creator tools
```

---

## 6. Technical details (Console + build)

| Item | Value |
|------|--------|
| Package name | `com.qobo1live.live` |
| versionName | `1.0.0` |
| versionCode | `1` |
| minSdk | 24 |
| Target SDK | Flutter default (keep Play policy compliant, usually latest) |

### Build commands
```bash
# After release keystore is configured:
flutter clean
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 7. Signing (must do before upload)

Current project note: release build still points at **debug** signing. For Play:

1. Generate upload keystore (keep password safe; back up `.jks`).  
2. Create `android/key.properties` (do **not** commit to git).  
3. Wire `signingConfigs.release` in `build.gradle.kts`.  
4. Prefer **Play App Signing** (Google holds app signing key; you upload with upload key).

---

## 8. Store assets checklist

- [ ] High-res icon 512×512  
- [ ] Feature graphic 1024×500  
- [ ] ≥2 phone screenshots (prefer 6+)  
- [ ] Short description  
- [ ] Full description  
- [ ] Privacy policy URL live  
- [ ] Support email  
- [ ] Content rating done  
- [ ] Data safety form done  
- [ ] Release AAB signed  
- [ ] Internal/closed test passed  

---

## 9. What you still need to provide (fill these)

Reply with these so we can finalize exact Console answers:

1. **Support email**  
2. **Privacy policy URL** (and Terms URL if any)  
3. **Website** (optional)  
4. **Company / developer name** on Play  
5. **Primary country** (India only vs global)  
6. Do you sell coins via **Google Play Billing** or only coin sellers / external?  
7. Is the app **18+** only?  
8. Any **ads**?

---

## 10. Suggested next steps together

1. You send privacy URL + support email + billing/ads answers.  
2. We refine Data safety + content-rating answers line by line.  
3. Configure **release signing** in Android (I can do this when you have keystore details locally — never paste keystore passwords in chat if avoidable).  
4. Build AAB → upload Internal testing.

---

*App display name on device is already set to **Qobo1live** (`AndroidManifest` / iOS display name).*
