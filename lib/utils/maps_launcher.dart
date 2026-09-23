import 'package:url_launcher/url_launcher.dart';

/// Google Maps への外部遷移URLを組み立てるヘルパー。
/// facility_detail_screen.dart / map_screen.dart で共用する。
class MapsLauncher {
  MapsLauncher._();

  /// 現在地から指定座標への経路をGoogle Mapsアプリ/Webで開く。
  static Future<void> openDirections(double latitude, double longitude) {
    return launchUrl(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  /// 住所検索結果をGoogle Mapsアプリ/Webで開く。
  static Future<void> openSearch(String address) {
    final query = Uri.encodeComponent(address);
    return launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }
}
