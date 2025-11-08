# HazeBot Admin

A modern, cross-platform admin interface for the HazeBot Discord bot built with Flutter. Manage your bot's configuration with an intuitive Material Design 3 interface.

## 📥 Quick Start

### Download the App

**Android APK:** [Download Latest Release](https://github.com/inventory69/HazeBot-Admin/releases/latest)

**Installation Guides:**
- [Android APK Download & Installation](APK_DOWNLOAD.md)
- [GitHub Actions Setup](GITHUB_ACTIONS.md)
- [Setup Checklist](SETUP_CHECKLIST.md)

💡 **Pro Tip:** Use [Obtainium](https://github.com/ImranR98/Obtainium) to automatically receive updates!

## ✨ Features

- 🔐 **Secure Authentication** - JWT-based login system
- ⚙️ **Configuration Management** - Manage bot settings, channels, roles, and more
- 📊 **Test Functions** - Test bot features like daily memes, Rocket League stats, and game data
- 📱 **Cross-Platform** - Web, Linux, Windows, macOS, and Android support
- 🎨 **Material Design 3** - Modern UI with dynamic colors and theme support
- 🔄 **Auto-Updates** - Versioned releases for every build (Obtainium compatible)
- 📋 **Log Viewer** - Real-time bot log monitoring with filters

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

### 3. Configure API Connection

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and set your API URL:

```env
API_BASE_URL=https://your-api-url.com/api
```

**API URL Guidelines:**
- **Web (local development):** `http://localhost:5000/api`
- **Android Emulator:** `http://10.0.2.2:5000/api`
- **Android Device (local network):** `http://YOUR_COMPUTER_IP:5000/api`
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

During development, use these keyboard shortcuts:
- `r` - Hot reload (fast refresh)
- `R` - Hot restart (full restart)
- `q` - Quit

## 🔨 Building for Production

### Android APK

```bash
# Standard release APK
flutter build apk --release

# Split APKs by CPU architecture (smaller file sizes)
flutter build apk --split-per-abi --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Web

```bash
flutter build web --release
```

Output: `build/web/` directory

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
│   ├── main.dart                      # Application entry point
│   ├── models/                        # Data models
│   ├── services/                      # Business logic & API
│   │   ├── api_service.dart          # REST API client
│   │   ├── auth_service.dart         # Authentication
│   │   ├── config_service.dart       # Configuration state
│   │   └── theme_service.dart        # Theme management
│   ├── screens/                       # UI screens
│   │   ├── login_screen.dart         # Login page
│   │   ├── home_screen.dart          # Main dashboard
│   │   ├── settings_screen.dart      # Settings page
│   │   ├── logs_screen.dart          # Log viewer
│   │   └── config/                   # Configuration screens
│   │       ├── general_config_screen.dart
│   │       ├── channels_config_screen.dart
│   │       ├── roles_config_screen.dart
│   │       ├── daily_meme_config_screen.dart
│   │       └── rocket_league_config_screen.dart
│   └── widgets/                       # Reusable UI components
├── android/                           # Android platform code
├── web/                              # Web platform code
├── linux/                            # Linux platform code
├── windows/                          # Windows platform code
├── macos/                            # macOS platform code
├── test/                             # Unit tests
├── pubspec.yaml                      # Dependencies
├── .env.example                      # Environment template
└── README.md                         # This file
```

## 🎯 Configuration Features

### General Settings
- Bot name and command prefix
- Presence update interval
- Message cooldown and fuzzy matching
- Basic bot behavior

### Channel Configuration
- Log and changelog channels
- Meme and welcome channels
- Ticket system channels
- All Discord channel mappings

### Role Management
- Admin, moderator, and member roles
- Interest-based roles
- Special feature roles

### Daily Meme Configuration
- Reddit subreddit sources
- Lemmy community sources
- Source selection (Reddit/Lemmy)
- Template caching settings
- Meme preferences and scheduling

### Rocket League Integration
- Rank check intervals
- Cache duration settings
- Player stat tracking

### Welcome System
- Server rules configuration
- Welcome message templates
- Button interaction responses

## 🧪 Development

### Code Analysis

Run Flutter's built-in analyzer:

```bash
flutter analyze
```

### Testing

```bash
flutter test
```

### Debugging

```bash
# Run with debug logging
flutter run --debug

# View logs
flutter logs
```

## 🌐 Deployment

### Web Deployment

Deploy the `build/web/` directory to any static hosting service:

- **GitHub Pages:** Free hosting for public repos
- **Firebase Hosting:** Fast and reliable
- **Netlify:** Easy deployment with CI/CD
- **Vercel:** Serverless platform
- **AWS S3 + CloudFront:** Scalable solution

### Android Deployment

**For Play Store:**
1. Create a keystore for app signing
2. Configure signing in `android/app/build.gradle`
3. Build App Bundle: `flutter build appbundle --release`
4. Upload to Google Play Console

**For Direct Distribution:**
1. Build APK: `flutter build apk --release`
2. Distribute via GitHub Releases, website, or direct download
3. Users must enable "Install from Unknown Sources"

## 🔒 Security Best Practices

- ✅ Use HTTPS for API connections in production
- ✅ Never commit `.env` or sensitive credentials
- ✅ Implement proper API authentication
- ✅ Store sensitive data using secure storage
- ✅ Enable ProGuard for Android release builds
- ✅ Regularly update dependencies

## 🐛 Troubleshooting

### CORS Issues (Web)
Ensure your Flask API has CORS properly configured:
```python
from flask_cors import CORS
CORS(app)
```

### Android Network Issues
- Check `AndroidManifest.xml` for internet permission
- For HTTP connections, configure network security in `android/app/src/main/res/xml/network_security_config.xml`

### Connection Refused
- Verify API server is running
- Check firewall settings
- Ensure correct IP address (especially for Android device testing)
- Use `http://10.0.2.2:5000/api` for Android emulator

### Build Issues
- Run `flutter clean` and `flutter pub get`
- Verify Flutter SDK version: `flutter --version`
- Check for dependency conflicts in `pubspec.yaml`

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly on Web and Android
5. Commit your changes: `git commit -m 'Add some feature'`
6. Push to the branch: `git push origin feature/your-feature`
7. Submit a pull request

## 👨‍💻 Developer

**Created by:** [inventory69](https://github.com/inventory69)

**Repository:** [github.com/inventory69/HazeBot-Admin](https://github.com/inventory69/HazeBot-Admin)

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🔗 Related Projects

- **HazeBot Discord Bot:** The main bot that this admin interface manages

---

**Need help?** Open an issue on [GitHub](https://github.com/inventory69/HazeBot-Admin/issues)
