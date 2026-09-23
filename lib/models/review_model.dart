import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String facilityId;
  final String userId;
  final String userNickname;
  final String? userProfileImageUrl;
  final String userType; // 'local' or 'visitor'
  final int rating; // 1 ~ 5
  final String text;
  final List<String> imageUrls;
  final DateTime createdAt;
  final bool isVerified;
  final String status; // 'approved' or 'pending'（連投レート制限に触れた場合のみサーバー側でpendingへ）

  const ReviewModel({
    required this.id,
    required this.facilityId,
    required this.userId,
    required this.userNickname,
    this.userProfileImageUrl,
    required this.userType,
    required this.rating,
    required this.text,
    required this.imageUrls,
    required this.createdAt,
    this.isVerified = false,
    this.status = 'approved',
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      facilityId: data['facilityId'] as String,
      userId: data['userId'] as String,
      userNickname: data['userNickname'] as String,
      userProfileImageUrl: data['userProfileImageUrl'] as String?,
      userType: data['userType'] as String? ?? 'visitor',
      rating: data['rating'] as int,
      text: data['text'] as String,
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] as bool? ?? false,
      status: data['status'] as String? ?? 'approved',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'facilityId': facilityId,
        'userId': userId,
        'userNickname': userNickname,
        'userProfileImageUrl': userProfileImageUrl,
        'userType': userType,
        'rating': rating,
        'text': text,
        'imageUrls': imageUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'isVerified': isVerified,
        // 常に'approved'で作成し、即時公開のUXを維持する。連投レート制限に触れた場合のみ
        // Cloud Functions(Admin SDK)が事後的に'pending'へ差し戻す（firestore.rules参照）。
        'status': 'approved',
      };

  bool get isLocal => userType == 'local';
}
