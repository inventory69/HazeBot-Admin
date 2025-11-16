# Setup Checklist - HazeBot Admin Panel

Complete checklist for setting up the HazeBot Admin Panel from scratch. Follow this guide to get everything running smoothly.

## ✅ Prerequisites

Before you begin, ensure you have:

### Backend Requirements
- [ ] **HazeBot Discord Bot** - Running with API enabled
- [ ] **Python 3.11+** - Backend runtime
- [ ] **Flask API** - Port 5070 accessible
- [ ] **Valid Bot Token** - Discord Developer Portal
- [ ] **Admin User** - Created in backend
- [ ] **Discord OAuth App** - For OAuth login (optional)

### Development Environment
- [ ] **Flutter SDK 3.0+** - Installed and in PATH
- [ ] **Dart SDK** - Included with Flutter
- [ ] **Git** - Version control
- [ ] **Code Editor** - VS Code, Android Studio, or IntelliJ

### Android Build (Optional)
- [ ] **Android SDK** - Platform tools installed
- [ ] **Java JDK 21** - For Gradle builds
- [ ] **Android Device/Emulator** - For testing

---

## 📋 Backend Setup (HazeBot)

### 1. Clone HazeBot Repository

```bash
cd /home/liq/gitProjects/
git clone https://github.com/inventory69/HazeBot.git
cd HazeBot
```

- [ ] Repository cloned
- [ ] Inside HazeBot directory

### 2. Install Python Dependencies

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

pip install -r requirements.txt
pip install -r api_requirements.txt
```

- [ ] Virtual environment created
- [ ] Dependencies installed
- [ ] No error messages

### 3. Configure Bot Settings

Create `Config.py` (not in git):

```python
import os
from dotenv import load_dotenv

load_dotenv()

# Discord Bot Token
BOT_TOKEN = os.getenv("BOT_TOKEN", "YOUR_BOT_TOKEN_HERE")

# API Settings
API_SECRET_KEY = os.getenv("API_SECRET_KEY", "your-secret-key-here")

# Discord Intents
from discord import Intents
intents = Intents.default()
intents.presences = True  # Required for Gaming Hub
intents.members = True    # Required for member info
intents.message_content = True  # Required for commands

# Channel IDs
MEME_CHANNEL_ID = 123456789  # Your meme channel
GAMING_CHANNEL_ID = 123456789  # Your gaming channel
ROCKET_LEAGUE_CHANNEL_ID = 123456789  # Your RL stats channel
# ... add other channel IDs
```

- [ ] `Config.py` created
- [ ] Bot token configured
- [ ] API secret key set
- [ ] Channel IDs configured
- [ ] Intents enabled

### 4. Set Up Environment Variables

Create `.env` in HazeBot root:

```env
# Discord
BOT_TOKEN=your_discord_bot_token

# API
API_SECRET_KEY=your_jwt_secret_key

# External APIs
IMGFLIP_USERNAME=your_imgflip_username
IMGFLIP_PASSWORD=your_imgflip_password
FLARESOLVER_API_URL=http://localhost:8191/v1

# Admin Users (username:password pairs)
API_ADMIN_USER=inventory69:your_password
API_EXTRA_USERS=duke:password123,alice:secret456
```

- [ ] `.env` created
- [ ] All secrets filled
- [ ] Admin users configured

### 5. Start Bot with API

```bash
python start_with_api.py
```

**Expected Output:**
```
✅ Bot logged in as: YourBotName#1234
🔧 Flask API running on http://0.0.0.0:5070
```

- [ ] Bot connects successfully
- [ ] API starts on port 5070
- [ ] No error messages
- [ ] Can access http://localhost:5070/api/health

### 6. Enable Discord Presence Intent

**Important for Gaming Hub:**

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Select your application
3. Go to **Bot** tab
4. Scroll to **Privileged Gateway Intents**
5. Enable **Presence Intent**
6. Enable **Server Members Intent**
7. Save changes
8. Restart bot

- [ ] Presence Intent enabled
- [ ] Server Members Intent enabled
- [ ] Bot restarted

---

## 📱 Frontend Setup (HazeBot-Admin)

### 1. Clone Repository

```bash
cd /home/liq/gitProjects/
git clone https://github.com/inventory69/HazeBot-Admin.git
cd HazeBot-Admin
```

- [ ] Repository cloned
- [ ] Inside HazeBot-Admin directory

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

- [ ] Dependencies downloaded
- [ ] No conflict errors
- [ ] `pubspec.lock` updated

### 3. Configure Environment

Copy example and edit:

```bash
cp .env.example .env
```

Edit `.env`:

```env
# API Configuration
API_BASE_URL=http://localhost:5070/api

# Image Proxy Configuration
IMAGE_PROXY_URL=http://localhost:5070/api/proxy/image

# Repository URL
GITHUB_REPO_URL=https://github.com/inventory69/HazeBot-Admin
```

**API URL by Platform:**
- **Web (local):** `http://localhost:5070/api`
- **Android Emulator:** `http://10.0.2.2:5070/api`
- **Android Device (LAN):** `http://YOUR_COMPUTER_IP:5070/api`
- **Production:** `https://your-domain.com/api`

- [ ] `.env` created
- [ ] API URL configured correctly
- [ ] Additional URLs configured (proxy, repo)

### 4. Verify Flutter Setup

```bash
flutter doctor
```

**Should show:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain
[✓] Chrome - develop for the web
[✓] Linux toolchain
[!] Android Studio (not required)
```

- [ ] Flutter installed correctly
- [ ] At least one platform available
- [ ] No critical errors

### 5. Run Development Build

**Web:**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d android
```

**Linux:**
```bash
flutter run -d linux
```

- [ ] App launches successfully
- [ ] Login screen appears
- [ ] No console errors

### 6. Test Login

**Credentials:**
- Username: `inventory69` (or your configured admin)
- Password: Your configured password

**Or use Discord OAuth:**
- Click Discord icon
- Authorize app
- Redirected back with token

- [ ] Login successful
- [ ] Dashboard loads
- [ ] API connection works

---

## 🔐 Discord OAuth Setup (Optional)

### 1. Create OAuth Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Select your application
3. Go to **OAuth2** → **General**
4. Add Redirect URI: `hazebot://auth/discord`
5. Copy **Client ID** and **Client Secret**

- [ ] OAuth app configured
- [ ] Redirect URI added
- [ ] Client credentials copied

### 2. Configure Backend

Add to `api/app.py`:

```python
DISCORD_CLIENT_ID = os.getenv("DISCORD_CLIENT_ID")
DISCORD_CLIENT_SECRET = os.getenv("DISCORD_CLIENT_SECRET")
DISCORD_REDIRECT_URI = "hazebot://auth/discord"
```

Add to `.env`:

```env
DISCORD_CLIENT_ID=your_client_id
DISCORD_CLIENT_SECRET=your_client_secret
```

- [ ] Backend configured
- [ ] Environment variables set

### 3. Test OAuth Flow

1. Click Discord icon on login screen
2. Browser opens Discord authorization
3. Click "Authorize"
4. App opens and logs in

- [ ] OAuth flow works
- [ ] Token received
- [ ] User info fetched

---

## 🏗️ Production Build

### Web Build

```bash
flutter build web --release --pwa-strategy=none
```

Output: `build/web/`

**Deploy to:**
- Static hosting (Netlify, Vercel, GitHub Pages)
- Own server with nginx/Apache
- Use `spa_server.py` for local testing

- [ ] Web build successful
- [ ] Static files generated
- [ ] Tested locally with `spa_server.py`
- [ ] Deployed to hosting

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**Split by architecture (smaller size):**
```bash
flutter build apk --split-per-abi --release
```

- [ ] APK built successfully
- [ ] Tested on device/emulator
- [ ] Signed (debug key or release key)

### Android App Bundle (Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

**Requires:**
- Release signing configured
- `android/key.properties` setup

- [ ] AAB built successfully
- [ ] Signed with release key
- [ ] Ready for Play Console upload

---

## 🤖 GitHub Actions CI/CD (Optional)

### 1. Set Up Repository Secrets

1. Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Add **New repository secret**

**Required secrets:**
- `API_BASE_URL` - Your API endpoint URL

- [ ] Repository secrets configured
- [ ] Workflow file exists (`.github/workflows/build-apk.yml`)

### 2. Test Workflow

**Option 1: Push to main**
```bash
git add .
git commit -m "test: Trigger CI build"
git push origin main
```

**Option 2: Manual trigger**
1. Go to **Actions** tab
2. Select workflow
3. Click **Run workflow**

- [ ] Workflow runs successfully
- [ ] APK uploaded as artifact
- [ ] Release created (if on main)

### 3. Download APK

1. Go to **Releases** tab
2. Click latest release
3. Download APK from assets

- [ ] Can download APK
- [ ] APK installs on device
- [ ] App works correctly

---

## ✅ Feature Testing

### User Features (All Users)

**HazeHub Dashboard:**
- [ ] Latest memes load
- [ ] Latest rank-ups load
- [ ] Meme detail screen opens
- [ ] Upvote system works
- [ ] Relative times show correctly

**Gaming Hub:**
- [ ] Member list loads
- [ ] Status indicators show (online/offline)
- [ ] Current activity displays
- [ ] Game request can be sent
- [ ] Filter by online/playing works

**Rocket League:**
- [ ] Can add account
- [ ] Stats display correctly
- [ ] Division shown (e.g., "Div 2")
- [ ] Rank colors correct
- [ ] Post to channel works

**Meme Generator:**
- [ ] Templates load
- [ ] Search works
- [ ] Can select template
- [ ] Text boxes appear
- [ ] Preview updates
- [ ] Can generate meme
- [ ] Can post to Discord
- [ ] Author tracked

**Meme Testing:**
- [ ] Can fetch from Reddit
- [ ] Can fetch from Lemmy
- [ ] Random meme works
- [ ] Can send to Discord

**Profile:**
- [ ] Avatar shows
- [ ] Discord role shows
- [ ] RL rank shows
- [ ] Stats displayed

**Preferences:**
- [ ] Can toggle notifications
- [ ] Settings persist

**Settings:**
- [ ] Theme toggle works
- [ ] About page accessible
- [ ] Version shown

### Admin Features (Admin Only)

**Admin Rail:**
- [ ] Admin icon appears
- [ ] Rail opens/closes
- [ ] All screens accessible

**Configuration:**
- [ ] General config loads & saves
- [ ] Channels config loads & saves
- [ ] Roles config loads & saves
- [ ] Daily Meme config loads & saves
- [ ] Daily Meme preferences loads & saves
- [ ] Meme config loads & saves
- [ ] Meme Generator config loads & saves
- [ ] Rocket League config loads & saves
- [ ] Texts config loads & saves
- [ ] Welcome config loads & saves

**Live Users:**
- [ ] Active sessions show
- [ ] Updates in real-time
- [ ] Can force logout (if implemented)

**Logs:**
- [ ] Logs load
- [ ] Filter by Cog works
- [ ] Filter by level works
- [ ] Search works
- [ ] Text selectable
- [ ] Copy buttons work
- [ ] Auto-refresh works

---

## 🐛 Troubleshooting

### Connection Issues

**Problem:** Can't connect to API

**Solutions:**
- [ ] Verify API is running: `curl http://localhost:5070/api/health`
- [ ] Check firewall allows port 5070
- [ ] Android: Use correct IP (10.0.2.2 for emulator)
- [ ] Check `.env` API_BASE_URL is correct

### Login Failures

**Problem:** Invalid credentials

**Solutions:**
- [ ] Verify credentials in backend `.env`
- [ ] Check API logs for errors
- [ ] Test with curl:
  ```bash
  curl -X POST http://localhost:5070/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"inventory69","password":"your_password"}'
  ```

### Gaming Hub Shows Offline

**Problem:** All users appear offline

**Solutions:**
- [ ] Enable Presence Intent in Discord Portal
- [ ] Restart bot after enabling intent
- [ ] Check `Config.py` has `Intents.presences = True`

### Token Expired Errors

**Problem:** Frequent "token expired" messages

**Solutions:**
- [ ] Check system clock (must be accurate)
- [ ] Backend: Token expiry set to 7 days
- [ ] Frontend: Token refresh enabled
- [ ] Clear app data and re-login

### Build Failures

**Problem:** Flutter build fails

**Solutions:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter doctor
```

- [ ] Run all commands
- [ ] Fix any doctor issues
- [ ] Retry build

---

## 📊 Performance Checklist

- [ ] API responds < 500ms
- [ ] Images load quickly
- [ ] Smooth scrolling
- [ ] No memory leaks
- [ ] Cache working (fewer API calls)

---

## 🔐 Security Checklist

- [ ] HTTPS in production
- [ ] `.env` files in `.gitignore`
- [ ] No secrets in code
- [ ] JWT tokens expire
- [ ] CORS configured correctly
- [ ] Rate limiting enabled (backend)
- [ ] Input validation (backend)

---

## 📚 Documentation Checklist

- [ ] README.md complete
- [ ] API documented
- [ ] Environment variables documented
- [ ] Setup instructions tested
- [ ] Troubleshooting guide available

---

## 🎉 Completion

Once all items are checked:

**You have successfully set up:**
- ✅ HazeBot Discord Bot with API
- ✅ HazeBot Admin Panel (Web/Mobile)
- ✅ All user features working
- ✅ All admin features working
- ✅ Production builds available
- ✅ CI/CD pipeline configured

**Next Steps:**
1. Invite bot to your Discord server
2. Configure channels and roles
3. Test all features with real users
4. Set up monitoring and logging
5. Plan feature updates

---

**Need Help?**
- GitHub Issues: https://github.com/inventory69/HazeBot-Admin/issues
- Documentation: [README.md](README.md)
- Backend Setup: [HazeBot README](https://github.com/inventory69/HazeBot)

---

**Last Updated:** November 16, 2025
**Estimated Setup Time:** 1-2 hours
**Difficulty:** Intermediate
