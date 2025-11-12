import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App configuration based on environment
class AppConfig {
  /// Get app name based on PROD_MODE
  /// - Production (PROD_MODE=true): "Chillventory"
  /// - Test/Dev (PROD_MODE=false): "Testventory"
  static String get appName {
    final prodMode = dotenv.env['PROD_MODE']?.toLowerCase() == 'true';
    return prodMode ? 'Chillventory' : 'Testventory';
  }

  /// Get app identifier for User-Agent
  static String get appIdentifier {
    final prodMode = dotenv.env['PROD_MODE']?.toLowerCase() == 'true';
    return prodMode ? 'Chillventory' : 'Testventory';
  }

  /// Check if running in production mode
  static bool get isProduction {
    return dotenv.env['PROD_MODE']?.toLowerCase() == 'true';
  }

  /// Get environment display name
  static String get environmentName {
    return isProduction ? 'Production' : 'Development';
  }

  /// Get theme accent color based on environment
  static bool get useProductionTheme {
    return isProduction;
  }
}
