import 'package:cloud_firestore/cloud_firestore.dart';

/// 共有リストに含まれる施設1件分のスナップショット。受信側が追加のFirestore読み取り無しで
/// 一覧表示できるよう、`FavoriteModel`と同じ考え方で施設情報を埋め込んでおく。
class SharedListItem {
  const SharedListItem({
    required this.facilityId,
    required this.facilityName,
    this.facilityThumbnailUrl,
    required this.facilityCategory,
  });

  final String facilityId;
  final String facilityName;
  final String? facilityThumbnailUrl;
  final String facilityCategory;

  factory SharedListItem.fromMap(Map<String, dynamic> data) => SharedListItem(
        facilityId: data['facilityId'] as String,
        facilityName: data['facilityName'] as String,
        facilityThumbnailUrl: data['facilityThumbnailUrl'] as String?,
        facilityCategory: data['facilityCategory'] as String? ?? 'service',
      );

  Map<String, dynamic> toMap() => {
        'facilityId': facilityId,
        'facilityName': facilityName,
        'facilityThumbnailUrl': facilityThumbnailUrl,
        'facilityCategory': facilityCategory,
      };
}

/// お気に入り（「行きたい」リスト）を他ユーザーへ共有するためのスナップショット。
/// 作成後は不変（お気に入りを更新しても共有済みリストには反映されない）。
class SharedList {
  const SharedList({
    required this.id,
    required this.ownerNickname,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final String ownerNickname;
  final List<SharedListItem> items;
  final DateTime createdAt;

  factory SharedList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedList(
      id: doc.id,
      ownerNickname: data['ownerNickname'] as String? ?? '近場まっぷユーザー',
      items: (data['items'] as List? ?? [])
          .map((e) => SharedListItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
