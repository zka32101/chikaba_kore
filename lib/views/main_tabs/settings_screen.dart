import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_preferences_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../utils/auth_error.dart';
import '../../utils/constants.dart';
import '../widgets/custom_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> _showPremiumDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('プレミアムにアップグレード'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('月額 ¥100 で以下の機能が使えます：'),
            SizedBox(height: 12),
            _PremiumFeature(text: 'クチコミ無制限閲覧'),
            _PremiumFeature(text: 'お気に入り無制限保存'),
            _PremiumFeature(text: '広告非表示'),
            _PremiumFeature(text: '優先サポート'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(minimumSize: Size.zero),
            child: const Text('アップグレード'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).upgradeToPremium();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プレミアム会員になりました'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  static Future<void> _showUserTypeSheet(
    BuildContext context,
    WidgetRef ref,
    String currentType,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ユーザータイプを選択',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('地元民'),
              subtitle: const Text('この地域に住んでいる・よく知っている'),
              trailing: currentType == 'local'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop('local'),
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: const Text('訪問者'),
              subtitle: const Text('旅行・観光・出張で来た'),
              trailing: currentType == 'visitor'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop('visitor'),
            ),
          ],
        ),
      ),
    );
    if (selected != null && selected != currentType && context.mounted) {
      await ref.read(authNotifierProvider.notifier).updateUserType(selected);
    }
  }

  static Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アカウントを削除しますか？'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'この操作は取り消せません。',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('削除されるデータ：'),
            SizedBox(height: 4),
            _DeleteNote(text: 'プロフィール情報'),
            _DeleteNote(text: 'お気に入りリスト'),
            _DeleteNote(text: 'クチコミ履歴'),
          ],
        ),
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
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(authNotifierProvider.notifier).deleteAccount();
        if (context.mounted) context.go('/login');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authErrorMessage(e)),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }
    }
  }

  static void _showVersionDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: '© 2026 近場コレ',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      appBar: const CustomAppBar(title: 'マイページ'),
      body: ListView(
        children: [
          if (user != null) ...[
            _ProfileHeader(
              nickname: user.nickname,
              isPremium: user.isPremium,
              avatarUrl: user.profileImageUrl,
            ),
            _ProfileStats(userId: user.uid),
            const Divider(),
          ],
          _SettingsSection(
            title: 'アカウント',
            items: [
              if (user == null)
                _SettingsItem(
                  icon: Icons.login,
                  label: 'ログイン / 新規登録',
                  onTap: () => context.go('/login'),
                ),
              if (user != null) ...[
                _SettingsItem(
                  icon: Icons.workspace_premium,
                  label: user.isPremium ? 'プレミアム会員（有効）' : 'プレミアムにアップグレード',
                  trailing: user.isPremium
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : const Text('¥100/月', style: TextStyle(color: AppColors.accent)),
                  onTap: user.isPremium
                      ? null
                      : () => _showPremiumDialog(context, ref),
                ),
                _SettingsItem(
                  icon: Icons.person_outline,
                  label: 'ユーザータイプ',
                  trailing: Text(
                    user.userType == 'local' ? '地元民' : '訪問者',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () => _showUserTypeSheet(context, ref, user.userType),
                ),
              ],
            ],
          ),
          _SettingsSection(
            title: '通知',
            items: [
              _SettingsSwitchItem(
                icon: Icons.notifications_outlined,
                label: 'プッシュ通知',
                subtitle: '新着スポット・お知らせを受け取る',
                value: ref.watch(notificationPreferencesProvider),
                onToggle: (v) => ref
                    .read(notificationPreferencesProvider.notifier)
                    .setEnabled(v),
              ),
            ],
          ),
          _SettingsSection(
            title: 'アプリ情報',
            items: [
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: 'プライバシーポリシー',
                onTap: () => launchUrl(
                  Uri.parse(AppConstants.privacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                label: '利用規約',
                onTap: () => launchUrl(
                  Uri.parse(AppConstants.termsOfServiceUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                label: 'バージョン情報',
                trailing: Text(AppConstants.appVersion,
                    style: const TextStyle(color: AppColors.textSecondary)),
                onTap: () => _showVersionDialog(context),
              ),
            ],
          ),
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
                child: const Text('ログアウト'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: TextButton(
                onPressed: () => _showDeleteAccountDialog(context, ref),
                child: const Text(
                  'アカウントを削除する',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String nickname;
  final bool isPremium;
  final String? avatarUrl;
  const _ProfileHeader({required this.nickname, required this.isPremium, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.person, size: 40, color: AppColors.primary),
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: Theme.of(context).textTheme.titleLarge),
                if (isPremium)
                  const Row(
                    children: [
                      Icon(Icons.workspace_premium, color: AppColors.accent, size: 16),
                      SizedBox(width: 4),
                      Text('プレミアム会員',
                          style: TextStyle(color: AppColors.accent, fontSize: 13)),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            tooltip: 'プロフィールを編集',
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...items,
        const Divider(height: 1),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final void Function(bool) onToggle;

  const _SettingsSwitchItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onToggle,
        activeThumbColor: AppColors.primary,
      ),
      onTap: () => onToggle(!value),
    );
  }
}

class _DeleteNote extends StatelessWidget {
  final String text;
  const _DeleteNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline,
              size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  final String text;
  const _PremiumFeature({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

/// プロフィール統計ダッシュボード
class _ProfileStats extends ConsumerWidget {
  final String userId;
  const _ProfileStats({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.edit_outlined,
            value: '0',
            label: '投稿',
            color: AppColors.primary,
          ),
          _StatItem(
            icon: Icons.favorite_outlined,
            value: favorites.length.toString(),
            label: 'お気に入り',
            color: AppColors.accent,
          ),
          _StatItem(
            icon: Icons.location_on_outlined,
            value: '0',
            label: '訪問',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

/// 統計アイテム
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
