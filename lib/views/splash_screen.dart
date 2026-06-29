import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/cache_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    final hasSeenOnboarding = CacheService().hasSeenOnboarding;
    authState.when(
      data: (isSignedIn) {
        if (isSignedIn) {
          context.go('/home');
        } else if (hasSeenOnboarding) {
          // オンボーディング済み → ログイン画面へ
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      },
      loading: () => hasSeenOnboarding
          ? context.go('/login')
          : context.go('/onboarding'),
      error: (_, _) => hasSeenOnboarding
          ? context.go('/login')
          : context.go('/onboarding'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.location_on, color: AppColors.primary, size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                '近場コレ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '地元のいいところ、全部ここに',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
