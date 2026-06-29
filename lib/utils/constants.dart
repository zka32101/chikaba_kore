import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = '近場コレ';
  static const String appVersion = '1.0.0';

  // タイムアウト
  static const int apiTimeoutSeconds = 10;
  static const int maxRetries = 3;

  // お気に入い制限（無料版）
  static const int freeFavoriteLimit = 100;

  // クチコミ表示（無料版）
  static const int freeReviewLimit = 10;

  // キャッシュ
  static const int imageCacheDays = 30;

  // 地図
  static const double defaultLatitude = 35.6812;
  static const double defaultLongitude = 139.7671;
  static const double defaultZoom = 14.0;

  // カテゴリ
  static const List<String> facilityCategories = [
    'dining',
    'cafe',
    'salon',
    'medical',
    'service',
    'event',
  ];

  // カテゴリ表示名
  static const Map<String, String> categoryNames = {
    'dining': '飲食',
    'cafe': 'カフェ',
    'salon': 'サロン',
    'medical': '医療',
    'service': 'サービス',
    'event': 'イベント',
  };

  // カテゴリアイコン
  static const Map<String, IconData> categoryIcons = {
    'dining': Icons.restaurant,
    'cafe': Icons.local_cafe,
    'salon': Icons.content_cut,
    'medical': Icons.local_hospital,
    'service': Icons.store,
    'event': Icons.event,
  };

  // 対応エリア（selectedCity）
  static const List<String> cities = [
    '東京23区',
    '横浜市',
    '大阪市',
    '名古屋市',
    '福岡市',
    '札幌市',
    '仙台市',
    '広島市',
    '京都市',
    '神戸市',
    '川崎市',
    'さいたま市',
    '千葉市',
    '静岡市',
    '浜松市',
    '岡山市',
    '熊本市',
  ];

  // 外部リンク
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';

  // エラーメッセージ
  static const String networkError = 'ネットワークに接続できません。接続を確認してください。';
  static const String serverError = 'サーバーエラーが発生しました。しばらくしてから再度お試しください。';
  static const String unknownError = '予期しないエラーが発生しました。';
  static const String authError = '認証に失敗しました。再度ログインしてください。';
}
