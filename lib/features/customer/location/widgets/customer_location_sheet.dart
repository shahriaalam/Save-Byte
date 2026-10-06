import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/location_constants.dart';
import '../customer_address_controller.dart';
import '../models/customer_address.dart';
import '../user_location_controller.dart';
import 'google_map_preview.dart';

/// Modal bottom sheet allowing the customer to switch delivery location:
/// - Country selector (Bangladesh)
/// - Use my current location (GPS)
/// - Saved address card with stylized Google Map preview (Home)
/// - Add new address
class CustomerLocationSheet extends ConsumerStatefulWidget {
  const CustomerLocationSheet({super.key});

  /// Shows this location selection bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CustomerLocationSheet(),
    );
  }

  @override
  ConsumerState<CustomerLocationSheet> createState() =>
      _CustomerLocationSheetState();
}

class _CustomerLocationSheetState extends ConsumerState<CustomerLocationSheet> {
  bool _isDetectingGps = false;

  Future<void> _handleUseCurrentLocation() async {
    setState(() => _isDetectingGps = true);
    try {
      final area = await ref
          .read(userLocationControllerProvider.notifier)
          .requestPermissionAndDetect();

      final locState = ref.read(userLocationControllerProvider);
      ref.read(customerAddressNotifierProvider.notifier).useCurrentLocation(
            area,
            detectedCity: locState.detectedCity ?? 'Dhaka',
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📍 Set to current location: $area, Dhaka',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not detect location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  void _showChangeCountryDialog() {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Text('🇧🇩 ', style: TextStyle(fontSize: 22)),
              Text('Select Country',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const ListTile(
                  leading: Text('🇧🇩', style: TextStyle(fontSize: 24)),
                  title: Text(
                    'Bangladesh',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'SaveBite is active in Dhaka, Chittagong & Sylhet',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: Icon(Icons.check_circle_rounded,
                      color: Color(0xFF15803D)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'More countries and regional expansions coming soon!',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showAddOrEditAddressSheet({CustomerAddress? existing}) {
    final isEditing = existing != null;
    final labelController = TextEditingController(
        text: existing?.label ?? 'Home');
    final addressLineController = TextEditingController(
        text: existing?.addressLine ?? '2B, House 32, Road 3, Block C Road 3');
    final cityController =
        TextEditingController(text: existing?.city ?? 'Dhaka');
    String selectedArea = existing?.area ?? 'Mirpur';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
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
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isEditing ? 'Edit Address' : 'Add New Address',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Label chips
                    const Text(
                      'Address Label',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Home', 'Office', 'Other'].map((l) {
                        final isSelected = labelController.text == l;
                        return ChoiceChip(
                          label: Text(l),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFE4E6),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              labelController.text = l;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Street Address Field
                    TextField(
                      controller: addressLineController,
                      decoration: InputDecoration(
                        labelText: 'Street Address & Flat / House No. *',
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Area Dropdown in Dhaka
                    DropdownButtonFormField<String>(
                      initialValue: LocationConstants.dhakaAreas
                              .contains(selectedArea)
                          ? selectedArea
                          : LocationConstants.dhakaAreas.first,
                      decoration: InputDecoration(
                        labelText: 'Dhaka Area / Neighborhood *',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: LocationConstants.dhakaAreas.map((a) {
                        return DropdownMenuItem(value: a, child: Text(a));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedArea = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // City
                    TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (addressLineController.text.trim().isEmpty) {
                            return;
                          }
                          final addr = CustomerAddress(
                            id: existing?.id ??
                                'addr-${DateTime.now().millisecondsSinceEpoch}',
                            label: labelController.text.trim(),
                            addressLine: addressLineController.text.trim(),
                            area: selectedArea,
                            city: cityController.text.trim().isEmpty
                                ? 'Dhaka'
                                : cityController.text.trim(),
                            division: 'Dhaka',
                            isDefault: true,
                          );

                          if (isEditing) {
                            ref
                                .read(customerAddressNotifierProvider.notifier)
                                .updateAddress(addr);
                          } else {
                            ref
                                .read(customerAddressNotifierProvider.notifier)
                                .addAddress(addr);
                          }

                          Navigator.pop(modalCtx);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Address updated successfully.'
                                      : 'Address saved and set to active.',
                                ),
                                backgroundColor: const Color(0xFF15803D),
                              ),
                            );
                          }
                        },
                        child: Text(
                          isEditing ? 'Update Address' : 'Save & Select Address',
                          style: const TextStyle(
                            fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(customerAddressNotifierProvider);

    // Ensure Home address is available for the card display
    final homeAddress = addressState.addresses.firstWhere(
      (a) => a.label.toLowerCase() == 'home',
      orElse: () => CustomerAddress.defaultHome,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP DRAG HANDLE
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. COUNTRY SELECTOR ROW
            Row(
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 22,
                  color: Color(0xFF1E293B),
                ),
                const SizedBox(width: 10),
                const Text(
                  '🇧🇩',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bangladesh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _showChangeCountryDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // 3. USE MY CURRENT LOCATION ROW
            InkWell(
              onTap: _isDetectingGps ? null : _handleUseCurrentLocation,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Row(
                  children: [
                    _isDetectingGps
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFFE11D48),
                            ),
                          )
                        : Transform.rotate(
                            angle: 0.785, // 45 degrees pointing top-right
                            child: const Icon(
                              Icons.navigation_outlined,
                              size: 22,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Use my current location',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. HOME ADDRESS CARD WITH GOOGLE MAP PROPER LOCATION
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1E293B),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stylized Google Map Preview
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14.4),
                    ),
                    child: GoogleMapPreview(
                      height: 135,
                      onTapMap: () {
                        // Tapping map sets home address
                        ref
                            .read(customerAddressNotifierProvider.notifier)
                            .selectAddress(homeAddress);
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  // Address Details
                  InkWell(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14.4),
                    ),
                    onTap: () {
                      ref
                          .read(customerAddressNotifierProvider.notifier)
                          .selectAddress(homeAddress);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '📍 Delivery address set to ${homeAddress.label}',
                          ),
                          backgroundColor: const Color(0xFF15803D),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                homeAddress.label,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => _showAddOrEditAddressSheet(
                                  existing: homeAddress,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            homeAddress.addressLine,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          Text(
                            homeAddress.city,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 5. ADD NEW ADDRESS
            InkWell(
              onTap: () => _showAddOrEditAddressSheet(),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 24,
                      color: Color(0xFF0F172A),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
