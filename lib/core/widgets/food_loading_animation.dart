import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Delicious animated food loading presentation featuring pulsing aroma ripples,
/// rotating food delicacies (ramen, burger, pizza, bakery, dining), and steam waves.
class FoodLoadingAnimation extends StatefulWidget {
  const FoodLoadingAnimation({
    this.title = 'Preparing Your Feast...',
    this.subtitle,
    this.size = 110.0,
    super.key,
  });

  final String title;
  final String? subtitle;
  final double size;

  @override
  State<FoodLoadingAnimation> createState() => _FoodLoadingAnimationState();
}

class _FoodLoadingAnimationState extends State<FoodLoadingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _steamController;
  late final AnimationController _rippleController;

  Timer? _foodSwitchTimer;
  int _currentFoodIndex = 0;

  static const List<({IconData icon, String label})> _foods = [
    (icon: Icons.restaurant_rounded, label: 'Fine Dining'),
    (icon: Icons.ramen_dining_rounded, label: 'Hot Noodles & Soup'),
    (icon: Icons.lunch_dining_rounded, label: 'Gourmet Burgers'),
    (icon: Icons.local_pizza_rounded, label: 'Artisan Pizzas'),
    (icon: Icons.bakery_dining_rounded, label: 'Fresh Bakery'),
    (icon: Icons.cake_rounded, label: 'Sweet Treats'),
  ];

  static const List<String> _subtitles = [
    'Finding fresh surplus food near you...',
    'Connecting with local restaurants & bakeries...',
    'Unlocking 50%+ discounts on delicious meals...',
    'Almost there! Preparing your SaveBite dashboard...',
  ];
  int _subtitleIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _foodSwitchTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (mounted) {
        setState(() {
          _currentFoodIndex = (_currentFoodIndex + 1) % _foods.length;
          _subtitleIndex = (_subtitleIndex + 1) % _subtitles.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _foodSwitchTimer?.cancel();
    _pulseController.dispose();
    _steamController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFood = _foods[_currentFoodIndex];
    final activeSubtitle = widget.subtitle ?? _subtitles[_subtitleIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Steam Particles & Food Emblem Stack
        SizedBox(
          width: widget.size * 1.6,
          height: widget.size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding Aroma Ripple Ring 1
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, _) {
                  final progress = _rippleController.value;
                  final scale = 1.0 + (progress * 0.45);
                  final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.22;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: opacity),
                      ),
                    ),
                  );
                },
              ),

              // Expanding Aroma Ripple Ring 2 (Offset phase)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, _) {
                  final progress = (_rippleController.value + 0.5) % 1.0;
                  final scale = 1.0 + (progress * 0.45);
                  final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.18;

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: opacity),
                      ),
                    ),
                  );
                },
              ),

              // Rising Steam Waves above the food
              Positioned(
                top: 0,
                child: AnimatedBuilder(
                  animation: _steamController,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final waveOffset = (_steamController.value + (index * 0.33)) % 1.0;
                        final verticalTravel = (1.0 - waveOffset) * 22;
                        final horizontalSway = math.sin((waveOffset * math.pi * 2) + index) * 5;
                        final opacity = math.sin(waveOffset * math.pi) * 0.7;

                        return Transform.translate(
                          offset: Offset(horizontalSway, -verticalTravel),
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                width: 3.5,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              // Main Pulsing Food Plate / Squircle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 0.94 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(widget.size * 0.32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: widget.size * 0.35,
                        offset: Offset(0, widget.size * 0.12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: widget.size * 0.18,
                        offset: Offset(0, widget.size * 0.06),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: Icon(
                        activeFood.icon,
                        key: ValueKey(activeFood.icon),
                        size: widget.size * 0.52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Food Category Micro-Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  activeFood.label,
                  key: ValueKey(activeFood.label),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Subtitle with smooth fade animation
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              activeSubtitle,
              key: ValueKey(activeSubtitle),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Elegant Animated Indeterminate Progress Bar
        SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: Color(0xFFF1F1F3),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full screen frosted overlay presenting the delicious FoodLoadingAnimation when logging in.
class FoodLoginLoadingOverlay extends StatelessWidget {
  const FoodLoginLoadingOverlay({
    required this.isLoading,
    this.title = 'Logging in to SaveBite...',
    super.key,
  });

  final bool isLoading;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Positioned.fill(
      child: PopScope(
        canPop: false,
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 0.88),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FoodLoadingAnimation(
                  title: title,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
