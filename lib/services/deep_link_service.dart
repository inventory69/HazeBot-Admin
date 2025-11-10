import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  /// Initialize deep link listener
  Future<void> init({required Function(Uri) onDeepLink}) async {
    debugPrint('🚀 DeepLinkService initializing...');

    // Handle deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('📱 Deep link received (app running): $uri');
      onDeepLink(uri);
    }, onError: (err) {
      debugPrint('❌ Deep link stream error: $err');
    });
    debugPrint('✅ Deep link stream listener registered');

    // Handle deep link that opened the app (cold start)
    try {
      debugPrint('🔍 Checking for initial deep link (cold start)...');
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('📱 Initial deep link found: $initialUri');
        onDeepLink(initialUri);
      } else {
        debugPrint('ℹ️  No initial deep link (normal app start)');
      }
    } catch (e) {
      debugPrint('❌ Failed to get initial deep link: $e');
    }

    debugPrint('✅ DeepLinkService initialization complete');
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
