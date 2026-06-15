# Install Forge on your own iPhone (free)

These steps let you run Forge on **your iPhone using your own Mac + your own
Apple ID** — for free. (A free Apple ID can install onto *your own* devices, so
this works even though sharing across people's phones does not.)

> Trade-off: free installs **expire after 7 days**. Just re-run from Xcode to
> refresh. (TestFlight removes this, but needs the paid program.)

## One-time setup (~15 min)

### 1. Install the tools
- Install **Xcode** from the Mac App Store (free, large download).
- Install **XcodeGen** (generates the project):
  ```bash
  # If you have Homebrew:
  brew install xcodegen
  # No Homebrew? install it first from https://brew.sh
  ```

### 2. Get the code
```bash
git clone https://github.com/sinhaankur/Forge.git
cd Forge
xcodegen generate
open Forge.xcodeproj
```

### 3. Sign in with YOUR Apple ID
- Xcode → **Settings** (⌘,) → **Accounts** → **+** → **Apple ID** → sign in with
  *your own* Apple ID (any free Apple ID works).

### 4. Set your team + a unique bundle ID
In `project.yml`, change two things to be yours:
- `DEVELOPMENT_TEAM: ""` → leave empty (Xcode auto-selects your personal team), and
- the bundle IDs `com.sinhaankur.forge` → e.g. `com.<yourname>.forge`
  (and `.watchkitapp` likewise). Then run `xcodegen generate` again.

*(Or simpler: open the project, select the **Glow** target → **Signing &
Capabilities** → check **Automatically manage signing** → pick your **Personal
Team**. If it complains the bundle ID is taken, change it to something unique.)*

### 5. Prepare your iPhone
- Plug your iPhone into your Mac, **unlock** it, tap **Trust This Computer**.
- On the iPhone: **Settings → Privacy & Security → Developer Mode → On** →
  restart → confirm **Turn On**.

### 6. Run it
- In Xcode, pick **your iPhone** as the destination (top bar) → press **▶ Run**.
- First launch: iPhone may say *Untrusted Developer* →
  **Settings → General → VPN & Device Management → tap your Apple ID → Trust** →
  open Forge.

## That's it
Forge runs on your phone with full features. Your data stays **on your device** —
nothing is shared with anyone, including Ankur. Genetics, health, everything is
local and private to you.

## When it stops opening (after ~7 days)
Just reconnect and press **▶ Run** in Xcode again to refresh the 7-day signing.

---
Questions? The app is open source — see `docs/` in the repo for how it works.
