import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../user_location_controller.dart';
import '../../notifications/notification_controller.dart';

/// Modal bottom sheet requesting location permission on first-time customer entry.
class LocationPermissionSheet extends ConsumerStatefulWidget {
  const LocationPermissionSheet({
    this.onCompleted,
    super.key,
  });

  final VoidCallback? onCompleted;

  /// Shows the location permission sheet if it has not been prompted yet.
  static Future<void> showIfFirstTime(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(userLocationControllerProvider.notifier);
    final hasPrompted = await notifier.hasPromptedPermission();
    if (!hasPrompted && context.mounted) {
      await showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const LocationPermissionSheet(),
      );
    }
  }

  /// Explicitly shows the location permission sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPermissionSheet(),
    );
  }

  @override
  ConsumerState<LocationPermissionSheet> createState() =>
      _LocationPermissionSheetState();
}

class _LocationPermissionSheetState
    extends ConsumerState<LocationPermissionSheet> {
  bool _isRequesting = false;

  Future<void> _handleAllowLocation() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      final detectedArea = await ref
          .read(userLocationControllerProvider.notifier)
          .requestPermissionAndDetect();

      if (!mounted) return;
      setState(() => _isRequesting = false);

      // Initialise the notification controller (starts realtime subscription)
      ref.read(notificationControllerProvider);

      Navigator.of(context).pop();
      widget.onCompleted?.call();

      // ── Request OS notification permission right after location ──────────
      if (mounted) {
        await _requestNotificationPermission();
      }

      final locState = ref.read(userLocationControllerProvider);

      String message;
      Color barColor;
      IconData icon;

      if (!locState.hasGpsFix && detectedArea == 'Dhaka') {
        message = '📍 Location estimated: Dhaka. Showing all active hot deals.';
        barColor = const Color(0xFF1E293B);
        icon = Icons.info_outline_rounded;
      } else if (!locState.isInsideDhaka) {
        message = '📍 Detected: $detectedArea (Outside Dhaka). Showing top Dhaka hot deals!';
        barColor = const Color(0xFF1E293B);
        icon = Icons.location_city_rounded;
      } else {
        message = '📍 Located in $detectedArea! Suggesting hot deals near you.';
        barColor = const Color(0xFF15803D);
        icon = Icons.check_circle_rounded;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: barColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isRequesting = false);
        Navigator.of(context).pop();
        widget.onCompleted?.call();
      }
    }
  }

  /// Requests OS-level notification permission via the native platform channel.
  /// On Android 13+ (API 33) this triggers the system permission dialog.
  /// On iOS this triggers the native permission request.
  /// Falls back gracefully on older Android versions where permission is
  /// granted by default at install time.
  Future<void> _requestNotificationPermission() async {
    try {
      const channel = MethodChannel('com.savebite/notifications');
      await channel.invokeMethod<bool>('requestPermission');
    } on MissingPluginException {
      // Platform channel not set up yet — show in-app soft-prompt instead
      if (mounted) {
        await _showNotificationPermissionDialog();
      }
    } catch (_) {
      if (mounted) {
        await _showNotificationPermissionDialog();
      }
    }
  }

  /// In-app notification opt-in dialog (soft-prompt before OS dialog).
  Future<void> _showNotificationPermissionDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE23744), Color(0xFF8B0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE23744).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Never Miss a Hot Deal!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Body
              const Text(
                'Get instant alerts when nearby restaurants post new surplus food offers with 45%+ discounts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // Benefits
              _buildPermBenefit(
                icon: Icons.flash_on_rounded,
                color: const Color(0xFFF59E0B),
                text: 'Instant alerts when deals go live near you',
              ),
              const SizedBox(height: 8),
              _buildPermBenefit(
                icon: Icons.savings_rounded,
                color: const Color(0xFF16A34A),
                text: 'Never miss a 50% or more discount again',
              ),
              const SizedBox(height: 8),
              _buildPermBenefit(
                icon: Icons.lock_outline_rounded,
                color: AppColors.primary,
                text: 'No spam — only real nearby surplus offers',
              ),
              const SizedBox(height: 24),

              // Allow button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_active_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Enable Notifications',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Skip link
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Maybe later',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermBenefit({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Animated Location & Fire Badge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFBA1A2E),
                        Color(0xFFEA580C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE047),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFF78350F),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Find 45%+ Hot Deals Near You',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Allow Save Bite to detect your Dhaka location to suggest hot deals with 45%+ discount and surplus meals right around your neighborhood.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Feature Highlights
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFEA580C),
                    text: 'Exclusive 45% or more surplus food discounts',
                  ),
                  const SizedBox(height: 10),
                  _buildBenefitRow(
                    icon: Icons.my_location_rounded,
                    iconColor: AppColors.primary,
                    text: 'Auto-detects Dhanmondi, Banani, Gulshan, Mirpur & more',
                  ),
                  const SizedBox(height: 10),
                  _buildBenefitRow(
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFF059669),
                    text: 'Near-you restaurants with active surplus food right now',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Allow Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleAllowLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isRequesting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Locating neighborhood...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.near_me_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Allow Location & Find Deals',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
