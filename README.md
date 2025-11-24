# HazeBot Admin Panel

A modern, cross-platform admin interface for the HazeBot Discord bot built with Flutter. Features a hybrid navigation system with user features for community members and powerful admin tools for bot management.

## 📥 Quick Start

### Download the App

**Android APK:** [Download Latest Release](https://github.com/inventory69/HazeBot-Admin/releases/latest)

**Installation Guides:**
- [Android APK Download & Installation](APK_DOWNLOAD.md)
- [GitHub Actions CI/CD Setup](GITHUB_ACTIONS.md)
- [Complete Setup Checklist](SETUP_CHECKLIST.md)

💡 **Pro Tip:** Use [Obtainium](https://github.com/ImranR98/Obtainium) to automatically receive updates from GitHub Releases!

## ✨ Key Features

### 🎮 User Features (Everyone)
- **HazeHub Dashboard** - Community news feed with latest memes & rank-ups
- **Gaming Hub** - See who's online, what they're playing, send game requests
- **Rocket League Stats** - Manage accounts, view ranks, post stats to Discord
- **Meme Generator** - Create custom memes with 100+ templates
- **Memes** - Fetch memes from Reddit/Lemmy and post to Discord
- **Profile System** - View Discord avatar, role, RL rank, activity stats
- **Preferences** - Manage notifications and personal settings

### ⚙️ Admin Features (Admin Only)
- **Configuration Management** - Complete bot settings control
  - General, Channels, Roles, Texts, Welcome Messages
  - Daily Meme sources (Reddit/Lemmy) and scheduling
  - Rocket League integration settings
  - Meme Generator configuration
- **Live Monitoring** - Active user sessions with real-time tracking
- **Log Viewer** - Bot logs with filtering by Cog, level, and search
- **Admin Navigation Rail** - Dedicated admin sidebar (hidden by default)

### 🎨 UI/UX Highlights
- **Material Design 3** - Android 16 Monet dynamic colors
- **Hybrid Navigation** - Bottom tabs (users) + Rail (admins)
- **Responsive Design** - Optimized for mobile, tablet, desktop
- **Dark/Light Mode** - System-synced theme switching
- **JWT Authentication** - Secure token-based auth with auto-refresh
- **Upvote System** - Discord reactions integration (👍)
- **Hero Animations** - Smooth transitions between screens

## 🚀 Installation & Setup

### Prerequisites

- **Flutter SDK:** 3.0.0 or higher ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK:** Included with Flutter
- **For Android builds:** Android SDK with Java 21
- **HazeBot API Server:** Must be running and accessible

### 1. Clone the Repository

```bash
git clone https://github.com/inventory69/HazeBot-Admin.git
cd HazeBot-Admin
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup (Required for Push Notifications)

**Android only** - Follow the [Firebase Setup Guide](FIREBASE_SETUP.md) to enable push notifications:

1. Download `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`
3. Add `firebase-credentials.json` to HazeBot backend root

⚠️ **Note:** App will build without Firebase, but push notifications won't work.

### 4. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
# API Configuration
API_BASE_URL=https://your-api-url.com/api

# Image Proxy Configuration
IMAGE_PROXY_URL=https://your-api-url.com/api/proxy/image

# Repository URL
GITHUB_REPO_URL=https://github.com/inventory69/HazeBot-Admin
```

**API URL Guidelines:**
- **Local Development (Web):** `http://localhost:5070/api`
- **Android Emulator:** `http://10.0.2.2:5070/api`
- **Android Device (LAN):** `http://YOUR_COMPUTER_IP:5070/api`
- **Production:** `https://your-domain.com/api`

⚠️ **Important:** Never commit the `.env` file to version control!

## 🏃 Running the Application

### Development Mode

**Web:**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d android
```

**Desktop:**
```bash
flutter run -d linux    # Linux
flutter run -d windows  # Windows
flutter run -d macos    # macOS
```

### Hot Reload

During development:
- `r` - Hot reload (fast UI refresh)
- `R` - Hot restart (full app restart)
- `q` - Quit

## 🔨 Building for Production

### Android APK

```bash
# Standard release APK
flutter build apk --release

# Split APKs by architecture (smaller size)
flutter build apk --split-per-abi --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Web

```bash
flutter build web --release --pwa-strategy=none
```

Output: `build/web/` directory

**Testing Web Build Locally:**
```bash
cd build/web
python3 spa_server.py  # Starts local server on port 8000
```

**Important:** Always do a hard refresh (Ctrl+Shift+R) after new builds to clear browser cache!

### Desktop

```bash
flutter build linux --release    # Linux
flutter build windows --release  # Windows
flutter build macos --release    # macOS
```

## 📁 Project Structure

```
HazeBot-Admin/
├── lib/
│   ├── main.dart                          # App entry point with JWT token loading
│   ├── services/                          # Business logic layer
│   │   ├── api_service.dart              # REST API client with token refresh
│   │   ├── auth_service.dart             # JWT authentication
│   │   ├── discord_auth_service.dart     # Discord OAuth + user info
│   │   ├── config_service.dart           # Configuration state management
│   │   ├── permission_service.dart       # Role-based permissions
│   │   ├── theme_service.dart            # Dark/Light mode + persistence
│   │   └── deep_link_service.dart        # Discord OAuth callback handling
│   ├── screens/                           # UI screens
│   │   ├── home_screen.dart              # Hybrid navigation (tabs + rail)
│   │   ├── login_screen.dart             # Login with Discord OAuth
│   │   ├── profile_screen.dart           # User profile with stats
│   │   ├── preferences_screen.dart       # User preferences
│   │   ├── settings_screen.dart          # App settings (theme, about)
│   │   ├── logs_screen.dart              # Bot log viewer with filters
│   │   ├── gaming_hub_screen.dart        # Gaming Hub (presence, requests)
│   │   ├── user_rocket_league_screen.dart # RL account management
│   │   ├── meme_detail_screen.dart       # Meme detail with upvotes
│   │   ├── test_screen.dart              # Development testing interface
│   │   ├── admin/
│   │   │   └── live_users_screen.dart    # Live session monitoring
│   │   └── config/                        # Admin configuration screens
│   │       ├── general_config_screen.dart
│   │       ├── channels_config_screen.dart
│   │       ├── roles_config_screen.dart
│   │       ├── texts_config_screen.dart
│   │       ├── welcome_config_screen.dart
│   │       ├── daily_meme_config_screen.dart
│   │       ├── daily_meme_preferences_screen.dart
│   │       ├── meme_config_screen.dart
│   │       ├── meme_generator_screen.dart
│   │       └── rocket_league_config_screen.dart
│   ├── utils/                             # Helper utilities
│   │   └── web_utils_web.dart            # Web-specific utilities
│   └── providers/                         # State providers
├── android/                               # Android platform code
├── web/                                   # Web platform code
├── linux/                                 # Linux platform code
├── windows/                               # Windows platform code
├── macos/                                 # macOS platform code
├── .github/workflows/                     # CI/CD workflows
│   └── build-apk.yml                     # Auto APK build + release
├── pubspec.yaml                          # Dependencies
├── .env.example                          # Environment template
├── spa_server.py                         # Local web server (Flutter SPA)
└── generate_adaptive_icons.sh           # Android icon generation
```

## 🎯 Feature Documentation

### Navigation System

**Hybrid Architecture:**
- **Bottom TabBar** (All Users): HazeHub, Gaming Hub, Rocket League, Meme Gen, Memes
- **Navigation Rail** (Admin Only): Admin screens accessible via admin icon
- **Bottom Sheet Menu** (Profile): Avatar click opens preferences, settings, logout

### HazeHub Dashboard

**Latest Memes Section:**
- Shows newest memes from Discord meme channel
- Custom meme badge (✨) for user-generated content
- Upvote system with Discord reactions (👍)
- Click for full detail view with Hero animation
- Optimistic UI updates (memes appear instantly after posting)

**Latest Rank-Ups Section:**
- Shows newest Rocket League rank promotions
- Parses Discord embed messages
- Displays rank icon, user, rank, division, mode

**Meme Detail Screen:**
- Full-size image with Hero animation
- Info cards: Author, Score, Source, Date, Upvotes
- Toggle upvote button (add/remove like in Discord)
- "View Original" opens source URL
- Loading states with proper button feedback

### Gaming Hub

**Features:**
- Live member list with Discord presence
- Status indicators: Online, Idle, DND, Offline
- Current activity/game display
- Filter: All / Online / Playing
- Search members by name
- Send game requests with custom messages
- Button interactions (Accept/Decline/Maybe)

**Requirements:**
- Discord Presence Intent enabled in bot config
- `Intents.presences = True` in backend

### Rocket League Integration

**Account Management:**
- Add/Remove/Update accounts
- Platform support: Epic Games, Steam, Xbox, PlayStation
- Stats display with division (e.g., "Diamond III Div 2")
- 4v4 mode support
- Rank colors matching Discord bot

**Post to Channel:**
- One-click stats posting to Discord
- Same format as `/rlstats` command
- Posts to configured RL channel

### Meme Generator

**Template Gallery:**
- 100+ Imgflip templates
- Grid layout (2/3/4 columns responsive)
- Real-time search & filter
- Live preview panel (desktop)

**Meme Creation:**
- Click template for preview
- Dialog with dynamic text fields (1-5 boxes)
- Preview & Post to Discord
- Author tracking (JWT user as creator)

### Memes (Fetch & Post)

**Features:**
- Fetch memes from Reddit subreddits
- Fetch memes from Lemmy communities
- Random meme from all sources
- Preview before posting
- Post directly to Discord meme channel
- Source attribution included

**Use Cases:**
- Share community content
- Quick meme posting
- Test new meme sources

### Admin Configuration

**General Settings:**
- Bot name, command prefix
- Presence update interval
- Message cooldown, fuzzy matching

**Channel Configuration:**
- Log, changelog, meme, welcome channels
- Gaming hub channel
- Rocket League channel
- Ticket system channels

**Role Management:**
- Admin, moderator, member roles
- Interest-based roles
- Special feature roles

**Daily Meme:**
- Reddit subreddit sources
- Lemmy community sources
- Source selection & scheduling
- Template cache settings

**Rocket League:**
- Rank check intervals
- Cache duration
- FlareSolverr integration settings

**Welcome System:**
- Server rules configuration
- Welcome message templates
- Button responses

### Log Viewer

**Features:**
- Real-time bot logs (newest first)
- Cog-specific color coding
- Filters: Cog, Level, Search
- Selectable text with copy buttons
- Auto-refresh (5 seconds)
- Responsive filter layout

### Authentication & Sessions

**JWT Token Management:**
- 7-day token expiry
- Proactive refresh (5-min buffer)
- Reactive refresh on 401 errors
- Token persistence via SharedPreferences
- Completer-based coordination (no parallel refreshes)

**Session Tracking:**
- 30-minute session timeout
- Active sessions monitoring
- Live user tracking in admin panel

**Discord OAuth:**
- OAuth2 flow with deep links
- Avatar & role name fetching
- Discord user info integration

### Theme System

**Material Design 3:**
- Dynamic Color with Android 16 Monet
- Surface hierarchy: `surface` → `surfaceContainerLow` → `surfaceContainerHigh` → `surfaceContainerHighest`
- Flat design (elevation: 0)
- Harmonized colors

**Theme Service:**
- Dark/Light mode toggle
- System theme sync
- Persistent theme storage

## 🧪 Development

### Code Quality

```bash
# Flutter analysis
flutter analyze

# Dart formatting
dart format .

# Run tests
flutter test
```

### Debugging

```bash
# Debug mode with logging
flutter run --debug

# View device logs
flutter logs

# View console output
adb logcat  # Android
```

### Meme Features Testing

Use the **Memes** tab to:
- **Fetch from Reddit** - Get memes from specific subreddits
- **Fetch from Lemmy** - Get memes from Lemmy communities
- **Random Meme** - Fetch random meme from all sources
- **Post to Discord** - Send fetched memes to Discord channel

## 🌐 Deployment

### Web Deployment

Deploy `build/web/` to:
- **GitHub Pages** - Free static hosting
- **Netlify** - CI/CD with auto-deploys
- **Vercel** - Serverless platform
- **Firebase Hosting** - Fast CDN
- **AWS S3 + CloudFront** - Scalable solution

**Important:** Configure SPA routing (all routes → index.html)

### Android Deployment

**Google Play Store:**
1. Create keystore for signing
2. Configure `android/app/build.gradle`
3. Build: `flutter build appbundle --release`
4. Upload to Play Console

**Direct Distribution:**
1. Build: `flutter build apk --release`
2. Distribute via GitHub Releases
3. Users enable "Unknown Sources"

**Automated CI/CD:**
- GitHub Actions builds APK on every push
- Auto-creates releases with version tags
- Obtainium-compatible for auto-updates

## 🔐 Security Best Practices

- ✅ Use HTTPS for production API
- ✅ Never commit `.env` or secrets
- ✅ JWT tokens with expiration
- ✅ Secure token storage (SharedPreferences)
- ✅ ProGuard/R8 for Android releases
- ✅ Regular dependency updates
- ✅ CORS properly configured on backend
- ✅ Role-based permission checks

## 🐛 Troubleshooting

### CORS Errors (Web)
**Solution:** Ensure Flask API has CORS configured:
```python
from flask_cors import CORS
CORS(app, origins=["*"])  # Or specific origins
```

### Connection Refused (Android)
**Solutions:**
- Android Emulator: Use `http://10.0.2.2:5070/api`
- Physical Device: Use computer's LAN IP
- Check firewall allows port 5070
- Verify API server is running

### Token Refresh Issues
**Solutions:**
- Check backend token expiry settings
- Verify `/api/auth/refresh` endpoint works
- Clear app data and re-login
- Check console for token-related errors

### Build Failures
**Solutions:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Stale Web Build
**Solution:** Hard refresh browser (Ctrl+Shift+R) after builds

### Android Signing Errors
**Solutions:**
- Verify keystore exists and path is correct
- Check `android/key.properties` configuration
- Ensure passwords match

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes & test thoroughly
4. Commit: `git commit -m 'feat: Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open Pull Request

**Guidelines:**
- Follow Flutter/Dart style guide
- Test on Web and Android
- Update documentation if needed
- Use conventional commits

## 📊 Tech Stack

**Frontend:**
- Flutter 3.x (Web + Mobile + Desktop)
- Material Design 3
- Provider (State Management)
- HTTP Client (REST API)

**Key Packages:**
- `jwt_decode` - JWT token handling
- `shared_preferences` - Local storage
- `dynamic_color` - Material You theming
- `url_launcher` - External links
- `app_links` - Deep link handling
- `timeago` - Relative time formatting
- `flutter_dotenv` - Environment variables

**Backend Integration:**
- Flask REST API (Python)
- JWT Authentication (HS256)
- Discord.py Bot Integration

## 📝 Changelog

See individual commits for detailed changes. Major milestones:

- **v2025.11.16** - Android 16 Monet surface hierarchy, upvote loading states
- **v2025.11.15** - Token refresh closure bug fix, NGINX proxy support
- **v2025.11.06** - Session management improvements, APICache implementation
- **v2025.10.xx** - Gaming Hub, HazeHub Dashboard, Meme Generator
- **v2025.09.xx** - Initial release with admin features

## 👨‍💻 Developer

**Created by:** [inventory69](https://github.com/inventory69)

**Repository:** [github.com/inventory69/HazeBot-Admin](https://github.com/inventory69/HazeBot-Admin)

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🔗 Related Projects

- **HazeBot** - Discord bot that this admin panel manages
- **HazeBot API** - Flask REST API backend

---

**Need Help?** Open an issue on [GitHub](https://github.com/inventory69/HazeBot-Admin/issues)

**Documentation:** See [AI_PROJECT_INSTRUCTIONS.md](../AI_PROJECT_INSTRUCTIONS.md) for complete technical details
