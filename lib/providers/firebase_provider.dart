import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebaseが実際に初期化されているかどうか。`main.dart`のFirebase初期化結果で
/// overrideされる。あんしんみち（project-039）由来のサービス群（経路探索・投稿等）が、
/// Firebase実装とLocal実装のどちらを使うか判定するために使う
/// （`docs/PHASE3_MODE_INTEGRATION_DESIGN.md`参照）。
final firebaseAvailableProvider = Provider<bool>((ref) => false);
