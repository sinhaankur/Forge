# Glow — Setup, Run & TestFlight Guide

The project is generated from `project.yml` with **XcodeGen**, so `Glow.xcodeproj`
is reproducible. If you ever edit targets/settings, edit `project.yml` and run
`xcodegen generate` rather than changing the project by hand.

---

## 1. Open & run in the Simulator (no Apple account needed)

```bash
brew install xcodegen        # only if not already installed
cd Glow
xcodegen generate            # creates/refreshes Glow.xcodeproj
open Glow.xcodeproj
```

In Xcode:
1. Select the **Glow** scheme and an **iPhone Simulator** (e.g. iPhone 16).
2. Press **⌘R**. The app launches with seeded routines and the Bihari meal plan.
3. To preview the **watch app**: in the scheme menu pick a paired Watch simulator,
   or run the iOS app and open the Watch simulator — today's routines sync over.

> The Simulator does **not** provide real Health data; HealthKit reads return 0
> there. Test Health on a real device.

---

## 2. Get it onto your own iPhone & Apple Watch (free, 7-day signing)

You can sideload with a **free** Apple ID — no paid program required, but builds
expire after 7 days and you can't use TestFlight.

1. Xcode ▸ **Settings ▸ Accounts** ▸ add your Apple ID.
2. Select the **Glow** target ▸ **Signing & Capabilities** ▸ check
   *Automatically manage signing* ▸ pick your **Personal Team**.
3. Do the same for the **GlowWatch** target.
4. You may need to make the bundle IDs unique to you — change
   `com.sinhaankur.glow` in `project.yml` (and `.watchkitapp`) to something like
   `com.<yourname>.glow`, then `xcodegen generate`.
5. Plug in your iPhone, select it as the run destination, **⌘R**.
6. On the phone: **Settings ▸ General ▸ VPN & Device Management** ▸ trust your
   developer certificate.

---

## 3. TestFlight (requires the paid Apple Developer Program — $99/yr)

This is the path to **install & test before launch**.

### One-time setup
1. Enrol at <https://developer.apple.com/programs/> (paid).
2. In `project.yml`, set `DEVELOPMENT_TEAM` to your **Team ID** (found in the
   developer portal ▸ Membership). Run `xcodegen generate`.
3. In **App Store Connect** (<https://appstoreconnect.apple.com>):
   - **Apps ▸ +** ▸ New App. Platform iOS, name "Glow", bundle ID
     `com.sinhaankur.glow` (register the ID in the portal first if prompted),
     SKU `glow-001`.

### Each build
1. In Xcode pick **Any iOS Device (arm64)** as the destination.
2. **Product ▸ Archive**. When the Organizer opens, select the archive ▸
   **Distribute App ▸ TestFlight & App Store ▸ Upload**.
   - The embedded watch app ships automatically with the iOS app.
3. Wait for processing (email from App Store Connect, ~5–15 min).
4. In App Store Connect ▸ **TestFlight**:
   - Add yourself under **Internal Testing** (instant, no review), or set up
     **External Testing** (needs a quick Beta App Review).
   - Provide the export-compliance answer (Glow uses no non-exempt encryption →
     "No").
5. Install **TestFlight** from the App Store on your iPhone, sign in with the
   same Apple ID, and install Glow. The watch app installs from the iPhone
   Watch app once the phone build is on.

### Bumping the build number
Increment `CURRENT_PROJECT_VERSION` (and `MARKETING_VERSION` for new versions)
in `project.yml`, regenerate, re-archive. Each upload needs a unique build
number.

---

## Bundle identifiers

| Target | Bundle ID |
|--------|-----------|
| iOS app | `com.sinhaankur.glow` |
| Watch app | `com.sinhaankur.glow.watchkitapp` |

Change the prefix in `project.yml` (`bundleIdPrefix` + the per-target
`PRODUCT_BUNDLE_IDENTIFIER`) if you want them under your own domain.

---

## Capabilities to enable in the portal

When you register the App ID, enable **HealthKit**. Automatic signing in Xcode
will then match the entitlement in `Glow/Glow.entitlements`.
