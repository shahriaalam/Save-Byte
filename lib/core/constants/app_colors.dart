import 'package:flutter/material.dart';

/// Central color palette for SaveBite.
/// Core brand colors: Red, White, and Black with premium gradients.
abstract final class AppColors {
  // Brand colors (Core Red, White, Black)
  static const Color primary = Color(0xFFE23744); // Appetizing Signature Red
  static const Color primaryLight = Color(0xFFFF5252);
  static const Color primaryDark = Color(0xFFB71C1C);

  static const Color secondary = Color(0xFF0F0F10); // Sleek Obsidian Black
  static const Color secondaryLight = Color(0xFF27272A);
  static const Color secondaryDark = Color(0xFF000000);

  // Pure colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0F0F10);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE23744), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF4B55), Color(0xFFE23744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF27272A), Color(0xFF0F0F10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redBlackGradient = LinearGradient(
    colors: [Color(0xFFE23744), Color(0xFF180A0C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Surface and background
  static const Color background = Color(0xFFF9F9FA); // Clean canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF4F4F5);

  // Text colors
  static const Color textPrimary = Color(0xFF0F0F10); // Crisp Black
  static const Color textSecondary = Color(0xFF52525B); // Charcoal
  static const Color textMuted = Color(0xFF71717A); // Slate
  static const Color textLight = Color(0xFFFFFFFF); // Pure White

  // Status & Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE23744);
  static const Color info = Color(0xFF2563EB);

  // Borders and dividers
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderFocus = Color(0xFFE23744);
  static const Color divider = Color(0xFFE4E4E7);
}
