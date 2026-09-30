import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// App logo icon mark featuring appetizing food iconography on a crimson gradient or inverted white surface.
class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({
    this.size = 40,
    this.borderRadius,
    this.iconSize,
    this.isInverted = false,
    super.key,
  });

  final double size;
  final double? borderRadius;
  final double? iconSize;
  final bool isInverted;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.28);
    final calculatedIconSize = iconSize ?? (size * 0.54);

    if (isInverted) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppColors.primary,
            width: (size * 0.05).clamp(2.0, 4.0),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: size * 0.28,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.restaurant_rounded,
            color: AppColors.primary,
            size: calculatedIconSize,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Colors.white,
          size: calculatedIconSize,
        ),
      ),
    );
  }
}

/// Complete brand logo displaying the food emblem and stylized SaveBite typography.
class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 64,
    this.showText = true,
    this.showTagline = false,
    this.isInverted = false,
    super.key,
  });

  final double size;
  final bool showText;
  final bool showTagline;
  final bool isInverted;

  @override
  Widget build(BuildContext context) {
    final logoWidget = AppLogoIcon(size: size, isInverted: isInverted);

    if (!showText) return logoWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
            children: const [
              TextSpan(
                text: 'Save',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'Bite',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            AppConstants.appTagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
