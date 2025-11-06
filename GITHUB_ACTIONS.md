# GitHub Actions Setup

This repository uses GitHub Actions to automatically build **Test** Android APK files configured with the test API URL.

## Setup Instructions

### 1. Add GitHub Secret

The APK build requires the **test** API URL to be configured. Add it as a GitHub Secret:

1. Go to your repository on GitHub
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `API_BASE_URL`
5. Value: `https://test-hazebot-admin.hzwd.xyz/api` (your test API URL, without trailing slash)
6. Click **Add secret**

**Important:** The workflow will fail if this secret is not set.

### 2. Workflow Triggers

The workflow automatically runs on:

- **Push to main branch** → Builds test release APK
- **Pull requests** → Builds test debug APK
- **Git tags** (v*) → Builds test release APK and creates GitHub Release
- **Manual trigger** → Via GitHub Actions tab

### 3. Build Outputs

All builds are configured for the **TEST environment**.

#### Artifacts
Every successful build uploads a test APK artifact:
- **Debug builds**: `hazebot-admin-test-debug.apk` (30 days retention)
- **Release builds**: `hazebot-admin-test-release.apk` (30 days retention)

To download:
1. Go to **Actions** tab
2. Click on a workflow run
3. Scroll to **Artifacts** section
4. Download the test APK

#### Releases
When you push a tag (e.g., `v1.0.0`), the workflow:
1. Builds a test release APK
2. Creates a GitHub Release with the test APK attached

Example:
```bash
git tag v1.0.0
git push origin v1.0.0
```

### 4. Manual Build

To manually trigger a build:
1. Go to **Actions** tab
2. Select **Build Android Test APK** workflow
3. Click **Run workflow**
4. Select branch
5. Click **Run workflow** button

## Workflow Details

- **OS**: Ubuntu Latest
- **Java**: 21 (Temurin distribution)
- **Flutter**: 3.35.7 stable
- **Build time**: ~5-10 minutes
- **Environment**: TEST (configured with TEST_API_BASE_URL)

## Security Notes

- ✅ Test API URL is stored as GitHub Secret (encrypted)
- ✅ Secret is only accessible during workflow runs
- ✅ Secret is not exposed in logs
- ✅ `.env` file is created during build and not committed
- ⚠️ These APKs are for **TESTING ONLY** - they connect to the test API

## APK Naming Convention

All APKs are clearly named to indicate they are test builds:
- `hazebot-admin-test-debug.apk` - Debug build for testing
- `hazebot-admin-test-release.apk` - Release build for testing

## Troubleshooting

### Build fails with "Secret API_BASE_URL is not set!"
Make sure you added the `API_BASE_URL` secret in repository settings (not `TEST_API_BASE_URL`).

### Build fails with Java error
The workflow uses Java 21. If you need a different version, edit `.github/workflows/build-apk.yml`.

### APK not working after download
Make sure you:
1. Downloaded the correct test APK
2. Have network access to the test API server
3. Are using valid test credentials

## Local Development

For local development, continue using your local `.env` file:
```env
API_BASE_URL=https://test-hazebot-admin.hzwd.xyz/api
```

Or for production testing locally:
```env
API_BASE_URL=https://your-production-api.com/api
```

The local `.env` is in `.gitignore` and won't be committed.
