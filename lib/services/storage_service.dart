import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// プロフィール画像をアップロードしてダウンロード URL を返す
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('profiles')
          .child(userId)
          .child('avatar.jpg');
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      appLogger.e('uploadProfileImage error', error: e);
      rethrow;
    }
  }

  /// レビュー画像を Firebase Storage にアップロードし、ダウンロード URL を返す
  Future<String> uploadReviewImage({
    required String facilityId,
    required String userId,
    required File file,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('reviews')
          .child(facilityId)
          .child(userId)
          .child(fileName);
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      appLogger.e('uploadReviewImage error', error: e);
      rethrow;
    }
  }
}
