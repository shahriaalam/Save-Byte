import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../shared/data/order_controller.dart';
import '../../../shared/models/food_offer.dart';
import '../../../shared/models/order.dart';
import '../../../shared/presentation/payment_portal_sheet.dart';
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-calculate initial default pickup time: 30 minutes from now or start of window
    final now = DateTime.now();
    final defaultPickup = now.add(const Duration(minutes: 30));
    _selectedPickupTime = _formatTimeDisplay(defaultPickup);

    // Pre-fill user profile info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(currentUserProfileProvider);
      if (profile != null) {
        if (_nameCtrl.text.isEmpty && profile.fullName != null) {
          _nameCtrl.text = profile.fullName!;
        }
        if (_phoneCtrl.text.isEmpty && profile.phone != null) {
          _phoneCtrl.text = profile.phone!;
        }
      }
      if (_nameCtrl.text.isEmpty) _nameCtrl.text = 'Guest Customer';
      if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = '01712345678';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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

    final totalPrice = widget.offer.discountedPrice * _quantity;
    final customerName = _nameCtrl.text.trim();
    final customerPhone = _phoneCtrl.text.trim();

    // 1. Launch the Payment Portal (bKash, Nagad, Card)
    final paymentResult = await showPaymentPortalSheet(
      context: context,
      title: 'Pay & Book Takeaway Order',
      subtitle: '${widget.offer.restaurantName ?? 'Restaurant'} • ${_quantity}x ${widget.offer.title}',
      amount: totalPrice,
      customerOrBusinessName: customerName,
      perkHighlights: [
        'Instant surplus meal booking confirmation',
        'Pickup scheduled: $_selectedPickupTime',
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
      );

      if (!mounted) return;
      Navigator.pop(context); // Close checkout bottom sheet

      if (createdOrder != null) {
        _showOrderSuccessDialog(createdOrder);
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

  void _showOrderSuccessDialog(Order order) {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
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
                  Navigator.pop(dialogCtx);
                  showCustomerOrdersSheet(context: context);
                },
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
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
    final totalSavings = offer.savings * _quantity;
    final originalTotal = offer.originalPrice * _quantity;
    final maxAvailable = offer.quantity.clamp(1, 99);

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
                              '৳${itemTotal.toStringAsFixed(0)}',
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
                        : 'Proceed to Pay ৳${itemTotal.toStringAsFixed(0)}',
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
