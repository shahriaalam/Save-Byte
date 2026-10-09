import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Represents a customer food rescue order for in-person takeaway / self-pickup.
/// SaveBite does not provide home delivery; all orders are self-pickup.
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,
    this.restaurantPhone,
    this.restaurantEmail,
    this.offerId,
    required this.title,
    this.imageUrl,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.originalUnitPrice,
    required this.totalPrice,
    required this.totalSavings,
    required this.pickupTime,
    required this.pickupCode,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    this.status = 'confirmed',
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.emailSentCustomer = true,
    this.emailSentRestaurant = true,
  });

  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantPhone;
  final String? restaurantEmail;
  final String? offerId;
  final String title;
  final String? imageUrl;
  final String category;
  final int quantity;
  final double unitPrice;
  final double originalUnitPrice;
  final double totalPrice;
  final double totalSavings;
  final String pickupTime;
  final String pickupCode;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final String status; // 'confirmed', 'ready_for_pickup', 'completed', 'cancelled'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool emailSentCustomer;
  final bool emailSentRestaurant;

  bool get isActivePickup => status == 'confirmed' || status == 'ready_for_pickup';
  bool get isConfirmed => status == 'confirmed';
  bool get isReadyForPickup => status == 'ready_for_pickup';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplayLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'completed':
        return 'Picked Up';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Booked';
    }
  }

  String get statusLabel => statusDisplayLabel;

  Color get statusColor {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF2563EB); // Blue
      case 'ready_for_pickup':
        return const Color(0xFFD97706); // Amber
      case 'completed':
        return const Color(0xFF16A34A); // Green
      case 'cancelled':
        return const Color(0xFFDC2626); // Red
      default:
        return AppColors.primary;
    }
  }

  int get statusColorHex => statusColor.toARGB32();

  Color get statusBgColor {
    switch (status) {
      case 'confirmed':
        return const Color(0xFFEFF6FF);
      case 'ready_for_pickup':
        return const Color(0xFFFFFBEB);
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFFFEDEC);
    }
  }

  Order copyWith({
    String? status,
    DateTime? updatedAt,
    bool? emailSentCustomer,
    bool? emailSentRestaurant,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantPhone: restaurantPhone,
      restaurantEmail: restaurantEmail,
      offerId: offerId,
      title: title,
      imageUrl: imageUrl,
      category: category,
      quantity: quantity,
      unitPrice: unitPrice,
      originalUnitPrice: originalUnitPrice,
      totalPrice: totalPrice,
      totalSavings: totalSavings,
      pickupTime: pickupTime,
      pickupCode: pickupCode,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      transactionId: transactionId,
      status: status ?? this.status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailSentCustomer: emailSentCustomer ?? this.emailSentCustomer,
      emailSentRestaurant: emailSentRestaurant ?? this.emailSentRestaurant,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: (json['order_number'] as String?) ?? 'SB-${json['id'].toString().substring(0, 6).toUpperCase()}',
      customerId: (json['customer_id'] as String?) ?? '',
      customerName: (json['customer_name'] as String?) ?? 'Customer',
      customerPhone: (json['customer_phone'] as String?) ?? '',
      customerEmail: json['customer_email'] as String?,
      restaurantId: (json['restaurant_id'] as String?) ?? '',
      restaurantName: (json['restaurant_name'] as String?) ?? 'Restaurant',
      restaurantAddress: (json['restaurant_address'] as String?) ?? 'Dhaka',
      restaurantPhone: json['restaurant_phone'] as String?,
      restaurantEmail: json['restaurant_email'] as String?,
      offerId: json['offer_id'] as String?,
      title: (json['title'] as String?) ?? 'Food Order',
      imageUrl: json['image_url'] as String?,
      category: (json['category'] as String?) ?? 'Food',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ??
          (((json['total_price'] as num?)?.toDouble() ?? 0) / ((json['quantity'] as num?)?.toInt() ?? 1)),
      originalUnitPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      totalSavings: (json['total_savings'] as num?)?.toDouble() ?? 0.0,
      pickupTime: (json['pickup_time'] as String?) ?? 'Today at scheduled window',
      pickupCode: (json['pickup_code'] as String?) ?? '1234',
      paymentMethod: (json['payment_method'] as String?) ?? 'bKash',
      paymentStatus: (json['payment_status'] as String?) ?? 'paid',
      transactionId: json['transaction_id'] as String?,
      status: (json['status'] as String?) ?? 'confirmed',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      emailSentCustomer: json['email_sent_customer'] as bool? ?? true,
      emailSentRestaurant: json['email_sent_restaurant'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (customerEmail != null) 'customer_email': customerEmail,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'restaurant_address': restaurantAddress,
      if (restaurantPhone != null) 'restaurant_phone': restaurantPhone,
      if (restaurantEmail != null) 'restaurant_email': restaurantEmail,
      if (offerId != null) 'offer_id': offerId,
      'title': title,
      if (imageUrl != null) 'image_url': imageUrl,
      'category': category,
      'quantity': quantity,
      'unit_price': unitPrice,
      'original_price': originalUnitPrice,
      'total_price': totalPrice,
      'total_savings': totalSavings,
      'pickup_time': pickupTime,
      'pickup_code': pickupCode,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      if (transactionId != null) 'transaction_id': transactionId,
      'status': status,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'email_sent_customer': emailSentCustomer,
      'email_sent_restaurant': emailSentRestaurant,
    };
  }
}

/// Aggregated sales metrics for a restaurant's food rescue takeaway orders.
class RestaurantSalesStats {
  const RestaurantSalesStats({
    this.totalOrders = 0,
    this.activeOrdersCount = 0,
    this.totalPortionsSold = 0,
    this.totalRevenue = 0.0,
    this.totalSavings = 0.0,
  });

  final int totalOrders;
  final int activeOrdersCount;
  final int totalPortionsSold;
  final double totalRevenue;
  final double totalSavings;

  factory RestaurantSalesStats.fromMap(Map<String, dynamic> map) {
    return RestaurantSalesStats(
      totalOrders: map['totalOrders'] as int? ?? 0,
      activeOrdersCount: map['activeOrders'] as int? ?? 0,
      totalPortionsSold: map['totalPortionsSold'] as int? ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalSavings: (map['totalSavings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
