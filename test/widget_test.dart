import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// AppTheme だけインポートしてテーマが正しく構築できるかを検証
import 'package:chikaba_kore/config/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme builds without error', () {
      final theme = AppTheme.light;
      expect(theme, isA<ThemeData>());
      expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
    });

    test('primary color is correct', () {
      expect(AppColors.primary, const Color(0xFF2D6A4F));
    });

    test('accent color is correct', () {
      expect(AppColors.accent, const Color(0xFFFF6B6B));
    });
  });

  group('ProviderScope', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: Text('近場コレ')),
            ),
          ),
        ),
      );
      expect(find.text('近場コレ'), findsOneWidget);
    });
  });
}
