import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/platform_file_picker.dart';
import '../../../core/widgets/primary_button.dart';
import '../../shared/models/restaurant.dart';
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
    name: 'Bengali Kitchen',
    url: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&auto=format&fit=crop&q=80',
  ),
  RestaurantPhotoPreset(
    name: 'Burger Joint',
    url: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600&auto=format&fit=crop&q=80',
  ),
  RestaurantPhotoPreset(
    name: 'Pizzeria & Oven',
    url: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&auto=format&fit=crop&q=80',
  ),
  RestaurantPhotoPreset(
    name: 'Bakery & Cafe',
    url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop&q=80',
  ),
  RestaurantPhotoPreset(
    name: 'Coffee Bistro',
    url: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&auto=format&fit=crop&q=80',
  ),
  RestaurantPhotoPreset(
    name: 'Grill & BBQ',
    url: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&auto=format&fit=crop&q=80',
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

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(currentRestaurantProvider);
    final actionState = ref.watch(restaurantActionNotifierProvider);
    final isSaving = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
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

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Completeness Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isComplete
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isComplete
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFDE68A),
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
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isComplete
                                      ? 'Profile Complete & Ready'
                                      : 'Profile Incomplete - Action Required',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isComplete
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isComplete
                                      ? 'Your restaurant profile is 100% complete with photo, division, and area info. You are fully eligible to post surplus food offers!'
                                      : 'Without a complete profile (including profile picture, division, area, address, and phone), you cannot post any food offers in SaveBite.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isComplete
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFB45309),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Restaurant Profile Picture Section
                    Text(
                      'Restaurant Profile Picture *',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload your storefront, kitchen, or logo so customers can recognize your restaurant.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Picture Preview Card
                    Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasProfilePic
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                          width: hasProfilePic ? 1.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          children: [
                            if (hasProfilePic)
                              Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              Container(
                                color: const Color(0xFFF8FAFC),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 38,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No profile picture uploaded yet',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Required to place posts and offers',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (hasProfilePic)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.6),
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
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: _isPickingFile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(
                        _isPickingFile
                            ? 'Selecting Image...'
                            : 'Upload Photo from Device',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isPickingFile ? null : _handleDeviceUpload,
                    ),
                    const SizedBox(height: 12),

                    // Photo Presets
                    const Text(
                      'Or choose a restaurant photo preset:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
                                    Image.network(
                                      preset.url,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      color: Colors.black.withValues(
                                        alpha: isSelected ? 0.3 : 0.45,
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
                    const SizedBox(height: 24),

                    // Restaurant Info Form
                    Text(
                      'Location & Business Info',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Restaurant Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name *',
                        prefixIcon: Icon(Icons.storefront_outlined),
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
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
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
                            decoration: const InputDecoration(
                              labelText: 'Division *',
                              prefixIcon: Icon(Icons.location_city_rounded),
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
                            decoration: const InputDecoration(
                              labelText: 'Area *',
                              prefixIcon: Icon(Icons.place_rounded),
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
                      decoration: const InputDecoration(
                        labelText: 'Detailed Street Address *',
                        prefixIcon: Icon(Icons.navigation_outlined),
                        hintText: 'House 14, Road 7, Dhanmondi, Dhaka',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Street address is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Cuisine Type
                    TextFormField(
                      controller: _cuisineController,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine Type *',
                        prefixIcon: Icon(Icons.restaurant_outlined),
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
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Description',
                        prefixIcon: Icon(Icons.description_outlined),
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
                            decoration: const InputDecoration(
                              labelText: 'Opening Time',
                              prefixIcon: Icon(Icons.schedule_rounded),
                              hintText: '10:00 AM',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _closingTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Closing Time',
                              prefixIcon: Icon(Icons.schedule_rounded),
                              hintText: '11:00 PM',
                            ),
                          ),
                        ),
                      ],
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
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
