import 'dart:math';
import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toJapaneseDate() => DateFormat('yyyy年M月d日').format(this);
  String toJapaneseDateTime() => DateFormat('yyyy年M月d日 HH:mm').format(this);
  String toRelativeTime() {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 30) return '${diff.inDays}日前';
    return toJapaneseDate();
  }
}

extension StringExtension on String {
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(this);
  bool get isValidPassword => length >= 6;
  bool get isValidNickname => length >= 2 && length <= 20;
}

extension DoubleExtension on double {
  String toRatingString() => toStringAsFixed(1);
}

/// 2点間のハーバーサイン距離（km）
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0; // 地球半径 km
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// km を表示文字列に変換（999m 未満は m 表示）
String formatDistance(double km) {
  if (km < 1.0) return '${(km * 1000).round()}m';
  if (km < 10.0) return '${km.toStringAsFixed(1)}km';
  return '${km.round()}km';
}
