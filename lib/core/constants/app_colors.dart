import 'package:flutter/material.dart';

/// App color palette defined in SaveBite specification (Section 55):
/// - Primary: Emerald / Green
/// - Secondary: Warm Orange
/// - Background: Warm White
/// - Text: Dark Charcoal
abstract final class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF059669); // Emerald
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF047857);

  static const Color secondary = Color(0xFFEA580C); // Warm Orange
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFC2410C);

  // Surface and background
  static const Color background = Color(0xFFFAFAF9); // Warm White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F4);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1917); // Dark Charcoal
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFF78716C);
  static const Color textLight = Color(0xFFFAFAF9);

  // Status & Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Borders and dividers
  static const Color border = Color(0xFFE7E5E4);
  static const Color borderFocus = Color(0xFF059669);
  static const Color divider = Color(0xFFE7E5E4);
}
