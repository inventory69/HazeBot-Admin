# Building HazeBot Admin 🔨

This guide covers building the admin panel for different platforms.

## Prerequisites

- **Flutter SDK** 3.0+ - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Platform-specific tools:**
  - **Web:** Chrome browser
  - **Android:** Android Studio or Android SDK
  - **Linux:** Required libraries (see below)

---

## Web Build

### Production Build

```bash
# Build optimized web version
flutter build web --release --pwa-strategy=none

# Output: build/web/
```

### Test Locally

```bash
# Start local server (port 8080)
python3 scripts/spa_server.py --dir build/web --port 8080

# Or navigate to build directory and use Python's built-in server
cd build/web
python3 -m http.server 8000
```

Open browser: `http://localhost:8000`

⚠️ **Important:** Hard refresh (Ctrl+Shift+R) after new builds to clear browser cache!

### Deployment

The web build is a static site that can be deployed to:
- **GitHub Pages**
- **Netlify**
- **Vercel**
- **Cloudflare Pages**
- Any static hosting service

**Note:** Make sure your hosting supports SPA (Single Page Application) routing.

---

## Android Build

### Development Build

```bash
# Build debug APK for testing
flutter build apk --debug
```

### Release Build (Standard)

```bash
# Build single universal APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

**File size:** ~50MB (contains all architectures)

### Release Build (Split APKs)

```bash
# Build separate APKs per architecture
flutter build apk --split-per-abi --release

# Output: build/app/outputs/flutter-apk/
# - app-armeabi-v7a-release.apk  (~18MB, 32-bit ARM)
# - app-arm64-v8a-release.apk    (~20MB, 64-bit ARM)
# - app-x86_64-release.apk       (~22MB, x86 64-bit)
```

**Recommended:** Use split APKs for smaller downloads. Most modern devices use `arm64-v8a`.

### App Bundle (Google Play)

```bash
# Build Android App Bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

**Use for:** Publishing to Google Play Store. Google Play generates optimized APKs for each device.

### Signing Configuration

For production builds, configure signing in `android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=/path/to/keystore.jks
```

See [Flutter Android Deployment](https://docs.flutter.dev/deployment/android) for details.

---

## Linux Desktop Build

### Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# Fedora
sudo dnf install clang cmake ninja-build gtk3-devel xz-devel

# Arch Linux
sudo pacman -S clang cmake ninja gtk3 xz
```

### Build

```bash
# Build release bundle
flutter build linux --release

# Output: build/linux/x64/release/bundle/
```

### Distribution

The `bundle/` directory contains:
- `hazebot_admin` - Executable
- `lib/` - Shared libraries
- `data/` - Assets

**Package for distribution:**
```bash
cd build/linux/x64/release
tar -czf hazebot-admin-linux.tar.gz bundle/
```

Users extract and run: `./bundle/hazebot_admin`

---

## Build Optimization

### Reduce APK Size

```bash
# Use split APKs
flutter build apk --split-per-abi --release

# Enable code shrinking (already configured in build.gradle)
flutter build apk --release --shrink
```

### Obfuscate Code

```bash
# Obfuscate Dart code (harder to reverse-engineer)
flutter build apk --release --obfuscate --split-debug-info=./symbols

# Save symbols/ directory for crash reporting
```

### Performance Profiling

```bash
# Build with profiling enabled
flutter build apk --profile

# Run performance overlay
flutter run --profile
```

---

## Environment-Specific Builds

### Development (Local API)

`.env`:
```env
API_BASE_URL=http://localhost:5070/api
```

### Staging

`.env.staging`:
```env
API_BASE_URL=https://staging.example.com/api
```

Build:
```bash
# Copy staging config
cp .env.staging .env

# Build
flutter build apk --release
```

### Production

`.env.production`:
```env
API_BASE_URL=https://api.example.com/api
```

Build:
```bash
# Copy production config
cp .env.production .env

# Build
flutter build apk --release
```

---

## Continuous Integration

### GitHub Actions

See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for complete CI/CD setup.

**Quick overview:**
- Automated builds on push/PR
- Web, Android, and Linux builds
- Artifact upload for downloads
- Automatic GitHub Releases

### Build Matrix

```yaml
strategy:
  matrix:
    platform: [web, android, linux]
```

---

## Troubleshooting

### "Gradle build failed"

```bash
# Clean build cache
flutter clean
rm -rf android/.gradle

# Rebuild
flutter pub get
flutter build apk --release
```

### "SDK version mismatch"

Check `android/app/build.gradle.kts`:
```kotlin
compileSdk = 35
minSdk = 28
targetSdk = 35
```

### "Unable to locate Android SDK"

```bash
# Set Android SDK path
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Or configure in Android Studio:
# File → Project Structure → SDK Location
```

### Web build cache issues

```bash
# Clear Flutter web cache
flutter clean
rm -rf build/web

# Clear browser cache
# Chrome: Ctrl+Shift+Delete → Clear browsing data
```

### Linux build dependencies missing

```bash
# Verify all dependencies
flutter doctor -v

# Reinstall if needed (Ubuntu/Debian)
sudo apt-get install --reinstall clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

---

## Build Scripts

### Create build script (Linux/Mac)

`build.sh`:
```bash
#!/bin/bash

echo "Building HazeBot Admin..."

# Web
echo "Building Web..."
flutter build web --release --pwa-strategy=none

# Android (split APKs)
echo "Building Android..."
flutter build apk --split-per-abi --release

# Linux
echo "Building Linux..."
flutter build linux --release

echo "✅ All builds complete!"
echo "Web: build/web/"
echo "Android: build/app/outputs/flutter-apk/"
echo "Linux: build/linux/x64/release/bundle/"
```

Make executable: `chmod +x build.sh`

Run: `./build.sh`

---

## �️ Build Scripts

The `scripts/` directory contains helper scripts for building and development:

### spa_server.py
**Purpose:** Minimal SPA (Single Page Application) server for testing web builds locally.

**Usage:**
```bash
# Serve web build
python3 scripts/spa_server.py --dir build/web --port 8080

# Custom directory and port
python3 scripts/spa_server.py --dir path/to/build --port 3000
```

**Features:**
- Serves static files from build directory
- Falls back to `index.html` for client-side routing
- Perfect for testing web builds before deployment

### generate_adaptive_icons.sh
**Purpose:** Generate Android adaptive launcher icons from a source PNG.

**Requirements:**
- ImageMagick (`sudo apt-get install imagemagick`)
- Source image: `app_icon_source.png` in project root

**Usage:**
```bash
# Run from project root
./scripts/generate_adaptive_icons.sh
```

**Output:**
- Foreground/background layers for all densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- XML descriptors in `mipmap-anydpi-v26/`
- Adaptive icons for Android 8.0+ (API 26)

### create_notification_icon.sh
**Purpose:** Create monochrome notification icons for Android status bar.

**Requirements:**
- ImageMagick
- Existing launcher icon in `android/app/src/main/res/mipmap-xxxhdpi/`

**Usage:**
```bash
# Run from project root
./scripts/create_notification_icon.sh
```

**Output:**
- White monochrome icons in `drawable-*/` directories
- All densities: 24dp (mdpi) to 96dp (xxxhdpi)
- Ready for Android notification system

---

## �🔗 Next Steps

- 📱 [APK Installation Guide](APK_DOWNLOAD.md) - Install built APKs
- 🔥 [Firebase Setup](FIREBASE_SETUP.md) - Configure push notifications
- 🚀 [GitHub Actions](GITHUB_ACTIONS.md) - Automated CI/CD builds
- 🧪 [Development Guide](DEVELOPMENT.md) - Development workflows
- 🏠 [Documentation Index](README.md) - All documentation

---

## 🆘 Getting Help

- **Build Issues:** Check troubleshooting section above
- **Platform-Specific:** Review [Flutter Documentation](https://docs.flutter.dev/deployment)
- **Questions:** Open an issue on [GitHub](https://github.com/YOUR_USERNAME/HazeBot-Admin/issues)
