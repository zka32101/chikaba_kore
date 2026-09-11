import 'package:cloud_firestore/cloud_firestore.dart';

/// Community question for local Q&A
class CommunityQuestion {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String city;
  final GeoPoint? location;
  final String question;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isAnswered;
  final int answerCount;
  final int viewCount;
  final String status; // open, closed, archived

  const CommunityQuestion({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.city,
    this.location,
    required this.question,
    required this.category,
    this.tags = const [],
    required this.createdAt,
    required this.expiresAt,
    this.isAnswered = false,
    this.answerCount = 0,
    this.viewCount = 0,
    this.status = 'open',
  });

  factory CommunityQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityQuestion(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? 'Unknown',
      userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
      city: data['city'] as String,
      location: data['location'] as GeoPoint?,
      question: data['question'] as String,
      category: data['category'] as String? ?? 'general',
      tags: List<String>.from(data['tags'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isAnswered: data['isAnswered'] as bool? ?? false,
      answerCount: data['answerCount'] as int? ?? 0,
      viewCount: data['viewCount'] as int? ?? 0,
      status: data['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'city': city,
    'location': location,
    'question': question,
    'category': category,
    'tags': tags,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'isAnswered': isAnswered,
    'answerCount': answerCount,
    'viewCount': viewCount,
    'status': status,
  };
}

/// Answer to community question
class CommunityAnswer {
  final String id;
  final String questionId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final int userReviewCount;  // Local credibility indicator
  final bool isLocalExpert;   // User reputation badge
  final String answer;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int upvotes;
  final int downvotes;
  final bool isAccepted;

  const CommunityAnswer({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    this.userReviewCount = 0,
    this.isLocalExpert = false,
    required this.answer,
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isAccepted = false,
  });

  factory CommunityAnswer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityAnswer(
      id: doc.id,
      questionId: data['questionId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? 'Unknown',
      userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
      userReviewCount: data['userReviewCount'] as int? ?? 0,
      isLocalExpert: data['isLocalExpert'] as bool? ?? false,
      answer: data['answer'] as String,
      images: List<String>.from(data['images'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      upvotes: data['upvotes'] as int? ?? 0,
      downvotes: data['downvotes'] as int? ?? 0,
      isAccepted: data['isAccepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'questionId': questionId,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'userReviewCount': userReviewCount,
    'isLocalExpert': isLocalExpert,
    'answer': answer,
    'images': images,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'upvotes': upvotes,
    'downvotes': downvotes,
    'isAccepted': isAccepted,
  };
}

/// User reputation and trust score
class UserReputation {
  final String userId;
  final int reviewCount;
  final int helpfulAnswers;
  final int communityContribution; // QA answers + upvotes
  final double trustScore;         // 0.0 - 1.0
  final bool isLocalExpert;
  final List<String> badges;       // Verified Local, Trusted Reviewer, etc.
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  const UserReputation({
    required this.userId,
    this.reviewCount = 0,
    this.helpfulAnswers = 0,
    this.communityContribution = 0,
    this.trustScore = 0.0,
    this.isLocalExpert = false,
    this.badges = const [],
    this.followerCount = 0,
    this.followingCount = 0,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  factory UserReputation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReputation(
      userId: doc.id,
      reviewCount: data['reviewCount'] as int? ?? 0,
      helpfulAnswers: data['helpfulAnswers'] as int? ?? 0,
      communityContribution: data['communityContribution'] as int? ?? 0,
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 0.0,
      isLocalExpert: data['isLocalExpert'] as bool? ?? false,
      badges: List<String>.from(data['badges'] as List? ?? []),
      followerCount: data['followerCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'reviewCount': reviewCount,
    'helpfulAnswers': helpfulAnswers,
    'communityContribution': communityContribution,
    'trustScore': trustScore,
    'isLocalExpert': isLocalExpert,
    'badges': badges,
    'followerCount': followerCount,
    'followingCount': followingCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
  };
}

/// User following relationship
class UserFollowing {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;
  final bool isBlocked;

  const UserFollowing({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.isBlocked = false,
  });

  factory UserFollowing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserFollowing(
      id: doc.id,
      followerId: data['followerId'] as String,
      followingId: data['followingId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isBlocked: data['isBlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'followerId': followerId,
    'followingId': followingId,
    'createdAt': Timestamp.fromDate(createdAt),
    'isBlocked': isBlocked,
  };
}

/// Community activity feed item
class CommunityFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String type;  // question_asked, answer_given, review_posted, user_followed
  final String title;
  final String description;
  final String? facilityId;
  final String? questionId;
  final String? answerId;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByCurrentUser;

  const CommunityFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.type,
    required this.title,
    required this.description,
    this.facilityId,
    this.questionId,
    this.answerId,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByCurrentUser = false,
  });

  factory CommunityFeedItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityFeedItem(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? 'Unknown',
      userAvatarUrl: data['userAvatarUrl'] as String? ?? '',
      type: data['type'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      facilityId: data['facilityId'] as String?,
      questionId: data['questionId'] as String?,
      answerId: data['answerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likeCount: data['likeCount'] as int? ?? 0,
      isLikedByCurrentUser: data['isLikedByCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'type': type,
    'title': title,
    'description': description,
    'facilityId': facilityId,
    'questionId': questionId,
    'answerId': answerId,
    'createdAt': Timestamp.fromDate(createdAt),
    'likeCount': likeCount,
    'isLikedByCurrentUser': isLikedByCurrentUser,
  };
}

/// Community statistics
class CommunityStats {
  final String city;
  final int totalQuestions;
  final int totalAnswers;
  final int topContributorsCount;
  final int activeUsersThisMonth;
  final List<String> topTags;
  final Map<String, int> questionsByCategory;
  final DateTime lastUpdatedAt;

  const CommunityStats({
    required this.city,
    this.totalQuestions = 0,
    this.totalAnswers = 0,
    this.topContributorsCount = 0,
    this.activeUsersThisMonth = 0,
    this.topTags = const [],
    this.questionsByCategory = const {},
    required this.lastUpdatedAt,
  });

  factory CommunityStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityStats(
      city: doc.id,
      totalQuestions: data['totalQuestions'] as int? ?? 0,
      totalAnswers: data['totalAnswers'] as int? ?? 0,
      topContributorsCount: data['topContributorsCount'] as int? ?? 0,
      activeUsersThisMonth: data['activeUsersThisMonth'] as int? ?? 0,
      topTags: List<String>.from(data['topTags'] as List? ?? []),
      questionsByCategory:
          Map<String, int>.from(data['questionsByCategory'] as Map? ?? {}),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'totalQuestions': totalQuestions,
    'totalAnswers': totalAnswers,
    'topContributorsCount': topContributorsCount,
    'activeUsersThisMonth': activeUsersThisMonth,
    'topTags': topTags,
    'questionsByCategory': questionsByCategory,
    'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
  };
}
