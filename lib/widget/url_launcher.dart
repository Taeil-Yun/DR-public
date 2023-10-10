import 'package:url_launcher/url_launcher.dart';

class UrlLauncherBuilder {
  launchURL(String uri) async {
    try {
      await launchUrl(
        Uri.parse(uri),
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
      );
    } catch (e) {
      throw 'Could not launch $uri';
    }
  }
}
