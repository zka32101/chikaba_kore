import 'package:flutter/material.dart';

/// 施設の営業時間（`FacilityModel.businessHours`の1曜日分）をパースした結果。
class BusinessHoursRange {
  final TimeOfDay open;
  final TimeOfDay close;
  const BusinessHoursRange({required this.open, required this.close});
}

/// `"09:00-18:00"`形式の営業時間文字列をパースする。「定休日」等の非時刻文字列や
/// 不正な値（24時間形式を超える時・分）の場合はnullを返す。
BusinessHoursRange? parseBusinessHoursRange(String value) {
  final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$').firstMatch(value);
  if (match == null) return null;

  final openHour = int.parse(match.group(1)!);
  final openMinute = int.parse(match.group(2)!);
  final closeHour = int.parse(match.group(3)!);
  final closeMinute = int.parse(match.group(4)!);
  if (openHour > 23 || closeHour > 23 || openMinute > 59 || closeMinute > 59) return null;

  return BusinessHoursRange(
    open: TimeOfDay(hour: openHour, minute: openMinute),
    close: TimeOfDay(hour: closeHour, minute: closeMinute),
  );
}
