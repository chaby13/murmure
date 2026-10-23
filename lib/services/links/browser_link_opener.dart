import 'package:url_launcher/url_launcher.dart';

import '../../domain/services/link_opener.dart';

/// Confie le lien au navigateur : c'est lui qui se connecte, pas Murmure.
class BrowserLinkOpener implements LinkOpener {
  const BrowserLinkOpener();

  @override
  Future<bool> open(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
