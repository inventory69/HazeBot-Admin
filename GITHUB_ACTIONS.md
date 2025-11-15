# 🤖 GitHub Actions - Automated Build Setup

This document explains how the automated GitHub Actions workflow builds and publishes APK releases for HazeBot Admin.

## 🎯 Overview

The GitHub Actions workflow automatically:
- ✅ Builds Android APK on every push to `main`
- ✅ Runs tests before building
- ✅ Creates versioned releases with unique build numbers
- ✅ Uploads APK as release asset
- ✅ Generates release notes from commit messages
- ✅ Supports manual workflow triggers
- ✅ Compatible with Obtainium for automatic updates

## 🚀 How It Works

### Automatic Builds (Push to main)

When you push to the `main` branch:

1. **🔨 Build Process:**
   - Checks out code
   - Sets up Java 21 and Flutter 3.35.7
   - Installs dependencies
   - Generates version number: `YYYY.MM.DD+build_number`
   - Builds release APK with signing (if configured)

2. **📦 Release Creation:**
   - Creates a new GitHub release
   - Tag format: `vYYYY.MM.DD-build.NNN`
   - Attaches APK as release asset
   - Includes commit message in release notes

3. **📥 Download:**
   - APK available at: [Latest Release](https://github.com/inventory69/HazeBot-Admin/releases/latest)
   - File name: `hazebot-admin-test-release.apk`

### Tagged Releases (Manual)

Create a version tag to trigger a special release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This creates a tagged release alongside the automated builds.

## ⚙️ Setup Instructions

### 1️⃣ Configure GitHub Secrets

Required secrets for the workflow:

| Secret Name | Description | Required |
|------------|-------------|----------|
| `API_BASE_URL` | API endpoint URL | ✅ Yes |
| `KEYSTORE_BASE64` | Base64-encoded keystore file | ⚠️ Optional |
| `KEYSTORE_PASSWORD` | Keystore password | ⚠️ Optional |
| `KEY_PASSWORD` | Key password | ⚠️ Optional |
| `KEY_ALIAS` | Key alias | ⚠️ Optional |

**To add secrets:**
1. Go to: `Settings` → `Secrets and variables` → `Actions`
2. Click: **New repository secret**
3. Add each secret with its name and value
4. Click: **Add secret**

⚠️ **Note:** Only `API_BASE_URL` is required. Keystore secrets are optional but recommended for production releases.

### 2️⃣ Create Keystore (Optional)

For signed releases, create a keystore:

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload-key
```

Convert to base64 for GitHub Secret:

```bash
base64 -w 0 upload-keystore.jks
```

### 3️⃣ Test the Workflow

**Option A - Automatic (Push):**
```bash
git add .
git commit -m "Test automated build"
git push origin main
```

**Option B - Manual Trigger:**
1. Go to: **Actions** tab on GitHub
2. Select: **Build Android Test APK**
3. Click: **Run workflow**
4. Choose branch: `main`
5. Click: **Run workflow**

## 📥 Downloading APK

### Method 1: Latest Release (Recommended ⭐)

1. Visit: [Latest Release](https://github.com/inventory69/HazeBot-Admin/releases/latest)
2. Scroll to **Assets**
3. Download: `hazebot-admin-test-release.apk`

**Benefits:**
- ✅ Always latest version
- ✅ Direct APK file (no ZIP)
- ✅ Release notes with commit info
- ✅ Unique version number per build
- ✅ Obtainium compatible

### Method 2: Workflow Artifacts

1. Go to: [Actions Tab](https://github.com/inventory69/HazeBot-Admin/actions)
2. Click on the latest successful workflow run
3. Scroll to **Artifacts**
4. Download the ZIP file
5. Extract ZIP to get APK

**Drawbacks:**
- ❌ Packaged as ZIP
- ❌ Artifacts expire after 30 days
- ❌ Requires GitHub login

## 📱 Installation

1. **📥 Download APK** (see above)
2. **📲 Transfer to Android device** (if needed)
3. **⚙️ Enable "Install from Unknown Sources"** in Android settings
4. **📦 Open APK file** and follow installation prompts
5. **🚀 Launch app** and log in with your credentials

## 📦 Obtainium Integration

[Obtainium](https://github.com/ImranR98/Obtainium) can automatically detect and install updates:

1. **Add app in Obtainium**
2. **App URL:** `https://github.com/inventory69/HazeBot-Admin`
3. **Version detection:** Automatic (uses release tags)
4. **Update notifications:** Automatic on new release

Each build gets a unique version: `vYYYY.MM.DD-build.NNN`

💡 **Tip:** Set up automatic checks in Obtainium to always have the latest version!

## 🔧 Workflow Configuration

### Workflow File
The workflow is defined in: `.github/workflows/build-apk.yml`

### Key Features
- **📍 Triggers:** Push to main, tags, PRs, manual dispatch
- **☕ Java Version:** 21 (Temurin distribution)
- **🦋 Flutter Version:** 3.35.7 (stable channel)
- **🏗️ Build Types:** Debug (PRs), Release (main/tags)
- **✍️ Signing:** Automatic if keystore secrets are configured
- **🧪 Tests:** Run before building (continues on failure)
- **📦 Versioning:** Automatic based on date + build number

### Workflow Triggers

| Trigger | Description | Build Type | Creates Release |
|---------|-------------|------------|-----------------|
| Push to `main` | Automatic on commit | Release | ✅ Yes |
| Pull Request | Automatic on PR | Debug | ❌ No |
| Git Tag (`v*`) | Manual tag push | Release | ✅ Yes |
| Manual | Via Actions tab | Release/Debug | Depends |

## 🐛 Troubleshooting

### ❌ Build Fails - Missing API_BASE_URL
**Error:** `Secret API_BASE_URL is not set!`

**Solution:** 
1. Go to repository Settings → Secrets and variables → Actions
2. Add `API_BASE_URL` secret with your API endpoint
3. Re-run the workflow

### ❌ Build Fails - Signing Error
**Error:** Keystore or signing configuration issues

**Solution:** 
- Verify all keystore secrets are correctly set
- Check base64 encoding of keystore file
- Or remove signing configuration for unsigned builds

### ❌ APK Not in Release
**Problem:** Release created but no APK attached

**Solution:** 
- Check workflow logs for build errors
- Verify APK was built successfully
- Check GITHUB_TOKEN permissions for release creation

### ⚠️ Tests Failing
**Problem:** Tests fail during workflow run

**Note:** The workflow continues even if tests fail (`continue-on-error: true`)

**Solution:**
- Review test logs in workflow output
- Fix failing tests locally
- Push fixes to trigger new build

### 📱 APK Won't Install
**Problem:** Downloaded APK won't install on device

**Solution:**
- Enable "Install from Unknown Sources" in Android settings
- Check if you have enough storage space
- Verify APK wasn't corrupted during download
- Try uninstalling old version first

## 🔒 Security Notes

- ✅ API URL stored as encrypted GitHub Secret
- ✅ Secrets only accessible during workflow runs
- ✅ Secrets not exposed in logs
- ✅ `.env` file created during build, never committed
- ✅ Keystore stored as base64 secret, never in repository
- ⚠️ Test builds connect to test API environment

## 📚 Additional Resources

- 📖 [Flutter CI/CD Documentation](https://docs.flutter.dev/deployment/cd)
- 🐙 [GitHub Actions Documentation](https://docs.github.com/actions)
- 📱 [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- 🔄 [Obtainium App](https://github.com/ImranR98/Obtainium)

## 💡 Tips & Best Practices

1. **🏷️ Use Semantic Versioning** for manual tags (e.g., `v1.0.0`, `v1.1.0`)
2. **📝 Write Clear Commit Messages** - they appear in release notes
3. **🧪 Test Locally First** - run `flutter build apk --release` before pushing
4. **🔐 Rotate Secrets Regularly** - update API keys and passwords periodically
5. **📊 Monitor Build Times** - optimize if builds take too long
6. **🔄 Keep Flutter Updated** - update Flutter version in workflow when needed

---

**Need help?** [Open an issue](https://github.com/inventory69/HazeBot-Admin/issues) or check the [main README](README.md)
