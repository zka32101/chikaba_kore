import 'package:riverpod/riverpod.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

/// Community service provider
final communityServiceProvider = Provider((ref) {
  return CommunityService();
});

/// Get questions for a city
final communityQuestionsProvider =
    FutureProvider.autoDispose
        .family<List<CommunityQuestion>, (String city, {String? category})>(
          (ref, params) async {
            final service = ref.watch(communityServiceProvider);
            return service.getQuestions(
              params.city,
              category: params.category,
            );
          },
        );

/// Stream questions for a city
final communityQuestionsStreamProvider =
    StreamProvider.autoDispose.family<List<CommunityQuestion>, String>(
      (ref, city) {
        final service = ref.watch(communityServiceProvider);
        return service.streamQuestions(city);
      },
    );

/// Get answers for a question
final communityAnswersProvider =
    FutureProvider.autoDispose.family<List<CommunityAnswer>, String>(
      (ref, questionId) async {
        final service = ref.watch(communityServiceProvider);
        return service.getAnswers(questionId);
      },
    );

/// Get user reputation
final userReputationProvider =
    FutureProvider.autoDispose.family<UserReputation, String>(
      (ref, userId) async {
        final service = ref.watch(communityServiceProvider);
        return service.getUserReputation(userId);
      },
    );

/// Stream user reputation
final userReputationStreamProvider =
    StreamProvider.autoDispose.family<UserReputation, String>(
      (ref, userId) {
        final service = ref.watch(communityServiceProvider);
        return service.streamUserReputation(userId);
      },
    );

/// Get top contributors for a city
final topContributorsProvider =
    FutureProvider.autoDispose.family<List<UserReputation>, String>(
      (ref, city) async {
        final service = ref.watch(communityServiceProvider);
        return service.getTopContributors(city);
      },
    );

/// Get community feed
final communityFeedProvider =
    FutureProvider.autoDispose.family<List<CommunityFeedItem>, String>(
      (ref, userId) async {
        final service = ref.watch(communityServiceProvider);
        return service.getCommunityFeed(userId);
      },
    );

/// Get community stats for a city
final communityStatsProvider =
    FutureProvider.autoDispose.family<CommunityStats, String>(
      (ref, city) async {
        final service = ref.watch(communityServiceProvider);
        return service.getCommunityStats(city);
      },
    );

/// Post question notifier
class PostQuestionNotifier extends StateNotifier<AsyncValue<String>> {
  PostQuestionNotifier(this._service) : super(const AsyncValue.data(''));

  final CommunityService _service;

  Future<void> postQuestion({
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String city,
    required String question,
    required String category,
    List<String> tags = const [],
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.postQuestion(
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        city: city,
        question: question,
        category: category,
        tags: tags,
      ),
    );
  }
}

/// Post question provider
final postQuestionProvider =
    StateNotifierProvider.autoDispose<PostQuestionNotifier, AsyncValue<String>>(
      (ref) {
        final service = ref.watch(communityServiceProvider);
        return PostQuestionNotifier(service);
      },
    );

/// Answer question notifier
class AnswerQuestionNotifier extends StateNotifier<AsyncValue<String>> {
  AnswerQuestionNotifier(this._service) : super(const AsyncValue.data(''));

  final CommunityService _service;

  Future<void> answerQuestion({
    required String questionId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String answer,
    List<String> images = const [],
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.answerQuestion(
        questionId: questionId,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        answer: answer,
        images: images,
      ),
    );
  }
}

/// Answer question provider
final answerQuestionProvider =
    StateNotifierProvider.autoDispose<AnswerQuestionNotifier, AsyncValue<String>>(
      (ref) {
        final service = ref.watch(communityServiceProvider);
        return AnswerQuestionNotifier(service);
      },
    );

/// Accept answer notifier
class AcceptAnswerNotifier extends StateNotifier<AsyncValue<void>> {
  AcceptAnswerNotifier(this._service) : super(const AsyncValue.data(null));

  final CommunityService _service;

  Future<void> acceptAnswer(
    String questionId,
    String answerId,
    String userId,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.acceptAnswer(questionId, answerId, userId),
    );
  }
}

/// Accept answer provider
final acceptAnswerProvider =
    StateNotifierProvider.autoDispose<AcceptAnswerNotifier, AsyncValue<void>>(
      (ref) {
        final service = ref.watch(communityServiceProvider);
        return AcceptAnswerNotifier(service);
      },
    );

/// Upvote answer notifier
class UpvoteAnswerNotifier extends StateNotifier<AsyncValue<void>> {
  UpvoteAnswerNotifier(this._service) : super(const AsyncValue.data(null));

  final CommunityService _service;

  Future<void> upvote(String questionId, String answerId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.upvoteAnswer(questionId, answerId),
    );
  }
}

/// Upvote answer provider
final upvoteAnswerProvider =
    StateNotifierProvider.autoDispose<UpvoteAnswerNotifier, AsyncValue<void>>(
      (ref) {
        final service = ref.watch(communityServiceProvider);
        return UpvoteAnswerNotifier(service);
      },
    );

/// Follow user notifier
class FollowUserNotifier extends StateNotifier<AsyncValue<void>> {
  FollowUserNotifier(this._service) : super(const AsyncValue.data(null));

  final CommunityService _service;

  Future<void> follow(String followerId, String followingId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.followUser(followerId, followingId),
    );
  }

  Future<void> unfollow(String followerId, String followingId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.unfollowUser(followerId, followingId),
    );
  }
}

/// Follow user provider
final followUserProvider =
    StateNotifierProvider.autoDispose<FollowUserNotifier, AsyncValue<void>>(
      (ref) {
        final service = ref.watch(communityServiceProvider);
        return FollowUserNotifier(service);
      },
    );

/// Question sort order
enum QuestionSortOrder {
  newest,
  mostAnswered,
  trending,
}

final questionSortOrderProvider =
    StateProvider<QuestionSortOrder>((ref) => QuestionSortOrder.newest);

/// Question category filter
final questionCategoryFilterProvider =
    StateProvider<String?>((ref) => null);

/// Question status filter
final questionStatusFilterProvider =
    StateProvider<String>((ref) => 'open');

/// User following status (check if current user follows another)
final isFollowingProvider =
    FutureProvider.autoDispose
        .family<bool, (String followerId, String followingId)>(
          (ref, params) async {
            final (followerId, followingId) = params;
            final service = ref.watch(communityServiceProvider);

            try {
              // In a real app, this would check if a following relationship exists
              // For now, return false as placeholder
              return false;
            } catch (e) {
              return false;
            }
          },
        );
