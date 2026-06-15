# How the Apple Watch reads Forge's data

The watch app is a **read-and-act companion**, not the source of truth. The
iPhone owns the SwiftData store; the watch shows a lightweight snapshot and sends
back simple commands.

## Data flow (mapping)

```
            iPhone (source of truth)                     Apple Watch
   ┌────────────────────────────────────┐        ┌────────────────────────┐
   │ SwiftData store                     │        │ ConnectivityService    │
   │  Routine / RoutineCompletion /      │        │  @Published snapshot    │
   │  SleepLog / UserProfile / Meal      │        └────────────┬───────────┘
   │                                     │                     │ renders
   │ RoutineStore.snapshot(in:)          │                     ▼
   │   → TodaySnapshot (Codable)         │        ┌────────────────────────┐
   └───────────────┬─────────────────────┘        │ WatchTodayView          │
                   │                               │  • today's routines     │
                   │ ① push (applicationContext)   │  • check-off toggles    │
                   ▼                               │  • current streak       │
   ┌────────────────────────────────────┐         └────────────┬───────────┘
   │ WCSession.updateApplicationContext  │ ───────────────────► │
   │   ["snapshot": <JSON data>]         │   WatchConnectivity   │
   └────────────────────────────────────┘                      │
                   ▲                                            │
                   │ ② sendMessage / transferUserInfo           │
                   │   WatchCommand.complete(routineID, value)  │
                   └────────────────────────────────────────────┘
```

## The three moving parts

1. **`TodaySnapshot`** (`ConnectivityService.swift`) — a small `Codable` value:
   each routine's id, name, kind, time-of-day, step count, target summary, and
   `completedToday`, plus the current `streak`. This is the *only* data that
   crosses to the watch — no full history, no health data.

2. **Phone → Watch (push):** whenever routines change or a completion is logged,
   the phone calls `ConnectivityService.push(snapshot)` →
   `WCSession.updateApplicationContext`. Application context always holds the
   *latest* state (older ones are coalesced), so the watch shows current data
   even if it was asleep.

3. **Watch → Phone (commands):** tapping a routine on the watch sends
   `WatchCommand.complete(routineID:achievedValue:)` via `sendMessage` (or
   `transferUserInfo` when not reachable). The phone applies it through
   `RoutineStore.toggleCompletion` and pushes a fresh snapshot back.

## Why this design

- **Single source of truth (phone).** The watch never writes to the database
  directly, avoiding sync conflicts. It only requests changes.
- **Tiny payloads.** `applicationContext` is built for small, latest-state
  snapshots — ideal for a glanceable "today" view.
- **Privacy preserved.** Only the day's routine summary + streak cross the link.
  Health, sleep, calendar, and DNA-derived data stay on the phone.

## Where it lives in code

| Concern | File |
|---|---|
| Snapshot + commands + WCSession wrapper | `Glow/Services/ConnectivityService.swift` |
| Building the snapshot | `Glow/Services/RoutineStore.swift` → `snapshot(in:)` |
| Push points | `Glow/GlowApp.swift` (`pushSnapshot`), completion toggles |
| Watch UI | `GlowWatch/WatchTodayView.swift` |

## Activity / Apple Health note

Activity, sleep, and workout *patterns* come from **Apple Health on the phone**,
which already aggregates Apple Watch + Strava + other sources. Forge reads Health
on the phone (on-device) rather than reading sensors on the watch directly —
so "all data and patterns are linked to Apple activity" by reading the Health
store, keeping one consistent, private source.
