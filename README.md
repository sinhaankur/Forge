<p align="center">
  <img src="Branding/glow-icon-512.png" width="120" alt="Forge icon">
</p>

<h1 align="center">Forge</h1>
<p align="center"><em>Built daily.</em></p>

Forge is a private, **on-device** iOS + Apple Watch app for personal **fitness**,
**skincare**, and **nutrition** routines — with personalized CrossFit
programming, reminders, and progress tracking. No account, no server, no
analytics. Your data never leaves your device.

## Features

- **Today** — a big-date checklist of the day's routines; tap to complete.
- **Fitness** — build routines or **generate a personalized CrossFit plan** from
  your body metrics, experience, and injuries. Every session opens with a
  structured, injury-aware **warm-up** (Raise → Mobilize → Activate → Potentiate).
- **Per-workout targets** — set a target (reps / weight / duration / distance /
  calories) and log how you did; progress can be pre-filled from Apple Health.
- **Skincare** — morning & evening routines with reminders.
- **Nutrition** — a Bihari/Indian body-recomposition meal plan with a daily
  protein tracker and fat-loss tips.
- **Progress** — streaks, a dot-calendar consistency view, and a bento stat grid.
- **Apple Watch** — view today's routines, check them off, see your streak.
- **Privacy-first** — optional Apple Health reads are on-device, read-only,
  minimal scope; optional genetic-trait fields never leave the device.

## Tech

- SwiftUI · SwiftData (local persistence) · HealthKit · WatchConnectivity ·
  UserNotifications
- iOS 17+ / watchOS 10+ · Xcode 26 · project generated via XcodeGen

## Project layout

```
Glow/            iOS app sources (folder name retained from original project name)
  Models/        SwiftData models (routines, steps, completions, meals, profile)
  Resources/     Theme & design system
  Services/      Seed data, notifications, Health, connectivity, CrossFit generator
  Views/         Today, Fitness, Skincare, Nutrition, Progress
GlowWatch/       watchOS app sources
Branding/        Brand guide & logo
project.yml      XcodeGen spec — edit this, then `xcodegen generate`
```

## Run it

```bash
brew install xcodegen        # if needed
xcodegen generate            # creates Forge.xcodeproj
open Forge.xcodeproj         # pick the Forge scheme + an iPhone simulator, ⌘R
```

See **[SETUP.md](SETUP.md)** for on-device install and TestFlight.

> Not medical advice. Consult a professional before starting any exercise or
> nutrition program, especially with existing injuries.
