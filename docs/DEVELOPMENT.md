# Development Guide 🧪

This guide covers development workflows, common patterns, and best practices for HazeBot Admin.

## Development Environment

### Prerequisites

- **Flutter SDK 3.0+** - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **VS Code** or **Android Studio** - Recommended IDEs
- **Chrome** - For web development
- **Android Studio** - For Android development (optional)

### Editor Setup

**VS Code Extensions:**
- Flutter
- Dart
- Flutter Widget Snippets
- Error Lens

**Android Studio Plugins:**
- Flutter
- Dart

---

## Hot Reload & Restart

During development, Flutter provides hot reload for instant UI updates:

- **`r`** - Hot reload (fast, preserves state)
- **`R`** - Hot restart (full restart, resets state)
- **`q`** - Quit development server

### When to Use Each

**Hot Reload (`r`):**
- UI changes (widgets, layouts, colors)
- Text changes
- Small logic changes
- Preserves app state

**Hot Restart (`R`):**
- Changes to `main()`
- Static field changes
- Global variable changes
- State needs to be reset

---

## Code Quality

### Analyze Code

```bash
# Run static analysis
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

### Format Code

```bash
# Format all Dart files
dart format .

# Format specific file
dart format lib/main.dart

# Check formatting without changes
dart format --output=none --set-exit-if-changed .
```

### Dependency Management

```bash
# Check for outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Get dependencies
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get
```

---

## Common Development Patterns

### API Call Pattern

**Standard async API call with loading/error states:**

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(_data[index].toString()));
      },
    );
  }
}
```

**Key Points:**
- ✅ Always check `mounted` before setState() in async callbacks
- ✅ Handle loading, error, and success states
- ✅ Use try-catch for error handling
- ✅ Clear previous errors before new requests

---

### Material Design 3 Surface Hierarchy

**Proper color usage for depth perception:**

```dart
// Scaffold background (lowest level)
Scaffold(
  backgroundColor: Theme.of(context).colorScheme.surface,
  body: ...
)

// Section card (low elevation)
Card(
  color: Theme.of(context).colorScheme.surfaceContainerLow,
  elevation: 0,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Section Title'),
        
        // Content card inside section (higher elevation)
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          elevation: 0,
          child: ListTile(
            title: Text('Content'),
          ),
        ),
      ],
    ),
  ),
)

// Input fields (highest elevation)
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
  ),
)
```

**Surface Hierarchy:**
1. `surface` - Scaffold background
2. `surfaceContainerLow` - Section cards
3. `surfaceContainer` - Default containers
4. `surfaceContainerHigh` - Content cards
5. `surfaceContainerHighest` - Input fields, search bars

**Always use `elevation: 0`** - Android 16 uses flat design with color depth instead of shadows.

---

### Responsive Layout

**Handle different screen sizes:**

```dart
class ResponsiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Mobile
    if (width < 600) {
      return MobileLayout();
    }
    // Tablet
    else if (width < 900) {
      return TabletLayout();
    }
    // Desktop
    else {
      return DesktopLayout();
    }
  }
}

// Or use LayoutBuilder
class AdaptiveLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return SingleColumnLayout();
        } else {
          return TwoColumnLayout();
        }
      },
    );
  }
}
```

**Breakpoints:**
- **Mobile:** < 600px
- **Tablet:** 600px - 899px
- **Desktop:** ≥ 900px

---

### Navigation Patterns

**Push new screen:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```

**Push with Hero animation:**
```dart
Hero(
  tag: 'unique-tag',
  child: Image.network(imageUrl),
)

// On destination screen
Hero(
  tag: 'unique-tag',
  child: Image.network(imageUrl),
)
```

**Pop with result:**
```dart
// Push and wait for result
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => EditScreen()),
);

if (result == true) {
  _loadData(); // Refresh data
}

// Pop with result
Navigator.pop(context, true);
```

---

### State Management

**Local State (StatefulWidget):**
```dart
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('Count: $_count');
  }
}
```

**Provider (for theme/auth):**
```dart
// Define provider
class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// Use in widget
final themeProvider = Provider.of<ThemeProvider>(context);
themeProvider.toggleTheme();
```

---

## Testing

### Run Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Widget Test Example

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments', (WidgetTester tester) async {
    // Build widget
    await tester.pumpWidget(MyApp());

    // Verify initial state
    expect(find.text('0'), findsOneWidget);

    // Tap button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify updated state
    expect(find.text('1'), findsOneWidget);
  });
}
```

---

## Debugging

### Debug Print

```dart
// Simple debug print
print('Debug: $value');

// Debug print (removed in release)
debugPrint('Debug: $value');

// Only in debug mode
if (kDebugMode) {
  print('Debug only: $value');
}
```

### Flutter DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Run app with DevTools
flutter run --observatory-port=9100
```

**DevTools Features:**
- Inspector - Widget tree visualization
- Performance - Frame rendering analysis
- Memory - Memory usage tracking
- Network - HTTP request monitoring
- Logging - Console output

### Common Issues

**Hot reload not working:**
```bash
# Try hot restart instead
R

# Or full rebuild
flutter clean
flutter pub get
flutter run
```

**Widget not updating:**
- Check if `setState()` is called
- Verify `mounted` before setState() in async
- Ensure widget is in StatefulWidget, not StatelessWidget

**Layout overflow:**
```dart
// Wrap in SingleChildScrollView
SingleChildScrollView(
  child: Column(children: [...]),
)

// Or use Flexible/Expanded
Row(
  children: [
    Flexible(child: Text('Long text...')),
  ],
)
```

---

## Performance Tips

### Build Optimization

```dart
// ✅ Good - const constructors
const Text('Hello')

// ❌ Bad - creates new widget every build
Text('Hello')

// ✅ Good - extract static widgets
final _staticWidget = Text('Static');

@override
Widget build(BuildContext context) {
  return Column(children: [_staticWidget]);
}
```

### Image Optimization

```dart
// Use cached network images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)

// Resize images
Image.network(
  url,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)
```

### List Optimization

```dart
// Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)

// Add keys for list items
ListView.builder(
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].name),
    );
  },
)
```

---

## Git Workflow

### Branch Strategy

```bash
# Create feature branch
git checkout -b feature/new-screen

# Make changes and commit
git add .
git commit -m "feat: add new screen"

# Push to remote
git push origin feature/new-screen
```

### Commit Messages

Follow conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `style:` - Formatting changes
- `docs:` - Documentation
- `test:` - Tests
- `chore:` - Maintenance

**Examples:**
```
feat: add user profile screen
fix: resolve authentication timeout
refactor: extract common widgets
style: format code with dart format
docs: update setup instructions
```

---

## 🔗 Next Steps

- 🔨 [Building Guide](BUILDING.md) - Build for all platforms
- 📋 [Features](FEATURES.md) - Understand existing features
- 🔥 [Firebase Setup](FIREBASE_SETUP.md) - Configure notifications
- 🏠 [Documentation Index](README.md) - All documentation

**Related Resources:**
- 🤖 [HazeBot Backend](https://github.com/inventory69/HazeBot) - Bot & API server
- 📖 [HazeBot API](https://github.com/inventory69/HazeBot/blob/main/api/README.md) - REST API reference
- 🏗️ [Flutter Documentation](https://docs.flutter.dev) - Official Flutter guides

---

## 🆘 Getting Help

- **Development Issues:** Check troubleshooting section above
- **Flutter Questions:** [Flutter Documentation](https://docs.flutter.dev)
- **Project Questions:** Open an issue on [GitHub](https://github.com/YOUR_USERNAME/HazeBot-Admin/issues)
