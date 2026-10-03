import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/platform_file_picker.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/data/promo_banner_controller.dart';
import '../../shared/models/promo_banner.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final promoBannersAsync = ref.watch(promoBannersControllerProvider);
    final banners =
        promoBannersAsync.asData?.value ?? PromoBanner.defaultBanners;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Log Out',
                message: 'Are you sure you want to log out of Admin Console?',
                confirmLabel: 'Log Out',
              );
              if (confirmed) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Profile Info Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Management',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile?.email ?? 'Administrator',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(
                    label: 'ADMIN',
                    backgroundColor: Color(0xFFE0E7FF),
                    textColor: Color(0xFF3730A3),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ========================================================
              // PROMOTIONAL HERO BANNERS MANAGEMENT SECTION
              // ========================================================
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.view_carousel_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Promotional Hero Banners',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F0F10),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Customer Home Slideshow (Admin Exclusive)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final confirmed = await ConfirmDialog.show(
                                context,
                                title: 'Reset Banners',
                                message:
                                    'Reset all 3 promotional banners to default deals?',
                                confirmLabel: 'Reset Defaults',
                              );
                              if (confirmed) {
                                await ref
                                    .read(promoBannersControllerProvider
                                        .notifier)
                                    .resetToDefaults();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Banners reset to default promotional deals.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Only administrators can change or place these 3 banners. Updates appear immediately on the customer home screen to drive customer engagement.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const Divider(height: 24),

                      // List of 3 Promotional Banners
                      for (int i = 0; i < banners.length; i++) ...[
                        _buildAdminBannerCard(context, ref, banners[i], i + 1),
                        if (i < banners.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Platform Moderation Info
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moderator Access Active',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Full administrative authority for surplus deal curation, banner promotions, restaurant approvals, and platform compliance.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBannerCard(
    BuildContext context,
    WidgetRef ref,
    PromoBanner banner,
    int slotNumber,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF880015),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SLOT #$slotNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF08A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        banner.badge,
                        style: const TextStyle(
                          color: Color(0xFF78350F),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: banner.gradient,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${PromoBanner.availableThemes[banner.themeKey]?.emoji ?? '🎨'} ${PromoBanner.availableThemes[banner.themeKey]?.name ?? 'Theme'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openEditBannerSheet(context, ref, banner),
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: const Text('Edit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            banner.bannerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F0F10),
            ),
          ),
          const SizedBox(height: 8),
          // Direct Banner Graphic Preview Card
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: banner.startColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                ? _buildAdminImagePreview(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      'No image uploaded yet.\nTap "Edit" to attach banner image.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openEditBannerSheet(
    BuildContext context,
    WidgetRef ref,
    PromoBanner banner,
  ) {
    final nameController = TextEditingController(text: banner.bannerName);
    final imageUrlController =
        TextEditingController(text: banner.imageUrl ?? '');
    String selectedTheme = banner.themeKey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.photo_size_select_actual_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Promotional Banner (${banner.id})',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload your banner picture, give it a name, and pick the matching app top background.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Banner Name
                    const Text('Banner Name',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. International Coffee Day - North End 10% OFF',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Banner Picture (PNG/JPG)
                    const Text('Banner Picture (PNG/JPG)',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                      'This image will be displayed directly as the banner on the customer home screen.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imageUrlController,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              hintText: 'assets/images/coffee_day_banner.jpg or URL',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final dataUrl = await pickImageFromDevice();
                            if (dataUrl != null) {
                              imageUrlController.text = dataUrl;
                              setSheetState(() {});
                            }
                          },
                          icon: const Icon(Icons.photo_library_rounded, size: 16),
                          label: const Text('Pick Image', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Presets
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('☕ Coffee Day (North End)',
                              style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            imageUrlController.text =
                                'assets/images/coffee_day_banner.jpg';
                            nameController.text =
                                'International Coffee Day - North End 10% OFF';
                            selectedTheme = 'coffee';
                            setSheetState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('🥬 Fresh Surplus',
                              style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            imageUrlController.text =
                                'assets/images/fresh_surplus_banner.jpg';
                            nameController.text =
                                'Fresh Surplus & Groceries';
                            selectedTheme = 'teal';
                            setSheetState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('🧀 Payday Feast',
                              style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            imageUrlController.text =
                                'assets/images/payday_feast_banner.jpg';
                            nameController.text =
                                'Pay Day Special - 55% to 75% OFF';
                            selectedTheme = 'yellow';
                            setSheetState(() {});
                          },
                        ),
                        if (imageUrlController.text.isNotEmpty)
                          ActionChip(
                            label: const Text('❌ Clear',
                                style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              imageUrlController.clear();
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Live Banner Preview Card
                    const Text('Live Banner Preview Card',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(int.parse(PromoBanner.availableThemes[selectedTheme]?.start ?? '0xFF3E2723')),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrlController.text.trim().isNotEmpty
                          ? _buildAdminImagePreview(
                              imageUrlController.text.trim(),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                nameController.text.trim().isNotEmpty
                                    ? nameController.text.trim()
                                    : 'Banner Preview (No picture selected)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Matching Background Theme
                    const Text(
                      'Matching App Top Background Theme',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'In the user interface, the top background smoothly transitions to this color when this banner is active.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PromoBanner.availableThemes.entries.map((entry) {
                        final key = entry.key;
                        final info = entry.value;
                        final isSelected = key == selectedTheme;
                        final startColor = Color(int.parse(info.start));
                        final endColor = Color(int.parse(info.end));

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedTheme = key);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [startColor, endColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: isSelected ? 2.5 : 0,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: startColor.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(info.emoji,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  info.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Dynamic Transition Bar Preview
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(int.parse(PromoBanner.availableThemes[selectedTheme]?.start ?? '0xFF3E2723')),
                            Color(int.parse(PromoBanner.availableThemes[selectedTheme]?.end ?? '0xFF5D4037')),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.palette_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Active Background: ${PromoBanner.availableThemes[selectedTheme]?.name ?? 'Theme'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          final themeInfo = PromoBanner.availableThemes[selectedTheme] ??
                              PromoBanner.availableThemes['coffee']!;
                          final newName = nameController.text.trim();
                          final newImageUrl = imageUrlController.text.trim();

                          final updated = banner.copyWith(
                            name: newName.isEmpty ? banner.bannerName : newName,
                            title: newName.isEmpty ? banner.title : newName,
                            themeKey: selectedTheme,
                            bgStartColor: themeInfo.start,
                            bgEndColor: themeInfo.end,
                            imageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                            clearImageUrl: newImageUrl.isEmpty,
                          );

                          await ref
                              .read(promoBannersControllerProvider.notifier)
                              .updateBanner(updated);

                          if (sheetCtx.mounted) {
                            Navigator.pop(sheetCtx);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Promotional banner (${banner.id}) updated successfully!'),
                                backgroundColor: const Color(0xFF15803D),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save & Publish Banner',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminImagePreview(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isCircle = false,
  }) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.image,
          size: width != null ? width * 0.6 : 28,
          color: Colors.grey.shade400,
        ),
      );
    }

    Widget imageWidget;
    if (cleanUrl.startsWith('data:image')) {
      try {
        final commaIndex = cleanUrl.indexOf(',');
        final base64Str =
            commaIndex != -1 ? cleanUrl.substring(commaIndex + 1) : cleanUrl;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image, size: width != null ? width * 0.6 : 28, color: Colors.grey),
        );
      } catch (_) {
        imageWidget =
            Icon(Icons.broken_image, size: width != null ? width * 0.6 : 28, color: Colors.grey);
      }
    } else if (cleanUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image, size: width != null ? width * 0.6 : 28, color: Colors.grey),
      );
    } else {
      imageWidget = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image, size: width != null ? width * 0.6 : 28, color: Colors.grey),
      );
    }

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageWidget,
    );
  }
}
