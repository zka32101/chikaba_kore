import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/announcement.dart';
import '../../providers/announcement_provider.dart';

/// お知らせ一覧画面（あんしんみち由来）。マイページから遷移する。
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  List<Announcement>? _announcements;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errorMessage = null);
    try {
      final announcements = await ref.read(announcementServiceProvider).fetchRecent();
      if (!mounted) return;
      setState(() => _announcements = announcements);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'お知らせの取得に失敗しました');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    final announcements = _announcements;
    if (announcements == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.campaign_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              const Text('お知らせはまだありません', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: announcements.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: Text(announcement.title),
            subtitle: Text(announcement.body),
            isThreeLine: announcement.body.length > 40,
            trailing: announcement.createdAt != null
                ? Text(
                    _formatRelativeTime(announcement.createdAt!),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  )
                : null,
          );
        },
      ),
    );
  }

  /// 相対時刻表示（例:「3時間前」）。
  String _formatRelativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inDays < 1) return '${diff.inHours}時間前';
    if (diff.inDays < 30) return '${diff.inDays}日前';
    return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
  }
}
