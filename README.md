# HazeBot Admin

Flutter-based admin interface for the HazeBot Discord bot. Available as web and Android app.

## 📥 Quick Download

**Want the APK?** → [Download Guide](APK_DOWNLOAD.md)

**Latest Release:** [Download APK](https://github.com/inventory69/HazeBot-Admin/releases/latest)

💡 **Tip:** Use [Obtainium](https://github.com/ImranR98/Obtainium) for automatic updates!

## Features

- 🔐 **Secure Authentication** - JWT-based login system
- ⚙️ **Configuration Management** - Manage bot settings, subreddits, and channels
- 📊 **Test Functions** - Test bot features like daily memes, Rocket League stats, and Warframe data
- 📱 **Cross-Platform** - Works on Web, Linux Desktop, and Android
- 🎨 **Material Design 3** - Modern UI with light/dark theme support
- 🔄 **Auto-Updates** - New versioned releases for every build (Obtainium compatible)

## Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- For Android builds: Android SDK with Java 21

- Running HazeBot API server

### Installation

## Installation

1. Clone the repository:

```bash### 1. Install Flutter

git clone <your-repo-url>

cd HazeBot-AdminFollow the official Flutter installation guide:

```- https://docs.flutter.dev/get-started/install



2. Copy the environment example file:### 2. Install Dependencies

```bash

cp .env.example .env```bash

```cd hazebot_admin

flutter pub get

3. Edit `.env` and set your API URL:```

```env

API_BASE_URL=https://your-api-url.com/api### 3. Configuration

```

Update the API base URL in `lib/services/api_service.dart`:

4. Install dependencies:

```bash```dart

flutter pub getstatic const String baseUrl = 'http://your-api-server:5000/api';

``````



### Running the AppFor local development, use:

- Web: `http://localhost:5000/api`

#### Desktop (Linux/Windows/macOS)- Android emulator: `http://10.0.2.2:5000/api`

```bash- Android device: `http://YOUR_COMPUTER_IP:5000/api`

flutter run -d linux    # Linux

flutter run -d windows  # Windows## Running the Application

flutter run -d macos    # macOS

```### Web



#### Web```bash

```bashflutter run -d chrome

flutter run -d chrome```

```

Or build for production:

#### Android

```bash```bash

flutter run -d androidflutter build web

``````



### Building for ProductionThe built files will be in `build/web/` directory.



#### Android APK### Android

```bash

flutter build apk --release```bash

```# Run in debug mode

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`flutter run



#### Web# Build APK

```bashflutter build apk

flutter build web

```# Build App Bundle for Play Store

flutter build appbundle

#### Linux```

```bash

flutter build linux## Project Structure

```

```

## Configurationhazebot_admin/

├── lib/

The app uses environment variables for configuration. Create a `.env` file in the root directory:│   ├── main.dart                 # App entry point

│   ├── models/                   # Data models

```env│   ├── services/                 # API and business logic

# API Base URL (without trailing slash)│   │   ├── api_service.dart      # REST API client

API_BASE_URL=https://your-api-url.com/api│   │   ├── auth_service.dart     # Authentication

```│   │   └── config_service.dart   # Configuration management

│   ├── screens/                  # UI screens

**Important:** Never commit the `.env` file to version control! It's included in `.gitignore`.│   │   ├── login_screen.dart     # Login page

│   │   ├── home_screen.dart      # Main dashboard

## Project Structure│   │   └── config/               # Configuration screens

│   │       ├── general_config_screen.dart

```│   │       ├── channels_config_screen.dart

lib/│   │       ├── roles_config_screen.dart

├── main.dart              # App entry point│   │       ├── meme_config_screen.dart

├── screens/               # UI screens│   │       ├── rocket_league_config_screen.dart

│   ├── login_screen.dart│   │       └── welcome_config_screen.dart

│   ├── home_screen.dart│   └── widgets/                  # Reusable UI components

│   ├── config_screen.dart├── pubspec.yaml                  # Dependencies

│   └── test_screen.dart└── README.md                     # This file

└── services/              # Business logic```

    ├── api_service.dart   # API communication

    ├── auth_service.dart  # Authentication## Features Overview

    └── config_service.dart # Configuration state

```### Dashboard

- Overview of bot configuration

## Development- Quick status indicators

- Configuration categories

### Code Style

### General Configuration

This project uses Flutter's recommended linting rules. Run the analyzer:- Bot name and command prefix

```bash- Presence update interval

flutter analyze- Message cooldown settings

```- Fuzzy matching threshold



### Testing### Channels Configuration

```bash- Configure Discord channel IDs

flutter test- Log channel, changelog channel

```- Meme channel, welcome channels

- Ticket system channels

## Related Projects

### Roles Configuration

- [HazeBot](https://github.com/yourusername/HazeBot) - The main Discord bot- Admin, moderator, and member roles

- Interest roles

## License- Special feature roles



See [LICENSE](LICENSE) file for details.### Meme Configuration

- Reddit subreddits
- Lemmy communities
- Meme sources (Reddit/Lemmy)
- Template cache duration

### Rocket League Configuration
- Rank check interval
- Cache TTL settings

### Welcome Configuration
- Server rules text
- Welcome messages
- Button reply messages

## Development

### Hot Reload

Flutter supports hot reload during development:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Debugging

```bash
flutter run --debug
flutter logs
```

### Building for Production

#### Web
```bash
flutter build web --release
```

#### Android
```bash
# Release APK
flutter build apk --release

# Split APKs by architecture
flutter build apk --split-per-abi --release
```

## Deployment

### Web Deployment

The web build can be deployed to any static hosting service:

```bash
flutter build web --release
# Deploy the build/web directory
```

Supported platforms:
- Firebase Hosting
- GitHub Pages
- Netlify
- Vercel
- AWS S3
- Any static web server

### Android Deployment

1. Sign your app (required for Play Store):
   - Create a keystore
   - Configure signing in `android/app/build.gradle`
   - Build signed APK or App Bundle

2. Deploy to:
   - Google Play Store (recommended)
   - Direct APK distribution
   - Internal testing channels

## Security Notes

- Change default API credentials
- Use HTTPS in production
- Implement proper API authentication
- Store sensitive data securely
- Enable ProGuard for Android release builds

## Troubleshooting

### CORS Issues (Web)
If you encounter CORS errors, ensure the Flask API has CORS properly configured.

### Android Network Issues
- Check AndroidManifest.xml for internet permission
- For HTTP (non-HTTPS) connections, configure network security

### Connection Refused
- Verify API server is running
- Check firewall settings
- Use correct IP address for device testing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly (web and Android)
5. Submit a pull request

## License

Same as HazeBot main project (MIT License)
