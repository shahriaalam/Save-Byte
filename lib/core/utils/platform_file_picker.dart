import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';

/// Shows a polished media-access soft-prompt dialog, then invokes the device
/// gallery picker. On permission denial, shows a "Go to Settings" dialog.
///
/// Returns a Base64 Data URL (data:image/...;base64,...), or null if the user
/// cancels at any point.
///
/// Pass [context] so the function can display permission-related dialogs.
Future<String?> pickImageWithPermission(BuildContext context) async {
  // Show soft pre-prompt dialog on supported mobile platforms
  final proceed = await _showMediaAccessDialog(context);
  if (!proceed) return null;
  if (!context.mounted) return null;

  return _pickImageFromDevice(context);
}

/// Lower-level picker without the soft-prompt (kept for backward compat).
/// Prefer [pickImageWithPermission] in UI code.
Future<String?> pickImageFromDevice() async {
  try {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';
    final base64 = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64';
  } catch (e, stack) {
    debugPrint('[SaveBite] pickImageFromDevice error: $e\n$stack');
    rethrow;
  }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

/// Shows a beautiful "Allow media access?" soft-prompt before the OS dialog.
/// Returns true if the user chose to proceed, false if they cancelled.
Future<bool> _showMediaAccessDialog(BuildContext context) async {
  // Skip soft-prompt on web — browser handles permissions inline
  if (kIsWeb) return true;

  final result = await showDialog<bool>(
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
                    color: const Color(0xFFE23744).withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Allow Photo Access',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Save Bite needs access to your photo library to let you upload a profile picture or food photo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Benefit rows
            _buildBenefit(
              icon: Icons.lock_outline_rounded,
              color: AppColors.primary,
              text: 'Your photos are never shared without your consent',
            ),
            const SizedBox(height: 8),
            _buildBenefit(
              icon: Icons.image_rounded,
              color: const Color(0xFF2563EB),
              text: 'Only the photo you select will be used',
            ),
            const SizedBox(height: 8),
            _buildBenefit(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF16A34A),
              text: 'You can change or remove it anytime',
            ),
            const SizedBox(height: 24),

            // Allow button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Open Photo Library',
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

            // Cancel link
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
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

  return result ?? false;
}

/// Runs the actual picker and handles permission-denied errors gracefully.
Future<String?> _pickImageFromDevice(BuildContext context) async {
  try {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (image == null) return null; // User cancelled

    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? 'image/jpeg';
    final base64 = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64';
  } on PlatformException catch (e) {
    debugPrint('[SaveBite] pickImageFromDevice PlatformException: $e');
    // Permission permanently denied — guide user to Settings
    if (context.mounted) {
      final code = e.code.toLowerCase();
      final isDenied = code.contains('permission') ||
          code.contains('denied') ||
          code.contains('unauthorized');

      if (isDenied) {
        await _showPermissionDeniedDialog(context);
      } else {
        // Other platform error (e.g. no gallery app) — show simple snack
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open photo library: ${e.message}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    return null;
  } catch (e, stack) {
    debugPrint('[SaveBite] pickImageFromDevice error: $e\n$stack');
    return null;
  }
}

/// "Go to Settings" dialog shown when permission is permanently denied.
Future<void> _showPermissionDeniedDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          color: AppColors.error,
          size: 28,
        ),
      ),
      title: const Text(
        'Photo Access Denied',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: AppColors.textPrimary,
        ),
      ),
      content: const Text(
        'Save Bite doesn\'t have permission to access your photos.\n\nPlease go to your device Settings → Apps → Save Bite → Permissions and enable "Photos" or "Storage".',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(
            'Maybe Later',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            // Open app settings via platform channel (best-effort)
            _openAppSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Open Settings',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Attempts to open the app's system settings page so the user can grant
/// the photo permission manually. Uses a platform channel as best-effort.
void _openAppSettings() {
  if (!kIsWeb) {
    try {
      const channel = MethodChannel('com.savebite/app_settings');
      channel.invokeMethod<void>('openAppSettings');
    } catch (_) {
      // Silently ignore — user will need to navigate manually
    }
  }
}

// ─── Shared benefit row widget ────────────────────────────────────────────────

Widget _buildBenefit({
  required IconData icon,
  required Color color,
  required String text,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 15),
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
