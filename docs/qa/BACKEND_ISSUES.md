# Qobo1live — Backend Issues

**Date:** 3 Oct 2026 · **Tested by:** Parth · **Server:** https://api.qobo1live.in

Only confirmed issues are listed. Priority: **HIGH** = broken / very slow · **MEDIUM** = partly wrong · **LOW** = cosmetic.

| # | Area | Problem | Priority |
|---|---|---|---|
| BE-01 | Gifts | Gift panel is very slow to load | HIGH |
| BE-02 | Gifts | Wrong file type for some gifts | MEDIUM |
| BE-03 | Gifts | Gift sounds don't play | MEDIUM |
| BE-04 | Gifts | Send-gift returns broken `dev-api` links (animation not playing) | HIGH |
| BE-05 | VIP Frames | No VIP frames returned, so the VIP Frames screen is empty | HIGH |

---

### BE-01 · Gift panel is very slow to load · HIGH

- **Problem:** Gift tiles stay blank or show a loader for a long time.
- **Why:** The gift "picture" is the full animation file (2–12 MB each) instead of a small image. Opening the Lucky tab downloads ~44 MB.
- **Fix:** Add a small preview image for every gift (PNG/WebP, ~200×200, under 50 KB) in a new field `thumbnailUrl`. Keep the big animation only in `animationUrl`. Make the preview required in the admin panel.
- **Check:** Gift panel loads almost instantly on mobile data.
- **API:** `GET /api/economy/gift-list`

### BE-02 · Wrong file type for some gifts · MEDIUM

- **Problem:** Gifts ABC (normal), rocket, god wish, star car, silpper, kis love say `format: "png"`, but the files are animations (SVGA).
- **Why:** Uploaded to Cloudinary as raw files without an extension, so they can't be resized and the app can't tell the real type.
- **Fix:** Set `format` to the real type (`svga` / `png` / `svg`). Upload preview images as normal images with an extension.
- **Check:** Each gift's `format` matches its file.
- **API:** `GET /api/economy/gift-list`

### BE-03 · Gift sounds don't play · MEDIUM

- **Problem:** Golden Dragon and Sports Car play with no sound.
- **Why:** Sound links use `assets.qobo1live.com`, which does not exist (no DNS record).
- **Fix:** Host the sound files on a working URL (e.g. `api.qobo1live.in/uploads/...` or Cloudinary) and update `soundUrl`.
- **Check:** Sound link opens in a browser and plays in the app.
- **API:** `GET /api/economy/gift-list`

### BE-04 · Send-gift returns broken `dev-api` links · HIGH

- **Problem:** After sending a gift (e.g. Dragon in a live stream), the gift animation does not play.
- **Why:** The production server returns links on the **dev** server: `https://dev-api.qobo1live.in/uploads/gifts/animations/animation-1791014084779-967704674.svga` → **404 Not Found**. The same file on `https://api.qobo1live.in/...` works. The receiver avatar also comes from `dev-api`.
- **Fix:** Build all URLs in the send-gift response (and gift socket events) with the production base URL `https://api.qobo1live.in` — likely a wrong base-URL setting on the production server.
- **Check:** `data.gift.animationUrl` in the send-gift response starts with `https://api.qobo1live.in` and opens in a browser.
- **API:** `POST /api/economy/send-gift` (fields `data.gift.animationUrl`, `thumbnailUrl`, `receiver.avatar`)
- **Note:** The app now uses the gift-list link instead, so animations play again — but the response should still be fixed.

### BE-05 · No VIP frames in the frame shop · HIGH

- **Problem:** Profile → VIP Frames shows "No VIP frames yet", so users can't buy any VIP frame.
- **Why:** `GET /api/frame/shop` returns no frame with `category: "vip"`. The app shows only frames where `category` is `vip` and `status` is `active`.
- **Fix:** Add VIP frames in the admin panel (Avatar Frames → category **VIP**, status **active**, with price and image) and make sure the shop API returns them.
- **Check:** `GET https://api.qobo1live.in/api/frame/shop` has at least one item with `"category": "vip"` and `"status": "active"`; the VIP Frames screen lists it.
- **API:** `GET /api/frame/shop`

---

## Still to test today (not confirmed — don't send yet)

| # | Area | What to check | Result |
|---|---|---|---|
| T-01 | PK Battle | Host picks 2 min → both phones show 2:00 and the battle ends together | Not tested |
| T-02 | ZEGOCLOUD | Live stream, audio/video rooms and 1-to-1 calls work with the new accounts | Not tested |
| T-03 | SVIP | After buying SVIP, log out → log in (or use another phone) → SVIP Center still shows "SVIP Member Active". If not, `GET /api/user/profile` / `GET /api/economy/vip-packages` don't return SVIP status (`isSvipActive` + `expiresAt`) | Not tested |
| T-04 | Mall | Open Mall → Entrance Effects / Chat Bubbles. If it says "No entrance effects yet", `GET /api/economy/mall` returns no items with type `entrance_effect` / `chat_bubble` — then it's a backend data issue | Not tested |
| T-05 | SVIP | Ledger shows 5 × `VIP_PURCHASE` (100 coins each) within 1 minute. Check with backend: should `POST /api/economy/buy-vip` block a second buy while SVIP is active (or extend expiry)? Also ledger sends spends as positive `amount` with no `direction` | Not tested |

---

## Already fixed in the app (no backend work)

| # | Screen | Problem | Fix |
|---|---|---|---|
| FE-01 | Join Live | Stream card overflowed and showed `LIVE_STREAM` | Redesigned card; labels wrap and read "Live stream" |
| FE-02 | Gifts (all screens) | Sent gift animation didn't play because the app used the broken send-gift link | App now uses the working gift-list link first, for sender and viewers |
| FE-03 | 1-to-1 call | Top bar overflowed on the right; billing pill text was cut off | Name area now shrinks with "…", billing pill always fits |
| FE-04 | Chat list | Showed old "Voice call · Missed call" even after a newer text like "Hii" | Text now updates both users' chat list, and newer messages replace the call preview |
| FE-05 | Family chat | Gift animation played only for the sender, not other members | Every member with the chat open now sees the gift animation |
| FE-06 | SVIP Center | Reopening the screen showed "Open SVIP Now" again after buying | Screen now remembers SVIP and shows a gold "SVIP Member Active" bar with real days left |
| FE-07 | Mall | Entrance Effects and Chat Bubbles showed fake demo items (Dragon Arrival, Star Shower) and never called the API | Tabs now load real items from `GET /api/economy/mall`, with an empty state if none |
| FE-08 | Transaction History | Old UI; spends like VIP purchase / family gift showed as green "+"; raw titles like `VIP_PURCHASE` | New UI (summary, day groups, colored icons); spends show red "−"; readable titles |
