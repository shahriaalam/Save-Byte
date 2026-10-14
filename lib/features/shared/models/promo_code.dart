import 'package:flutter/foundation.dart';

/// Represents a platform-sponsored promo code / coupon for customer food rescue orders.
///
/// Business Rule:
/// Promo codes are setup and controlled EXCLUSIVELY by platform administrators.
/// The discount is 100% absorbed by the SaveBite app authority / platform.
/// Partner restaurants NEVER suffer any deduction or loss from promo discounts,
/// and always receive their full meal payout (unitPrice * quantity).
@immutable
class PromoCode {
  final String id;
  final String code; // Uppercase alphanumeric (e.g. 'SAVEBITE50')
  final String title;
  final String description;
  final String discountType; // 'flat' (BDT ৳) or 'percentage' (%)
  final double discountValue; // Flat amount in BDT or percentage number
  final double minOrderAmount; // Minimum order subtotal required to apply
  final double? maxDiscount; // Cap on discount for percentage-based vouchers
  final bool isActive;
  final int usedCount;
  final String? createdBy;
  final DateTime? expiresAt;
  final bool isPlatformSponsored; // True = App authority absorbs the discount

  const PromoCode({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.discountType = 'flat',
    required this.discountValue,
    this.minOrderAmount = 0.0,
    this.maxDiscount,
    this.isActive = true,
    this.usedCount = 0,
    this.createdBy,
    this.expiresAt,
    this.isPlatformSponsored = true,
  });

  bool get isPercentage => discountType.toLowerCase() == 'percentage';
  bool get isFlat => !isPercentage;

  /// Human-readable discount tag (e.g. '৳50 OFF' or '20% OFF')
  String get discountTag {
    if (isPercentage) {
      final capped = maxDiscount != null ? ' (Max ৳${maxDiscount!.toStringAsFixed(0)})' : '';
      return '${discountValue.toStringAsFixed(0)}% OFF$capped';
    } else {
      return '৳${discountValue.toStringAsFixed(0)} OFF';
    }
  }

  /// Calculates the discount amount in BDT for a given order subtotal.
  double calculateDiscount(double subtotal) {
    if (subtotal < minOrderAmount) return 0.0;

    double calculated;
    if (isPercentage) {
      calculated = subtotal * (discountValue / 100.0);
      if (maxDiscount != null && calculated > maxDiscount!) {
        calculated = maxDiscount!;
      }
    } else {
      calculated = discountValue;
    }

    // Discount cannot exceed the subtotal
    return calculated > subtotal ? subtotal : calculated;
  }

  PromoCode copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? discountType,
    double? discountValue,
    double? minOrderAmount,
    double? maxDiscount,
    bool? isActive,
    int? usedCount,
    String? createdBy,
    DateTime? expiresAt,
    bool? isPlatformSponsored,
  }) {
    return PromoCode(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      isActive: isActive ?? this.isActive,
      usedCount: usedCount ?? this.usedCount,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
      isPlatformSponsored: isPlatformSponsored ?? this.isPlatformSponsored,
    );
  }

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: (json['id'] as String?) ?? 'promo-${DateTime.now().millisecondsSinceEpoch}',
      code: (json['code'] as String? ?? '').toUpperCase().trim(),
      title: (json['title'] as String?) ?? 'Promotional Discount',
      description: (json['description'] as String?) ?? '',
      discountType: (json['discount_type'] as String?) ?? 'flat',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      isActive: (json['is_active'] as bool?) ?? true,
      usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      isPlatformSponsored: (json['is_platform_sponsored'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code.toUpperCase().trim(),
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      if (maxDiscount != null) 'max_discount': maxDiscount,
      'is_active': isActive,
      'used_count': usedCount,
      if (createdBy != null) 'created_by': createdBy,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'is_platform_sponsored': isPlatformSponsored,
    };
  }

  /// Default baseline promo codes sponsored by the SaveBite platform authority.
  static List<PromoCode> get defaultPromoCodes => [
    const PromoCode(
      id: 'promo-sb50',
      code: 'SAVEBITE50',
      title: 'SaveBite Welcome Gift',
      description: '৳50 OFF on food orders above ৳150',
      discountType: 'flat',
      discountValue: 50.0,
      minOrderAmount: 150.0,
      isActive: true,
      usedCount: 342,
      isPlatformSponsored: true,
    ),
    const PromoCode(
      id: 'promo-save20',
      code: 'SAVE20',
      title: '20% Surplus Food Saver',
      description: '20% OFF on takeaway meals (Min ৳100, Max ৳80)',
      discountType: 'percentage',
      discountValue: 20.0,
      minOrderAmount: 100.0,
      maxDiscount: 80.0,
      isActive: true,
      usedCount: 518,
      isPlatformSponsored: true,
    ),
    const PromoCode(
      id: 'promo-rescue30',
      code: 'RESCUE30',
      title: 'Green Earth Food Rescue',
      description: '৳30 OFF on any food rescue order',
      discountType: 'flat',
      discountValue: 30.0,
      minOrderAmount: 80.0,
      isActive: true,
      usedCount: 204,
      isPlatformSponsored: true,
    ),
    const PromoCode(
      id: 'promo-zero-waste',
      code: 'ZEROWASTE',
      title: 'Zero Food Waste Hero',
      description: '15% OFF for eco-conscious foodies (Min ৳120)',
      discountType: 'percentage',
      discountValue: 15.0,
      minOrderAmount: 120.0,
      maxDiscount: 60.0,
      isActive: true,
      usedCount: 167,
      isPlatformSponsored: true,
    ),
  ];
}

/// Validation result when applying a promo code at checkout.
class PromoCodeValidationResult {
  final bool isValid;
  final double discountAmount;
  final String message;
  final PromoCode? promoCode;

  const PromoCodeValidationResult({
    required this.isValid,
    this.discountAmount = 0.0,
    required this.message,
    this.promoCode,
  });

  factory PromoCodeValidationResult.success({
    required PromoCode promo,
    required double discount,
  }) {
    return PromoCodeValidationResult(
      isValid: true,
      discountAmount: discount,
      message: 'Code applied! You save ৳${discount.toStringAsFixed(0)} (Platform Sponsored)',
      promoCode: promo,
    );
  }

  factory PromoCodeValidationResult.failure(String message) {
    return PromoCodeValidationResult(
      isValid: false,
      discountAmount: 0.0,
      message: message,
    );
  }
}
