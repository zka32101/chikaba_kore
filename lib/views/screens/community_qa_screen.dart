import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/community_model.dart';
import '../../providers/community_provider.dart';
import '../../utils/logger.dart';

class CommunityQAScreen extends ConsumerWidget {
  final String city;
  final String userId;

  const CommunityQAScreen({
    Key? key,
    required this.city,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(
      communityQuestionsStreamProvider(city),
    );
    final statsAsync = ref.watch(communityStatsProvider(city));
    final sortOrder = ref.watch(questionSortOrderProvider);
    final categoryFilter = ref.watch(questionCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ローカルQ&A'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(communityQuestionsStreamProvider(city));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSortOptions(context, ref),
          ),
        ],
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
        data: (questions) {
          // Filter and sort questions
          var filtered = questions;

          if (categoryFilter != null) {
            filtered = filtered
                .where((q) => q.category == categoryFilter)
                .toList();
          }

          // Sort based on selection
          switch (sortOrder) {
            case QuestionSortOrder.newest:
              filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            case QuestionSortOrder.mostAnswered:
              filtered.sort((a, b) => b.answerCount.compareTo(a.answerCount));
            case QuestionSortOrder.trending:
              filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
          }

          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Stats bar
              if (statsAsync.hasValue)
                _buildStatsBar(statsAsync.value!),

              // Filter chip
              if (categoryFilter != null)
                _buildFilterChip(context, ref, categoryFilter!),

              // Questions list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) => _buildQuestionItem(
                    context,
                    filtered[index],
                    userId,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAskQuestionDialog(context, ref, userId, city),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsBar(CommunityStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('質問', stats.totalQuestions.toString(), Colors.blue),
          _buildStatItem('回答', stats.totalAnswers.toString(), Colors.green),
          _buildStatItem(
            '貢献者',
            stats.topContributorsCount.toString(),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String category,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        children: [
          Chip(
            label: Text(category),
            onDeleted: () {
              ref.read(questionCategoryFilterProvider.notifier).state = null;
            },
            deleteIcon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(
    BuildContext context,
    CommunityQuestion question,
    String userId,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      title: Text(
        question.question,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(question.userAvatarUrl),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.userName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(question.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Chip(
                label: Text(
                  question.category,
                  style: const TextStyle(fontSize: 11),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                backgroundColor: Colors.grey[100],
              ),
              const SizedBox(width: 8),
              Icon(Icons.message, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${question.answerCount}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${question.viewCount}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (question.isAnswered)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '解決済',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () => _showQuestionDetail(context, question, userId),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'まだ質問がありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                _showAskQuestionDialog(context, ref, userId, city),
            child: const Text('最初の質問を投稿'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inHours < 1) {
      return '${diff.inMinutes}分前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  void _showAskQuestionDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String city,
  ) {
    // Placeholder for question creation dialog
    appLogger.d('Show ask question dialog for $city');
  }

  void _showQuestionDetail(
    BuildContext context,
    CommunityQuestion question,
    String userId,
  ) {
    // Placeholder for question detail navigation
    appLogger.d('Show question detail: ${question.id}');
  }

  void _showSortOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ソート順序',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('新しい順'),
              onTap: () {
                ref.read(questionSortOrderProvider.notifier).state =
                    QuestionSortOrder.newest;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('回答が多い'),
              onTap: () {
                ref.read(questionSortOrderProvider.notifier).state =
                    QuestionSortOrder.mostAnswered;
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('トレンディング'),
              onTap: () {
                ref.read(questionSortOrderProvider.notifier).state =
                    QuestionSortOrder.trending;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
