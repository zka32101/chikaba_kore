import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

final feedViewModeProvider = StateProvider<FeedViewMode>((ref) => FeedViewMode.reel);

enum FeedViewMode { reel, grid }

final searchQueryProvider = StateProvider<String>((ref) => '');

final isOpenNowFilterProvider = StateProvider<bool>((ref) => false);

/// 地図タブのモード（施設探索 / 安全ルート探索）。
/// `docs/PHASE3_MODE_INTEGRATION_DESIGN.md`の「地図タブ内でモード切替」方針に対応。
enum MapMode { facility, safetyRoute }

final mapModeProvider = StateProvider<MapMode>((ref) => MapMode.facility);
