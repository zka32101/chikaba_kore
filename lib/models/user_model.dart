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
  final int reviewCount; // クチコミ投稿の累計数。Cloud Functionsのみ更新
  final int visitCount; // 「訪問」実績の累計数（クチコミ投稿+お気に入り「行ってきた」）。Cloud Functionsのみ更新

  const UserModel({
    required this.uid,
    required this.nickname,
    this.profileImageUrl,
    required this.userType,
    required this.selectedCity,
    this.isPremium = false,
    required this.createdAt,
    required this.updatedAt,
    this.reviewCount = 0,
    this.visitCount = 0,
  });

  /// 訪問実績バッジの段階定義（閾値が高い順）
  static const _visitBadgeTiers = <(int threshold, String label)>[
    (30, '近場レジェンド'),
    (15, '地元マスター'),
    (5, 'ご近所探検家'),
    (1, 'はじめての一歩'),
  ];

  /// 現在の訪問実績バッジ。該当なしの場合はnull
  String? get visitBadgeLabel {
    for (final tier in _visitBadgeTiers) {
      if (visitCount >= tier.$1) return tier.$2;
    }
    return null;
  }

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
      reviewCount: data['reviewCount'] as int? ?? 0,
      visitCount: data['visitCount'] as int? ?? 0,
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
        'reviewCount': reviewCount,
        'visitCount': visitCount,
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
        reviewCount: reviewCount,
        visitCount: visitCount,
      );
}
