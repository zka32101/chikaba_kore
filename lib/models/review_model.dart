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
      };

  bool get isLocal => userType == 'local';
}
