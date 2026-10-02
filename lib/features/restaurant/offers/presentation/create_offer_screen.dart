import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/platform_file_picker.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../shared/models/food_offer.dart';
import '../../../shared/models/restaurant.dart';
import '../../presentation/restaurant_controller.dart';
import '../../profile/widgets/food_photo_presets.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '5');

  String _selectedCategory = 'Rice';
  int _selectedHoursUntilExpiry = 3;
  String? _imageUrl;
  bool _isPickingFile = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _handleDeviceUpload() async {
    setState(() => _isPickingFile = true);
    try {
      final dataUrl = await pickImageFromDevice();
      if (mounted && dataUrl != null) {
        setState(() {
          _imageUrl = dataUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: $e'),
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

  Future<void> _handlePublish(Restaurant restaurant) async {
    if (!_formKey.currentState!.validate()) return;

    final origPrice = double.tryParse(_originalPriceController.text.trim()) ?? 0;
    final discPrice = double.tryParse(_discountedPriceController.text.trim()) ?? 0;

    if (discPrice >= origPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discounted price must be less than original price.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String? finalImageUrl = _imageUrl;

    // Upload base64 data URL to Supabase Storage if available
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
          }

          final filePath = 'offers/${restaurant.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
          final storage = Supabase.instance.client.storage
              .from(SupabaseConstants.bucketAvatars);

          await storage.uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: mimeType),
          );

          finalImageUrl = storage.getPublicUrl(filePath);
        }
      } catch (e) {
        debugPrint('Supabase offer image upload notice: $e');
      }
    }

    // Default category fallback photo if none selected
    finalImageUrl ??= kFoodPhotoPresets
        .firstWhere((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase(),
            orElse: () => kFoodPhotoPresets.first)
        .url;

    final newOffer = FoodOffer(
      id: 'offer_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      restaurantAddress: restaurant.address,
      division: restaurant.division ?? 'Dhaka',
      area: restaurant.area,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      originalPrice: origPrice,
      discountedPrice: discPrice,
      quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
      availableFrom: DateTime.now(),
      availableUntil: DateTime.now().add(Duration(hours: _selectedHoursUntilExpiry)),
      imageUrl: finalImageUrl,
      isActive: true,
      adminBlocked: false,
    );

    final success = await ref
        .read(restaurantActionNotifierProvider.notifier)
        .createOffer(newOffer);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surplus food offer posted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final err = ref.read(restaurantActionNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Failed to post offer.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(currentRestaurantProvider);
    final actionState = ref.watch(restaurantActionNotifierProvider);
    final isPublishing = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Surplus Food'),
      ),
      body: restaurantAsync.when(
        data: (restaurant) {
          if (restaurant == null) {
            return const Center(child: Text('Restaurant profile not found.'));
          }

          // STRICT CHECK: IF RESTAURANT PROFILE IS NOT COMPLETE, BLOCK POSTING
          if (!restaurant.isProfileComplete) {
            return _buildIncompleteProfileBlocker(context, restaurant);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Restaurant identity chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: restaurant.imageUrl != null
                                ? NetworkImage(restaurant.imageUrl!)
                                : null,
                            child: restaurant.imageUrl == null
                                ? const Icon(Icons.storefront_rounded, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${restaurant.area ?? 'Dhaka'}, ${restaurant.division ?? 'Dhaka'}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Verified Partner',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Offer Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Food Offer Title *',
                        hintText: 'e.g. Chicken Biryani, Butter Croissant Box',
                        prefixIcon: Icon(Icons.fastfood_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please provide a title for the food offer'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Food Category *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final cat in AppConstants.categories)
                          DropdownMenuItem(value: cat, child: Text(cat)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Price Row
                    Row(
                      children: [
                        // Original Price
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Original Price (৳) *',
                              prefixIcon: Icon(Icons.money_off_rounded),
                              hintText: '250',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final val = double.tryParse(v.trim());
                              if (val == null || val <= 0) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Discounted Surplus Price
                        Expanded(
                          child: TextFormField(
                            controller: _discountedPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Surplus Price (৳) *',
                              prefixIcon: Icon(Icons.local_offer_outlined),
                              hintText: '120',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final val = double.tryParse(v.trim());
                              if (val == null || val <= 0) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quantity and Expiry Row
                    Row(
                      children: [
                        // Quantity
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Portions Available *',
                              prefixIcon: Icon(Icons.format_list_numbered_rounded),
                              hintText: '5',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final val = int.tryParse(v.trim());
                              if (val == null || val <= 0) return 'Min 1';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Expiry Duration
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedHoursUntilExpiry,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Available For *',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1 Hour')),
                              DropdownMenuItem(value: 2, child: Text('2 Hours')),
                              DropdownMenuItem(value: 3, child: Text('3 Hours')),
                              DropdownMenuItem(value: 4, child: Text('4 Hours')),
                              DropdownMenuItem(value: 6, child: Text('6 Hours')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedHoursUntilExpiry = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Food Image Upload / Preset
                    Text(
                      'Food Item Photo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    if (_imageUrl != null && _imageUrl!.isNotEmpty)
                      Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(_imageUrl!, fit: BoxFit.cover),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.white),
                                  onPressed: () => setState(() => _imageUrl = null),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: _isPickingFile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: const Text('Upload Photo from Device'),
                      onPressed: _isPickingFile ? null : _handleDeviceUpload,
                    ),
                    const SizedBox(height: 10),

                    // Presets
                    const Text(
                      'Or choose a food category preset:',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kFoodPhotoPresets.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final preset = kFoodPhotoPresets[idx];
                          final isSelected = _imageUrl == preset.url;
                          return GestureDetector(
                            onTap: () => setState(() => _imageUrl = preset.url),
                            child: Container(
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(preset.url, fit: BoxFit.cover),
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      alignment: Alignment.center,
                                      child: Text(
                                        preset.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
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
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g. Fresh lunch surplus packaged safely in takeaway container.',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Publish Button
                    PrimaryButton(
                      text: 'Publish Surplus Food Post',
                      isLoading: isPublishing,
                      onPressed: isPublishing ? null : () => _handlePublish(restaurant),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading restaurant: $err')),
      ),
    );
  }

  /// UI displayed when the restaurant's profile is incomplete, preventing any post placement
  Widget _buildIncompleteProfileBlocker(BuildContext context, Restaurant restaurant) {
    final missing = restaurant.missingProfileFields;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: Color(0xFFD97706),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Complete Your Profile First',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'To maintain quality and safety in Dhaka, restaurants cannot place food posts until their profile is completely filled out.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Missing Required Items:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in missing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 14,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Complete Restaurant Profile',
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: () {
                  context.push(AppRoutes.restaurantProfile);
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
