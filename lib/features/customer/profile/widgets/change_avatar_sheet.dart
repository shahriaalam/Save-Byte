import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/utils/platform_file_picker.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/auth_controller.dart';

/// Delicious preset food avatar option
class FoodAvatarPreset {
  const FoodAvatarPreset({
    required this.name,
    required this.url,
    required this.emoji,
  });

  final String name;
  final String url;
  final String emoji;
}

const List<FoodAvatarPreset> kFoodAvatarPresets = [
  FoodAvatarPreset(
    name: 'Pizza Lover',
    url: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=240&auto=format&fit=crop&q=80',
    emoji: '🍕',
  ),
  FoodAvatarPreset(
    name: 'Gourmet Burger',
    url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=240&auto=format&fit=crop&q=80',
    emoji: '🍔',
  ),
  FoodAvatarPreset(
    name: 'Hot Ramen',
    url: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=240&auto=format&fit=crop&q=80',
    emoji: '🍜',
  ),
  FoodAvatarPreset(
    name: 'Fresh Bakery',
    url: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=240&auto=format&fit=crop&q=80',
    emoji: '🥐',
  ),
  FoodAvatarPreset(
    name: 'Healthy Bowl',
    url: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=240&auto=format&fit=crop&q=80',
    emoji: '🥗',
  ),
  FoodAvatarPreset(
    name: 'Artisan Coffee',
    url: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=240&auto=format&fit=crop&q=80',
    emoji: '☕',
  ),
  FoodAvatarPreset(
    name: 'Sweet Treats',
    url: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=240&auto=format&fit=crop&q=80',
    emoji: '🍰',
  ),
  FoodAvatarPreset(
    name: 'Sushi Feast',
    url: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=240&auto=format&fit=crop&q=80',
    emoji: '🍣',
  ),
  FoodAvatarPreset(
    name: 'Crunchy Taco',
    url: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=240&auto=format&fit=crop&q=80',
    emoji: '🌮',
  ),
  FoodAvatarPreset(
    name: 'Chef Passion',
    url: 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=240&auto=format&fit=crop&q=80',
    emoji: '👨‍🍳',
  ),
  FoodAvatarPreset(
    name: 'Berry Smoothie',
    url: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=240&auto=format&fit=crop&q=80',
    emoji: '🍓',
  ),
  FoodAvatarPreset(
    name: 'Avocado Toast',
    url: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=240&auto=format&fit=crop&q=80',
    emoji: '🥑',
  ),
];

/// Modal bottom sheet allowing customers to change their profile picture via:
/// 1. Curated food presets
/// 2. Device/computer file upload
/// 3. Custom web URL
/// 4. Reset/remove photo
class ChangeAvatarSheet extends ConsumerStatefulWidget {
  const ChangeAvatarSheet({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<ChangeAvatarSheet> createState() => _ChangeAvatarSheetState();
}

class _ChangeAvatarSheetState extends ConsumerState<ChangeAvatarSheet> {
  late String? _selectedUrl;
  bool _isSaving = false;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.profile.avatarUrl;
  }

  Future<void> _handleDeviceUpload() async {
    setState(() => _isPickingFile = true);
    try {
      final dataUrl = await pickImageFromDevice();
      if (mounted && dataUrl != null) {
        setState(() {
          _selectedUrl = dataUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);

    String? finalAvatarUrl =
        (_selectedUrl != null && _selectedUrl!.trim().isNotEmpty)
            ? _selectedUrl!.trim()
            : null;

    // If image was selected from device (base64 data URL), upload to Supabase Storage
    if (finalAvatarUrl != null && finalAvatarUrl.startsWith('data:image')) {
      try {
        final commaIndex = finalAvatarUrl.indexOf(',');
        if (commaIndex != -1) {
          final header = finalAvatarUrl.substring(0, commaIndex);
          final base64Data = finalAvatarUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64Data);

          String mimeType = 'image/jpeg';
          String extension = 'jpg';
          if (header.contains('image/png')) {
            mimeType = 'image/png';
            extension = 'png';
          } else if (header.contains('image/webp')) {
            mimeType = 'image/webp';
            extension = 'webp';
          }

          final filePath = '${widget.profile.id}/avatar.$extension';
          final storage = Supabase.instance.client.storage
              .from(SupabaseConstants.bucketAvatars);

          await storage.uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mimeType,
            ),
          );

          final rawUrl = storage.getPublicUrl(filePath);
          // Append timestamp query parameter to bust image caching
          finalAvatarUrl = '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        }
      } catch (storageError) {
        debugPrint('[SaveBite] Supabase Storage upload notice: $storageError. Falling back to local data URL.');
        // If Supabase cloud storage bucket is unavailable/restricted, gracefully keep the base64 data URL
      }
    }

    final resolvedFullName = (widget.profile.fullName != null &&
            widget.profile.fullName!.trim().isNotEmpty)
        ? widget.profile.fullName!.trim()
        : [widget.profile.firstName, widget.profile.lastName]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(' ');

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          id: widget.profile.id,
          fullName: resolvedFullName.isNotEmpty ? resolvedFullName : 'Customer',
          phone: widget.profile.phone,
          avatarUrl: finalAvatarUrl,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile picture.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomInset + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Change Profile Picture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Live Preview Card
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarUrl: _selectedUrl,
                      name: widget.profile.fullName,
                      radius: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Preview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedUrl == null || _selectedUrl!.isEmpty
                                ? 'Using your default initials monogram'
                                : (_selectedUrl!.startsWith('data:image')
                                      ? 'Custom photo from device'
                                      : 'Custom foodie photo selected'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedUrl != null && _selectedUrl!.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Remove'),
                        onPressed: () {
                          setState(() {
                            _selectedUrl = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: Upload from device
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: _isPickingFile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.primary,
                      ),
                label: Text(
                  _isPickingFile
                      ? 'Selecting Photo...'
                      : 'Upload Photo from Device',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: _isPickingFile ? null : _handleDeviceUpload,
              ),
              const SizedBox(height: 20),

              // Option 2: Curated Foodie Presets
              const Row(
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Choose a Foodie Avatar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 102,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kFoodAvatarPresets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final preset = kFoodAvatarPresets[index];
                    final isSelected = _selectedUrl == preset.url;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUrl = preset.url;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 76,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      preset.url,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Text(
                                                  preset.emoji,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              PrimaryButton(
                text: 'Save Profile Picture',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveAvatar,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
