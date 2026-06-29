import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme/app_theme.dart';
import '../services/cache_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _pages = [
    _PageData(
      gradient: [Color(0xFF2D6A4F), Color(0xFF52B788)],
      emoji: '🗺️',
      badge: '近場コレとは？',
      title: '近所の\n穴場を発見しよう',
      description: '800m圏内の施設をスマホ一台で探索。\n地図・リスト・グリッドで見やすく表示します。',
      steps: [
        _StepItem(icon: Icons.location_on_rounded, text: 'GPS で周辺施設を自動検出'),
        _StepItem(icon: Icons.filter_list_rounded, text: 'カテゴリ・評価で絞り込み'),
        _StepItem(icon: Icons.map_rounded, text: 'マップ表示で位置を確認'),
      ],
    ),
    _PageData(
      gradient: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
      emoji: '🎰',
      badge: '今日どこ行く？',
      title: 'ガチャで\n行き先を決めよう',
      description: '迷ったらガチャ！未訪問 × ★4以上の\n穴場スポットをランダムにご提案。',
      steps: [
        _StepItem(icon: Icons.casino_rounded, text: 'ホーム画面のガチャボタンをタップ'),
        _StepItem(icon: Icons.star_rounded, text: '★4以上 × 未訪問スポットから選出'),
        _StepItem(icon: Icons.directions_walk_rounded, text: '「いってきます」で詳細ページへ'),
      ],
    ),
    _PageData(
      gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      emoji: '💎',
      badge: '差別化機能',
      title: '穴波スコアで\n本当の穴場を探そう',
      description: '「地元民がよく行く × あまり知られていない」\n施設を独自スコアで可視化します。',
      steps: [
        _StepItem(icon: Icons.people_rounded, text: '地元民レビュー比率が高い施設'),
        _StepItem(icon: Icons.trending_up_rounded, text: '評価が高いのに口コミが少ない'),
        _StepItem(icon: Icons.emoji_events_rounded, text: '穴波スコア高いほど「真の穴場」'),
      ],
    ),
    _PageData(
      gradient: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
      emoji: '⭐',
      badge: 'クチコミ機能',
      title: '地元民の\nリアルな声を聞こう',
      description: '地元民・訪問者それぞれの視点でレビュー。\n信頼できる情報で失敗しない選択を。',
      steps: [
        _StepItem(icon: Icons.verified_rounded, text: '地元民バッジ付きレビューが充実'),
        _StepItem(icon: Icons.photo_camera_rounded, text: '写真付きの詳細なクチコミ'),
        _StepItem(icon: Icons.favorite_rounded, text: '行きたい / 行く予定でお気に入り管理'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _fadeController.reset();
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    } else {
      _finish(toSignup: true);
    }
  }

  Future<void> _finish({required bool toSignup}) async {
    await CacheService().setOnboardingSeen();
    if (mounted) {
      context.go(toSignup ? '/signup' : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: page.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── ヘッダー（スキップ） ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // ページ数
                    Text(
                      '${_currentPage + 1} / ${_pages.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // スキップボタン
                    if (!isLast)
                      TextButton(
                        onPressed: () => _finish(toSignup: true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        child: const Row(
                          children: [
                            Text('スキップ',
                                style: TextStyle(fontSize: 13)),
                            SizedBox(width: 2),
                            Icon(Icons.skip_next_rounded, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ─── ページコンテンツ ───
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    _fadeController.reset();
                    setState(() => _currentPage = i);
                    _fadeController.forward();
                  },
                  itemBuilder: (_, i) => FadeTransition(
                    opacity: _fadeAnimation,
                    child: _OnboardingPage(data: _pages[i]),
                  ),
                ),
              ),

              // ─── インジケーター ───
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── ボタン ───
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  children: [
                    // メインボタン
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? '始める 🎉' : '次へ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: page.gradient[0],
                              ),
                            ),
                            if (!isLast) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: page.gradient[0]),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ログインリンク
                    TextButton(
                      onPressed: () => _finish(toSignup: false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.75),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'すでにアカウントをお持ちの方はこちら',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 絵文字 + バッジ
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(data.emoji,
                      style: const TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // タイトル
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          // 説明文
          Text(
            data.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          // ステップリスト
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: data.steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i < data.steps.length - 1 ? 14 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(step.icon,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final List<Color> gradient;
  final String emoji;
  final String badge;
  final String title;
  final String description;
  final List<_StepItem> steps;

  const _PageData({
    required this.gradient,
    required this.emoji,
    required this.badge,
    required this.title,
    required this.description,
    required this.steps,
  });
}

class _StepItem {
  final IconData icon;
  final String text;
  const _StepItem({required this.icon, required this.text});
}
