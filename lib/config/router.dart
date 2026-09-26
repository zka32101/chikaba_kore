import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/splash_screen.dart';
import '../views/onboarding_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/facility_detail_screen.dart';
import '../views/main_tabs/home_screen.dart';
import '../views/main_tabs/map_screen.dart';
import '../views/main_tabs/favorite_screen.dart';
import '../views/main_tabs/settings_screen.dart';
import '../views/search_screen.dart';
import '../views/write_review_screen.dart';
import '../views/profile_edit_screen.dart';
import '../views/screens/premium_screen.dart';
import '../views/screens/pending_reviews_screen.dart';
import '../views/safety_route/paint_submission_screen.dart';
import '../views/safety_route/phone_verification_screen.dart';
import '../views/safety_route/spot_comments_screen.dart';
import '../views/safety_route/spots_list_screen.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// フォアグラウンド通知バナー等、ルート直下の[Overlay]にアクセスするために使う。
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
    GoRoute(
      path: '/facility/:id',
      builder: (_, state) => FacilityDetailScreen(facilityId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
    GoRoute(path: '/profile/edit', builder: (_, _) => const ProfileEditScreen()),
    GoRoute(path: '/premium', builder: (_, _) => const PremiumScreen()),
    GoRoute(
      path: '/admin/pending-reviews',
      builder: (_, _) => const PendingReviewsScreen(),
    ),
    GoRoute(
      path: '/facility/:id/review',
      builder: (_, state) => WriteReviewScreen(
        facilityId: state.pathParameters['id']!,
        facilityName: state.uri.queryParameters['name'] ?? '',
      ),
    ),
    // 安全ルートモード（あんしんみち由来）の周辺機能
    GoRoute(path: '/safety-route/spots', builder: (_, _) => const SpotsListScreen()),
    GoRoute(path: '/safety-route/comments', builder: (_, _) => const SpotCommentsScreen()),
    GoRoute(path: '/safety-route/submit', builder: (_, _) => const PaintSubmissionScreen()),
    GoRoute(path: '/safety-route/verification', builder: (_, _) => const PhoneVerificationScreen()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
        GoRoute(path: '/favorites', builder: (_, _) => const FavoriteScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);

class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  int _tabIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/favorites')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex(context),
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/map');
            case 2:
              context.go('/favorites');
            case 3:
              context.go('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: '地図'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'お気に入り'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}
