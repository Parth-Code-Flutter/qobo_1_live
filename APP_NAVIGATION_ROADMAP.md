# Qobo One Live — Client Navigation Roadmap & Interaction Matrix

This document acts as the definitive roadmap and navigation hierarchy of the **Qobo One Live** mobile client application. It maps out all developed UI screens, explains what happens on key interactions (`onClick` events), and details how the screens link together.

---

## 📊 Project Progress Dashboard (Mobile App)

*   **Total Developed UI Screens & Sub-views:** 39 Surfaces
*   **Fully Integrated & Wired Screens:** 14 Screens (Splash, Login, Phone Login, OTP Verify, New Password, Onboarding, Profile Edit, User Search, Room Creation, Discover Search/Follow, Entrance Patti Store, User Level, Agency Host Onboarding Form, Agency Host Status)
*   **Fully Designed Premium Mock Screens:** 25 Screens (Discover Swipers, Live Broadcast view, Messaging, Wallet, Transaction Log, Revenue, Agency Owner Hub, Agency Recruitment, Agency Hosts List, Coin Seller Dashboard, Block List, Settings, Followers List, Family Hub, Visitors List, Backpack, SVIP Center, Aristocracy Center, Mall Store, Point Center, Medals List, Broadcast History, Customer Support Support, PK Battles Matching, Call Cards Deck, Live Moderation Console)

---

## 🗺️ Application Navigation Flow Chart

```mermaid
graph TD
    SplashView["Splash Screen (Check Token)"]
    AuthLoginView["Login Screen (/login)"]
    AuthSignUpView["Sign Up Screen (/sign-up)"]
    AuthVerifyAccountView["OTP Verification (/verify-account)"]
    NewPasswordView["New Password (/new-password)"]
    UpdateProfileView["Onboarding Profile (/update-profile)"]
    BottomNavView["Bottom Navigation Hub (/bottom-nav)"]
    
    %% Tab Screens
    DiscoverTabView["Tab 0: Discover Home"]
    LiveRoomView["Tab 1: Live Rooms Feed"]
    LiveActionView["Tab 2: Go Live Center ❤️"]
    MessagesTabView["Tab 3: Messages Tab"]
    ProfileTabView["Tab 4: Profile Tab"]
    
    %% Navigation Links
    SplashView -->|No Token| AuthLoginView
    SplashView -->|Token Exists| BottomNavView
    
    AuthLoginView -->|Click 'Sign Up'| AuthSignUpView
    AuthLoginView -->|Click 'Forgot Password'| AuthVerifyAccountView
    AuthLoginView -->|Click 'OTP Login'| AuthVerifyAccountView
    AuthLoginView -->|Credentials Success| BottomNavView
    
    AuthSignUpView -->|Submit Form| AuthVerifyAccountView
    AuthSignUpView -->|Click 'Sign In'| AuthLoginView
    
    AuthVerifyAccountView -->|OTP Success (Forgot Pass)| NewPasswordView
    AuthVerifyAccountView -->|OTP Success (Signup)| UpdateProfileView
    AuthVerifyAccountView -->|OTP Success (OTP Login)| BottomNavView
    
    NewPasswordView -->|Reset Success| AuthLoginView
    UpdateProfileView -->|Save Success| BottomNavView
    
    BottomNavView --> DiscoverTabView
    BottomNavView --> LiveRoomView
    BottomNavView --> LiveActionView
    BottomNavView --> MessagesTabView
    BottomNavView --> ProfileTabView
    
    %% Inner views & sub-routines
    DiscoverTabView -->|Click 'Agency Banner'| AgencyHostOnboardingView["Agency Host Onboarding Form"]
    DiscoverTabView -->|Click 'Agency Owner Register'| AgencyOwnerRegisterView["Agency Owner Register Form"]
    
    AgencyHostOnboardingView -->|Submit Form| AgencyHostStatusView["Agency Host Status View"]
    
    AgencyOwnerRegisterView -->|Submit Form| AgencyOwnerView["Agency Owner dashboard"]
    AgencyOwnerView -->|Click 'Recruit Link'| AgencyRecruitLinkView["Recruit Link View"]
    AgencyOwnerView -->|Click 'Host List'| AgencyHostListView["Hosts List View"]
    AgencyOwnerView -->|Click 'Revenue Reports'| AgencyRevenueView["Revenue Reports View"]
    
    LiveActionView -->|Click 'Audio/Video Live'| LiveRoomCreateView["Live Room Create View"]
    LiveRoomCreateView -->|Click 'Go Live'| LiveBroadcastView["Live Broadcast Screen"]
    
    MessagesTabView -->|Click Conversation| ChatDetailView["1-to-1 Chat Detail Screen"]
    
    ProfileTabView -->|Click 'Edit Icon'| UserBasicProfileView["User Basic Profile Edit"]
    ProfileTabView -->|Click 'Wallet Card'| WalletView["Wallet & Balances"]
    ProfileTabView -->|Click 'Settings'| SettingsView["Settings View"]
    ProfileTabView -->|Click 'Follow/Fans'| FollowListView["Followers List View"]
    
    WalletView -->|Click 'Transaction Logs'| TransactionHistoryView["Transaction History Log"]
    WalletView -->|Click 'VIP Store'| VipStoreView["VIP Store View"]
    WalletView -->|Click 'Coin Sellers'| CoinSellerView["Coin Seller Panel"]
    
    SettingsView -->|Click 'Block List'| BlockListView["Blocked Users View"]
    
    %% Profile Grid items
    ProfileTabView -->|Click 'Visitors'| VisitorsView["Visitors List"]
    ProfileTabView -->|Click 'User Level'| UserLevelView["User Level & Badges"]
    ProfileTabView -->|Click 'Backpack'| BackpackView["My Backpack"]
    ProfileTabView -->|Click 'Family'| FamilyView["Family Dashboard / Browse"]
    ProfileTabView -->|Click 'SVIP'| SvipView["SVIP Center"]
    ProfileTabView -->|Click 'Activity'| ActivityView["Hot Activities"]
    ProfileTabView -->|Click 'Aristocracy Center'| AristocracyCenterView["Aristocracy Center"]
    ProfileTabView -->|Click 'Mall'| MallView["Virtual Mall Store"]
    ProfileTabView -->|Click 'Point Center'| PointCenterView["Point Center"]
    ProfileTabView -->|Click 'Award'| AwardView["Medals & Awards"]
    ProfileTabView -->|Click 'Broadcast Watched'| BroadcastWatchedView["Broadcast History"]
    ProfileTabView -->|Click 'Customer Service'| CustomerServiceView["Customer Support Hub"]
```

---

## 📱 Detailed Screen Interaction Matrix

Here is the exact mapping of what happens when a client clicks on buttons inside each developed screen.

### 1. Splash Screen (`SplashView` · `/splash`)
*   **Visual State:** Rendered on cold boot with the official branding logo and standard loading indicator.
*   **Interactions (`onClick` / Auto-Triggers):**
    *   **Auto-Trigger (On Load):** Checks local secure storage for an existing session JWT token.
        *   *If token exists and is valid:* Automatically routes to **Bottom Navigation Hub** (`BOTTOM_NAV`).
        *   *If no token / expired session:* Automatically routes to **Login Screen** (`AUTH_LOGIN`).

### 2. Login Screen (`AuthLoginView` · `/login`)
*   **Visual State:** Beautiful dual-entry input card (Username/Password), social sign-in buttons, and quick routing footers.
*   **Interactions (`onClick`):**
    *   **Click "Forgot Password?" text link:** Redirects to **OTP Verification Screen** (`AUTH_VERIFY_ACCOUNT`) in *Forgot Password* mode.
    *   **Click "Sign Up" footer link:** Routes directly to **Register Screen** (`AUTH_SIGN_UP`).
    *   **Click "Login with Phone / OTP" text link:** Redirects to **OTP Verification Screen** (`AUTH_VERIFY_ACCOUNT`) in *Phone OTP Login* mode.
    *   **Click "Google / Facebook" OAuth buttons:** Opens secure native social picker sheets. Toggles API to `/social`. On success, automatically logs the user in and routes to **Bottom Navigation Hub** (`BOTTOM_NAV`).
    *   **Click "Login" button:**
        *   *If fields are invalid:* Shows localized inline validation errors.
        *   *If valid credentials:* Triggers API `POST /api/auth/login`. On success, saves credentials and opens **Bottom Navigation Hub** (`BOTTOM_NAV`).

### 3. Register Screen (`AuthSignUpView` · `/sign-up`)
*   **Visual State:** Standard sign-up header with username, email, and password form capture widgets.
*   **Interactions (`onClick`):**
    *   **Click "Sign In" footer link:** Pops screen and returns to **Login Screen** (`AUTH_LOGIN`).
    *   **Click "Google / Facebook" sign-up buttons:** Registers new profile silenty using social credentials and enters the **Bottom Navigation Hub** (`BOTTOM_NAV`).
    *   **Click "Sign Up" button:**
        *   *If email/pass forms are valid:* Routes to **OTP Verification Screen** (`AUTH_VERIFY_ACCOUNT`) to confirm phone attachment.

### 4. OTP Verification Screen (`AuthVerifyAccountView` · `/verify-account`)
*   **Visual State:** Centered phone number text capture widget and a 4-digit security code input grid.
*   **Interactions (`onClick`):**
    *   **Click Country Code Selector:** Opens country flag picker scroll sheet.
    *   **Click "Send Verification Code" button:** Fires `POST /api/auth/login-phone` (or `forgot-password`). Renders native success toasts.
    *   **Click "Verify OTP" button:**
        *   Validates OTP input code. If correct:
            *   *Scenario A (Onboarding Sign Up):* Routes to **Onboarding Profile Screen** (`UPDATE_PROFILE`).
            *   *Scenario B (Forgot Password flow):* Routes to **New Password Screen** (`AUTH_NEW_PASSWORD`).
            *   *Scenario C (Direct OTP Login):* Sets session and opens **Bottom Navigation Hub** (`BOTTOM_NAV`).

### 5. New Password Screen (`NewPasswordView` · `/new-password`)
*   **Visual State:** Double-secure password validation inputs (New Password & Confirm Password).
*   **Interactions (`onClick`):**
    *   **Click "Submit" button:** Validates fields. Calls API `POST /api/auth/reset-password`. On success, pops back to **Login Screen** (`AUTH_LOGIN`) with a success message.

### 6. Onboarding Profile Screen (`UpdateProfileView` · `/update-profile`)
*   **Visual State:** Interactive profile setup step (Avatar upload circle, Nickname, Age Picker, Gender switches).
*   **Interactions (`onClick`):**
    *   **Click Avatar placeholder circle:** Launches system camera or photo gallery picker.
    *   **Click Age selection input:** Slides open a custom Cupertino wheel selector allowing the user to select an age from 13 to 100.
    *   **Click "Next" button:** Encapsulates updates inside `PUT /api/user/update` (Multipart) and uploads to the server. On success, launches **Bottom Navigation Hub** (`BOTTOM_NAV`).

---

### 7. Bottom Navigation Hub (`BottomNavView` · `/bottom-nav`)
Consists of a persistent premium bottom navigator bar that controls and paints 5 core sub-views:

#### Tab 0: Discover Home Screen (`DiscoverTabView`)
*   **Visual State:** Banner ads slider, horizontal Category selection pill buttons, and trending user grids.
*   **Interactions (`onClick`):**
    *   **Click "Explore Search" input bar:** Opens debounced search layer.
        *   *Type query:* Matches usernames dynamically via API `GET /api/user/search`.
        *   *Click "Follow" button next to search items:* Instantly follows/unfollows the user via `POST /api/user/follow-unfollow`.
    *   **Click "Agency Host Onboarding" promotional banner:** Routes to **Agency Host Onboarding Form** (`AGENCY_HOST_ONBOARDING`).
    *   **Click "Agency Owner Register" button:** Routes to **Agency Owner Register Screen** (`AGENCY_OWNER_REGISTER`).
    *   **Click Tab Buttons (Popular, New, Bangladesh, Sab, Shresth):** Dynamically filters discover listings (currently mocks custom grids).
    *   **Click "Audio Room" grid card:** Opens premium **Discover Audio Room mockup** view.
    *   **Click "Video Room" card:** Opens dating card **Call Swiper mockup** view.

#### Tab 1: Live Rooms Feed (`LiveRoomView`)
*   **Visual State:** Dynamic categorization tabs (Sab, Shresth, Naya, Bangladesh) and a grid layout displaying active streaming rooms.
*   **Interactions (`onClick`):**
    *   **Click Category Tabs:** Filters the listing feed grid.
    *   **Click any active Room grid item:** Enters the designated stream directly by launching the **Live Broadcast Screen** (`LIVE_BROADCAST`) in *Audience mode*.

#### Tab 2: Go Live Center Button ❤️ (`LiveActionView`)
*   **Visual State:** Explore screen designed exactly to Figma specs (vibrant gold gradients, live statistics, dynamic entry triggers).
*   **Interactions (`onClick`):**
    *   **Click "Audio Live" / "Video Live" cards:** Routes directly to **Live Room Create Screen** (`LIVE_ROOM_CREATE`).

#### Tab 3: Messages Hub (`MessagesTabView`)
*   **Visual State:** Combined inbox containing Direct Messages (DMs), official system notifications, and call match records.
*   **Interactions (`onClick`):**
    *   **Click any chat conversation block:** Launches **1-to-1 Chat Detail Screen** (`CHAT_DETAIL`).

#### Tab 4: Profile Tab Screen (`ProfileTabView`)
*   **Visual State:** Hero card showing user's level badge, ID, avatar, and background poster, followed by an operational feature grid.
*   **Interactions (`onClick`):**
    *   **Click Edit Badge (top-right overlay):** Routes to **User Basic Profile Screen** (`USER_BASIC_PROFILE`).
    *   **Click "Wallet" action card:** Routes directly to the **Wallet Screen** (`WalletView`).
    *   **Click "Follow" or "Fans" statistics:** Routes to **Follow List Screen** (`FOLLOW_LIST`).
    *   **Click Settings gear icon:** Routes to **Settings Screen** (`SETTINGS`).
    *   **Click Grid Tiles (Backpack, Family, SVIP, Mall, Aristocracy Center, Point Center, User Level, Award, Broadcast Watched, Customer Service, Visitors):** Launches their respective screens.

---

### 8. User Basic Profile Screen (`UserBasicProfileView` · `/user-basic-profile`)
*   **Visual State:** Full profile details edit form, with direct controls to customize user backgrounds.
*   **Interactions (`onClick`):**
    *   **Click "Upload Poster Background" button:** Launches the native gallery picker. Instantly uploads the photo via API `POST /api/user/poster-upload`. On success, updates the background instantly and caches the new URL.
    *   **Click Profile Avatar Circle:** Gallery picker to update avatar photo.
    *   **Click Form Row items (Relationship Status, Languages, Locations, Interests, Voice Show, Link Accounts):** Launches a custom selection modal (`CommonRadioChoiceDialog`). When an option is clicked (e.g. Single, married, English, Hindi, Travel, Music, India), it updates the local state and highlights the row in purple.
    *   **Click "Save Profile" button:** Submits all changed/dirty attributes via PUT API and pops back to profile.

### 9. Live Room Create Screen (`LiveRoomCreateView` · `/live-room-create`)
*   **Visual State:** Stream preparation room (Title input field, Audio/Video switcher, Seat count bubble selectors).
*   **Interactions (`onClick`):**
    *   **Click "AUDIO" or "VIDEO" switch buttons:** Switches room type.
    *   **Click Seat count buttons (4, 8, etc.):** Sets maximum guest limits.
    *   **Click "Go Live" button:** Triggers API `POST /api/room/create`. On successful creation, launches **Live Broadcast Screen** (`LIVE_BROADCAST`) in *Host Mode*.

### 10. Live Broadcast / Streaming View (`LiveBroadcastView` · `/live-broadcast`)
*   **Visual State:** Real-time streaming interface showing co-host grid panels, active audience counters, and chat logs overlay.
*   **Interactions (`onClick`):**
    *   **Click Gift Icon (bottom navigation bar):** Opens **Gifts Bottom Sheet** (`GiftsBottomSheet`).
        *   *Click on gift selection (Rose, Heart, Diamond):* Triggers mock transaction log, sends SVGA gift animation overlay.
    *   **Click Settings/Options gear Icon:** Opens **Room Options Sheet** (`RoomOptionsSheet`).
        *   *Click mic mute, kick user, lock seat rules:* Initiates moderator control methods.
    *   **Click Shield Shield Icon (top-right corner):** Opens **Live Moderation Control Room** (`LiveModerationView`) for managing SOS alerts.

### 11. Wallet & Balances Screen (`WalletView`)
*   **Visual State:** Displays user balances (Coins, Diamonds, Beans) alongside recharge packages.
*   **Interactions (`onClick`):**
    *   **Click PK R Plan Recharge Cards:** Triggers standard Pakistani Rupee payment workflows (Razopay/Google Pay simulated overlay).
    *   **Click "Transaction History" link:** Routes to **Transaction History Screen** (`TransactionHistoryView`).
    *   **Click "VIP Store" promotional banner:** Routes to **VIP Store Screen** (`VipStoreView`).
    *   **Click "Official Sellers" transfer link:** Routes to **Coin Seller Panel** (`COIN_SELLER`).

### 12. Transaction History Screen (`TransactionHistoryView` · `/transaction-history`)
*   **Visual State:** Two-tab log list (Coins History vs Diamonds History).
*   **Interactions (`onClick`):**
    *   **Click "Coins" or "Diamonds" header tabs:** Toggles and loads the respective log lists.

### 13. Agency Host Onboarding Form (`AgencyHostOnboardingView` · `/agency-host-onboarding`)
*   **Visual State:** Application form captures legal details, WhatsApp number, and verification real photos.
*   **Interactions (`onClick`):**
    *   **Click Category select field:** Launches bottom select modal for categories (Solo, PK, Chat, Music).
    *   **Click "Upload verification photo" box:** Gallery image picker.
    *   **Click "Submit Application" button:** Validates fields. Displays a premium celebration success dialog (`CommonGiffyDialog`).
        *   **Click "Check Status" button inside dialog:** Redirects to **Agency Host Status Screen** (`AGENCY_HOST_STATUS`).

### 14. Agency Host Status Screen (`AgencyHostStatusView` · `/agency-host-status`)
*   **Visual State:** Displays a progress checklist indicating if the submitted application is PENDING, APPROVED, or REJECTED by agency administrators.

### 15. Family Screen (`FamilyView` · `/family`)
*   **Visual State:** Dual-state: Browse state allows searching for trending families. Dashboard state shows Family bulletins, Quest lists, level details, and active online member rosters.
*   **Interactions (`onClick`):**
    *   **Click "Apply to Join" or "Search":** Instantly queries family lists and simulates membership join requests.
    *   **Click "Quests":** Displays rewards claiming interface.

### 16. Visitors Screen (`VisitorsView` · `/visitors`)
*   **Visual State:** Lists users who viewed your profile, showing timestamp, level, and VIP status.
*   **Interactions (`onClick`):**
    *   **Click "Follow":** Instantly toggles follow/unfollow status.
    *   **Click "Message":** Redirects to direct chat.

### 17. User Level Screen (`UserLevelView` · `/user-level`)
*   **Visual State:** Shows current level, EXP progress indicator, unlocked perks, and lock/unlock milestones.
*   **Interactions (`onClick`):**
    *   **Click "My Perks" or "Badge Milestones" sub-tabs:** Toggles views.

### 18. Backpack Screen (`BackpackView` · `/backpack`)
*   **Visual State:** Vault grid displaying gifts, frames, chat bubbles, and entry animations.
*   **Interactions (`onClick`):**
    *   **Click "Equip / Unequip":** Activates/deactivates the item on the user's active profile configuration.
    *   **Click "Visit Mall":** Deep links directly to the Mall view to buy decorations.

### 19. SVIP Center Screen (`SvipView` · `/svip`)
*   **Visual State:** Premium dark obsidian gold dashboard presenting six VIP privileges and subscription tiers.
*   **Interactions (`onClick`):**
    *   **Click "Open SVIP Now":** Validates coin balance, deducts price, and activates membership.

### 20. Activity Screen (`ActivityView` · `/activity`)
*   **Visual State:** Vertical card layout of ongoing/upcoming platform events.
*   **Interactions (`onClick`):**
    *   **Click "Join Now" or "Notify Me":** Triggers event join protocols or registers push notifications.

### 21. Aristocracy Center Screen (`AristocracyCenterView` · `/aristocracy-center`)
*   **Visual State:** Horizontal rank selector (Knight, Viscount, Duke, King) with rank-colored details list and custom action buttons.
*   **Interactions (`onClick`):**
    *   **Click "Subscribe":** Deducts coins and updates active noble title.

### 22. Virtual Mall Screen (`MallView` · `/mall`)
*   **Visual State:** Item store showing category tabs and an interactive preview simulator box.
*   **Interactions (`onClick`):**
    *   **Click store card:** Displays a live rendering of the item (e.g. avatar frame border, entry chat box) in the simulator.
    *   **Click price button:** Buys item and transfers it directly to user's Backpack.

### 23. Point Center Screen (`PointCenterView` · `/point-center`)
*   **Visual State:** Points summary and dual tabs (Daily Tasks vs Point items store).
*   **Interactions (`onClick`):**
    *   **Click "Claim":** Collects daily points from completed tasks.
    *   **Click "Redeem":** Spends points to buy items from the store.

### 24. Medals & Awards Screen (`AwardView` · `/award`)
*   **Visual State:** Achievement badges list, level progression bar, and points accumulated indicator.
*   **Interactions (`onClick`):**
    *   **Click Medal Card:** Shows milestones detail.

### 25. Broadcast History Screen (`BroadcastWatchedView` · `/broadcast-watched`)
*   **Visual State:** Lists recently visited rooms and active streams.
*   **Interactions (`onClick`):**
    *   **Click "Watch":** Instantly enters the live room.

### 26. Customer Support Hub (`CustomerServiceView` · `/customer-service`)
*   **Visual State:** Support console with FAQs, support ticket listings, and live chat message bubble interface.
*   **Interactions (`onClick`):**
    *   **Click "Submit Ticket":** Launches bottom sheet form to submit support tickets.
    *   **Click "Send":** Submits live chat messages to help center agents.

---

### 📥 27. Agency Owner Register Screen (`AgencyOwnerRegisterView` · `/agency-owner-register`)
*   **Visual State:** Custom registration form with text inputs for Agency Name, Contact Email, Contact Number, and Agency Bio.
*   **Interactions (`onClick`):**
    *   **Click "Register Agency" button:** Validates details and logs agency registration. Automatically navigates to the **Agency Owner Dashboard** (`AGENCY_OWNER`).

### 📥 28. Agency Owner Dashboard (`AgencyOwnerView` · `/agency-owner`)
*   **Visual State:** High-fidelity dashboard for agency owners. Displays daily agent statistics, active stream hours, monthly revenue estimates, and host analytics lists.
*   **Interactions (`onClick`):**
    *   **Click "Recruit Host Link":** Routes to **Recruit Link Creator** (`AGENCY_RECRUIT_LINK`).
    *   **Click "My Hosts List":** Routes to **Agency Hosts List** (`AGENCY_HOST_LIST`).
    *   **Click "Commission & Revenue Reports":** Routes to **Agency Revenue Reports** (`AGENCY_REVENUE`).

### 📥 29. Recruit Link View (`AgencyRecruitLinkView` · `/agency-recruit-link`)
*   **Visual State:** Displays active host recruitment cards with a copyable custom invitation URL and code.
*   **Interactions (`onClick`):**
    *   **Click "Copy Invite Code" or "Copy Invite Link":** Copies invitation details to clipboard with a success toast.

### 📥 30. Agency Hosts List View (`AgencyHostListView` · `/agency-host-list`)
*   **Visual State:** Searchable list of hosts associated with the owner's agency, displaying active status, hourly streaming counters, and diamonds accumulated.
*   **Interactions (`onClick`):**
    *   **Click user item:** Deep-links to host analytics stats.

### 📥 31. Agency Revenue View (`AgencyRevenueView` · `/agency-revenue`)
*   **Visual State:** Commission tables, monthly ledgers, and payout status indicators (Pending/Transferred).
*   **Interactions (`onClick`):**
    *   **Click payout requests:** Triggers withdrawal simulations.

### 📥 32. Coin Seller Panel (`CoinSellerView` · `/coin-seller`)
*   **Visual State:** Dashboard panel for official coin sellers, displaying available coin reserves and buyer transfer logs.
*   **Interactions (`onClick`):**
    *   **Click "Transfer Coins" button:** Launches a modal to input Buyer UID and Coins Amount.
    *   **Click "Confirm Transfer":** Simulates deduction and writes log to the records sheet.

### 📥 33. Follow List Screen (`FollowListView` · `/follow-list`)
*   **Visual State:** Two-tab list (Followings list vs Followers list) displaying user badges.
*   **Interactions (`onClick`):**
    *   **Click list item:** Redirects directly to the user profile.
    *   **Click "Unfollow" button:** Instantly toggles following state.

### 📥 34. Settings Screen (`SettingsView` · `/settings`)
*   **Visual State:** Standard gear menu list covering Account Security, Block List, Clear Cache, and Logout.
*   **Interactions (`onClick`):**
    *   **Click "Block List" option:** Routes to **Blocked Users View** (`BLOCK_LIST`).
    *   **Click "Log Out":** Clears tokens and returns to **Login Screen** (`AUTH_LOGIN`).

### 📥 35. Block List Screen (`BlockListView` · `/block-list`)
*   **Visual State:** List of blocked user accounts showing timestamps.
*   **Interactions (`onClick`):**
    *   **Click "Unblock":** Instantly removes from list and updates status.

### 📥 36. Entrance Patti Store (`EntrancePattiView` · `/entrance-patti`)
*   **Visual State:** Showcases custom chat ribbon banners, title entry styles, and premium text color ribbons.
*   **Interactions (`onClick`):**
    *   **Click preview:** Renders a demo preview of how the user's name card enters a live room.

### 📥 37. Live Moderation Console (`LiveModerationView` · `/live-moderation`)
*   **Visual State:** Dashboard panel listing recent safety flags, bad comments flagged, and security SOS calls.
*   **Interactions (`onClick`):**
    *   **Click SOS items:** Triggers moderator room entry or alarm logs.

### 📥 38. PK Battle Screen (`PKBattleView` · `/pk-battle`)
*   **Visual State:** Matchmaking page with split layout, challenge radar animation, matching criteria, and target invitation lists.
*   **Interactions (`onClick`):**
    *   **Click "Quick Match":** Starts challengers radar simulation.
    *   **Click "Send PK Request" next to candidate host:** Launches outgoing invitation.

### 📥 39. Call View (`CallView` · `/call`)
*   **Visual State:** Tinder-style card deck layout displaying local matching profiles with bio keywords, swiping buttons (Like/Pass), match popups, and quick-access matched conversation list.
*   **Interactions (`onClick`):**
    *   **Click Like (Heart) / Pass (Cross):** Swipes card in/out of screen.
    *   **Click Match Inbox conversation:** Redirects straight to DMs.

---

## 📝 Maintenance Rules (Keep this up to date)

When a developer implements a new screen or links a mock button click to open a new route:
1.  Add the new screen to the **Progress Dashboard** statistics.
2.  Update the **Mermaid Flow Chart** by drawing an arrow (`-->`) from the parent screen to the new screen node.
3.  Add a new section under **Screen-by-Screen Navigation Matrix** detailing its visual state, interactive `onClick` buttons, and where they navigate.
