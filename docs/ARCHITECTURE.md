# Forge — Architecture

A small, lightweight SwiftUI app (~7 MB). No backend, no third-party SDKs.

## Stack
- **SwiftUI** (iOS 17+, watchOS 10+) — forced dark, pure-black bento UI.
- **SwiftData** — local persistence (the single source of truth).
- **Apple frameworks only:** HealthKit, CoreMotion, EventKit, UserNotifications,
  WatchConnectivity, PhotosUI, and **FoundationModels** (on-device LLM, iOS 26).
- **XcodeGen** — the project is generated from `project.yml` (don't hand-edit the
  `.xcodeproj`; edit the spec and run `xcodegen generate`).

## Targets
| Target | Platform | Bundle ID |
|---|---|---|
| `Glow` (display name **Forge**) | iOS | `com.sinhaankur.forge` |
| `GlowWatch` | watchOS (embedded) | `com.sinhaankur.forge.watchkitapp` |

> Folder/symbol names keep the original `Glow` prefix; the product is **Forge**.

## Layout
```
Glow/
  Models/Models.swift        SwiftData models (Routine, RoutineStep,
                             RoutineCompletion, Meal, UserProfile, SleepLog)
  Resources/                 Theme, Haptics, ExerciseFigure
  Services/                  Stores + device integrations:
                               RoutineStore, SleepStore, SeedData,
                               NotificationService, HealthService, MotionService,
                               CalendarService, ConnectivityService,
                               WorkoutGenerator, ExerciseLibrary, ExerciseGuide,
                               PlanParser, HormoneInsight, DNAImporter, AIService
  Views/                     Today, Sleep, Fitness, Skincare, Nutrition,
                             Progress, DNA, Welcome, About, Focus session, …
GlowWatch/                   watchOS companion (today list + sync)
docs/                        this documentation
project.yml                  XcodeGen spec (targets, signing, Info.plist)
```

## Data model (SwiftData)
- `Routine` 1—* `RoutineStep`, 1—* `RoutineCompletion`.
- `Routine` carries an optional session **target** (metric + value).
- `UserProfile` (single row): identity, body metrics, injuries, days/week, and
  optional **genetic trait categories** (never raw genotypes).
- `SleepLog` — one row per night.
- `Meal` — the nutrition plan.

## Device integrations (all read-only, on-device)
- **HealthService** (HealthKit): active energy, steps, distance, workouts, sleep.
  Requires the HealthKit entitlement → paid account; off by default so free
  installs work.
- **MotionService** (CoreMotion): pedometer steps/distance + activity-type
  timeline (driving/walking/running/cycling/stationary). Works on free accounts.
- **CalendarService** (EventKit): finds free gaps around meetings.
- **AIService** (FoundationModels): note→plan + coaching; falls back to
  `PlanParser` (regex) when unavailable.

## Build
```bash
brew install xcodegen
xcodegen generate
# Simulator:
xcodebuild -project Forge.xcodeproj -scheme Forge \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
# Device (set your own team):
xcodebuild -project Forge.xcodeproj -target Glow \
  -destination 'id=<DEVICE_UDID>' -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=<YOUR_TEAM_ID> build
```
