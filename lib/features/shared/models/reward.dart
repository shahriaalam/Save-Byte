import 'package:flutter/foundation.dart';

/// Represents a customer reward posted by platform administrators.
///
/// Business Rules:
/// 1. Admin posts rewards with a deadline (e.g., daily or weekly).
/// 2. Expired rewards disappear automatically.
/// 3. Customers view and click "Claim" to avail the reward.
/// 4. On checkout, a customer can apply ONLY ONE advantage per order
///    (either 1 promo code OR 1 claimed reward).
/// 5. Discount is 100% platform-sponsored; restaurants receive 100% full payout.
@immutable
class Reward {
  final String id;
  final String title;
  final String description;
  final double minOrderAmount; // e.g., 1000 BDT
  final double discountValue; // e.g., 30 BDT
  final String discountType; // 'flat' (BDT ৳) or 'percentage' (%)
  final DateTime expiresAt; // Deadline after which reward is not available
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final bool isClaimed; // Whether the active user has claimed this reward
  final bool isUsed; // Whether the active user has redeemed it

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    this.minOrderAmount = 0.0,
    required this.discountValue,
    this.discountType = 'flat',
    required this.expiresAt,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    this.isClaimed = false,
    this.isUsed = false,
  });

  bool get isPercentage => discountType.toLowerCase() == 'percentage';
  bool get isFlat => !isPercentage;

  /// Check whether the reward deadline has passed
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check whether the reward is active and still within its validity deadline
  bool get isValid => isActive && !isExpired;

  /// Human-friendly discount badge (e.g., '৳30 OFF' or '10% OFF')
  String get discountTag {
    if (isPercentage) {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    return '৳${discountValue.toStringAsFixed(0)} OFF';
  }

  /// Human-friendly requirement (e.g., 'Min spend ৳1,000')
  String get requirementTag =>
      minOrderAmount > 0 ? 'Min. spend ৳${minOrderAmount.toStringAsFixed(0)}' : 'No min. spend';

  /// Human-readable remaining time until deadline
  String get remainingTimeText {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Expired';

    final diff = expiresAt.difference(now);
    if (diff.inDays > 1) {
      return 'Ends in ${diff.inDays} days';
    } else if (diff.inDays == 1) {
      return 'Ends tomorrow';
    } else if (diff.inHours > 0) {
      return 'Ends in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else if (diff.inMinutes > 0) {
      return 'Ends in ${diff.inMinutes} mins';
    } else {
      return 'Ending soon';
    }
  }

  /// Calculates the discount in BDT for a given order subtotal.
  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderAmount) return 0.0;

    double calculated;
    if (isPercentage) {
      calculated = subtotal * (discountValue / 100.0);
    } else {
      calculated = discountValue;
    }

    return calculated > subtotal ? subtotal : calculated;
  }

  Reward copyWith({
    String? id,
    String? title,
    String? description,
    double? minOrderAmount,
    double? discountValue,
    String? discountType,
    DateTime? expiresAt,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    bool? isClaimed,
    bool? isUsed,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isClaimed: isClaimed ?? this.isClaimed,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  factory Reward.fromJson(Map<String, dynamic> json, {bool isClaimed = false, bool isUsed = false}) {
    return Reward(
      id: (json['id'] as String?) ?? 'rew-${DateTime.now().millisecondsSinceEpoch}',
      title: (json['title'] as String?) ?? 'Exclusive Reward',
      description: (json['description'] as String?) ?? '',
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      discountType: (json['discount_type'] as String?) ?? 'flat',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String) ?? DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      isActive: (json['is_active'] as bool?) ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isClaimed: isClaimed,
      isUsed: isUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'min_order_amount': minOrderAmount,
      'discount_value': discountValue,
      'discount_type': discountType,
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Default baseline community rewards created for high-value food savers.
  static List<Reward> defaultRewards() {
    final now = DateTime.now();
    return [
      Reward(
        id: 'reward-1000-30',
        title: 'SaveBite Mega Order Perk',
        description: 'Order 1000 taka product and get 30 tk off',
        minOrderAmount: 1000.0,
        discountValue: 30.0,
        discountType: 'flat',
        expiresAt: now.add(const Duration(days: 7)),
        isActive: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Reward(
        id: 'reward-500-20',
        title: 'Weekend Food Rescue Delight',
        description: 'Order 500 taka product and get 20 tk off',
        minOrderAmount: 500.0,
        discountValue: 20.0,
        discountType: 'flat',
        expiresAt: now.add(const Duration(days: 3)),
        isActive: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Reward(
        id: 'reward-1500-50',
        title: 'Community Feast Saver',
        description: 'Order 1500 taka product and get 50 tk off',
        minOrderAmount: 1500.0,
        discountValue: 50.0,
        discountType: 'flat',
        expiresAt: now.add(const Duration(days: 5)),
        isActive: true,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
