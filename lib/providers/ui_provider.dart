import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

final feedViewModeProvider = StateProvider<FeedViewMode>((ref) => FeedViewMode.reel);

enum FeedViewMode { reel, grid }

final searchQueryProvider = StateProvider<String>((ref) => '');

final isOpenNowFilterProvider = StateProvider<bool>((ref) => false);
