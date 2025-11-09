// Conditional export for web-specific utilities
export 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils_web.dart';
