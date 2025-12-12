# HazeBot-Admin Copilot Instructions

## Architecture Overview

**HazeBot-Admin** is a cross-platform Flutter app (Web primary, Android, Linux Desktop) providing admin interface and user features for HazeBot Discord bot.

### Hybrid Navigation Model
- **Bottom Tabs (All Users):** HazeHub, Gaming Hub, Rocket League, Memes, Profile
- **Admin Rail (Admin Only):** Config, Cogs, Tickets, Monitoring, Logs
- Admin rail slides out on desktop/tablet, bottom nav on mobile
- Role-based visibility: Admin sees everything, regular users see only bottom tabs

### Project Structure
```
lib/
├── main.dart                 # Entry point, theme setup, MaterialApp
├── screens/                  # Full-page screens (home, login, individual features)
├── widgets/                  # Reusable components (cards, buttons, dialogs)
├── services/                 # API client, auth, WebSocket, notifications
├── providers/                # State management (Provider pattern)
├── models/                   # Data classes (User, Ticket, Config, etc.)
└── utils/                    # Helpers (constants, theme, formatters)
```

## State Management: Provider Pattern

All app state is managed via **Provider** package. Key providers:
- `AuthProvider` - JWT token, user info, login/logout, role checking
- `TicketProvider` - Ticket list, WebSocket connection, real-time messages
- `ConfigProvider` - Bot configuration, channel/role IDs, feature toggles
- `ThemeProvider` - Dark/Light mode, Material You dynamic colors

**Pattern:**
```dart
// Define provider
class MyProvider extends ChangeNotifier {
  void updateValue() {
    // ... change state
    notifyListeners(); // Triggers UI rebuild
  }
}

// Register in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyProvider()),
  ],
  child: MyApp(),
)

// Consume in widgets
Consumer<MyProvider>(
  builder: (context, provider, child) => Text(provider.value),
)
// OR
Provider.of<MyProvider>(context, listen: false).updateValue();
```

## API Integration

### API Service (`services/api_service.dart`)
Singleton service handling all HTTP requests to HazeBot API.

**Key Methods:**
- `login(username, password)` - Basic auth, returns JWT token
- `loginWithDiscord(code)` - OAuth2 flow, exchanges code for token
- `get/post/put/delete(endpoint, {data, headers})` - Generic REST methods
- Auto-adds JWT token to Authorization header if available

**Platform-Aware URLs:**
- Web: `API_BASE_URL` from `.env`
- Android Emulator: `http://10.0.2.2:5070/api`
- Android Device: Requires local network IP (e.g., `http://192.168.1.100:5070/api`)

### Image Proxy Pattern
Discord CDN images require authorization. API provides `/api/proxy/image?url=<encoded_url>` endpoint.

**Usage:**
```dart
Image.network(
  '${Config.imageProxyUrl}?url=${Uri.encodeComponent(discordImageUrl)}',
  headers: {'Authorization': 'Bearer $token'},
)
```

## WebSocket (Real-Time Tickets)

### Connection Management (`services/websocket_service.dart`)
Socket.IO client for real-time ticket updates.

**Events:**
- `connect` - Establish connection with JWT auth
- `join_ticket` - Subscribe to specific ticket room
- `ticket_message` - Receive/send chat messages
- `ticket_closed` - Handle ticket closure
- `disconnect` - Clean up on logout/app close

**Pattern:**
```dart
socketService.connect(token);
socketService.on('ticket_message', (data) {
  // Update TicketProvider with new message
  ticketProvider.addMessage(data);
});
socketService.emit('join_ticket', {'ticket_id': ticketId});
```

**Smart Notification Suppression:** When viewing a ticket, suppress push notifications for that ticket to avoid duplicate alerts.

## Material Design 3 (Android 16 Monet)

### Dynamic Color Theming
Uses `dynamic_color` package to extract system colors (Android 12+).

**Implementation (`main.dart`):**
```dart
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: lightDynamic ?? fallbackLightScheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkDynamic ?? fallbackDarkScheme,
        useMaterial3: true,
      ),
    );
  },
)
```

**Custom Themes:** When dynamic colors unavailable (Web, iOS), fallback to custom `ColorScheme` with pastel pink/purple theme.

## Firebase Cloud Messaging (FCM)

### Push Notifications (`services/notification_service.dart`)
Handles foreground notifications and token management.

**Setup:**
1. Initialize Firebase: `Firebase.initializeApp()`
2. Request permission: `FirebaseMessaging.instance.requestPermission()`
3. Get token: `FirebaseMessaging.instance.getToken()`
4. Send token to API: `POST /api/fcm/register {token, device_info}`

**Foreground Handling:**
```dart
FirebaseMessaging.onMessage.listen((message) {
  // Show local notification using flutter_local_notifications
  _showLocalNotification(message.notification!);
});
```

**Background/Terminated:** Handled by Firebase natively (Android system notifications).

## Deep Linking (Discord OAuth2 Callback)

### App Links (`app_links` package)
Handles `admin.haze.pro/discord/callback?code=...` deep links for OAuth2.

**Implementation (`main.dart`):**
```dart
final appLinks = AppLinks();
appLinks.uriLinkStream.listen((uri) {
  if (uri.path.contains('/discord/callback')) {
    final code = uri.queryParameters['code'];
    authProvider.loginWithDiscord(code);
  }
});
```

**Android Setup:** Configured in `android/app/src/main/AndroidManifest.xml` with intent filters.

## Common Patterns

### Creating New Screen
1. Create file in `screens/{feature}_screen.dart`
2. Use `Scaffold` with `AppBar` and body
3. Consume providers with `Consumer` or `Provider.of`
4. Add route to `main.dart` MaterialApp routes

### Adding API Endpoint
1. Add method to `services/api_service.dart`
2. Handle response/errors, return typed model
3. Update provider to call new method
4. Trigger with `notifyListeners()` to update UI

### Handling Forms
```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Submit form
          }
        },
      ),
    ],
  ),
)
```

## Development Workflows

### Running Locally
```bash
# Web (hot reload, fast iteration)
flutter run -d chrome

# Android (emulator or device)
flutter run -d android

# Linux Desktop
flutter run -d linux
```

**Environment Configuration:**
1. Copy `.env.example` to `.env`
2. Set `API_BASE_URL` for target environment (local/prod)
3. For Android device, use local network IP: `http://192.168.1.X:5070/api`

### Building Production APK
```bash
# Release build (minified, obfuscated)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

**GitHub Actions:** `.github/workflows/build-production-apk.yml` auto-builds on push to `main`, creates GitHub release with APK artifact.

### Code Quality
```bash
flutter analyze           # Static analysis
flutter test              # Run unit tests (if any)
dart format lib/          # Auto-format code
```

## Testing Strategy

- **No formal test suite:** Manual testing on Web + Android
- **Test Users:** Use test credentials in HazeBot test environment
- **API Testing:** Postman collection for endpoint validation
- **Device Testing:** Test on emulator + real Android device + Web browsers

## Deployment

### Web (admin.haze.pro)
Deployed via `devops-scripts/scripts/deploy-hazebot-admin.sh`:
1. `flutter build web --release`
2. Package `build/web/` to tar.gz
3. Upload to hzwd server
4. Extract to `/var/www/admin.haze.pro/`
5. NGINX serves static files with reverse proxy to API

### Android (APK)
- **GitHub Releases:** Auto-published by GitHub Actions
- **Obtainium:** Users can track releases for auto-updates
- **Direct Download:** Link in README points to latest release

## Troubleshooting

### WebSocket Not Connecting
- Check JWT token is valid (not expired)
- Verify API URL includes protocol (`https://` not `admin.haze.pro`)
- Confirm CORS settings in HazeBot API allow origin
- Check Socket.IO server is running (`start_with_api.py`)

### Deep Links Not Working (Android)
- Verify `AndroidManifest.xml` has correct intent filters
- Test with `adb shell am start -a android.intent.action.VIEW -d "https://admin.haze.pro/discord/callback?code=test"`
- Check app is set as default handler for domain

### Theme Not Loading
- Verify `DynamicColorBuilder` in `main.dart`
- Check `ThemeProvider` is registered in `MultiProvider`
- Confirm Material 3 is enabled: `useMaterial3: true`

### API 401 Unauthorized
- Token expired (check JWT expiry with jwt.io)
- Token not stored correctly in `SharedPreferences`
- API expects `Bearer <token>` format in Authorization header

### Image Proxy Issues
- Discord CDN URLs must be URL-encoded
- Proxy requires valid JWT token in headers
- Fallback to placeholder if proxy fails (graceful degradation)
