# Qobo One Live — Mobile Client App

Client application for **Qobo One Live** built in Flutter using GetX, featuring audio/video streaming, chat integration, vertical dater scrolling, PK battles, and agency host onboarding.

## 🚀 Getting Started

To run the application locally, make sure you have Flutter SDK installed.

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
2.  **Run the application in development mode:**
    ```bash
    flutter run
    ```

---

## 📘 API & Client Navigation Roadmap Status

We maintain central tracking documents to streamline backend integrations and report progress directly to the client:

👉 **[SCREEN_API_INTEGRATION_ROADMAP.md (Screen API Status Matrix)](file:///Users/onlymac/Documents/Projects/qobo_one_live/SCREEN_API_INTEGRATION_ROADMAP.md)**
*   Provides a structured table of **all developed UI screens** (12 Done, 12 Needs Integration, 15 Needs Backend API).
*   Lists exactly what endpoints exist and what is needed from the backend team.

👉 **[APP_NAVIGATION_ROADMAP.md (Client UI/UX Roadmap)](file:///Users/onlymac/Documents/Projects/qobo_one_live/APP_NAVIGATION_ROADMAP.md)**
*   Provides a high-level **visual navigation flow chart** (using Mermaid).
*   Details a **Screen-by-Screen Interaction Matrix** mapping out exactly what happens on key clicks (`onClick` triggers) and which screens open.
*   Acts as a structured deliverable you can share with your client.

👉 **[API_DOCUMENTATION.md (Backend API Contract)](file:///Users/onlymac/Documents/Projects/qobo_one_live/API_DOCUMENTATION.md)**
*   Outlines the standard JSON envelope schemas and bearer token authorization rules.
*   Lists all **12 fully integrated APIs** with complete request/response JSON contracts for the backend team.
*   Provides a progress index showing repository-ready features vs mocked modules.

---

## 📁 Repository Structure

```
lib/
├── app/               # Views, Controllers, and Bindings by module (GetX)
├── constants/         # Global colors, icons, and local storage constants
├── repo/              # Repository layer for API services (auth, room, agency)
├── routes/            # GetX registered application routes
├── services/          # Low-level network clients, base API constants, and header config
└── utils/             # Reusable UI widgets, validators, formatters, and helpers
```
