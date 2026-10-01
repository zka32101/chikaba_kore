import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_announcement_service.dart';
import '../services/announcement_service.dart';
import 'firebase_provider.dart';

/// お知らせ一覧（あんしんみち由来、`docs/PHASE3_MODE_INTEGRATION_DESIGN.md`参照）で使用。
final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalAnnouncementService();
  return FirestoreAnnouncementService(FirebaseFirestore.instance);
});
