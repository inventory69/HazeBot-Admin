# GitHub Actions CI/CD Setup

Complete guide for setting up automated APK builds with GitHub Actions for the HazeBot Admin Panel.

## 🎯 Overview

This repository uses GitHub Actions to automatically build Android APK files on every push and tag. The workflow handles:

- ✅ Automated builds on push to `main`
- ✅ Pull request validation builds
- ✅ Tagged releases with semantic versioning
- ✅ Automatic APK uploads as GitHub Releases
- ✅ Environment-specific builds (test/production)

---

## 🛠️ Setup Instructions

### 1. Repository Secrets

The workflow requires secrets for configuration. Add them in your repository:

**Navigate to:**
`Settings` → `Secrets and variables` → `Actions`

**Required Secrets:**

#### `API_BASE_URL` (REQUIRED)
- **Description:** API endpoint URL
- **Value:** `https://your-api-url.com/api`
- **Example:** `https://test-hazebot-admin.hzwd.xyz/api`
- **Important:** No trailing slash!

#### `PROD_MODE` (REQUIRED)
- **Description:** Production mode flag
- **Value:** `true` or `false`
- **Example:** `true` for Production (Chillventory), `false` for Development (Testventory)
- **Important:** Lowercase, no quotes!

#### `IMAGE_PROXY_URL` (Optional)
- **Description:** Image proxy URL for CORS-free image loading
- **Value:** `https://your-api-url.com/api/proxy/image`
- **Example:** `https://test-hazebot-admin.hzwd.xyz/api/proxy/image`

**Steps to Add:**
1. Click **New repository secret**
2. Name: e.g., `PROD_MODE`
3. Value: e.g., `true`
4. Click **Add secret**

📚 **Detailed Setup Guide:** See [GITHUB_SECRETS_SETUP.md](docs/GITHUB_SECRETS_SETUP.md)

---

## 🔄 Workflow Triggers

The workflow automatically runs on:

### 1. Push to Main Branch
**Trigger:** `git push origin main`

**Actions:**
- Builds release APK
- Creates date-versioned release (e.g., `v2025.11.16-build.123`)
- Uploads APK as release asset
- Generates release notes from commit message

**Use Case:** Continuous deployment, every commit becomes a release

### 2. Pull Requests
**Trigger:** Opening or updating a PR

**Actions:**
- Builds debug APK (faster)
- Uploads as artifact (not released)
- Validates build process

**Use Case:** Testing changes before merge

### 3. Git Tags
**Trigger:** `git tag v1.0.0 && git push origin v1.0.0`

**Actions:**
- Builds release APK
- Creates GitHub Release with tag version
- Uploads APK as release asset
- Uses tag as version name

**Use Case:** Manual versioned releases (milestones)

### 4. Manual Dispatch
**Trigger:** GitHub UI → Actions → Run workflow

**Actions:**
- Build on-demand
- Choose branch
- Downloads via artifacts

**Use Case:** Testing specific branches

---

## 📦 Build Outputs

### GitHub Releases (Automatic)

**Created for:**
- Every push to `main`
- Every git tag

**Contents:**
- APK file attached as asset
- Version tag (date-based or semantic)
- Release notes (commit message)
- Download statistics

**Access:**
`https://github.com/YOUR_USERNAME/HazeBot-Admin/releases`

### Workflow Artifacts

**Created for:**
- All builds (including PRs)

**Contents:**
- APK files (ZIP compressed)
- 30-day retention
- Requires GitHub login to download

**Access:**
1. Go to **Actions** tab
2. Click workflow run
3. Scroll to **Artifacts**
4. Download ZIP

---

## 🏗️ Workflow Details

### Build Environment

```yaml
Runner: ubuntu-latest
Java: 21 (Temurin distribution)
Flutter: 3.35.7 stable channel
Build Time: ~5-10 minutes
```

### Build Steps

1. **Checkout Code** - Clone repository
2. **Setup Java** - Install JDK 21
3. **Setup Flutter** - Install Flutter SDK
4. **Create .env** - Generate from secrets
5. **Install Dependencies** - `flutter pub get`
6. **Build APK** - `flutter build apk --release`
7. **Upload Artifact** - Store in workflow run
8. **Create Release** - Publish to GitHub (if triggered)

### Version Numbering

**Format:** `vYYYY.MM.DD-build.NNN`

**Example:** `v2025.11.16-build.042`

**Components:**
- `YYYY.MM.DD` - Build date
- `NNN` - GitHub run number (unique)

**Why This Format?**
- ✅ Chronological ordering
- ✅ Uniqueness guaranteed
- ✅ Obtainium compatible
- ✅ Human-readable

---

## 🔐 Security Considerations

### Secrets Management

**Best Practices:**
- ✅ Never commit `.env` to repository
- ✅ Secrets encrypted at rest by GitHub
- ✅ Secrets not exposed in logs
- ✅ Secrets only accessible during workflow runs
- ✅ Use separate secrets for test/production

**Secret Visibility:**
```
❌ NOT accessible: Forks, pull requests from forks
✅ Accessible: Main repo workflows
```

### APK Signing

**Release Builds:**
- Signed with Flutter debug key (by default)
- For production, configure release signing:
  1. Generate keystore
  2. Add keystore secrets
  3. Configure `android/key.properties`

**Debug Builds:**
- Signed with debug key
- Suitable for testing only

---

## 🚀 Manual Release Creation

### Date-Versioned Release (Automatic)

Every push creates a release automatically:

```bash
git add .
git commit -m "feat: Add new feature"
git push origin main
```

GitHub Actions will:
1. Build APK
2. Create release: `v2025.11.16-build.NNN`
3. Attach APK
4. Use commit message as release notes

### Semantic Versioned Release (Manual)

For milestone releases:

```bash
# Tag current commit
git tag v1.0.0

# Push tag to GitHub
git push origin v1.0.0
```

GitHub Actions will:
1. Build APK
2. Create release: `v1.0.0`
3. Attach APK
4. Mark as "latest" release

### Pre-Release

For beta/RC versions:

```bash
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

Workflow detects pre-release from tag format.

---

## 🧪 Testing Workflow

### Local Validation

Before pushing, test locally:

```bash
# Ensure build works
flutter build apk --release

# Check for errors
flutter analyze

# Format code
dart format .
```

### Test GitHub Workflow

**Option 1: Draft PR**
1. Create feature branch
2. Push to GitHub
3. Open draft PR
4. Workflow runs automatically
5. Check artifacts

**Option 2: Manual Trigger**
1. Go to **Actions** tab
2. Select **Build Android APK**
3. Click **Run workflow**
4. Select branch
5. Click **Run workflow**

---

## 📊 Monitoring Builds

### Workflow Status

**View Status:**
`Actions` tab → Select workflow run

**Status Indicators:**
- 🟢 Success - Build completed
- 🔴 Failure - Build failed
- 🟡 In Progress - Currently building
- ⚪ Queued - Waiting to start

### Build Logs

**Access Logs:**
1. Click workflow run
2. Click job name (e.g., "build")
3. Expand steps to view logs

**Useful for:**
- Debugging build failures
- Verifying environment setup
- Checking APK output location

### Notifications

**Enable Notifications:**
`Settings` → `Notifications` → **Actions**

**Get notified for:**
- Build failures
- Build successes
- Deployment completions

---

## 🐛 Troubleshooting

### Build Fails with "Secret Not Set"

**Error:** `Secret API_BASE_URL is not set!`

**Solution:**
1. Go to repo `Settings` → `Secrets and variables` → `Actions`
2. Verify `API_BASE_URL` exists
3. Check spelling (case-sensitive)
4. Re-run workflow

### Java Version Mismatch

**Error:** `Unsupported Java version`

**Solution:**
- Workflow uses Java 21
- Edit `.github/workflows/build-apk.yml`:
```yaml
- name: Set up JDK
  uses: actions/setup-java@v4
  with:
    java-version: '17'  # Change to your version
```

### Flutter SDK Issues

**Error:** `Flutter SDK not found`

**Solution:**
- Check Flutter version in workflow
- Verify Flutter installation step
- Update `flutter-action` version:
```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.35.7'  # Latest stable
```

### APK Not Uploaded

**Issue:** Build succeeds but no APK in release

**Check:**
1. Verify workflow has release creation step
2. Check trigger (tags vs. pushes)
3. Ensure `GITHUB_TOKEN` has write permissions
4. Review workflow logs for upload errors

### Workflow Not Triggering

**Possible Causes:**
- Workflow file not in `.github/workflows/`
- YAML syntax errors
- Branch protection rules
- Repository permissions

**Solution:**
- Validate YAML syntax
- Check Actions enabled in repo settings
- Review branch protection rules

---

## 🔧 Customization

### Change Build Configuration

Edit `.github/workflows/build-apk.yml`:

```yaml
# Build command
- name: Build APK
  run: |
    flutter build apk --release \
      --split-per-abi \  # Split by architecture
      --target-platform android-arm64  # Specific platform
```

### Add Build Steps

Insert additional steps:

```yaml
# Before build
- name: Run Tests
  run: flutter test

# After build
- name: Sign APK
  run: |
    # Your signing commands
```

### Modify Version Format

Edit version tag generation:

```yaml
# In workflow file
VERSION_TAG="v$(date +'%Y.%m.%d')-build-${{ github.run_number }}"
```

---

## 📚 Additional Resources

**GitHub Actions Documentation:**
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Creating Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)

**Flutter Build Documentation:**
- [Building for Android](https://docs.flutter.dev/deployment/android)
- [Build Modes](https://docs.flutter.dev/testing/build-modes)

---

## 📝 Workflow File Reference

**Location:** `.github/workflows/build-apk.yml`

**Key Sections:**
```yaml
name: Build Android APK
on: [push, pull_request, create]  # Triggers
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
      - uses: subosito/flutter-action@v2
      # ... build steps
```

---

## 🆘 Support

**Issues?** 
- GitHub Issues: https://github.com/inventory69/HazeBot-Admin/issues
- Include workflow run URL and error logs

**Questions?**
- Review [README.md](README.md)
- Check [APK_DOWNLOAD.md](APK_DOWNLOAD.md)

---

**Last Updated:** November 16, 2025
**Workflow Version:** 2.0
**Minimum GitHub Actions:** v2
