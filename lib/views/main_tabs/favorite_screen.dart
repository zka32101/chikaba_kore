import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme/app_theme.dart';
import '../../models/favorite_model.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';

class FavoriteScreen extends ConsumerStatefulWidget {
  const FavoriteScreen({super.key});

  @override
  ConsumerState<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends ConsumerState<FavoriteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _sortBy;
  late bool _isComparisonMode;
  late final Set<String> _selectedForComparison;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sortBy = 'saved';
    _isComparisonMode = false;
    _selectedForComparison = {};
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareFavorites(List<FavoriteModel> favorites) {
    if (favorites.isEmpty) return;
    final text = StringBuffer('【近場コレ - お気に入り】\n\n');
    for (final fav in favorites) {
      text.writeln('• ${fav.facilityName}');
    }
    text.writeln('\n共有元：近場コレ\n#近場コレ');
    Share.share(text.toString(), subject: 'お気に入り（${favorites.length}件）');
  }

  void _showComparisonView() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('比較機能'),
        content: const Text('複数施設の比較表示機能は開発中です。\n複数選択した施設の詳細が並列表示されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'お気に入り'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'お気に入りを保存しよう',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ログインすると「行きたい」「今行く」\nリストに施設を保存できます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ログインする',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text(
                    'アカウントをお持ちでない方はこちら',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final wantToGo = ref.watch(wantToGoProvider);
    final willGo = ref.watch(willGoProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'お気に入り',
        actions: [
          if (wantToGo.isNotEmpty || willGo.isNotEmpty) ...[
            IconButton(
              icon: Icon(
                _isComparisonMode
                    ? Icons.compare_arrows_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              tooltip: _isComparisonMode ? '比較モード終了' : '比較モード',
              onPressed: () => setState(() {
                _isComparisonMode = !_isComparisonMode;
                if (!_isComparisonMode) _selectedForComparison.clear();
              }),
            ),
            if (_isComparisonMode && _selectedForComparison.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.pageview_rounded),
                tooltip: '比較表示',
                onPressed: () => _showComparisonView(),
              ),
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _sortBy = v),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (ctx) => [
                _sortItem('saved', '保存日順', Icons.schedule_rounded, _sortBy),
                _sortItem('name', '名前順', Icons.sort_by_alpha_rounded, _sortBy),
                _sortItem(
                    'category', 'カテゴリ順', Icons.category_rounded, _sortBy),
              ],
              child: IconButton(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'ソート',
                onPressed: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: '共有',
              onPressed: () => _shareFavorites(wantToGo + willGo),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${wantToGo.length + willGo.length}件',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bookmark_rounded, size: 15),
                    const SizedBox(width: 6),
                    Text('行きたい (${wantToGo.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_walk_rounded, size: 15),
                    const SizedBox(width: 6),
                    Text('今行く (${willGo.length})'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FavoriteList(
                  favorites: wantToGo,
                  emptyMessage: '行きたい施設をまだ保存していません',
                  emptyIcon: Icons.bookmark_add_rounded,
                  sortBy: _sortBy,
                  isComparisonMode: _isComparisonMode,
                  selectedForComparison: _selectedForComparison,
                  onSelectionChanged: (id) => setState(() {
                    if (_selectedForComparison.contains(id)) {
                      _selectedForComparison.remove(id);
                    } else {
                      _selectedForComparison.add(id);
                    }
                  }),
                ),
                _FavoriteList(
                  favorites: willGo,
                  emptyMessage: '今日行く予定の施設がありません',
                  emptyIcon: Icons.directions_walk_rounded,
                  sortBy: _sortBy,
                  isComparisonMode: _isComparisonMode,
                  selectedForComparison: _selectedForComparison,
                  onSelectionChanged: (id) => setState(() {
                    if (_selectedForComparison.contains(id)) {
                      _selectedForComparison.remove(id);
                    } else {
                      _selectedForComparison.add(id);
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
      String value, String label, IconData icon, String current) {
    final selected = current == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color:
                      selected ? AppColors.primary : AppColors.textPrimary)),
          if (selected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded,
                size: 16, color: AppColors.primary),
          ],
        ],
      ),
    );
  }
}

class _FavoriteList extends ConsumerWidget {
  final List<FavoriteModel> favorites;
  final String emptyMessage;
  final IconData emptyIcon;
  final String sortBy;
  final bool isComparisonMode;
  final Set<String> selectedForComparison;
  final void Function(String)? onSelectionChanged;

  const _FavoriteList({
    required this.favorites,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.sortBy,
    required this.isComparisonMode,
    required this.selectedForComparison,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon,
                    size: 40, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '施設詳細の♡ボタンから追加できます',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<FavoriteModel>.from(favorites);
    switch (sortBy) {
      case 'name':
        sorted.sort((a, b) => a.facilityName.compareTo(b.facilityName));
      case 'category':
        sorted.sort((a, b) => a.facilityCategory.compareTo(b.facilityCategory));
      case 'saved':
      default:
        sorted.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(favoritesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => isComparisonMode
            ? GestureDetector(
                onTap: () => onSelectionChanged?.call(sorted[i].id),
                child: Stack(
                  children: [
                    _FavoriteItem(
                      favorite: sorted[i],
                      onTap: () => onSelectionChanged?.call(sorted[i].id),
                      onStatusChange: (status) => ref
                          .read(favoriteNotifierProvider.notifier)
                          .updateStatus(sorted[i].facilityId, status),
                      onRemove: () => ref
                          .read(favoriteNotifierProvider.notifier)
                          .remove(sorted[i].facilityId),
                      onEditMemo: (memo) => ref
                          .read(favoriteNotifierProvider.notifier)
                          .updateMemo(sorted[i].facilityId, memo),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4),
                          ],
                        ),
                        child: Checkbox(
                          value: selectedForComparison.contains(sorted[i].id),
                          onChanged: (_) =>
                              onSelectionChanged?.call(sorted[i].id),
                          checkColor: Colors.white,
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _FavoriteItem(
                favorite: sorted[i],
                onTap: () =>
                    context.push('/facility/${sorted[i].facilityId}'),
                onStatusChange: (status) => ref
                    .read(favoriteNotifierProvider.notifier)
                    .updateStatus(sorted[i].facilityId, status),
                onRemove: () => ref
                    .read(favoriteNotifierProvider.notifier)
                    .remove(sorted[i].facilityId),
                onEditMemo: (memo) => ref
                    .read(favoriteNotifierProvider.notifier)
                    .updateMemo(sorted[i].facilityId, memo),
              ),
      ),
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  final FavoriteModel favorite;
  final VoidCallback onTap;
  final void Function(FavoriteStatus) onStatusChange;
  final VoidCallback onRemove;
  final void Function(String) onEditMemo;

  const _FavoriteItem({
    required this.favorite,
    required this.onTap,
    required this.onStatusChange,
    required this.onRemove,
    required this.onEditMemo,
  });

  Future<void> _showMemoDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: favorite.memo ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('メモを編集'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 200,
          decoration:
              const InputDecoration(hintText: '行く前に確認したいことなど…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) onEditMemo(result);
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('削除しますか？'),
        content: Text('「${favorite.facilityName}」をお気に入りから削除します'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: Size.zero,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok == true) onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // サムネイル
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
                child: favorite.facilityThumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: favorite.facilityThumbnailUrl!,
                        width: 96,
                        height: 110,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              // コンテンツ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // カテゴリバッジ
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          favorite.facilityCategory,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // 施設名
                      Text(
                        favorite.facilityName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // メモ
                      if (favorite.memo != null &&
                          favorite.memo!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.note_rounded,
                                size: 12,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                favorite.memo!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // アクション行
                      Row(
                        children: [
                          _StatusToggle(
                            current: favorite.status,
                            onChanged: onStatusChange,
                          ),
                          const Spacer(),
                          _ActionIcon(
                            icon: favorite.memo != null &&
                                    favorite.memo!.isNotEmpty
                                ? Icons.edit_note_rounded
                                : Icons.note_add_outlined,
                            onTap: () => _showMemoDialog(context),
                            tooltip: 'メモ',
                          ),
                          const SizedBox(width: 6),
                          _ActionIcon(
                            icon: Icons.delete_outline_rounded,
                            onTap: () => _confirmRemove(context),
                            tooltip: '削除',
                            color: AppColors.accent.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 96,
        height: 110,
        color: AppColors.divider,
        child: const Icon(Icons.image_not_supported_rounded,
            color: AppColors.textSecondary),
      );
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          child: Icon(icon, size: 17,
              color: color ?? AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final FavoriteStatus current;
  final void Function(FavoriteStatus) onChanged;

  const _StatusToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isWillGo = current == FavoriteStatus.willGo;
    final color = isWillGo ? AppColors.willGo : AppColors.wantToGo;
    final icon = isWillGo
        ? Icons.directions_walk_rounded
        : Icons.bookmark_rounded;
    final label = isWillGo ? '今行く' : '行きたい';

    return GestureDetector(
      onTap: () => onChanged(
        isWillGo ? FavoriteStatus.wantToGo : FavoriteStatus.willGo,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
