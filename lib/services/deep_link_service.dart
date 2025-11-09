import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  /// Initialize deep link listener
  Future<void> init({required Function(Uri) onDeepLink}) async {
    // Handle deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link received: $uri');
      onDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });

    // Handle deep link that opened the app (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial deep link: $initialUri');
        onDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial deep link: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
