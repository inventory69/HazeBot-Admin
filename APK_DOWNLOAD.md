# Android APK Download & Installation Guide

Complete guide for downloading and installing the HazeBot Admin Panel on Android devices.

## 📥 Download Options

### Option 1: Latest Release (Recommended)

**Direct Download:**
1. Visit: https://github.com/inventory69/HazeBot-Admin/releases/latest
2. Scroll to **Assets** section
3. Click `hazebot-admin-release.apk`
4. APK downloads to your device

**Advantages:**
- ✅ Always the latest stable version
- ✅ Direct APK file (no extraction needed)
- ✅ Release notes with changelog
- ✅ Semantic versioning (e.g., `v2025.11.16+123`)
- ✅ Obtainium compatible for auto-updates

### Option 2: GitHub Actions Artifacts

**For Testing Bleeding-Edge Builds:**
1. Go to: https://github.com/inventory69/HazeBot-Admin/actions
2. Click latest successful workflow run
3. Scroll to **Artifacts** section
4. Download `hazebot-admin-release` ZIP
5. Extract ZIP to get APK

**Disadvantages:**
- ❌ Packaged as ZIP
- ❌ Expires after 30 days
- ❌ Requires GitHub account
- ❌ May be unstable (development builds)

---

## 📱 Installation Steps

### 1. Download APK

Choose download option above and save APK to your device.

### 2. Enable Unknown Sources

**Android 8.0+ (Oreo and newer):**
1. Open **Settings** → **Apps & notifications**
2. Tap **Advanced** → **Special app access**
3. Tap **Install unknown apps**
4. Select your browser or file manager
5. Enable **Allow from this source**

**Older Android versions:**
1. Open **Settings** → **Security**
2. Enable **Unknown sources**
3. Confirm warning

### 3. Install APK

1. Open **Downloads** or **File Manager**
2. Tap the downloaded APK file
3. Tap **Install**
4. Wait for installation to complete
5. Tap **Open** or find app in app drawer

### 4. First Launch

1. Open HazeBot Admin
2. Enter API URL (if not pre-configured)
3. Login with credentials or Discord OAuth
4. Grant notification permissions (optional)

---

## 🔄 Auto-Updates with Obtainium

[Obtainium](https://github.com/ImranR98/Obtainium) automatically checks for new releases and notifies you.

### Setup:

1. Install Obtainium from [GitHub Releases](https://github.com/ImranR98/Obtainium/releases)
2. Open Obtainium
3. Tap **+** (Add App)
4. Enter: `https://github.com/inventory69/HazeBot-Admin`
5. Obtainium auto-detects release pattern
6. Tap **Add**

### How It Works:

- Checks for new releases periodically
- Notifies when update available
- Downloads and installs with one tap
- Respects semantic versioning

**Version Format:** `vYYYY.MM.DD-build.NNN`
- Example: `v2025.11.16-build.123`
- Date-based with build number for uniqueness

---

## ⚙️ Configuration

### API URL Setup

**Pre-configured APKs:**
- Test builds: `https://test-hazebot-admin.hzwd.xyz/api`
- Production builds: Your production API URL

**Manual Configuration:**
1. Open app
2. Login screen → **Settings** icon
3. Enter your API URL
4. Format: `https://your-domain.com/api` (no trailing slash)
5. Save and return to login

**API URL Examples:**
- **Local Testing:** `http://10.0.2.2:5070/api` (emulator)
- **LAN Testing:** `http://192.168.1.100:5070/api` (physical device)
- **Production:** `https://your-domain.com/api`

### API Configuration

The APK connects to the API URL configured during build time. Different builds can be configured for different environments:

**Test Builds:**
- Connect to test/staging API
- Debug logging enabled
- Typically named with `-test` suffix

**Production Builds:**
- Connect to production API
- Optimized logging
- Standard release naming

---

## 🏷️ Release Types

### Automated Releases

**Trigger:** Every push to `main` branch

**Process:**
1. GitHub Actions builds APK
2. Creates release with version tag
3. Attaches APK as asset
4. Generates release notes from commit

**Version Format:** `vYYYY.MM.DD-build.NNN`

### Manual Releases

**Trigger:** Git tags (e.g., `v1.0.0`)

**Process:**
```bash
cd /home/liq/gitProjects/HazeBot-Admin
git tag v1.0.0
git push origin v1.0.0
```

Creates versioned release alongside automated builds.

---

## 🔧 Troubleshooting

### "App not installed" Error

**Causes & Solutions:**
- **Signature mismatch:** Uninstall old version first
- **Corrupted download:** Re-download APK
- **Insufficient storage:** Free up space
- **Android version too old:** Requires Android 5.0+ (API 21)

### "Parse error" / "There was a problem parsing the package"

**Solutions:**
- Re-download APK (may be corrupted)
- Check Android version compatibility
- Ensure downloaded file is complete

### APK Won't Open After Install

**Solutions:**
- Check permissions granted
- Restart device
- Clear app cache: Settings → Apps → HazeBot Admin → Storage → Clear Cache

### Connection Issues

**Solutions:**
- Verify API URL is correct
- Check network connectivity
- Ensure API server is running
- Try switching WiFi/Mobile data

### Login Failures

**Solutions:**
- Verify credentials
- Check API URL configuration
- Test API in browser: `https://your-api-url.com/api/health`
- Check device date/time (affects JWT tokens)

---

## 🔐 Security Notes

### APK Safety

- ✅ Built from official GitHub repository
- ✅ Signed with release keystore
- ✅ Source code publicly auditable
- ✅ No third-party app stores involved

### Installation Permissions

**Required:**
- Internet access (API communication)

**Optional:**
- Notifications (update alerts, meme notifications)
- Storage (download memes, cache images)

### Data Privacy

- JWT tokens stored securely in SharedPreferences
- No sensitive data in plain text
- HTTPS required for production
- Tokens expire after 7 days

---

## 📊 APK Details

**Build Configuration:**
- **Build Type:** Release
- **Minimum SDK:** Android 5.0 (API 21)
- **Target SDK:** Android 14 (API 34)
- **Architecture:** Universal (arm64-v8a, armeabi-v7a, x86_64)
- **Size:** ~20-30 MB (varies by architecture)

**Optimizations:**
- ProGuard/R8 enabled (code shrinking)
- Resource shrinking enabled
- Native library compression

---

## 🆘 Support

**Problems?** Open an issue:
- GitHub Issues: https://github.com/inventory69/HazeBot-Admin/issues
- Include: Android version, APK version, error messages

**Questions?**
- Check [README.md](README.md) for full documentation
- Review [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)

---

**Last Updated:** November 16, 2025
**Minimum Android Version:** 5.0 (Lollipop)
**Recommended Android Version:** 8.0+ (Oreo or newer)
