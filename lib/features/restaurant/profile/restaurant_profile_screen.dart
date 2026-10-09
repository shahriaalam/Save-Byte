import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/platform_file_picker.dart';
import '../../../core/widgets/double_pull_reload.dart';
import '../../../core/widgets/primary_button.dart';
import '../../shared/models/restaurant.dart';
import '../../shared/data/order_controller.dart';
import '../presentation/restaurant_controller.dart';

/// Curated restaurant preset photos
class RestaurantPhotoPreset {
  const RestaurantPhotoPreset({
    required this.name,
    required this.url,
  });

  final String name;
  final String url;
}

const List<RestaurantPhotoPreset> kRestaurantPhotoPresets = [
  RestaurantPhotoPreset(
    name: 'Biryani & Kabab',
    url: 'assets/images/biryani_logo.jpg',
  ),
  RestaurantPhotoPreset(
    name: 'Burger Hub',
    url: 'assets/images/burger_hub_logo.jpg',
  ),
  RestaurantPhotoPreset(
    name: 'Woodfire Pizza',
    url: 'assets/images/woodfire_crust_logo.jpg',
  ),
  RestaurantPhotoPreset(
    name: 'Hot & Crispy',
    url: 'assets/images/hot_crispy_logo.jpg',
  ),
  RestaurantPhotoPreset(
    name: 'Bakery & Sweets',
    url: 'assets/images/bakery_logo.jpg',
  ),
  RestaurantPhotoPreset(
    name: 'Bistro & Coffee',
    url: 'assets/images/blue_bell_logo.jpg',
  ),
];

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  ConsumerState<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState
    extends ConsumerState<RestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _cuisineController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;

  String _selectedDivision = 'Dhaka';
  String? _selectedArea;
  String? _imageUrl;
  bool _isPickingFile = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
    _cuisineController = TextEditingController();
    _openingTimeController = TextEditingController();
    _closingTimeController = TextEditingController();
  }

  void _populateData(Restaurant restaurant) {
    if (_initialized) return;
    _nameController.text = restaurant.name;
    _phoneController.text = restaurant.phone ?? '';
    _addressController.text = restaurant.address ?? '';
    _descriptionController.text = restaurant.description ?? '';
    _cuisineController.text = restaurant.cuisineType ?? 'Bengali';
    _openingTimeController.text = restaurant.openingTime ?? '10:00 AM';
    _closingTimeController.text = restaurant.closingTime ?? '11:00 PM';
    _selectedDivision = restaurant.division ?? 'Dhaka';
    _selectedArea = restaurant.area;
    _imageUrl = restaurant.imageUrl;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _cuisineController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleDeviceUpload() async {
    setState(() => _isPickingFile = true);
    try {
      final dataUrl = await pickImageWithPermission(context);
      if (mounted && dataUrl != null) {
        setState(() {
          _imageUrl = dataUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
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

  Future<void> _handleSave(Restaurant original) async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrl == null || _imageUrl!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a restaurant profile picture to complete your profile.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedArea == null || _selectedArea!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Area in Dhaka for your restaurant location.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String? finalImageUrl = _imageUrl?.trim();

    // If image is a local base64 data URL, upload to Supabase Storage if available
    if (finalImageUrl != null && finalImageUrl.startsWith('data:image')) {
      try {
        final commaIndex = finalImageUrl.indexOf(',');
        if (commaIndex != -1) {
          final header = finalImageUrl.substring(0, commaIndex);
          final base64Data = finalImageUrl.substring(commaIndex + 1);
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

          final filePath = 'restaurants/${original.id}/profile.$extension';
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
          finalImageUrl = '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        }
      } catch (e) {
        debugPrint('Supabase storage upload notice: $e');
        // Graceful fallback: keep the base64 data URL
      }
    }

    final updated = original.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      division: _selectedDivision,
      area: _selectedArea?.trim(),
      cuisineType: _cuisineController.text.trim(),
      description: _descriptionController.text.trim(),
      openingTime: _openingTimeController.text.trim(),
      closingTime: _closingTimeController.text.trim(),
      imageUrl: finalImageUrl,
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(restaurantActionNotifierProvider.notifier)
        .updateProfile(updated);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update restaurant profile.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _quickFillBlueBell() {
    setState(() {
      _nameController.text = 'Blue Bell Café';
      _phoneController.text = '01711234567';
      _addressController.text = 'House 14, Road 4, Block D, Banasree, Dhaka';
      _selectedDivision = 'Dhaka';
      _selectedArea = 'Banasree';
      _cuisineController.text = 'Specialty Coffee & Italian Bistro';
      _descriptionController.text =
          'Artisanal Coffee Roastery & Italian Bistro in Banasree. Handcrafted pasta, slow-roasted beans, sourdough sandwiches, and signature tiramisu.';
      _openingTimeController.text = '07:30 AM';
      _closingTimeController.text = '11:00 PM';
      _imageUrl =
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Filled Blue Bell Café info!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 15,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(currentRestaurantProvider);
    final actionState = ref.watch(restaurantActionNotifierProvider);
    final isSaving = actionState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Restaurant Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          restaurantAsync.when(
            data: (restaurant) {
              if (restaurant == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: InkWell(
                    onTap: isSaving ? null : () => _handleSave(restaurant),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSaving)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          const SizedBox(width: 5),
                          Text(
                            isSaving ? 'Saving' : 'Save',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: restaurantAsync.when(
        data: (restaurant) {
          if (restaurant == null) {
            return const Center(child: Text('Restaurant account not found.'));
          }
          _populateData(restaurant);

          final areas = LocationConstants.getAreasForDivision(_selectedDivision);
          final hasProfilePic = _imageUrl != null && _imageUrl!.trim().isNotEmpty;
          final isComplete = restaurant.isProfileComplete;

          return DoublePullReload(
            onReload: () async {
              ref.invalidate(currentRestaurantProvider);
              await ref.read(currentRestaurantProvider.future);
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 50),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // 1. WARM PEACH / RED BRAND IDENTITY HEADER
                    // (Matching User Profile Interface conduct)
                    // ==========================================
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFECE5),
                            Color(0xFFFFF7F2),
                            Colors.white,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(
                          children: [
                            // Circular Avatar with Red Accent Ring & Camera Badge
                            GestureDetector(
                              onTap: _handleDeviceUpload,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary, width: 2.8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: const Color(0xFFFFECE5),
                                      backgroundImage: (hasProfilePic && !_imageUrl!.startsWith('assets/'))
                                          ? NetworkImage(_imageUrl!)
                                          : null,
                                      child: (hasProfilePic && _imageUrl!.startsWith('assets/'))
                                          ? ClipOval(
                                              child: Image.asset(
                                                _imageUrl!,
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : (!hasProfilePic
                                              ? const Icon(Icons.storefront_rounded, size: 34, color: AppColors.primary)
                                              : null),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          restaurant.name,
                                          style: const TextStyle(
                                            fontSize: 18.5,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.verified_rounded, size: 17, color: AppColors.primary),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_cuisineController.text.isNotEmpty ? _cuisineController.text : "Restaurant Partner"} • ${_selectedArea ?? "Dhaka"}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isComplete ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isComplete ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isComplete ? Icons.verified_rounded : Icons.info_outline_rounded,
                                          size: 12,
                                          color: isComplete ? const Color(0xFF059669) : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isComplete ? 'Profile Complete' : 'Profile Incomplete',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isComplete ? const Color(0xFF047857) : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile Completeness Status Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isComplete
                                    ? const Color(0xFFBBF7D0)
                                    : const Color(0xFFFECDD3),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isComplete
                                      ? Icons.verified_rounded
                                      : Icons.warning_amber_rounded,
                                  color: isComplete
                                      ? const Color(0xFF16A34A)
                                      : AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isComplete
                                            ? 'Profile Complete & Ready'
                                            : 'Profile Incomplete - Action Required',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isComplete
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFF9F1239),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isComplete
                                            ? 'Your restaurant profile is 100% complete with photo, division, and area info. You are fully eligible to post food offers!'
                                            : 'Without a complete profile (including profile picture, division, area, address, and phone), you cannot post any food offers in SaveBite.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isComplete
                                              ? const Color(0xFF166534)
                                              : const Color(0xFFBE123C),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Live Takeaway Profit & Sales Card
                          Consumer(
                            builder: (context, ref, _) {
                              final stats = ref.watch(restaurantSalesStatsProvider(restaurant.id));
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.025),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Takeaway Profit & Revenue',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '৳${stats.totalRevenue.toStringAsFixed(0)} earned • ${stats.totalPortionsSold} portions sold (${stats.activeOrdersCount} active)',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // ==========================================
                          // SECTION 1: RESTAURANT BRAND & LOGO
                          // ==========================================
                          _buildSectionHeader('RESTAURANT BRAND & LOGO'),
                          _buildCardContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Restaurant Logo *',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Upload your official restaurant logo so customers can recognize your shop.',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      foregroundColor: AppColors.primary,
                                      backgroundColor: const Color(0xFFFFF1F2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: Color(0xFFFECDD3)),
                                      ),
                                    ),
                                    icon: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary),
                                    label: const Text(
                                      'Quick Fill (Blue Bell Café)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    onPressed: _quickFillBlueBell,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Picture Preview Card
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: hasProfilePic
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: hasProfilePic ? 1.8 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      fit: StackFit.expand,
                                      children: [
                                        if (hasProfilePic)
                                          _imageUrl!.startsWith('assets/')
                                              ? Image.asset(
                                                  _imageUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Center(
                                                    child: Icon(
                                                      Icons.broken_image_rounded,
                                                      size: 40,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                )
                                              : Image.network(
                                                  _imageUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Center(
                                                    child: Icon(
                                                      Icons.broken_image_rounded,
                                                      size: 40,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                )
                                        else
                                          const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 36,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'No logo uploaded yet',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Required to place posts and offers',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (hasProfilePic)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Material(
                                              color: Colors.black.withValues(alpha: 0.65),
                                              shape: const CircleBorder(),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                tooltip: 'Remove Picture',
                                                onPressed: () {
                                                  setState(() => _imageUrl = null);
                                                },
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Device Upload Button
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                  ),
                                  icon: _isPickingFile
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.upload_file_rounded,
                                          size: 18, color: AppColors.primary),
                                  label: Text(
                                    _isPickingFile
                                        ? 'Selecting Image...'
                                        : 'Upload Logo from Device',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: _isPickingFile ? null : _handleDeviceUpload,
                                ),
                                const SizedBox(height: 14),

                                // Logo Presets
                                const Text(
                                  'Or choose a brand logo preset:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 72,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: kRestaurantPhotoPresets.length,
                                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      final preset = kRestaurantPhotoPresets[idx];
                                      final isSelected = _imageUrl == preset.url;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() => _imageUrl = preset.url);
                                        },
                                        child: Container(
                                          width: 90,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : const Color(0xFFE2E8F0),
                                              width: isSelected ? 2.5 : 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(4),
                                                  child: preset.url.startsWith('assets/')
                                                      ? Image.asset(
                                                          preset.url,
                                                          fit: BoxFit.contain,
                                                        )
                                                      : Image.network(
                                                          preset.url,
                                                          fit: BoxFit.contain,
                                                        ),
                                                ),
                                                Container(
                                                  color: Colors.black.withValues(
                                                    alpha: isSelected ? 0.35 : 0.45,
                                                  ),
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets.all(2),
                                                  child: Text(
                                                    preset.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Align(
                                                    alignment: Alignment.topRight,
                                                    child: Padding(
                                                      padding: EdgeInsets.all(4),
                                                      child: Icon(
                                                        Icons.check_circle_rounded,
                                                        color: AppColors.primary,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ==========================================
                          // SECTION 2: LOCATION & BUSINESS INFO
                          // ==========================================
                          _buildSectionHeader('LOCATION & BUSINESS INFO'),
                          _buildCardContainer(
                            child: Column(
                              children: [
                                // Restaurant Name
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Restaurant Name *',
                                    prefixIcon: Icons.storefront_outlined,
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Restaurant name is required'
                                      : null,
                                ),
                                const SizedBox(height: 14),

                                // Phone Number
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Contact Phone Number *',
                                    prefixIcon: Icons.phone_outlined,
                                    hintText: '017XXXXXXXX',
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Phone number is required'
                                      : null,
                                ),
                                const SizedBox(height: 14),

                                // Division & Area Row (Dhaka, Bangladesh focus)
                                Row(
                                  children: [
                                    // Division Dropdown
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _selectedDivision,
                                        isExpanded: true,
                                        decoration: _buildInputDecoration(
                                          labelText: 'Division *',
                                          prefixIcon: Icons.location_city_rounded,
                                        ),
                                        items: [
                                          for (final div in LocationConstants.divisions)
                                            DropdownMenuItem(
                                              value: div,
                                              child: Text(div, overflow: TextOverflow.ellipsis),
                                            ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedDivision = val;
                                              _selectedArea = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Area Dropdown
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: areas.contains(_selectedArea)
                                            ? _selectedArea
                                            : null,
                                        decoration: _buildInputDecoration(
                                          labelText: 'Area *',
                                          prefixIcon: Icons.place_rounded,
                                          hintText: 'Select Area',
                                        ),
                                        items: [
                                          for (final area in areas)
                                            DropdownMenuItem(
                                              value: area,
                                              child: Text(area, overflow: TextOverflow.ellipsis),
                                            ),
                                        ],
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Area is required'
                                            : null,
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedArea = val;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Detailed Address
                                TextFormField(
                                  controller: _addressController,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Detailed Street Address *',
                                    prefixIcon: Icons.navigation_outlined,
                                    hintText: 'House 14, Road 7, Dhanmondi, Dhaka',
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Street address is required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ==========================================
                          // SECTION 3: CUISINE & OPERATING HOURS
                          // ==========================================
                          _buildSectionHeader('CUISINE & OPERATING HOURS'),
                          _buildCardContainer(
                            child: Column(
                              children: [
                                // Cuisine Type
                                TextFormField(
                                  controller: _cuisineController,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Cuisine Type *',
                                    prefixIcon: Icons.restaurant_outlined,
                                    hintText: 'Bengali / Fast Food / Bakery / Pizza',
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Cuisine type is required'
                                      : null,
                                ),
                                const SizedBox(height: 14),

                                // Description
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 2,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Restaurant Description',
                                    prefixIcon: Icons.description_outlined,
                                    hintText: 'Authentic local cuisine, fresh daily snacks...',
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Operating Hours Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _openingTimeController,
                                        decoration: _buildInputDecoration(
                                          labelText: 'Opening Time',
                                          prefixIcon: Icons.schedule_rounded,
                                          hintText: '10:00 AM',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _closingTimeController,
                                        decoration: _buildInputDecoration(
                                          labelText: 'Closing Time',
                                          prefixIcon: Icons.schedule_rounded,
                                          hintText: '11:00 PM',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Save Button
                          PrimaryButton(
                            text: 'Save Restaurant Profile',
                            isLoading: isSaving,
                            onPressed: isSaving ? null : () => _handleSave(restaurant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
