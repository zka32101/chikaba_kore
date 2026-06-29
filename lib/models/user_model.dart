import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nickname;
  final String? profileImageUrl;
  final String userType; // 'local' or 'visitor'
  final String selectedCity;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.nickname,
    this.profileImageUrl,
    required this.userType,
    required this.selectedCity,
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nickname: data['nickname'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      userType: data['userType'] as String? ?? 'visitor',
      selectedCity: data['selectedCity'] as String? ?? '東京23区',
      isPremium: data['isPremium'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
        'userType': userType,
        'selectedCity': selectedCity,
        'isPremium': isPremium,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  UserModel copyWith({
    String? nickname,
    String? profileImageUrl,
    String? userType,
    String? selectedCity,
    bool? isPremium,
    DateTime? updatedAt,
  }) =>
      UserModel(
        uid: uid,
        nickname: nickname ?? this.nickname,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        userType: userType ?? this.userType,
        selectedCity: selectedCity ?? this.selectedCity,
        isPremium: isPremium ?? this.isPremium,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
