<p align="center">
  <img src="Branding/glow-icon-512.png" width="120" alt="Glow icon">
</p>

<h1 align="center">Glow</h1>
<p align="center"><em>Show up. Glow up.</em></p>

Glow is a private, **on-device** iOS + Apple Watch app for personal **fitness**,
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
- **Privacy-first HealthKit** — read-only, on-device, minimal scopes.

## Tech

- SwiftUI · SwiftData (local persistence) · HealthKit · WatchConnectivity ·
  UserNotifications
- iOS 17+ / watchOS 10+ · Xcode 26

## Project layout

```
Glow/
  Models/            SwiftData models (routines, steps, completions, meals, profile)
  Resources/         Theme & design system
  Services/          Seed data, notifications, Health, connectivity, CrossFit generator
  Views/             Today, Fitness, Skincare, Nutrition, Progress
Branding/            Brand guide & logo
```

## Status

Source + branding are complete. The Xcode project (iOS + watchOS targets) and
TestFlight configuration are being added next — see `SETUP.md` once available.

> Not medical advice. Consult a professional before starting any exercise or
> nutrition program, especially with existing injuries.
