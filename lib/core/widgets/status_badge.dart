import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Reusable status badge widget (Section 56).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    super.key,
    this.backgroundColor,
    this.textColor,
    this.isSuccess = false,
    this.isWarning = false,
    this.isError = false,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSuccess;
  final bool isWarning;
  final bool isError;

  factory StatusBadge.fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return StatusBadge(label: status.toUpperCase(), isSuccess: true);
      case 'pending':
        return StatusBadge(label: status.toUpperCase(), isWarning: true);
      case 'suspended':
      case 'rejected':
      case 'admin blocked':
      case 'admin_blocked':
      case 'disabled':
        return StatusBadge(label: status.toUpperCase(), isError: true);
      case 'inactive':
      case 'expired':
      default:
        return StatusBadge(
          label: status.toUpperCase(),
          backgroundColor: AppColors.surfaceVariant,
          textColor: AppColors.textMuted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (backgroundColor != null && textColor != null) {
      bg = backgroundColor!;
      fg = textColor!;
    } else if (isSuccess) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
    } else if (isWarning) {
      bg = AppColors.warning.withValues(alpha: 0.12);
      fg = AppColors.warning;
    } else if (isError) {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
    } else {
      bg = AppColors.surfaceVariant;
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
