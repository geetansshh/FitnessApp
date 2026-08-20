# FitnessApp

A minimal, fast calorie / macro / water / weight tracker — a simpler alternative to
MyFitnessPal. **Local-first** SwiftUI iOS app with an **optional** Go backend for cloud backup.

```
FitnessApp/
├── ios/        SwiftUI app (MVVM, SwiftData local storage, Swift Charts)
└── backend/    Go REST API (Postgres) — optional cloud backup
```

## iOS app

Requires **Xcode 16+** (free on the Mac App Store) to build/run/ship. You can edit the
Swift files in VS Code, but building an iOS app and pushing to TestFlight only works in Xcode.

```
open ios/FitnessApp.xcodeproj
```
Pick an iPhone simulator and hit ⌘R. Everything works offline — no backend needed.

**Features:** onboarding with a Mifflin-St Jeor calorie/macro calculator (+ water goal); a Today
dashboard with date navigation, a logging **streak**, calorie ring, macro bars, water,
weight-goal progress with an **ETA to goal**, and **one-tap quick actions** (log food / add a
glass / weigh in) without leaving the tab; food logging grouped by **meal** with a **searchable
built-in food table** (~70 common foods, servings stepper), **recent foods**, per-meal add
buttons, swipe-to-repeat, and tap-to-edit; a water tracker with preset amounts and
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

Go + Postgres (`pgx`), no CGO — builds a static binary and a distroless image.

```
cd backend
export DATABASE_URL='postgres://...'
go run .
```
Listens on `:8080`; tables are created on startup. See `backend/README.md` for the API and
deploy steps (`render.yaml` at the repo root is a one-click Render blueprint).
In the app: Settings → enable server sync → set the URL and API key → "Back up now".
Backup is push-only and **idempotent** — entries carry their local id, so re-running it
updates rows instead of duplicating them.

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
