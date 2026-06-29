import 'package:cloud_firestore/cloud_firestore.dart';

enum FavoriteStatus { wantToGo, willGo }

class FavoriteModel {
  final String id;
  final String facilityId;
  final String facilityName;
  final String? facilityThumbnailUrl;
  final String facilityCategory;
  final FavoriteStatus status;
  final DateTime savedAt;
  final String? memo;

  const FavoriteModel({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    this.facilityThumbnailUrl,
    required this.facilityCategory,
    required this.status,
    required this.savedAt,
    this.memo,
  });

  factory FavoriteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteModel(
      id: doc.id,
      facilityId: data['facilityId'] as String,
      facilityName: data['facilityName'] as String,
      facilityThumbnailUrl: data['facilityThumbnailUrl'] as String?,
      facilityCategory: data['facilityCategory'] as String? ?? 'service',
      status: (data['status'] as String?) == 'will_go'
          ? FavoriteStatus.willGo
          : FavoriteStatus.wantToGo,
      savedAt: (data['savedAt'] as Timestamp).toDate(),
      memo: data['memo'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'facilityId': facilityId,
        'facilityName': facilityName,
        'facilityThumbnailUrl': facilityThumbnailUrl,
        'facilityCategory': facilityCategory,
        'status': status == FavoriteStatus.willGo ? 'will_go' : 'want_to_go',
        'savedAt': Timestamp.fromDate(savedAt),
        'memo': memo,
      };

  FavoriteModel copyWith({FavoriteStatus? status, String? memo}) => FavoriteModel(
        id: id,
        facilityId: facilityId,
        facilityName: facilityName,
        facilityThumbnailUrl: facilityThumbnailUrl,
        facilityCategory: facilityCategory,
        status: status ?? this.status,
        savedAt: savedAt,
        memo: memo ?? this.memo,
      );
}
