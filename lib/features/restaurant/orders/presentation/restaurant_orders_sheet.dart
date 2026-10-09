import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../shared/data/order_controller.dart';
import '../../../shared/models/order.dart';

/// Shows the modal bottom sheet for managing incoming customer takeaway orders.
void showRestaurantOrdersSheet(BuildContext context, String restaurantId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RestaurantOrdersSheet(restaurantId: restaurantId),
  );
}

class RestaurantOrdersSheet extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantOrdersSheet({
    super.key,
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantOrdersSheet> createState() =>
      _RestaurantOrdersSheetState();
}

class _RestaurantOrdersSheetState extends ConsumerState<RestaurantOrdersSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(restaurantOrdersProvider(widget.restaurantId));
    final salesStats = ref.watch(restaurantSalesStatsProvider(widget.restaurantId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
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
                        'Takeaway Pickups & Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Self-Pickup only • No home delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Refresh Orders',
                  onPressed: () {
                    ref.invalidate(restaurantOrdersProvider(widget.restaurantId));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Takeaway strict notice
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SaveBite operates purely on customer self-pickup. Customers will come to your shop at their specified pickup time. Check their 4-digit PIN before handing over the package.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mini Sales Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Active Pickups',
                    value: '${salesStats.activeOrdersCount}',
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Portions Sold',
                    value: '${salesStats.totalPortionsSold}',
                    icon: Icons.fastfood_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Pickup Sales',
                    value: '৳${salesStats.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(
                  text: 'Active Pickups (${salesStats.activeOrdersCount})',
                ),
                Tab(
                  text: 'Order History (${ordersAsync.value?.where((o) => o.isCompleted || o.isCancelled).length ?? 0})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tab views
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading orders: $err'),
                ),
              ),
              data: (orders) {
                final activeOrders =
                    orders.where((o) => o.isConfirmed || o.isReadyForPickup).toList();
                final historyOrders =
                    orders.where((o) => o.isCompleted || o.isCancelled).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(activeOrders, isActiveTab: true),
                    _buildOrdersList(historyOrders, isActiveTab: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, {required bool isActiveTab}) {
    if (orders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              icon: isActiveTab
                  ? Icons.takeout_dining_outlined
                  : Icons.history_rounded,
              title: isActiveTab
                  ? 'No Active Pickups'
                  : 'No Past Orders',
              message: isActiveTab
                  ? 'When customers order and pay online, their scheduled takeaway details will show here immediately.'
                  : 'Completed or handed-over takeaway orders will be archived here.',
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildRestaurantOrderCard(order);
      },
    );
  }

  String _formatOrderTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    return '$hour:$minute $period, ${dt.day} $month';
  }

  Widget _buildRestaurantOrderCard(Order order) {
    final statusColor = Color(order.statusColorHex);
    final formattedTime = _formatOrderTime(order.createdAt);
    final pickupTimeStr = order.pickupTime;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isReadyForPickup
              ? const Color(0xFF10B981)
              : const Color(0xFFE2E8F0),
          width: order.isReadyForPickup ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Ordered at $formattedTime',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.statusLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dish Title & Portion
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.quantity} portion${order.quantity > 1 ? 's' : ''} • ৳${order.unitPrice.toStringAsFixed(0)} each',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${order.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PAID • ${order.paymentMethod.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scheduled Pickup Time Box (Prominent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on_rounded, color: Color(0xFFEA580C), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scheduled Pickup: Today at $pickupTimeStr',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC2410C),
                          ),
                        ),
                      ),
                      // PIN pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDBA74)),
                        ),
                        child: Text(
                          'PIN: ${order.pickupCode}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC2410C),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Customer Info Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (order.customerPhone.isNotEmpty) ...[
                        const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: order.customerPhone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied ${order.customerPhone} to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            order.customerPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: "${order.notes}"',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],

                // Action Buttons for Restaurant
                if (order.isConfirmed || order.isReadyForPickup) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (order.isConfirmed) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text(
                              'Mark Ready for Pickup',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await ref
                                  .read(orderControllerProvider.notifier)
                                  .updateStatus(
                                    order.id,
                                    'ready_for_pickup',
                                    restaurantId: widget.restaurantId,
                                    customerId: order.customerId,
                                  );
                              if (!mounted) return;
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Order marked as Ready for Pickup! Customer notified.'),
                                    backgroundColor: Color(0xFF2563EB),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                      if (order.isReadyForPickup) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.task_alt_rounded, size: 18),
                            label: const Text(
                              'Mark as Picked Up',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await ref
                                  .read(orderControllerProvider.notifier)
                                  .updateStatus(
                                    order.id,
                                    'completed',
                                    restaurantId: widget.restaurantId,
                                    customerId: order.customerId,
                                  );
                              if (!mounted) return;
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Order completed! Package handed over to customer.'),
                                    backgroundColor: Color(0xFF059669),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
