# iOS Build Guide — MacBook Air M4

## Prerequisites
- MacBook Air M4 with macOS
- iPhone with USB cable
- Free Apple ID (for personal device install)

---

## STEP 1: Install Flutter

Open **Terminal** and run:

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Flutter
brew install --cask flutter

# Verify installation
flutter doctor
```

---

## STEP 2: Install Xcode

1. Open **App Store** → search **Xcode** → Install (~15GB, one-time)
2. After install, run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

---

## STEP 3: Clone & Set Up the Project

```bash
git clone https://github.com/RajasekharPalleti/budget_tracker.git
cd budget_tracker
flutter pub get
cd ios && pod install && cd ..
```

---

## STEP 4: Open in Xcode & Configure Signing

```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Click **Runner** in the left sidebar
2. Go to **Signing & Capabilities** tab
3. Check ✅ **Automatically manage signing**
4. Select your **Team** (sign in with Apple ID if prompted — free account works)
5. Set a unique **Bundle Identifier**, e.g.: `com.raja.budgettracker`

---

## STEP 5: Build & Install

### Option A — Run directly on iPhone (fastest, no IPA needed)

Plug your iPhone into your Mac via USB, then:

```bash
# List connected devices
flutter devices

# Install and run directly on your iPhone
flutter run --release -d <your-iphone-device-id>
```

### Option B — Build an IPA file

```bash
flutter build ipa --release
```

IPA location:
```
build/ios/ipa/budget_tracker.ipa
```

---

## STEP 6: Install IPA on iPhone

### Via Xcode (USB — simplest)
1. Open Xcode → **Window → Devices and Simulators**
2. Select your iPhone
3. Click **+** under Installed Apps
4. Select `build/ios/ipa/budget_tracker.ipa`

### Via Apple Configurator 2 (free)
1. Download **Apple Configurator 2** from Mac App Store
2. Connect iPhone via USB
3. Drag the `.ipa` file onto your device

### Via AltStore (wireless, free — up to 3 apps)
1. Install [AltStore](https://altstore.io) on Mac + iPhone
2. Drag the `.ipa` into AltStore on iPhone

---

## Time Estimate

| Step | Time |
|---|---|
| Flutter install | ~5 min |
| Xcode install | ~15 min (one-time) |
| Clone + pod install | ~3 min |
| Xcode signing setup | ~3 min |
| Build IPA | ~3 min |
| Install on iPhone | ~1 min |
| **Total** | **~30 min** |

> 💡 **Tip:** Use `flutter run --release` with your iPhone plugged in for the fastest test — it skips the IPA step entirely.
