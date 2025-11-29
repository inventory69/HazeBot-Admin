# Changelog

All notable changes to HazeBot Admin Panel will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Refactored README.md - reduced from 370 to 208 lines (-44%)
- Moved development workflows to DEVELOPMENT.md (11 KB)
- Moved build instructions to BUILDING.md (6.2 KB)
- Improved documentation structure for better maintainability

### Added
- DEVELOPMENT.md - Comprehensive development guide
  - Hot reload workflows
  - Common code patterns (API calls, Material Design 3, responsive layouts)
  - Testing and debugging guides
  - Performance optimization tips
  - Git workflow best practices
- BUILDING.md - Complete build guide for all platforms
  - Web, Android, Linux build instructions
  - Optimization tips (APK size, obfuscation)
  - Environment-specific builds
  - CI/CD integration
  - Troubleshooting section

### Fixed
- Fixed escaped backticks in README code blocks
- Corrected Material Design 3 surface hierarchy documentation
- Improved inline code formatting throughout documentation

## [3.8.0] - 2025-11-29

### Added
- Material Design 3 with Android 16 Monet dynamic colors
- Hybrid navigation system (bottom tabs + admin rail)
- HazeHub dashboard with community feed
- Gaming Hub with online status tracking
- Rocket League account management
- Meme generator with 100+ templates
- Admin configuration panel
- Cog manager with load/unload/reload
- Ticket system management
- Live monitoring of active sessions
- Log viewer with filtering
- JWT authentication with automatic refresh
- WebSocket support for real-time updates
- Pull-to-refresh on all lists
- Hero animations for smooth transitions
- Responsive layout (mobile, tablet, desktop)
- Dark/Light mode with system sync

### Changed
- Complete UI redesign with Material Design 3
- Improved navigation with hybrid system
- Enhanced performance with smart caching
- Better error handling across all screens

### Fixed
- Authentication token refresh issues
- Layout overflow on small screens
- Image loading and caching
- Theme switching persistence

---

## Version History

- **3.8.0** (2025-11-29) - Material Design 3 redesign, hybrid navigation
- **3.7.x** - Previous versions (legacy)

---

## Upgrade Notes

### From 3.7.x to 3.8.0

**Breaking Changes:**
- Theme system completely rewritten for Material Design 3
- Navigation structure changed to hybrid system
- API authentication now requires JWT tokens

**Migration Steps:**
1. Update Flutter SDK to 3.0+
2. Run `flutter pub get` to update dependencies
3. Clear app data (logout and login again for new tokens)
4. Review custom theme colors (surface hierarchy changed)

**New Features:**
- Explore new HazeHub dashboard
- Try Gaming Hub for online status
- Use admin rail for quick management access

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on contributing to this project.

Report bugs and request features via [GitHub Issues](https://github.com/inventory69/HazeBot-Admin/issues).
