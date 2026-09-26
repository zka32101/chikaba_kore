import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_spot_comment_service.dart';
import '../services/spot_comment_service.dart';
import 'firebase_provider.dart';

/// 投稿に付随するコメント（「みんなの声」）の取得。
final spotCommentServiceProvider = Provider<SpotCommentService>((ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return LocalSpotCommentService();
  return FirestoreSpotCommentService(FirebaseFirestore.instance);
});
