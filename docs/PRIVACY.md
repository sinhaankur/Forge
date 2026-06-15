# Forge — Privacy

**Health over everything else — including your privacy.** Forge is built so your
most personal data never leaves your phone.

## Principles
- **No account. No server. No analytics.** Forge has no backend; it cannot
  upload your data because there is nowhere to upload it to.
- **On-device only.** Routines, sleep, profile, and derived genetic traits live
  in a local SwiftData store on your device.
- **Read-only, minimal scopes.** Health, Calendar, Motion, and Photos are read
  with the smallest scope needed and used locally.
- **On-device AI.** Apple Foundation Models runs the LLM on your phone — prompts
  and your data are never sent to any cloud.

## What Forge reads (and why)
| Source | Used for | Leaves device? |
|---|---|---|
| Apple Health | Activity, sleep, workouts → progress & readiness | No |
| CoreMotion | Steps, distance, activity-type timeline | No |
| Calendar (EventKit) | Find free time around meetings for reminders | No |
| Photos | Pick a profile avatar (downscaled, stored locally) | No |
| DNA file (you choose) | Parsed locally into trait categories | No |

## Your DNA, specifically
- You import a raw DNA file; Forge parses it **on-device** and keeps only coarse
  **trait categories** (e.g. "high aerobic response") — **never your raw
  genotypes**, and never the file itself.
- The source code contains the parsing rules and SNP IDs, but **none of your
  results**. This repository is code-only and has never contained personal data.

## Sharing
Forge is meant for you (and, if you choose, family). "Sharing" means installing
the app on another person's device — each install is fully independent and that
person's data stays on *their* phone. There is no shared account or pooled data.

## Not medical advice
Forge provides general wellness and fitness information only, including optional
genetic-trait and readiness insights. It is not a medical device and does not
diagnose, treat, or prevent any condition. Consult a qualified professional
before starting any exercise, nutrition, or health program.
