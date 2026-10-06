import 'package:flutter/material.dart';

/// Centralized color palette for the Account & Profile screens
/// (Customer Profile & Restaurant Account).
/// Stored here so all color codes can be easily accessed, modified, or themed in the future.
abstract final class AccountColors {
  // ==========================================
  // BACKGROUNDS
  // ==========================================
  /// Clean pure white background for the Account screens
  static const Color background = Color(0xFFFFFFFF);

  /// Card surface color
  static const Color cardSurface = Color(0xFFF8FAFC);

  /// Card border outline
  static const Color cardBorder = Color(0xFFF1F5F9);

  // ==========================================
  // PEACH HEADER GRADIENT
  // ==========================================
  /// Customer profile peach gradient start
  static const Color headerPeachStart = Color(0xFFFFECE5);

  /// Customer profile peach gradient middle
  static const Color headerPeachMid = Color(0xFFFFF7F2);

  /// Customer profile peach gradient end
  static const Color headerPeachEnd = Color(0xFFFFFFFF);

  /// Restaurant account header gradient start
  static const Color restaurantHeaderStart = Color(0xFFFFF8F6);

  /// Restaurant account header gradient end
  static const Color restaurantHeaderEnd = Color(0xFFFFEFEA);

  // ==========================================
  // SUPER SAVER & GOLD MERCHANT BADGES
  // ==========================================
  static const Color superSaverBadgeBg = Color(0xFFFFF1F2);
  static const Color superSaverBadgeBorder = Color(0xFFFFCCD3);
  static const Color superSaverBadgePrimary = Color(0xFFE11D48);
  static const Color superSaverBadgeDark = Color(0xFFBE123C);

  static const Color goldBadgeBg = Color(0xFFFFFBEB);
  static const Color goldBadgeBorder = Color(0xFFFDE68A);
  static const Color goldBadgeText = Color(0xFFD97706);

  // ==========================================
  // QUICK ACTION TILES (7 VIBRANT CIRCULAR TILES)
  // ==========================================
  /// Orders
  static const Color actionOrders = Color(0xFF059669);
  static const Color actionOrdersBg = Color(0xFFECFDF5);

  /// Addresses / Update Info
  static const Color actionAddresses = Color(0xFF0284C7);
  static const Color actionAddressesBg = Color(0xFFF0F9FF);

  /// Favourites / Hours
  static const Color actionFavourites = Color(0xFFE11D48);
  static const Color actionFavouritesBg = Color(0xFFFFF1F2);

  /// Vouchers / Ad Packages
  static const Color actionVouchers = Color(0xFFD97706);
  static const Color actionVouchersBg = Color(0xFFFFFBEB);

  /// Rewards / Safety Rules
  static const Color actionRewards = Color(0xFF7C3AED);
  static const Color actionRewardsBg = Color(0xFFF5F3FF);

  /// Help Center
  static const Color actionHelpCenter = Color(0xFF0891B2);
  static const Color actionHelpCenterBg = Color(0xFFECFEFF);

  /// Contact Us
  static const Color actionContact = Color(0xFFEA580C);
  static const Color actionContactBg = Color(0xFFFFF7ED);

  // ==========================================
  // MENU LIST ITEMS & CHEVRONS
  // ==========================================
  static const Color menuIconBg = Color(0xFFF1F5F9);
  static const Color menuIconDefault = Color(0xFF475569);
  static const Color menuChevron = Color(0xFFE11D48);

  // ==========================================
  // DELETE ACCOUNT BUTTON (DARK RED)
  // ==========================================
  static const Color deleteButtonBg = Color(0xFF991B1B);
  static const Color deleteButtonText = Color(0xFFFFFFFF);

  // ==========================================
  // TYPOGRAPHY COLORS
  // ==========================================
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}
