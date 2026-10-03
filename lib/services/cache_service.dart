import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/recent_facility_entry.dart';
import '../utils/logger.dart';

class CacheService {
  static const String _facilityBox = 'facilities';
  static const String _userBox = 'user';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_facilityBox);
    await Hive.openBox(_userBox);
  }

  Box get _facilities => Hive.box(_facilityBox);
  Box get _user => Hive.box(_userBox);

  Future<void> cacheFacilities(String key, List<Map<String, dynamic>> data) async {
    await _facilities.put(key, jsonEncode(data));
  }

  List<Map<String, dynamic>>? getCachedFacilities(String key) {
    final raw = _facilities.get(key) as String?;
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      appLogger.w('Cache decode error', error: e);
      return null;
    }
  }

  Future<void> cacheUserData(Map<String, dynamic> data) async {
    await _user.put('current', jsonEncode(data));
  }

  Map<String, dynamic>? getCachedUserData() {
    final raw = _user.get('current') as String?;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ---- オンボーディング ----

  static const _kOnboardingSeen = 'onboarding_seen';

  /// オンボーディング完了フラグを保存
  Future<void> setOnboardingSeen() async {
    await _user.put(_kOnboardingSeen, true);
  }

  /// オンボーディングを表示済みかどうか
  bool get hasSeenOnboarding {
    return _user.get(_kOnboardingSeen, defaultValue: false) as bool;
  }

  // ---- 検索履歴 ----

  static const _kSearchHistory = 'search_history';
  static const _kMaxHistory = 10;

  /// 検索履歴に追加（重複排除・最大 10 件）
  Future<void> addSearchHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final current = searchHistory;
    final updated = [q, ...current.where((s) => s != q)].take(_kMaxHistory).toList();
    await _user.put(_kSearchHistory, jsonEncode(updated));
  }

  /// 検索履歴を取得（新しい順）
  List<String> get searchHistory {
    final raw = _user.get(_kSearchHistory) as String?;
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  /// 検索履歴を全消去
  Future<void> clearSearchHistory() async {
    await _user.delete(_kSearchHistory);
  }

  // ---- 最近見た施設 ----

  static const _kRecentFacilities = 'recent_facilities';
  static const _kMaxRecentFacilities = 10;

  /// 最近見た施設に追加（同一施設は先頭に移動・重複排除、最大 10 件）
  Future<void> addRecentFacility(RecentFacilityEntry entry) async {
    final current = recentFacilities;
    final updated = [entry, ...current.where((e) => e.id != entry.id)]
        .take(_kMaxRecentFacilities)
        .toList();
    await _user.put(
      _kRecentFacilities,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  /// 最近見た施設を取得（新しい順）
  List<RecentFacilityEntry> get recentFacilities {
    final raw = _user.get(_kRecentFacilities) as String?;
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(RecentFacilityEntry.fromJson)
          .toList();
    } catch (e) {
      appLogger.w('Recent facilities decode error', error: e);
      return const [];
    }
  }

  /// 最近見た施設の履歴を全消去
  Future<void> clearRecentFacilities() async {
    await _user.delete(_kRecentFacilities);
  }

  Future<void> clearUserCache() async {
    await _user.clear();
  }

  Future<void> clearAll() async {
    await _facilities.clear();
    await _user.clear();
  }
}
