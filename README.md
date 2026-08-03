# FitnessApp

A minimal, fast calorie / macro / water / weight tracker — a simpler alternative to
MyFitnessPal. **Local-first** SwiftUI iOS app with an **optional** Go backend for cloud backup.

```
FitnessApp/
├── ios/        SwiftUI app (MVVM, SwiftData local storage, Swift Charts)
└── backend/    Go REST API (stdlib only, JSON-file store) — optional
```

## iOS app

Requires **Xcode 16+** (free on the Mac App Store) to build/run/ship. You can edit the
Swift files in VS Code, but building an iOS app and pushing to TestFlight only works in Xcode.

```
open ios/FitnessApp.xcodeproj
```
Pick an iPhone simulator and hit ⌘R. Everything works offline — no backend needed.

**Features:** onboarding with a Mifflin-St Jeor calorie/macro calculator (+ water goal); a Today
dashboard with date navigation, a logging **streak**, calorie ring, macro bars, water, and
weight-goal progress with an **ETA to goal**; food logging grouped by **meal** (breakfast/lunch/
dinner/snack) with quick-add presets, **recent foods**, and tap-to-edit; a water tracker with
configurable local reminder times; **weight-trend** and **14-day calorie-history** charts; editable
goals that recompute the target; **Apple Health** two-way weight sync + steps/energy read; a
**Home/Lock-Screen widget** (calories left + water); and settings (units, reminders, sync, reset).

**Stack:** SwiftUI · SwiftData (local) · Swift Charts · WidgetKit · HealthKit · UserNotifications · MVVM.

**Capabilities:** HealthKit + App Groups (`group.com.geetansh.FitnessApp`) — both work on a free
personal team for development. The widget target is `FitnessAppWidgetExtension`.

**Debug helpers** (compiled out of Release): launch args `-seedDemo` (loads sample data) and
`-tab food|goals|water|settings` (opens a tab) for screenshot verification.
Deployment target iOS 17. Bundle id `com.fitnessapp.FitnessApp` (change it under target
Signing & Capabilities and set your Team before running on a device / TestFlight).

## Backend (optional)

Pure Go standard library — no modules to download, no CGO.

```
cd backend
go run .
```
Listens on `:8080`, persists to `./data/fitness.json`. See `backend/README.md` for the API.
In the app: Settings → enable server sync → set the URL → "Back up now".

The calorie math in `ios/.../Calc/CalorieCalculator.swift` and `backend/internal/calc`
is intentionally identical so offline and server results match.

## Shipping to TestFlight

1. Add a 1024×1024 app icon to `ios/FitnessApp/Assets.xcassets/AppIcon.appiconset`.
2. In Xcode: set your Apple Developer Team, a unique bundle id, then Product → Archive.
3. Distribute App → App Store Connect → upload → add testers in TestFlight.
   (Requires Apple Developer Program membership.)

## Not in v1 (by design)

Barcode scanning, big food database, recipes, social, AI analysis, gamification,
subscriptions. Cloud sync is push-only backup; two-way merge is a later addition.
