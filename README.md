# 🤖 HazeBot Admin

A modern, cross-platform admin interface for HazeBot Discord bot built with Flutter. Manage your Discord bot with an intuitive Material Design 3 interface while exploring community content, tracking gaming stats, and staying connected with your server.

## 📥 Quick Start

### Download & Install

**🤖 Android APK:** [Download Latest Release](https://github.com/inventory69/HazeBot-Admin/releases/latest)

💡 **Pro Tip:** Use [Obtainium](https://github.com/ImranR98/Obtainium) for automatic updates!

**📚 Additional Guides:**
- [Android APK Download & Installation](APK_DOWNLOAD.md)
- [GitHub Actions Setup](GITHUB_ACTIONS.md)
- [Setup Checklist](SETUP_CHECKLIST.md)

## ✨ Features

### 🎮 User Features (All Users)
- 📊 **Dashboard (HazeHub)** - View latest memes and Rocket League rank-ups from your community
- 🎮 **Gaming Hub** - Browse and search your Discord server's game library
- 🏎️ **Rocket League Stats** - Track your personal Rocket League stats and ranks
- 🎨 **Meme Generator** - Create custom memes with easy-to-use tools
- 🖼️ **Meme Browser** - Browse and test meme templates
- 👤 **Profile Management** - View and manage your Discord profile
- 🔐 **Discord OAuth** - Seamless Discord authentication with deep linking

### ⚙️ Admin Features (Admin/Mod Only)
- 🎛️ **General Configuration** - Bot name, command prefix, presence settings
- 📢 **Channel Management** - Configure log, meme, welcome, and ticket channels
- 👥 **Role Management** - Set up admin, moderator, and special interest roles
- 🎭 **Daily Meme Config** - Reddit/Lemmy sources, scheduling, and preferences
- 🏎️ **Rocket League Config** - Rank check intervals and player tracking settings
- 📝 **Text Configuration** - Welcome messages and server rules templates
- 👁️ **Live Users Monitor** - Real-time session tracking and user activity
- 📋 **Log Viewer** - Real-time bot log monitoring with filtering
- 🧪 **Test Functions** - Test bot features before deployment

### 🚀 Technical Features
- 📱 **Cross-Platform** - Web, Linux, Windows, macOS, and Android support
- 🎨 **Material Design 3** - Modern UI with dynamic colors and adaptive themes
- 🔐 **Secure Authentication** - JWT-based with automatic token refresh
- 🔄 **Auto-Updates** - Versioned releases for every build (Obtainium compatible)
- 🔗 **Deep Linking** - Seamless OAuth callback handling
- 💾 **Smart Caching** - Efficient data management with automatic refresh
- 🎯 **Permission System** - Role-based access control for features

## 🚀 Installation & Setup

### Prerequisites

- **Flutter SDK:** 3.0.0 or higher ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK:** Included with Flutter
- **For Android builds:** Android SDK with Java 21+
- **HazeBot API Server:** Must be running and accessible

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/inventory69/HazeBot-Admin.git
cd HazeBot-Admin
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Configure API Connection

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and set your API URL:

```env
API_BASE_URL=https://your-api-url.com/api
```

**API URL Examples:**
- **Web (local dev):** `http://localhost:5000/api`
- **Android Emulator:** `http://10.0.2.2:5000/api`
- **Android Device (local network):** `http://YOUR_COMPUTER_IP:5000/api`
- **Production:** `https://your-domain.com/api`

⚠️ **Important:** Never commit the `.env` file to version control!

### 4️⃣ Discord OAuth Setup (Optional)

To enable Discord authentication in addition to standard login:

1. **Create Discord Application:**
   - Go to [Discord Developer Portal](https://discord.com/developers/applications)
   - Create a new application
   - Note your `Client ID` and `Client Secret`

2. **Configure OAuth2 Redirects:**
   - In Discord app settings, go to OAuth2
   - Add redirect URIs:
     - For web: `https://your-domain.com/oauth/callback`
     - For Android: `hazebot://oauth`
   
3. **Configure API Server:**
   - Set Discord OAuth credentials in your API server environment
   - Ensure OAuth endpoints are properly configured

4. **Test Deep Linking (Android):**
   ```bash
   adb shell am start -W -a android.intent.action.VIEW -d "hazebot://oauth?token=test"
   ```

🎉 Users can now log in via Discord OAuth or traditional username/password!

## 📸 Screenshots & Features Preview

### 🎨 User Interface
- **Modern Material Design 3** - Clean, adaptive interface with dynamic colors
- **Dark/Light Theme** - Automatic theme switching based on system preferences
- **Responsive Layout** - Optimized for mobile, tablet, and desktop
- **Smooth Navigation** - Bottom navigation for users, rail navigation for admins

### 🎮 Key Screens
- **📊 Dashboard (HazeHub)** - Latest memes and rank-ups at a glance
- **🎮 Gaming Hub** - Browse your Discord server's game collection
- **🏎️ Rocket League Stats** - Real-time player rankings and statistics
- **🎨 Meme Generator** - Create and customize memes with various templates
- **⚙️ Admin Panel** - Comprehensive bot configuration interface
- **📋 Log Viewer** - Real-time bot logs with filtering and search

## 🏃 Running the Application

### Development Mode

**🌐 Web:**
```bash
flutter run -d chrome
```

**📱 Android:**
```bash
flutter run -d android
```

**💻 Desktop:**
```bash
flutter run -d linux    # Linux
flutter run -d windows  # Windows
flutter run -d macos    # macOS
```

### ⚡ Hot Reload

During development, use these keyboard shortcuts:
- `r` - Hot reload (fast refresh)
- `R` - Hot restart (full restart)
- `q` - Quit

## 🔨 Building for Production

### 📱 Android APK

```bash
# Standard release APK
flutter build apk --release

# Split APKs by CPU architecture (smaller file sizes)
flutter build apk --split-per-abi --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### 📦 Android App Bundle (Google Play Store)

```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### 🌐 Web

```bash
flutter build web --release
```

**Output:** `build/web/` directory

### 💻 Desktop

```bash
flutter build linux --release    # 🐧 Linux
flutter build windows --release  # 🪟 Windows
flutter build macos --release    # 🍎 macOS
```

## 📁 Project Structure

```
HazeBot-Admin/
├── 📂 lib/
│   ├── 🚀 main.dart                            # Application entry point
│   ├── 📂 screens/                             # UI screens
│   │   ├── 🔐 login_screen.dart               # Login with JWT/Discord OAuth
│   │   ├── 🏠 home_screen.dart                # Main navigation & dashboard
│   │   ├── 📊 gaming_hub_screen.dart          # Game library browser
│   │   ├── 🏎️ user_rocket_league_screen.dart  # Personal RL stats
│   │   ├── 🎨 meme_generator_screen.dart      # Meme creation tool
│   │   ├── 📋 logs_screen.dart                # Bot log viewer
│   │   ├── ⚙️ settings_screen.dart            # App settings
│   │   ├── 👤 profile_screen.dart             # User profile
│   │   ├── 📂 config/                         # Admin configuration screens
│   │   │   ├── general_config_screen.dart
│   │   │   ├── channels_config_screen.dart
│   │   │   ├── roles_config_screen.dart
│   │   │   ├── daily_meme_config_screen.dart
│   │   │   ├── rocket_league_config_screen.dart
│   │   │   └── texts_config_screen.dart
│   │   └── 📂 admin/                          # Admin-only screens
│   │       └── live_users_screen.dart
│   ├── 📂 services/                            # Business logic & APIs
│   │   ├── 🔌 api_service.dart                # REST API client
│   │   ├── 🔐 auth_service.dart               # JWT authentication
│   │   ├── 🎮 discord_auth_service.dart       # Discord OAuth
│   │   ├── 🔗 deep_link_service.dart          # Deep link handling
│   │   ├── 👮 permission_service.dart         # Role-based access
│   │   ├── ⚙️ config_service.dart             # Bot configuration state
│   │   └── 🎨 theme_service.dart              # Theme management
│   ├── 📂 providers/                           # State management
│   │   └── data_cache_provider.dart           # Data caching
│   └── 📂 utils/                               # Utilities
│       ├── app_config.dart
│       └── web_utils*.dart
├── 📂 android/                                 # Android platform code
├── 📂 web/                                     # Web platform code
├── 📂 linux/                                   # Linux platform code
├── 📂 windows/                                 # Windows platform code
├── 📂 macos/                                   # macOS platform code
├── 📂 test/                                    # Unit tests
├── 📄 pubspec.yaml                             # Dependencies
├── 📄 .env.example                             # Environment template
└── 📄 README.md                                # This file
```

## 🎯 Configuration Capabilities

### 🎛️ General Settings
- Bot name and command prefix
- Presence update interval
- Message cooldown and fuzzy matching
- Basic bot behavior configuration

### 📢 Channel Configuration
- Log and changelog channels
- Meme and welcome channels
- Ticket system channels
- Complete Discord channel mappings

### 👥 Role Management
- Admin, moderator, and member roles
- Interest-based roles
- Special feature roles
- Permission-based access control

### 🎭 Daily Meme Configuration
- Reddit subreddit sources
- Lemmy community sources
- Source selection (Reddit/Lemmy/Both)
- Template caching settings
- Meme preferences and scheduling
- Custom posting times

### 🏎️ Rocket League Integration
- Rank check intervals
- Cache duration settings
- Player stat tracking
- Automatic rank-up notifications

### 💬 Welcome System
- Server rules configuration
- Welcome message templates
- Button interaction responses
- Custom embeds and formatting

## 🧪 Development & Testing

### 🔍 Code Analysis

Run Flutter's built-in analyzer:

```bash
flutter analyze
```

### 🧪 Testing

```bash
flutter test
```

### 🐛 Debugging

```bash
# Run with debug logging
flutter run --debug

# View logs in real-time
flutter logs
```

### 🔧 Useful Commands

```bash
# Clean build artifacts
flutter clean

# Update dependencies
flutter pub get

# Check Flutter SDK version
flutter --version

# List available devices
flutter devices
```

## 🌐 Deployment

### 🌍 Web Deployment

Deploy the `build/web/` directory to any static hosting service:

- **🐙 GitHub Pages** - Free hosting for public repos
- **🔥 Firebase Hosting** - Fast and reliable CDN
- **🚀 Netlify** - Easy deployment with CI/CD
- **▲ Vercel** - Serverless platform with edge functions
- **☁️ AWS S3 + CloudFront** - Scalable enterprise solution

### 📱 Android Deployment

**For Google Play Store:**
1. Create a keystore for app signing
2. Configure signing in `android/app/build.gradle`
3. Build App Bundle: `flutter build appbundle --release`
4. Upload to Google Play Console
5. Submit for review

**For Direct Distribution:**
1. Build APK: `flutter build apk --release`
2. Distribute via GitHub Releases, website, or direct download
3. Users must enable "Install from Unknown Sources"
4. Consider using GitHub Actions for automated builds (see [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md))

### 🤖 Automated Builds (GitHub Actions)

This repository includes a GitHub Actions workflow that automatically:
- ✅ Builds APK on every push to `main`
- ✅ Creates versioned releases with unique build numbers
- ✅ Uploads APK as release asset
- ✅ Supports Obtainium for automatic updates

See [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md) for setup instructions.

## 🔒 Security Best Practices

- ✅ **HTTPS Only** - Always use HTTPS for API connections in production
- ✅ **Environment Variables** - Never commit `.env` files or sensitive credentials
- ✅ **JWT Authentication** - Tokens are securely stored and auto-refreshed
- ✅ **Discord OAuth** - Secure authentication via Discord's OAuth2 flow
- ✅ **Code Obfuscation** - Enable ProGuard for Android release builds
- ✅ **Dependency Updates** - Regularly update dependencies for security patches
- ✅ **Permission System** - Role-based access control for sensitive features

## 🐛 Troubleshooting

### 🌐 CORS Issues (Web)
Ensure your API server has CORS properly configured:
```python
from flask_cors import CORS
CORS(app)
```

### 📱 Android Network Issues
- ✅ Check `AndroidManifest.xml` for internet permission
- ✅ For HTTP connections (dev only), configure `network_security_config.xml`
- ✅ Use `http://10.0.2.2:5000/api` for Android emulator
- ✅ Use your computer's local IP for physical device testing

### 🔌 Connection Refused
- ✅ Verify API server is running and accessible
- ✅ Check firewall settings on server
- ✅ Ensure correct IP address in `.env` file
- ✅ Test API endpoint in browser or Postman first

### 🔐 Authentication Issues
- ✅ Check token expiration (tokens auto-refresh)
- ✅ Verify Discord OAuth redirect URI is configured
- ✅ Clear app data/cache if login fails persistently
- ✅ Ensure API server supports Discord OAuth endpoints

### 🏗️ Build Issues
- ✅ Run `flutter clean` and `flutter pub get`
- ✅ Verify Flutter SDK version: `flutter --version` (3.0.0+)
- ✅ Check for dependency conflicts in `pubspec.yaml`
- ✅ For Android: Ensure Java 21+ is installed
- ✅ Delete `pubspec.lock` and run `flutter pub get` again

### 🔗 Deep Link Issues (Discord OAuth)
- ✅ Verify deep link scheme in `AndroidManifest.xml`
- ✅ Check app is set as default for `hazebot://` URLs
- ✅ Test deep link with: `adb shell am start -W -a android.intent.action.VIEW -d "hazebot://oauth?token=test"`

## ❓ Frequently Asked Questions

### Can I use this without Discord OAuth?
✅ Yes! The app supports both traditional username/password login and Discord OAuth. Discord OAuth is optional.

### Do I need admin permissions to use the app?
⚠️ Partial. Regular users can access Dashboard, Gaming Hub, Rocket League Stats, and Meme Generator. Admin features require admin/moderator permissions.

### How do I get automatic updates?
📱 Use [Obtainium](https://github.com/ImranR98/Obtainium) with this repository URL. It automatically detects new releases and notifies you.

### Can I self-host this app?
✅ Absolutely! Clone the repository, configure your API endpoint in `.env`, and build for your preferred platform.

### What platforms are supported?
📱 Android, 🌐 Web, 🐧 Linux, 🪟 Windows, 🍎 macOS - All platforms are fully supported!

### Is my data secure?
🔒 Yes! Tokens are stored securely, communications can use HTTPS, and the app implements JWT-based authentication with automatic token refresh.

### Can I customize the theme?
🎨 The app automatically adapts to your system theme (Material You on Android 12+). Light and dark themes are supported.

### How often are releases published?
🚀 Every push to main automatically creates a new release with a versioned APK. Manual releases can also be tagged.

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. 🍴 **Fork** the repository
2. 🌿 **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. 💻 **Make** your changes with clear, descriptive commits
4. 🧪 **Test** thoroughly on multiple platforms (Web, Android recommended)
5. 📝 **Document** any new features or changes
6. ✅ **Run** `flutter analyze` to check code quality
7. 🚀 **Push** to your branch: `git push origin feature/amazing-feature`
8. 🎯 **Submit** a pull request with a clear description

### 📋 Contribution Guidelines
- Follow Flutter/Dart style guidelines
- Write meaningful commit messages
- Test on at least 2 platforms before submitting
- Update documentation for new features
- Keep PRs focused on a single feature/fix

## 🛠️ Technology Stack

- **🎯 Framework:** Flutter 3.0+
- **💙 Language:** Dart
- **🎨 UI:** Material Design 3 with dynamic color support
- **🔐 Auth:** JWT + Discord OAuth2
- **🔌 API:** REST API with `http` package
- **📦 State Management:** Provider
- **💾 Storage:** SharedPreferences for local data
- **🔗 Deep Links:** app_links package
- **🎨 Theme:** dynamic_color for Material You support

## 👨‍💻 Author & Links

**👤 Created by:** [inventory69](https://github.com/inventory69)

**📦 Repository:** [github.com/inventory69/HazeBot-Admin](https://github.com/inventory69/HazeBot-Admin)

**🐛 Issues:** [Report bugs or request features](https://github.com/inventory69/HazeBot-Admin/issues)

**📥 Releases:** [Download APKs](https://github.com/inventory69/HazeBot-Admin/releases)

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🔗 Related Projects

- **🤖 HazeBot Discord Bot** - The main Discord bot that this admin interface manages

---

<div align="center">

**Made with ❤️ and Flutter**

Need help? [Open an issue](https://github.com/inventory69/HazeBot-Admin/issues) • [View Documentation](https://github.com/inventory69/HazeBot-Admin/wiki)

</div>
