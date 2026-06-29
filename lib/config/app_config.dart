import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get revenueCatApiKey => dotenv.env['REVENUECAT_API_KEY'] ?? '';
  static String get admobAppId => dotenv.env['ADMOB_APP_ID'] ?? '';
  static String get admobBannerAdUnitId => dotenv.env['ADMOB_BANNER_AD_UNIT_ID'] ?? '';
  static String get admobInterstitialAdUnitId => dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID'] ?? '';
}
