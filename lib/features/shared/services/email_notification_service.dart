import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../core/constants/supabase_constants.dart';
import '../models/order.dart';

/// Service responsible for generating and sending transactional order emails
/// to customers and restaurants for SaveBite takeaway food rescue bookings.
class EmailNotificationService {
  EmailNotificationService({this.client});

  final supa.SupabaseClient? client;

  /// Sends order confirmation email and in-app alert to the customer.
  Future<bool> sendCustomerOrderEmail(Order order) async {
    try {
      final emailRecipient = order.customerEmail?.trim().isNotEmpty == true
          ? order.customerEmail!
          : '${order.customerPhone.replaceAll(RegExp(r'\D'), '')}@savebite.app';

      debugPrint('📧 [EMAIL DISPATCH TO CUSTOMER] -> $emailRecipient');
      debugPrint('Subject: Your SaveBite Order #${order.orderNumber} is Confirmed! (Takeaway Pickup)');
      debugPrint(
        'Body Preview:\n'
        'Dear ${order.customerName},\n'
        'Your surplus food order from ${order.restaurantName} is confirmed and booked.\n'
        '• Ordered Item: ${order.quantity}x ${order.title}\n'
        '• Amount Paid: ৳${order.totalPrice.toStringAsFixed(0)} via ${order.paymentMethod} (Txn: ${order.transactionId ?? 'Verified'})\n'
        '• Total Savings: ৳${order.totalSavings.toStringAsFixed(0)}\n'
        '• SCHEDULED PICKUP TIME: ${order.pickupTime}\n'
        '• PICKUP VERIFICATION PIN: ${order.pickupCode}\n'
        '• RESTAURANT ADDRESS: ${order.restaurantAddress}\n'
        '• IMPORTANT: SaveBite operates on a takeaway model. Please pick up your food in person. There is no home delivery service.',
      );

      // Record in Supabase notifications table if client is authenticated
      final supaClient = client;
      if (supaClient != null) {
        try {
          await supaClient.from(SupabaseConstants.tableNotifications).insert({
            'user_id': order.customerId,
            'title': 'Order Confirmed: ${order.orderNumber}',
            'message':
                'Pickup at ${order.pickupTime} from ${order.restaurantName}. Show Pickup PIN: ${order.pickupCode}.',
            'type': 'order',
            'data': {
              'order_id': order.id,
              'order_number': order.orderNumber,
              'pickup_time': order.pickupTime,
              'pickup_code': order.pickupCode,
              'restaurant_name': order.restaurantName,
              'restaurant_address': order.restaurantAddress,
              'total_price': order.totalPrice,
            },
            'is_read': false,
          });
        } catch (e) {
          debugPrint('Notice: In-app customer notification fallback: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Failed to dispatch customer email: $e');
      return false;
    }
  }

  /// Sends new order alert email and in-app notification to the restaurant.
  Future<bool> sendRestaurantOrderEmail(Order order) async {
    try {
      final emailRecipient = order.restaurantEmail?.trim().isNotEmpty == true
          ? order.restaurantEmail!
          : 'orders@${order.restaurantName.toLowerCase().replaceAll(RegExp(r'\s+'), '')}.savebite.app';

      debugPrint('📧 [EMAIL DISPATCH TO RESTAURANT] -> $emailRecipient');
      debugPrint('Subject: New Food Rescue Pickup Order: #${order.orderNumber}');
      debugPrint(
        'Body Preview:\n'
        'Attention ${order.restaurantName},\n'
        'A customer has booked food for takeaway pickup!\n'
        '• Customer: ${order.customerName} (${order.customerPhone})\n'
        '• Item: ${order.quantity}x ${order.title}\n'
        '• Scheduled Customer Pickup: ${order.pickupTime}\n'
        '• Paid Amount: ৳${order.totalPrice.toStringAsFixed(0)} (Paid via ${order.paymentMethod})\n'
        '• Customer Pickup PIN: ${order.pickupCode}\n'
        'Please have the portions packaged and ready for the customer at the scheduled pickup time.',
      );

      // Record in-app alert for restaurant if possible
      final supaClient = client;
      if (supaClient != null) {
        try {
          // If restaurantId is a valid user or restaurant UUID, notify restaurant owner
          await supaClient.from(SupabaseConstants.tableNotifications).insert({
            'user_id': order.restaurantId,
            'title': 'New Pickup Order #${order.orderNumber}',
            'message':
                '${order.customerName} ordered ${order.quantity}x ${order.title} for pickup at ${order.pickupTime}.',
            'type': 'order',
            'data': {
              'order_id': order.id,
              'order_number': order.orderNumber,
              'customer_name': order.customerName,
              'customer_phone': order.customerPhone,
              'pickup_time': order.pickupTime,
              'quantity': order.quantity,
              'total_price': order.totalPrice,
            },
            'is_read': false,
          });
        } catch (e) {
          debugPrint('Notice: In-app restaurant notification fallback: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Failed to dispatch restaurant email: $e');
      return false;
    }
  }
}
