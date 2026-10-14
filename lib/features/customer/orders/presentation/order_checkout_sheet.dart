import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../shared/data/order_controller.dart';
import '../../../shared/data/promo_code_controller.dart';
import '../../../shared/data/reward_controller.dart';
import '../../../shared/models/food_offer.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/promo_code.dart';
import '../../../shared/models/reward.dart';
import '../../../shared/presentation/payment_portal_sheet.dart';
import '../../../../core/router/app_router.dart';
import 'customer_orders_sheet.dart';

/// Opens the customer order checkout & pickup scheduling bottom sheet.
Future<void> showOrderCheckoutSheet({
  required BuildContext context,
  required FoodOffer offer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => OrderCheckoutSheet(offer: offer),
  );
}

class OrderCheckoutSheet extends ConsumerStatefulWidget {
  const OrderCheckoutSheet({
    required this.offer,
    super.key,
  });

  final FoodOffer offer;

  @override
  ConsumerState<OrderCheckoutSheet> createState() => _OrderCheckoutSheetState();
}

class _OrderCheckoutSheetState extends ConsumerState<OrderCheckoutSheet> {
  int _quantity = 1;
  String _selectedPickupTime = '';
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _promoCtrl = TextEditingController();
  PromoCode? _appliedPromo;
  Reward? _appliedReward;
  bool _isValidatingPromo = false;
  String? _promoError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-calculate initial default pickup time: 30 minutes from now or start of window
    final now = DateTime.now();
    final defaultPickup = now.add(const Duration(minutes: 30));
    _selectedPickupTime = _formatTimeDisplay(defaultPickup);

    // Pre-fill user profile info if logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentUserProfileProvider);
      if (profile != null) {
        if (_nameCtrl.text.isEmpty && profile.fullName != null && profile.fullName!.trim().isNotEmpty) {
          _nameCtrl.text = profile.fullName!.trim();
        }
        if (_phoneCtrl.text.isEmpty && profile.phone != null && profile.phone!.trim().isNotEmpty) {
          _phoneCtrl.text = profile.phone!.trim();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromoCode([String? codeOverride]) async {
    final code = (codeOverride ?? _promoCtrl.text).trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _promoError = 'Please enter a promo code';
      });
      return;
    }

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    final subtotal = widget.offer.discountedPrice * _quantity;
    final result = await ref
        .read(promoCodeControllerProvider.notifier)
        .validatePromo(code: code, orderAmount: subtotal);

    if (!mounted) return;

    if (result.isValid && result.promoCode != null) {
      setState(() {
        _appliedPromo = result.promoCode;
        _appliedReward = null; // Single advantage rule: clear reward when promo is applied
        _promoCtrl.text = result.promoCode!.code;
        _promoError = null;
        _isValidatingPromo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Promo "${result.promoCode!.code}" applied! You save ৳${result.discountAmount.toStringAsFixed(0)} (Platform Sponsored)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      setState(() {
        _promoError = result.message;
        _isValidatingPromo = false;
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromo = null;
      _promoCtrl.clear();
      _promoError = null;
    });
  }

  void _applyReward(Reward reward) {
    final subtotal = widget.offer.discountedPrice * _quantity;
    setState(() {
      _appliedReward = reward;
      _appliedPromo = null; // Single advantage rule: clear promo when reward is applied
      _promoCtrl.clear();
      _promoError = null;
    });

    if (subtotal < reward.minOrderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reward "${reward.title}" selected! Requires min. order of ৳${reward.minOrderAmount.toStringAsFixed(0)}. Add more portions to activate discount.',
          ),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      final discount = reward.calculateDiscount(subtotal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reward "${reward.title}" applied! You save ৳${discount.toStringAsFixed(0)} (Platform Sponsored)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeReward() {
    setState(() {
      _appliedReward = null;
    });
  }

  String _formatTimeDisplay(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return 'Today at $hour:$minute $period';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return 'Today at $hour:$minute $period';
  }

  String _formatWindowTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _pickCustomTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPickupTime = _formatTimeOfDay(picked);
      });
    }
  }

  Future<void> _handleProceedToPayment() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide your name and phone number for pickup contact.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final subtotal = widget.offer.discountedPrice * _quantity;
    double appliedDiscount = 0.0;
    String? discountAdvantageTitle;

    if (_appliedPromo != null && subtotal >= _appliedPromo!.minOrderAmount) {
      appliedDiscount = _appliedPromo!.calculateDiscount(subtotal);
      discountAdvantageTitle = 'Platform voucher "${_appliedPromo!.code}"';
    } else if (_appliedReward != null && subtotal >= _appliedReward!.minOrderAmount) {
      appliedDiscount = _appliedReward!.calculateDiscount(subtotal);
      discountAdvantageTitle = 'Claimed reward "${_appliedReward!.title}"';
    }

    final payableAmount = (subtotal - appliedDiscount) < 0.0 ? 0.0 : (subtotal - appliedDiscount);
    final customerName = _nameCtrl.text.trim();
    final customerPhone = _phoneCtrl.text.trim();

    // 1. Launch the Payment Portal (bKash, Nagad, Card)
    final paymentResult = await showPaymentPortalSheet(
      context: context,
      title: 'Pay & Book Takeaway Order',
      subtitle: '${widget.offer.restaurantName ?? 'Restaurant'} • ${_quantity}x ${widget.offer.title}',
      amount: payableAmount,
      customerOrBusinessName: customerName,
      perkHighlights: [
        'Instant surplus meal booking confirmation',
        'Pickup scheduled: $_selectedPickupTime',
        if (discountAdvantageTitle != null && appliedDiscount > 0)
          '$discountAdvantageTitle applied (-৳${appliedDiscount.toStringAsFixed(0)})',
        'Direct takeaway pickup — zero delivery fees',
      ],
      itemType: 'food_order',
    );

    if (paymentResult == null || !paymentResult.isSuccess) {
      return; // Payment cancelled or failed
    }

    setState(() => _isSubmitting = true);

    try {
      final userProfile = ref.read(currentUserProfileProvider);
      final customerId = userProfile?.id ?? 'demo-customer-id';
      final customerEmail = userProfile?.email ?? '$customerPhone@savebite.app';

      // 2. Persist order & decrement stock & send email
      final createdOrder = await ref.read(orderControllerProvider.notifier).placeOrder(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        restaurantId: widget.offer.restaurantId,
        restaurantName: widget.offer.restaurantName ?? 'Restaurant',
        restaurantAddress: widget.offer.restaurantAddress ?? 'Dhaka',
        offerId: widget.offer.id,
        title: widget.offer.title,
        imageUrl: widget.offer.imageUrl,
        category: widget.offer.category,
        quantity: _quantity,
        unitPrice: widget.offer.discountedPrice,
        originalUnitPrice: widget.offer.originalPrice,
        pickupTime: _selectedPickupTime,
        paymentMethod: paymentResult.gateway?.toUpperCase() ?? 'BKASH',
        transactionId: paymentResult.transactionId,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        promoCode: _appliedPromo?.code ?? _appliedReward?.title,
        discountAmount: appliedDiscount,
      );

      // 3. If a claimed reward was used, mark it as redeemed
      if (_appliedReward != null) {
        await ref.read(rewardControllerProvider.notifier).redeemReward(_appliedReward!.id);
      }

      if (!mounted) return;
      // Close checkout bottom sheet cleanly first
      Navigator.of(context).pop();

      if (createdOrder != null) {
        // Schedule dialog presentation on root navigator context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetContext = rootNavigatorKey.currentContext;
          if (targetContext != null) {
            _showOrderSuccessDialog(targetContext, createdOrder);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  static void _showOrderSuccessDialog(BuildContext targetContext, Order order) {
    final navContext = (targetContext.mounted ? targetContext : rootNavigatorKey.currentContext) ??
        rootNavigatorKey.currentContext ??
        targetContext;

    showDialog<void>(
      context: navContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon with animated pulse look
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A34A),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Booked & Paid! 🎉',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Order #${order.orderNumber}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Pickup Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pickup Code:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Text(
                          'PIN ${order.pickupCode}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.pickupTime,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.restaurantName,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.restaurantAddress,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.promoCode != null && order.discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_number_rounded, size: 13, color: Color(0xFF15803D)),
                          const SizedBox(width: 4),
                          Text(
                            'Promo ${order.promoCode} (-৳${order.discountAmount.toStringAsFixed(0)}) • Paid ৳${order.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Takeaway Reminder
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No home delivery. Please collect your food in person. Email confirmation sent!',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text(
                  'View in My Orders',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  final ordersContext = rootNavigatorKey.currentContext ?? navContext;
                  showCustomerOrdersSheet(context: ordersContext);
                },
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final itemTotal = offer.discountedPrice * _quantity;
    final originalTotal = offer.originalPrice * _quantity;
    final maxAvailable = offer.quantity.clamp(1, 99);

    final rewardsAsync = ref.watch(activeRewardsProvider);
    final claimedRewards = rewardsAsync.value
            ?.where((r) => r.isValid && r.isClaimed && !r.isUsed)
            .toList() ??
        [];

    // Dynamic advantage discount calculation (Single Advantage Rule)
    double appliedDiscount = 0.0;
    bool isRewardMinOrderMet = true;

    if (_appliedPromo != null) {
      if (itemTotal >= _appliedPromo!.minOrderAmount) {
        appliedDiscount = _appliedPromo!.calculateDiscount(itemTotal);
      }
    } else if (_appliedReward != null) {
      if (itemTotal >= _appliedReward!.minOrderAmount) {
        appliedDiscount = _appliedReward!.calculateDiscount(itemTotal);
      } else {
        isRewardMinOrderMet = false;
      }
    }
    final totalPayable = (itemTotal - appliedDiscount) < 0.0 ? 0.0 : (itemTotal - appliedDiscount);
    final totalSavings = (offer.savings * _quantity) + appliedDiscount;

    final now = DateTime.now();
    final in15m = _formatTimeDisplay(now.add(const Duration(minutes: 15)));
    final in30m = _formatTimeDisplay(now.add(const Duration(minutes: 30)));
    final in45m = _formatTimeDisplay(now.add(const Duration(minutes: 45)));
    final in60m = _formatTimeDisplay(now.add(const Duration(minutes: 60)));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Schedule Food Pickup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // STRICT NO HOME DELIVERY BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFB45309),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Self-Pickup Takeaway Only (No Delivery)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'SaveBite is a food rescue platform. Customers must pick up their meals directly from the restaurant in person.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Offer Summary Tile
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    if (offer.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          offer.imageUrl!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 54,
                            height: 54,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.restaurant_rounded, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDEC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fastfood_rounded, color: AppColors.primary),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${offer.restaurantName ?? 'Restaurant'} • ${offer.area ?? 'Dhaka'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '৳${offer.discountedPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '৳${offer.originalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Portion Quantity Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Portions',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${offer.quantity} portions available',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          onPressed: _quantity < maxAvailable
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PICKUP TIME SELECTION (Required)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'When will you pick up?',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Custom Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: _pickCustomTime,
                  ),
                ],
              ),
              Text(
                'Pickup Window: ${_formatWindowTime(offer.availableFrom)} – ${_formatWindowTime(offer.availableUntil)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),

              // Quick Time Selection Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTimeChip('In 15 mins', in15m),
                  _buildTimeChip('In 30 mins', in30m),
                  _buildTimeChip('In 45 mins', in45m),
                  _buildTimeChip('In 1 hour', in60m),
                ],
              ),
              const SizedBox(height: 10),

              // Selected Time Display Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled Pickup: $_selectedPickupTime',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer Contact Info (Name & Phone)
              const Text(
                'Pickup Contact',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter full name',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '01XXXXXXXXX',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Pickup Note / Request (Optional)',
                  hintText: 'e.g. Please pack in paper bag',
                  labelStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),

              // OFFERS & ADVANTAGES SECTION (Single Advantage Rule: 1 Promo OR 1 Claimed Reward)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (_appliedPromo != null || _appliedReward != null)
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFE2E8F0),
                    width: (_appliedPromo != null || _appliedReward != null) ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (_appliedPromo != null || _appliedReward != null)
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                (_appliedPromo != null || _appliedReward != null)
                                    ? Icons.check_circle_rounded
                                    : Icons.local_offer_outlined,
                                size: 16,
                                color: (_appliedPromo != null || _appliedReward != null)
                                    ? const Color(0xFF16A34A)
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Have a Promo Code?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '1 Advantage / Order',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 1. If Promo Code is currently applied
                    if (_appliedPromo != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _appliedPromo!.code,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF15803D),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '-৳${appliedDiscount.toStringAsFixed(0)} OFF',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '🛡️ 100% Platform Sponsored • ${offer.restaurantName ?? 'Restaurant'} receives full payout',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: _removePromoCode,
                            ),
                          ],
                        ),
                      ),
                    ]
                    // 2. If Claimed Reward is currently applied
                    else if (_appliedReward != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isRewardMinOrderMet ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isRewardMinOrderMet ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isRewardMinOrderMet ? Icons.card_giftcard_rounded : Icons.info_outline_rounded,
                              color: isRewardMinOrderMet ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _appliedReward!.title,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: isRewardMinOrderMet
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF92400E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isRewardMinOrderMet) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '-৳${appliedDiscount.toStringAsFixed(0)} OFF',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isRewardMinOrderMet)
                                    Text(
                                      '🛡️ 100% Platform Sponsored • ${offer.restaurantName ?? 'Restaurant'} receives full payout',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF166534),
                                      ),
                                    )
                                  else
                                    Text(
                                      'Requires min. order of ৳${_appliedReward!.minOrderAmount.toStringAsFixed(0)} (Current: ৳${itemTotal.toStringAsFixed(0)}). Add more items to unlock!',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: _removeReward,
                            ),
                          ],
                        ),
                      ),
                    ]
                    // 3. Neither Promo nor Reward is currently applied
                    else ...[
                      // Promo code input row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: _promoCtrl,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter code (e.g. SAVEBITE50)',
                                  hintStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    letterSpacing: 0,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 16),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                ),
                                onSubmitted: (_) => _applyPromoCode(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isValidatingPromo ? null : () => _applyPromoCode(),
                              child: _isValidatingPromo
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Apply',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (_promoError != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _promoError!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Show user's claimed rewards if available
                      if (claimedRewards.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'OR APPLY A CLAIMED REWARD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...claimedRewards.map((reward) {
                          final qualifies = itemTotal >= reward.minOrderAmount;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reward.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${reward.discountTag} • ${reward.requirementTag}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: qualifies ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: qualifies ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () => _applyReward(reward),
                                  child: const Text(
                                    'Use',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Price Calculation Summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Items Subtotal',
                      '৳${itemTotal.toStringAsFixed(0)}',
                      strikethrough: '৳${originalTotal.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _buildSummaryRow('Delivery Fee', '৳0 (Self-Pickup)', isGreen: true),
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Platform Service Fee',
                      'FREE',
                      isGreen: true,
                    ),
                    if (appliedDiscount > 0) ...[
                      const SizedBox(height: 6),
                      _buildSummaryRow(
                        _appliedPromo != null
                            ? 'Promo Discount (${_appliedPromo!.code})'
                            : 'Reward Discount (${_appliedReward!.title})',
                        '-৳${appliedDiscount.toStringAsFixed(0)}',
                        isGreen: true,
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🛡️ App authority sponsored • ${offer.restaurantName ?? 'Restaurant'} receives 100% payout',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Payable',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Pay online to book food',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৳${totalPayable.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            if (totalSavings > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Saved ৳${totalSavings.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payment_rounded, size: 20),
                  label: Text(
                    _isSubmitting
                        ? 'Processing...'
                        : 'Proceed to Pay ৳${totalPayable.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleProceedToPayment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String formattedTime) {
    final isSelected = _selectedPickupTime == formattedTime;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _selectedPickupTime = formattedTime;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    String? strikethrough,
    bool isGreen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
          ),
        ),
        Row(
          children: [
            if (strikethrough != null) ...[
              Text(
                strikethrough,
                style: const TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
