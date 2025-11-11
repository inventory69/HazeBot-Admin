// Web implementation using dart:html
import 'dart:html' as html;

class WebUtils {
  static String getCurrentUrl() {
    return html.window.location.href;
  }

  static void replaceUrl(String newUrl) {
    html.window.history.replaceState(null, '', newUrl);
  }

  static void navigateToUrl(String url) {
    html.window.location.href = url;
  }

  static void openInNewTab(String url) {
    html.window.open(url, '_blank');
  }
}
