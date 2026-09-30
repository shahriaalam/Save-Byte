import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_bite/core/constants/app_colors.dart';
import 'package:save_bite/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('provides Material 3 theme with emerald primary and warm orange secondary', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.brightness, Brightness.light);
    });
  });
}
