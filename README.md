# HazeBot Admin Panel 📱

> **Modern cross-platform admin interface for HazeBot built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev/)
[![Material Design 3](https://img.shields.io/badge/Material-Design%203-green.svg)](https://m3.material.io/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Feature-rich admin panel with hybrid navigation combining user features for community members and powerful management tools for administrators. Built with Flutter for Web, Android, and Desktop.

## ✨ Key Features

- 🎨 **Material Design 3** - Android 16 Monet dynamic colors with system theme
- 🔐 **JWT Authentication** - Secure token-based auth with automatic refresh
- 🎮 **User Features** - HazeHub, Gaming Hub, Rocket League, Meme Generator
- ⚙️ **Admin Tools** - Configuration, live monitoring, cog manager, log viewer
- 📱 **Cross-Platform** - Web (primary), Android, Linux Desktop
- 🚀 **Responsive** - Mobile, tablet, and desktop optimized

## 📥 Quick Download

**Android APK:** [Download Latest Release](https://github.com/inventory69/HazeBot-Admin/releases/latest)

💡 **Pro Tip:** Use [Obtainium](https://github.com/ImranR98/Obtainium) for automatic updates!

**[📱 Installation Guide](docs/APK_DOWNLOAD.md)** | **[🔧 Setup Checklist](docs/SETUP_CHECKLIST.md)**

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK 3.0+** - [Install](https://docs.flutter.dev/get-started/install)
- **HazeBot Bot + API Server** - Running and accessible
  - 📖 **[HazeBot Setup Guide](https://github.com/inventory69/HazeBot/blob/main/docs/BOT_SETUP.md)** - Complete bot installation instructions

### Setup

```bash
git clone https://github.com/inventory69/HazeBot-Admin.git
cd HazeBot-Admin
flutter pub get

# Configure
cp .env.example .env
# Edit .env with your API URL

# Run
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d linux     # Linux
```

### Configuration

Edit `.env`:

```env
API_BASE_URL=https://your-api-url.com/api
IMAGE_PROXY_URL=https://your-api-url.com/api/proxy/image
GITHUB_REPO_URL=https://github.com/inventory69/HazeBot-Admin
```

**API URL Examples:**
- Local Web: `http://localhost:5070/api`
- Android Emulator: `http://10.0.2.2:5070/api`
- Android Device: `http://YOUR_LOCAL_IP:5070/api`
- Production: `https://your-domain.com/api`

**[📖 Detailed Setup Guide](docs/SETUP_CHECKLIST.md)**

---

## 📦 Features

### 🎮 User Features (All Users)
- **HazeHub** - Community feed with memes & rank-ups
- **Gaming Hub** - See who's online, send game requests
- **Rocket League** - Manage accounts, stats, post to Discord
- **Meme Generator** - Create memes with 100+ templates
- **Profile** - Avatar, role, RL rank, activity stats

### ⚙️ Admin Features (Admin Only)
- **Configuration** - Bot settings (channels, roles, memes, RL)
- **Cog Manager** - Load/unload/reload bot cogs
- **Tickets** - Real-time chat with WebSocket, claim/assign/close actions
- **Monitoring** - Active user sessions with analytics
- **Logs** - Bot logs with filtering

### 🎨 UI/UX
- Hybrid navigation (bottom tabs + admin rail)
- Android 16 Monet dynamic theming
- Dark/Light mode with system sync
- Hero animations & smooth transitions
- Pull-to-refresh on all lists
- Real-time WebSocket updates for tickets
- Smart push notification suppression
- Message caching for instant loading

**[📋 Complete Features List](docs/FEATURES.md)** - Full feature documentation with details

---

## 🏗️ Architecture

### Navigation
- **Bottom TabBar** (Users) - HazeHub, Gaming Hub, RL, Memes
- **Navigation Rail** (Admins) - Config, Cogs, Tickets, Logs
- **Admin Toggle** - Show/hide admin features
- **Profile Menu** - Bottom sheet with settings

### Material Design 3
- **Surface Hierarchy** - Proper color depth (low/high/highest)
- **Elevation 0** - Flat design per Android 16
- **Dynamic Colors** - Monet system theme integration

### State Management
- **Local State** - StatefulWidget for screens
- **Provider** - Theme and authentication
- **mounted checks** - Before setState() in async
- **WebSocket Service** - Real-time ticket updates
- **Message Cache** - Persistent message storage

**[🏗️ Detailed Architecture](https://github.com/inventory69/HazeBot/blob/main/docs/ARCHITECTURE.md)**

---

## 🔨 Building

### Web
```bash
flutter build web --release --pwa-strategy=none
```

### Android
```bash
flutter build apk --split-per-abi --release
```

### Linux
```bash
flutter build linux --release
```

**[📖 Complete Build Guide](docs/BUILDING.md)**

---

## 📚 Documentation

**[📖 Documentation Index](docs/README.md)** - Complete documentation overview

**Quick Links:**
- 📱 **[APK Download](docs/APK_DOWNLOAD.md)** - Android installation
- 🔧 **[Setup Checklist](docs/SETUP_CHECKLIST.md)** - Quick setup verification
- 🔨 **[Building](docs/BUILDING.md)** - Build for all platforms
- 🧪 **[Development](docs/DEVELOPMENT.md)** - Dev workflows & patterns
- 🔥 **[Firebase Setup](docs/FIREBASE_SETUP.md)** - Push notifications
- 🚀 **[GitHub Actions](docs/GITHUB_ACTIONS.md)** - CI/CD pipeline
- 📋 **[Features](docs/FEATURES.md)** - Complete feature list
- 📝 **[Changelog](docs/CHANGELOG.md)** - Version history

**Related:**
- 🤖 **[HazeBot Backend](https://github.com/inventory69/HazeBot)** - Bot & API server
- 📖 **[HazeBot Docs](https://github.com/inventory69/HazeBot/blob/main/docs/README.md)** - Backend documentation
- 🔌 **[HazeBot API](https://github.com/inventory69/HazeBot/blob/main/api/README.md)** - REST API reference

---

## 🧪 Development

### Hot Reload
- `r` - Hot reload (preserves state)
- `R` - Hot restart (resets state)
- `q` - Quit

### Code Quality
```bash
flutter analyze       # Check code
dart format .         # Format code
flutter test          # Run tests
```

**[📖 Development Guide](docs/DEVELOPMENT.md)**

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Quick Steps:**
1. Fork repository
2. Create branch (`git checkout -b feature/name`)
3. Follow code style (`dart format .`)
4. Test on multiple platforms
5. Submit Pull Request

**Guidelines:**
- ✅ Material Design 3 surface hierarchy
- ✅ Check `mounted` before setState()
- ✅ Try-catch on all API calls
- ✅ Support mobile/tablet/desktop

---

## 📄 License

MIT License - see [LICENSE](LICENSE). Free to use and modify!

---

## 🙏 Acknowledgments

Built with 💖 for The Chillventory community

- Powered by [Flutter](https://flutter.dev/)
- Material Design 3 guidelines
- Special thanks to contributors

**Questions?** Open an issue on GitHub!

*Made with 💖 for The Chillventory* 📱✨
