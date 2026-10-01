import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_model.dart';
import '../models/shared_list.dart';
import '../services/shared_list_service.dart';

/// Firestoreの`sharedLists`コレクションを使った実装。共有コードはドキュメントの自動生成ID
/// をそのまま使う（コピー&ペーストでの共有を前提とし、短縮は行わない）。
class FirestoreSharedListService implements SharedListService {
  FirestoreSharedListService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<String> createSharedList(String ownerNickname, List<FavoriteModel> favorites) async {
    final items = favorites
        .map((f) => SharedListItem(
              facilityId: f.facilityId,
              facilityName: f.facilityName,
              facilityThumbnailUrl: f.facilityThumbnailUrl,
              facilityCategory: f.facilityCategory,
            ).toMap())
        .toList();

    final doc = await _firestore.collection('sharedLists').add({
      'ownerNickname': ownerNickname,
      'items': items,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  @override
  Future<SharedList?> fetchSharedList(String shareCode) async {
    final doc = await _firestore.collection('sharedLists').doc(shareCode).get();
    if (!doc.exists) return null;
    return SharedList.fromFirestore(doc);
  }
}
