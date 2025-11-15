# ✅ Setup Checklist

Complete setup guide for HazeBot Admin development and deployment.

## 🎯 Overview

This checklist covers:
- ✅ Initial repository setup
- ✅ GitHub Actions configuration
- ✅ API server configuration
- ✅ Discord OAuth setup (optional)
- ✅ Build and release process

## 📋 Initial Setup

### 1️⃣ Repository Setup

- [ ] Clone repository locally
  ```bash
  git clone https://github.com/inventory69/HazeBot-Admin.git
  cd HazeBot-Admin
  ```

- [ ] Install Flutter SDK (3.0.0+)
  - Download from [flutter.dev](https://flutter.dev)
  - Add to PATH
  - Run `flutter doctor` to verify

- [ ] Install dependencies
  ```bash
  flutter pub get
  ```

### 2️⃣ Environment Configuration

- [ ] Copy example environment file
  ```bash
  cp .env.example .env
  ```

- [ ] Configure API endpoint in `.env`
  ```env
  API_BASE_URL=https://your-api-url.com/api
  ```

- [ ] Verify `.env` is in `.gitignore` (should already be)

### 3️⃣ Test Local Build

- [ ] Run on web (development)
  ```bash
  flutter run -d chrome
  ```

- [ ] Run on Android (if available)
  ```bash
  flutter run -d android
  ```

- [ ] Verify app connects to API
- [ ] Test login functionality

## 🤖 GitHub Actions Setup

### 1️⃣ Configure Repository Secrets

Add these secrets in repository settings:

- [ ] **Required:** `API_BASE_URL`
  - Go to: Settings → Secrets and variables → Actions
  - Add secret with your API endpoint
  - Example: `https://api.example.com/api`

- [ ] **Optional:** Android signing secrets (for production)
  - `KEYSTORE_BASE64` - Base64 encoded keystore
  - `KEYSTORE_PASSWORD` - Keystore password
  - `KEY_PASSWORD` - Key password
  - `KEY_ALIAS` - Key alias (e.g., `upload-key`)

### 2️⃣ Create Signing Key (Optional)

For signed releases:

- [ ] Generate keystore
  ```bash
  keytool -genkey -v -keystore upload-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias upload-key
  ```

- [ ] Convert to base64
  ```bash
  base64 -w 0 upload-keystore.jks
  ```

- [ ] Add base64 string to GitHub secrets

### 3️⃣ Test Workflow

- [ ] Push to main branch to trigger automatic build
  ```bash
  git add .
  git commit -m "Test automated build"
  git push origin main
  ```

- [ ] Check Actions tab for build status
- [ ] Verify release was created
- [ ] Download and test APK

## 🎮 Discord OAuth Setup (Optional)

### 1️⃣ Create Discord Application

- [ ] Go to [Discord Developer Portal](https://discord.com/developers/applications)
- [ ] Click "New Application"
- [ ] Enter application name
- [ ] Note down Client ID and Client Secret

### 2️⃣ Configure OAuth2

- [ ] In Discord app settings, go to OAuth2
- [ ] Add redirect URIs:
  - Web: `https://your-domain.com/oauth/callback`
  - Android: `hazebot://oauth`
- [ ] Select required scopes:
  - `identify` - Get user information
  - `email` - Get user email (optional)

### 3️⃣ Configure API Server

- [ ] Add Discord credentials to API server environment
  ```env
  DISCORD_CLIENT_ID=your_client_id
  DISCORD_CLIENT_SECRET=your_client_secret
  DISCORD_REDIRECT_URI=https://your-domain.com/oauth/callback
  ```

- [ ] Implement OAuth endpoints on API server
  - `/api/auth/discord` - Initiate OAuth flow
  - `/api/auth/discord/callback` - Handle OAuth callback
  - `/api/auth/discord/mobile` - Handle mobile auth

### 4️⃣ Test Discord OAuth

- [ ] Test web OAuth flow in browser
- [ ] Test Android deep link
  ```bash
  adb shell am start -W -a android.intent.action.VIEW \
    -d "hazebot://oauth?token=test"
  ```
- [ ] Verify user data is retrieved correctly

## 🌐 API Server Configuration

### Required API Endpoints

Ensure your API server implements these endpoints:

#### Authentication
- [ ] `POST /api/auth/login` - Username/password login
- [ ] `POST /api/auth/refresh` - Refresh JWT token
- [ ] `GET /api/auth/user` - Get current user info
- [ ] `GET /api/auth/discord` - Discord OAuth (optional)
- [ ] `POST /api/auth/discord/callback` - Discord callback (optional)

#### Configuration (Admin)
- [ ] `GET /api/config` - Get bot configuration
- [ ] `POST /api/config` - Update bot configuration

#### Dashboard Data (All Users)
- [ ] `GET /api/memes/latest` - Latest memes
- [ ] `GET /api/rankups/latest` - Latest rank-ups
- [ ] `GET /api/games` - Game library
- [ ] `GET /api/users/{id}/rocket-league` - User RL stats

#### Admin Features
- [ ] `GET /api/logs` - Bot logs
- [ ] `GET /api/admin/live-users` - Live user sessions
- [ ] `POST /api/test/*` - Test endpoints

### Security Configuration

- [ ] Enable CORS for allowed origins
  ```python
  from flask_cors import CORS
  CORS(app, origins=["https://your-domain.com"])
  ```

- [ ] Implement JWT authentication
  - Token expiry: 1 hour (recommended)
  - Refresh token support
  - Secure token storage

- [ ] Use HTTPS in production
- [ ] Implement rate limiting
- [ ] Validate all inputs
- [ ] Log authentication attempts

## 📱 Deployment Checklist

### Web Deployment

- [ ] Build for production
  ```bash
  flutter build web --release
  ```

- [ ] Deploy `build/web/` to hosting service
  - GitHub Pages
  - Firebase Hosting
  - Netlify
  - Vercel
  - AWS S3 + CloudFront

- [ ] Configure custom domain (optional)
- [ ] Enable HTTPS
- [ ] Test on multiple browsers

### Android Deployment

- [ ] Build release APK
  ```bash
  flutter build apk --release
  ```

- [ ] Test APK on real device
- [ ] Distribute via:
  - GitHub Releases (automatic via Actions)
  - Google Play Store
  - Direct download from website

### Desktop Deployment (Optional)

- [ ] Build for Linux
  ```bash
  flutter build linux --release
  ```

- [ ] Build for Windows
  ```bash
  flutter build windows --release
  ```

- [ ] Build for macOS
  ```bash
  flutter build macos --release
  ```

- [ ] Package and distribute executables

## 🧪 Testing Checklist

### Manual Testing

- [ ] Login with username/password
- [ ] Login with Discord OAuth (if enabled)
- [ ] Navigate all user screens
  - Dashboard
  - Gaming Hub
  - Rocket League Stats
  - Meme Generator
  - Profile

- [ ] Test admin screens (if admin)
  - General Config
  - Channels Config
  - Roles Config
  - Daily Meme Config
  - Rocket League Config
  - Texts Config
  - Live Users
  - Logs Viewer
  - Test Functions

- [ ] Test theme switching (light/dark)
- [ ] Test responsive layout (mobile/tablet/desktop)
- [ ] Test error handling
- [ ] Test logout and re-login

### Automated Testing

- [ ] Run Flutter tests
  ```bash
  flutter test
  ```

- [ ] Run code analysis
  ```bash
  flutter analyze
  ```

- [ ] Fix any issues found

## 📊 Monitoring Setup

### Optional but Recommended

- [ ] Set up error tracking (e.g., Sentry, Firebase Crashlytics)
- [ ] Monitor API response times
- [ ] Track user analytics (privacy-compliant)
- [ ] Set up uptime monitoring
- [ ] Configure log aggregation

## 📚 Documentation

- [ ] Update README.md with any custom setup steps
- [ ] Document API endpoints
- [ ] Document environment variables
- [ ] Add screenshots to README
- [ ] Create user guide (optional)
- [ ] Document troubleshooting steps

## 🚀 Launch Checklist

Before going live:

- [ ] All tests passing
- [ ] No critical bugs
- [ ] API server stable and tested
- [ ] HTTPS enabled
- [ ] Secrets properly configured
- [ ] Backup strategy in place
- [ ] Monitoring configured
- [ ] Documentation complete
- [ ] Team trained (if applicable)

## 🔄 Post-Launch

- [ ] Monitor for errors
- [ ] Check user feedback
- [ ] Plan first update
- [ ] Set up regular maintenance schedule
- [ ] Keep dependencies updated
- [ ] Regular security audits

---

## 📝 Notes

- Keep this checklist updated as your setup evolves
- Check off items as you complete them
- Document any custom steps specific to your deployment
- Share with team members for consistent setup

---

**Need help?** [Open an issue](https://github.com/inventory69/HazeBot-Admin/issues) or check the [main documentation](README.md).
