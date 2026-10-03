import 'package:cloud_firestore/cloud_firestore.dart';

/// クチコミへの返信（リプライ）。`reviews/{reviewId}/replies`サブコレクションに
/// 保存する。ログイン済みの全ユーザーが投稿できるスレッド形式。
class ReviewReply {
  final String id;
  final String reviewId;
  final String userId;
  final String userNickname;
  final String? userProfileImageUrl;
  final String text;
  final DateTime createdAt;

  const ReviewReply({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.userNickname,
    this.userProfileImageUrl,
    required this.text,
    required this.createdAt,
  });

  factory ReviewReply.fromFirestore(String reviewId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewReply(
      id: doc.id,
      reviewId: reviewId,
      userId: data['userId'] as String,
      userNickname: data['userNickname'] as String,
      userProfileImageUrl: data['userProfileImageUrl'] as String?,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userNickname': userNickname,
        'userProfileImageUrl': userProfileImageUrl,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
