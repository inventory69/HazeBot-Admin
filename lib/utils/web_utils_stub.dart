// Stub implementation for non-web platforms (Android, iOS, etc.)

class WebUtils {
  static String getCurrentUrl() {
    // On non-web platforms, return empty string
    return '';
  }

  static void replaceUrl(String newUrl) {
    // No-op on non-web platforms
  }

  static void navigateToUrl(String url) {
    // No-op on non-web platforms
    // OAuth on mobile is handled via deep links
  }

  static void openInNewTab(String url) {
    // No-op on non-web platforms
    // Could use url_launcher package for mobile
  }
}
