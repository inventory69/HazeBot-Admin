# GitHub Copilot Code Review Instructions - HazeBot-Admin

## Review Philosophy
- Only comment when you have HIGH CONFIDENCE (>80%) that an issue exists
- Be concise: one sentence per comment when possible
- Focus on actionable feedback, not observations
- When reviewing text, only comment on clarity issues if the text is genuinely confusing or could lead to errors. "Could be clearer" is not the same as "is confusing" - stay silent unless HIGH confidence it will cause problems

## Priority Areas (Review These)

### Security & Safety
- JWT token exposure or improper storage (should use SharedPreferences)
- Credential exposure or hardcoded API keys
- Missing input validation on user-entered data
- Improper error handling that could leak sensitive info
- API calls without authentication headers
- Missing token refresh logic
- Insecure HTTP instead of HTTPS in production

### Correctness Issues
- Logic errors that could cause crashes or incorrect behavior
- Race conditions in async code
- Memory leaks (unclosed streams, controllers not disposed)
- Missing `mounted` checks before `setState()` in async callbacks
- Incorrect navigation that could cause stack overflow
- Off-by-one errors in pagination or list indexing
- Missing null checks on optional API responses
- BuildContext used across async gaps
- Improper use of deprecated Flutter APIs
- Missing error handling in API calls (try-catch)
- State updates after widget disposal

### Architecture & Patterns
- Code that violates Material Design 3 patterns
- Breaking Android 16 Monet Surface Hierarchy (wrong surface colors)
- Inconsistent responsive design (missing mobile/tablet/desktop breakpoints)
- Missing const constructors where possible (performance issue)
- Improper StatefulWidget/StatelessWidget choice
- Not following established navigation patterns (Hybrid TabBar + Rail)
- Breaking theme-aware color usage (hardcoded colors instead of theme colors)
- Missing RefreshIndicator on lists
- Not using established widgets (should reuse existing widgets)

## Project-Specific Context

### Frontend (Flutter/Dart)
- **Technology**: Flutter 3.x, Material Design 3, Provider State Management
- **Target Platforms**: Web (primary), Android (secondary), Linux Desktop
- **Architecture**: Hybrid Navigation (Bottom TabBar for users + Navigation Rail for admins)

- **Core Files**:
  - `lib/main.dart` - App Entry Point with Dynamic Color support
  - `lib/screens/home_screen.dart` - Hybrid Navigation System
  - `lib/services/api_service.dart` - All API calls (300+ lines)
  - `lib/services/auth_service.dart` - JWT Authentication
  - `lib/services/theme_service.dart` - Theme management
  - `lib/models/` - Data models (Ticket, TicketConfig, etc.)
  - `lib/widgets/` - Reusable widgets (CogCard, etc.)

- **Navigation System**:
  - Bottom TabBar: HazeHub, Gaming Hub, Rocket League, Meme Gen, Memes (for ALL users)
  - Navigation Rail: Admin Panel (hidden by default, only for admins)
  - Admin Icon in AppBar toggles Rail visibility
  - Profile avatar in AppBar opens Bottom Sheet Menu

- **API Integration**:
  - Base URL from environment variable (`.env`)
  - JWT token in Authorization header (Bearer)
  - Automatic token refresh with 5-min buffer
  - Session tracking on backend
  - User-Agent header: "Testventory/Chillventory" with device info

- **State Management**:
  - Local state with StatefulWidget for most screens
  - Provider for theme/auth (minimal, no unnecessary global state)
  - `mounted` checks before setState() in async callbacks
  - Dispose controllers/streams in dispose() method

- **Error Handling**:
  - Try-catch around all API calls
  - Loading states: `_isLoading`, `_error`
  - Error widgets with retry buttons
  - Empty state widgets with helpful messages
  - SnackBars for user feedback (success/error)

### Material Design 3 & Android 16 Monet

**CRITICAL: Surface Hierarchy** (most common mistake):
```dart
// Scaffold Background (lowest level)
scaffoldBackgroundColor: colorScheme.surface

// Section Cards (e.g., "Latest Items", category containers)
Card(
  color: colorScheme.surfaceContainerLow,
  elevation: 0,  // Flat design per Android 16
)

// Content Cards (items within sections)
Card(
  color: colorScheme.surfaceContainerHigh,
  elevation: 0,
)

// Input Fields (highest level)
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
  ),
)
```

**Theme Colors** (NEVER hardcode):
- Use `Theme.of(context).colorScheme.primary` instead of `Colors.blue`
- Use `Theme.of(context).textTheme.titleLarge` instead of hardcoded font sizes
- Exceptions: Status colors (Colors.red for errors, Colors.green for success)

**Responsive Design**:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 600;
    final isTablet = constraints.maxWidth < 900;
    final padding = isMobile ? 12.0 : 24.0;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      // ...
    );
  },
)
```

### Code Quality Standards

**Formatting**:
- `flutter analyze` - Analyze code
- `dart format .` - Format code
- Always use const constructors where possible
- Line length: 120 characters (analysis_options.yaml)

**Common Patterns**:
```dart
// API Call Pattern
Future<void> _loadData() async {
  try {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await ApiService().getData();
    
    if (mounted) {
      setState(() {
        _data = result['data'] ?? [];
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}
```

### Recent Patterns to Follow

**Version 3.8 Updates**:
- Modular API architecture with Blueprint pattern
- All API calls via `ApiService()` methods
- User-Agent header in all requests
- Proper loading states with `CircularProgressIndicator`
- RefreshIndicator on all lists
- Collapsible UI (Categories and Cards)
- Local state updates (no full screen reloads)
- Async action handlers with `Future<void> Function()` callbacks

**Ticket System Pattern** (Version 3.5):
- Two-tab layout: Manage + Configuration
- Status filtering with chips
- Detail dialogs with nested tabs (Details + Messages)
- Action buttons with confirmation dialogs
- Monet surface hierarchy throughout

**Cog Manager Pattern** (Version 3.7):
- Collapsible cards (expanded state per card)
- Collapsible categories (expanded state per category)
- Quick jump filter with count badges
- Local status updates (no API reload on action)
- Async action handlers with loading states

## CI Pipeline Context

**Important**: Reviews happen before build/tests complete. Do not flag issues that automated checks will catch.

### What Our Checks Do

**Flutter/Dart checks** (currently manual, should be automated):
- `flutter analyze` - Static analysis
- `dart format --set-exit-if-changed .` - Format check
- `flutter build web --release --pwa-strategy=none` - Web build
- `flutter build apk` - Android build (currently has issues)

**Key setup**:
- Uses `.env` for environment variables (never committed)
- Firebase config in `android/app/google-services.json` (never committed)
- Material Design 3 with dynamic_color package
- Web deployment via `spa_server.py` (serves build/web/)

**Testing strategy**:
- Manual testing on Web (Chrome/Firefox)
- Manual testing on Linux Desktop
- Android testing on device (APK builds have issues)
- Hard refresh required after web build (Ctrl+Shift+R) due to browser caching

## Skip These (Low Value)

Do not comment on:
- **Style/formatting** - dart format handles this
- **Analysis warnings** - flutter analyze handles this
- **Missing dependencies** - pubspec.yaml and pub get handle this
- **Minor naming suggestions** - unless truly confusing
- **Suggestions to add comments** - for self-documenting code
- **Refactoring suggestions** - unless there's a clear bug or maintainability issue
- **Multiple issues in one comment** - choose the single most critical issue
- **Logging suggestions** - we don't need excessive logging in production
- **Pedantic accuracy in text** - unless it would cause actual confusion or errors

## Response Format

When you identify an issue:
1. **State the problem** (1 sentence)
2. **Why it matters** (1 sentence, only if not obvious)
3. **Suggested fix** (code snippet or specific action)

Example:
```
Missing `mounted` check before setState(). Add `if (mounted)` to prevent setState on disposed widget.
```

## When to Stay Silent

If you're uncertain whether something is an issue, don't comment. False positives create noise and reduce trust in the review process.

## Project Standards (from AI_PROJECT_INSTRUCTIONS.md)

### Screen Creation Checklist

**ALWAYS include**:
1. Scaffold with transparent AppBar (`Colors.transparent`)
2. LayoutBuilder for responsive design
3. Loading state with CircularProgressIndicator
4. Error state with retry button
5. Empty state with helpful icon/text
6. RefreshIndicator on lists
7. Try-catch on all API calls
8. `mounted` checks before setState() in async
9. Monet Surface Hierarchy (correct surface colors)
10. Theme-aware colors (no hardcoded colors)

### API Integration Checklist

**Frontend (Flutter)**:
- API Service method in `api_service.dart`
- Uses `_get()/_post()/_put()/_delete()` wrappers
- Token automatically in headers
- Error handling with try-catch
- `mounted` check before setState()
- Loading state management
- User feedback (SnackBars)

**Naming Conventions**:
- API methods: `getFeatureData()`, `createFeatureItem()`, `updateFeatureItem()`
- State variables: `_isLoading`, `_error`, `_data`
- Private methods: `_loadData()`, `_handleAction()`

### Common Mistakes to Avoid

1. **Wrong Surface Colors**: Using `surfaceContainerHigh` for section cards (should be `surfaceContainerLow`)
2. **Hardcoded Colors**: Using `Colors.blue` instead of `colorScheme.primary`
3. **Missing Mounted Check**: setState() after async without `if (mounted)`
4. **No Loading State**: API calls without `_isLoading` indicator
5. **Wrong Responsive Breakpoints**: Using fixed sizes instead of `constraints.maxWidth < 600`
6. **Elevation > 0**: Should always use `elevation: 0` (Flat Design per Android 16)
7. **Missing const**: Not using `const` constructors where possible
8. **No Error Handling**: API calls without try-catch
9. **BuildContext Across Async**: Using context after await without checking mounted
10. **Disposed Controllers**: Not disposing TextEditingController/StreamController

### Files to NEVER Commit

- `.env` - Contains API URLs and credentials
- `android/app/google-services.json` - Firebase configuration
- `build/` - Build artifacts
- `.dart_tool/` - Dart tools cache
- `*.lock` files (except `pubspec.lock`)

### Environment Variables

Required in `.env`:
- `API_BASE_URL` - Backend API URL
- `DEFAULT_USERNAME` - Dev login username
- `DEFAULT_PASSWORD` - Dev login password
- `IMAGE_PROXY_URL` - CORS proxy for images
- `GITHUB_REPO_URL` - Repository URL for About screen
