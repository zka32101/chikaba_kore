import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_congestion_service.dart';
import '../models/congestion_report.dart';
import '../services/congestion_service.dart';
import 'firebase_provider.dart';

/// 施設の「今の混雑状況」投稿・取得。
final congestionServiceProvider = Provider<CongestionService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalCongestionService();
  return FirestoreCongestionService(FirebaseFirestore.instance, FirebaseFunctions.instance);
});

/// 指定した施設の直近の混雑状況。
final congestionStatusProvider =
    FutureProvider.autoDispose.family<CongestionStatus, String>((ref, facilityId) async {
  final service = ref.watch(congestionServiceProvider);
  return service.fetchStatus(facilityId);
});

/// 指定した施設の時間帯別混雑パターン（ヒートマップ表示用）。
final congestionHourlyPatternProvider =
    FutureProvider.autoDispose.family<CongestionHourlyPattern, String>((ref, facilityId) async {
  final service = ref.watch(congestionServiceProvider);
  return service.fetchHourlyPattern(facilityId);
});

/// 混雑状況の投稿操作。
class CongestionReportNotifier extends StateNotifier<AsyncValue<void>> {
  final CongestionService _service;
  final Ref _ref;
  CongestionReportNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<void> submitReport(String facilityId, CongestionLevel level) async {
    state = const AsyncValue.loading();
    try {
      await _service.submitReport(facilityId, level);
      _ref.invalidate(congestionStatusProvider(facilityId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final congestionReportNotifierProvider =
    StateNotifierProvider<CongestionReportNotifier, AsyncValue<void>>((ref) {
  return CongestionReportNotifier(ref.watch(congestionServiceProvider), ref);
});
