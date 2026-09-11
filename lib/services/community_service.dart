import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';
import '../utils/logger.dart';

/// Community features service (Q&A, user reputation, following)
class CommunityService {
  static final CommunityService _instance = CommunityService._();
  factory CommunityService() => _instance;
  CommunityService._();

  final _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _questionsCollection = 'community_questions';
  static const String _answersCollection = 'community_answers';
  static const String _reputationCollection = 'user_reputation';
  static const String _followingCollection = 'user_following';
  static const String _feedCollection = 'community_feed';
  static const String _statsCollection = 'community_stats';

  // Reputation calculation constants
  static const double _reviewWeight = 0.3;
  static const double _answerWeight = 0.3;
  static const double _contributionWeight = 0.4;
  static const int _localExpertThreshold = 50; // 50 reviews

  /// Post a community question
  Future<String> postQuestion({
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String city,
    required String question,
    required String category,
    List<String> tags = const [],
    GeoPoint? location,
  }) async {
    try {
      final questionDoc = _firestore.collection(_questionsCollection).doc();
      final now = DateTime.now();

      final communityQuestion = CommunityQuestion(
        id: questionDoc.id,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        city: city,
        location: location,
        question: question,
        category: category,
        tags: tags,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)), // 7-day expiry
      );

      await questionDoc.set(communityQuestion.toFirestore());

      // Update city stats
      await _updateCityStats(city);

      // Create feed item
      await _createFeedItem(
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        type: 'question_asked',
        title: 'ローカルQ&Aに質問を投稿',
        description: question,
        questionId: questionDoc.id,
      );

      appLogger.d('Question posted: $city by $userId');
      return questionDoc.id;
    } catch (e) {
      appLogger.e('Error posting question', error: e);
      rethrow;
    }
  }

  /// Answer a community question
  Future<String> answerQuestion({
    required String questionId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String answer,
    List<String> images = const [],
  }) async {
    try {
      // Get question to get user review count
      final questionDoc = await _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .get();

      if (!questionDoc.exists) {
        throw Exception('Question not found');
      }

      final question = CommunityQuestion.fromFirestore(questionDoc);
      final userReview = await _getUserReviewCount(userId);
      final isLocalExpert = userReview >= _localExpertThreshold;

      final answerDoc = _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .collection(_answersCollection)
          .doc();

      final communityAnswer = CommunityAnswer(
        id: answerDoc.id,
        questionId: questionId,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        userReviewCount: userReview,
        isLocalExpert: isLocalExpert,
        answer: answer,
        images: images,
        createdAt: DateTime.now(),
      );

      await answerDoc.set(communityAnswer.toFirestore());

      // Update question answer count
      await questionDoc.reference.update({
        'answerCount': FieldValue.increment(1),
      });

      // Update user reputation
      await _updateUserReputation(userId, questionAnswered: true);

      // Create feed item
      await _createFeedItem(
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        type: 'answer_given',
        title: 'ローカルQ&Aで回答を投稿',
        description: answer.substring(0, Math.min(100, answer.length)),
        questionId: questionId,
        answerId: answerDoc.id,
      );

      appLogger.d('Answer posted to question: $questionId by $userId');
      return answerDoc.id;
    } catch (e) {
      appLogger.e('Error posting answer', error: e);
      rethrow;
    }
  }

  /// Get questions for a city
  Future<List<CommunityQuestion>> getQuestions(
    String city, {
    int limit = 20,
    String? category,
    bool? isAnswered,
  }) async {
    try {
      var query = _firestore
          .collection(_questionsCollection)
          .where('city', isEqualTo: city)
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category)
            as Query<Map<String, dynamic>>;
      }

      if (isAnswered != null) {
        query = query.where('isAnswered', isEqualTo: isAnswered)
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CommunityQuestion.fromFirestore(doc))
          .toList();
    } catch (e) {
      appLogger.e('Error fetching questions', error: e);
      rethrow;
    }
  }

  /// Stream questions for a city
  Stream<List<CommunityQuestion>> streamQuestions(String city) {
    return _firestore
        .collection(_questionsCollection)
        .where('city', isEqualTo: city)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => CommunityQuestion.fromFirestore(doc))
                .toList());
  }

  /// Get answers for a question
  Future<List<CommunityAnswer>> getAnswers(String questionId) async {
    try {
      final snapshot = await _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .collection(_answersCollection)
          .orderBy('upvotes', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CommunityAnswer.fromFirestore(doc))
          .toList();
    } catch (e) {
      appLogger.e('Error fetching answers', error: e);
      rethrow;
    }
  }

  /// Upvote an answer
  Future<void> upvoteAnswer(String questionId, String answerId) async {
    try {
      await _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .collection(_answersCollection)
          .doc(answerId)
          .update({
            'upvotes': FieldValue.increment(1),
          });

      // Update answer author's reputation
      final answerDoc = await _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .collection(_answersCollection)
          .doc(answerId)
          .get();

      if (answerDoc.exists) {
        final answer = CommunityAnswer.fromFirestore(answerDoc);
        await _updateUserReputation(answer.userId, helpfulAnswer: true);
      }
    } catch (e) {
      appLogger.e('Error upvoting answer', error: e);
      rethrow;
    }
  }

  /// Mark answer as accepted (by question author)
  Future<void> acceptAnswer(
    String questionId,
    String answerId,
    String userId,
  ) async {
    try {
      // Verify user is question author
      final questionDoc = await _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .get();

      final question = CommunityQuestion.fromFirestore(questionDoc);
      if (question.userId != userId) {
        throw Exception('Only question author can accept answers');
      }

      await _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .collection(_answersCollection)
          .doc(answerId)
          .update({'isAccepted': true});

      // Mark question as answered
      await questionDoc.reference.update({'isAnswered': true});

      // Grant bonus reputation to answer author
      final answerDoc = await _firestore
          .collection(_questionsCollection)
          .doc(questionId)
          .collection(_answersCollection)
          .doc(answerId)
          .get();

      if (answerDoc.exists) {
        final answer = CommunityAnswer.fromFirestore(answerDoc);
        await _updateUserReputation(answer.userId, acceptedAnswer: true);
      }
    } catch (e) {
      appLogger.e('Error accepting answer', error: e);
      rethrow;
    }
  }

  /// Follow a user
  Future<void> followUser(
    String followerId,
    String followingId,
  ) async {
    try {
      if (followerId == followingId) {
        throw Exception('Cannot follow yourself');
      }

      final followingDoc = _firestore.collection(_followingCollection).doc();

      await followingDoc.set(UserFollowing(
        id: followingDoc.id,
        followerId: followerId,
        followingId: followingId,
        createdAt: DateTime.now(),
      ).toFirestore());

      // Update follower/following counts
      await _firestore
          .collection(_reputationCollection)
          .doc(followerId)
          .update({
            'followingCount': FieldValue.increment(1),
          });

      await _firestore
          .collection(_reputationCollection)
          .doc(followingId)
          .update({
            'followerCount': FieldValue.increment(1),
          });

      appLogger.d('$followerId started following $followingId');
    } catch (e) {
      appLogger.e('Error following user', error: e);
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(
    String followerId,
    String followingId,
  ) async {
    try {
      await _firestore
          .collection(_followingCollection)
          .where('followerId', isEqualTo: followerId)
          .where('followingId', isEqualTo: followingId)
          .get()
          .then((snapshot) {
            for (final doc in snapshot.docs) {
              doc.reference.delete();
            }
          });

      // Update counts
      await _firestore
          .collection(_reputationCollection)
          .doc(followerId)
          .update({
            'followingCount': FieldValue.increment(-1),
          });

      await _firestore
          .collection(_reputationCollection)
          .doc(followingId)
          .update({
            'followerCount': FieldValue.increment(-1),
          });

      appLogger.d('$followerId unfollowed $followingId');
    } catch (e) {
      appLogger.e('Error unfollowing user', error: e);
      rethrow;
    }
  }

  /// Get user reputation
  Future<UserReputation> getUserReputation(String userId) async {
    try {
      final doc = await _firestore
          .collection(_reputationCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return UserReputation(
          userId: userId,
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        );
      }

      return UserReputation.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching user reputation', error: e);
      rethrow;
    }
  }

  /// Stream user reputation
  Stream<UserReputation> streamUserReputation(String userId) {
    return _firestore
        .collection(_reputationCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return UserReputation(
              userId: userId,
              createdAt: DateTime.now(),
              lastUpdatedAt: DateTime.now(),
            );
          }
          return UserReputation.fromFirestore(doc);
        });
  }

  /// Get top contributors for a city
  Future<List<UserReputation>> getTopContributors(
    String city, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reputationCollection)
          .orderBy('trustScore', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserReputation.fromFirestore(doc))
          .toList();
    } catch (e) {
      appLogger.e('Error fetching top contributors', error: e);
      rethrow;
    }
  }

  /// Get community feed
  Future<List<CommunityFeedItem>> getCommunityFeed(
    String userId, {
    int limit = 50,
  }) async {
    try {
      // Get users that current user is following
      final followingSnapshot = await _firestore
          .collection(_followingCollection)
          .where('followerId', isEqualTo: userId)
          .get();

      final followingIds = followingSnapshot.docs
          .map((doc) => (doc.data()['followingId'] as String))
          .toList();

      if (followingIds.isEmpty) {
        return [];
      }

      final feedSnapshot = await _firestore
          .collection(_feedCollection)
          .where('userId', whereIn: followingIds)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return feedSnapshot.docs
          .map((doc) => CommunityFeedItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      appLogger.e('Error fetching community feed', error: e);
      rethrow;
    }
  }

  /// Get community stats for a city
  Future<CommunityStats> getCommunityStats(String city) async {
    try {
      final doc = await _firestore
          .collection(_statsCollection)
          .doc(city)
          .get();

      if (!doc.exists) {
        return CommunityStats(
          city: city,
          lastUpdatedAt: DateTime.now(),
        );
      }

      return CommunityStats.fromFirestore(doc);
    } catch (e) {
      appLogger.e('Error fetching community stats', error: e);
      rethrow;
    }
  }

  // ============ Private Helper Methods ============

  /// Update user reputation (called after reviews, answers, etc.)
  Future<void> _updateUserReputation(
    String userId, {
    bool questionAnswered = false,
    bool helpfulAnswer = false,
    bool acceptedAnswer = false,
  }) async {
    try {
      final reputation = await getUserReputation(userId);
      var newContribution = reputation.communityContribution;
      var newHelpful = reputation.helpfulAnswers;

      if (questionAnswered) newContribution += 1;
      if (helpfulAnswer) {
        newHelpful += 1;
        newContribution += 1;
      }
      if (acceptedAnswer) {
        newHelpful += 2; // Bonus for accepted
        newContribution += 5;
      }

      // Calculate trust score
      final trustScore = _calculateTrustScore(
        reputation.reviewCount,
        newHelpful,
        newContribution,
      );

      // Determine if local expert
      final isLocalExpert = reputation.reviewCount >= _localExpertThreshold;

      await _firestore
          .collection(_reputationCollection)
          .doc(userId)
          .set({
            'helpfulAnswers': newHelpful,
            'communityContribution': newContribution,
            'trustScore': trustScore,
            'isLocalExpert': isLocalExpert,
            'lastUpdatedAt': Timestamp.now(),
          }, SetOptions(merge: true));
    } catch (e) {
      appLogger.e('Error updating user reputation', error: e);
    }
  }

  /// Calculate trust score (0.0 - 1.0)
  double _calculateTrustScore(
    int reviewCount,
    int helpfulAnswers,
    int communityContribution,
  ) {
    final reviewScore = (reviewCount / 100).clamp(0.0, 1.0) * _reviewWeight;
    final answerScore = (helpfulAnswers / 50).clamp(0.0, 1.0) * _answerWeight;
    final contributionScore =
        (communityContribution / 100).clamp(0.0, 1.0) * _contributionWeight;

    return reviewScore + answerScore + contributionScore;
  }

  /// Get user's review count (for credibility)
  Future<int> _getUserReviewCount(String userId) async {
    try {
      final rep = await getUserReputation(userId);
      return rep.reviewCount;
    } catch (e) {
      appLogger.e('Error getting user review count', error: e);
      return 0;
    }
  }

  /// Create community feed item
  Future<void> _createFeedItem({
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String type,
    required String title,
    required String description,
    String? facilityId,
    String? questionId,
    String? answerId,
  }) async {
    try {
      final feedDoc = _firestore.collection(_feedCollection).doc();

      final feedItem = CommunityFeedItem(
        id: feedDoc.id,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        type: type,
        title: title,
        description: description,
        facilityId: facilityId,
        questionId: questionId,
        answerId: answerId,
        createdAt: DateTime.now(),
      );

      await feedDoc.set(feedItem.toFirestore());
    } catch (e) {
      appLogger.e('Error creating feed item', error: e);
    }
  }

  /// Update city statistics
  Future<void> _updateCityStats(String city) async {
    try {
      final questionCount = await _firestore
          .collection(_questionsCollection)
          .where('city', isEqualTo: city)
          .count()
          .get();

      await _firestore.collection(_statsCollection).doc(city).set({
        'totalQuestions': questionCount.count ?? 0,
        'lastUpdatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      appLogger.e('Error updating city stats', error: e);
    }
  }
}

// Math helper
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
