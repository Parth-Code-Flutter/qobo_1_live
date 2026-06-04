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
├── services/          # Low-level network clients, theme persistence, header config
├── theme/             # Light/dark ThemeData + semantic color tokens
└── utils/             # Reusable UI widgets, validators, formatters, and helpers
```

---

## 🎨 Theming (Light / Dark / System)

The app supports **Light**, **Dark**, and **System** appearance. The user selects the mode under **Settings → Appearance**. The choice is persisted via `ThemeController` (`kStorageThemeMode` in secure storage).

### Core files

| File | Role |
| --- | --- |
| `lib/theme/app_theme.dart` | Builds `ThemeData` for light and dark |
| `lib/theme/app_theme_colors.dart` | Semantic tokens (`AppThemeColors` `ThemeExtension`) |
| `lib/theme/theme_context.dart` | `context.appColors` accessor |
| `lib/services/theme_controller.dart` | Load/save mode; `Get.changeThemeMode` |
| `lib/app/qobo_app.dart` | `GetMaterialApp` with `theme`, `darkTheme`, `themeMode` |

### Shared UI widgets

| Widget | When to use |
| --- | --- |
| `AppScreenBackground` | Main tabs with hero gradient (Discover, Live Rooms, Profile, Messages) |
| `ThemedScaffold` | Standard screens; defaults scaffold/surface to theme |
| `AppSearchField` | Inline search bars (tabs, headers) |
| `AppTextField` | Forms; uses theme fill, border, hint, and label colors |
| `CommonAppBarWidget` | Prefer without custom `titleColor` / `backgroundColor` overrides |

### Rules for new and updated screens

1. **Do not** use `kColorWhite`, `kColorText`, `kColorBackground`, or `kImgBG` for screen chrome unless it is a fixed brand accent (e.g. primary buttons, gradient CTAs).
2. **Do** read colors from `context.appColors` (or `Theme.of(context).colorScheme` for Material defaults).
3. **Hero / tab headers** (content on lavender gradient): `onHeroPrimary`, `onHeroSecondary`, `onHeroMuted`.
4. **Cards, sheets, lists**: `surface`, `textPrimary`, `textSecondary`, `hint`, `divider`, `border`.
5. **Search & text fields**: `searchFieldFill`, `searchFieldBorder`, `searchFieldHint` — use `AppSearchField` / `AppTextField` instead of one-off `TextField` styling.
6. **Bottom nav**: `navBarTop`, `navBarBottom`, `navLabelSelected`, `navLabelUnselected` (see `bottom_nav_view.dart`).
7. When touching an existing screen, migrate hardcoded background/text colors in the same change when practical.

### Example

```dart
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/app_widgets/app_search_field.dart';

@override
Widget build(BuildContext context) {
  final colors = context.appColors;
  return Column(
    children: [
      const AppSearchField(hintText: 'Search'),
      SemiBoldText(
        text: 'Section title',
        color: colors.onHeroPrimary,
      ),
    ],
  );
}
```

### Adding or changing tokens

1. Add fields to `AppThemeColors` in `app_theme_colors.dart` (both `light` and `dark` static instances).
2. Wire `copyWith` and `lerp`.
3. Use the token in UI via `context.appColors.yourToken`.
4. Optionally map the token in `app_theme.dart` `inputDecorationTheme` or other `ThemeData` slots if it should apply globally.

### Cursor / agent conventions

Theming rules for AI-assisted edits live in `.cursor/rules/qobo-flutter-getx-conventions.mdc` (section **6. Theming**). Keep that section in sync when conventions change.
