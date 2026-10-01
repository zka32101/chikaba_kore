import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../models/shared_list.dart';
import '../../providers/shared_list_provider.dart';
import '../widgets/custom_app_bar.dart';

/// 共有コードを入力して、他ユーザーのお気に入りリストを閲覧する画面。
/// `initialShareCode`が指定されていれば、入力をスキップして直接表示する
/// （共有時のテキストにコードを含める形で遷移してきた場合）。
class SharedListScreen extends ConsumerStatefulWidget {
  final String? initialShareCode;
  const SharedListScreen({super.key, this.initialShareCode});

  @override
  ConsumerState<SharedListScreen> createState() => _SharedListScreenState();
}

class _SharedListScreenState extends ConsumerState<SharedListScreen> {
  final _controller = TextEditingController();
  String? _submittedCode;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialShareCode;
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      _submittedCode = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '共有リストを見る'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '共有コードを入力すると、相手のお気に入りリストを見られます',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '共有コードを貼り付け',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('表示'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildResult()),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _submittedCode = code);
  }

  Widget _buildResult() {
    final code = _submittedCode;
    if (code == null) return const SizedBox.shrink();

    final listAsync = ref.watch(sharedListProvider(code));
    return listAsync.when(
      data: (list) {
        if (list == null) {
          return const Center(
            child: Text(
              'このコードのリストは見つかりませんでした',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return _SharedListView(list: list);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text('読み込みに失敗しました', style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _SharedListView extends StatelessWidget {
  final SharedList list;
  const _SharedListView({required this.list});

  @override
  Widget build(BuildContext context) {
    if (list.items.isEmpty) {
      return const Center(
        child: Text('このリストは空です', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${list.ownerNickname}さんのお気に入り（${list.items.length}件）',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: list.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = list.items[i];
              return ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(item.facilityName),
                subtitle: Text(item.facilityCategory),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/facility/${item.facilityId}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
