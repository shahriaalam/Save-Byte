import '../../../core/utils/price_calculator.dart';

/// Food offer model representing offers table (Section 12, 13, 14, 44).
class FoodOffer {
  const FoodOffer({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.availableFrom,
    required this.availableUntil,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.adminBlocked = false,
    this.blockedReason,
    this.createdAt,
    this.updatedAt,
    this.restaurantName,
    this.restaurantAddress,
    this.division,
    this.area,
    this.isBoosted = false,
    this.boostedUntil,
  });

  final String id;
  final String restaurantId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String category;
  final double originalPrice;
  final double discountedPrice;
  final int quantity;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final bool isActive;
  final bool adminBlocked;
  final String? blockedReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isBoosted;
  final DateTime? boostedUntil;

  // Joined presentation fields
  final String? restaurantName;
  final String? restaurantAddress;
  final String? division;
  final String? area;

  /// Absolute monetary savings in BDT (৳)
  double get savings => PriceCalculator.calculateSavings(
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
      );

  /// Discount percentage (e.g. 50%)
  int get discountPercentage => PriceCalculator.calculateDiscountPercentage(
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
      );

  /// Section 13 & 44 visibility check:
  /// is_active = true AND admin_blocked = false AND available_until > current_time
  bool isVisibleToCustomer([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return isActive && !adminBlocked && availableUntil.isAfter(now);
  }

  factory FoodOffer.fromJson(Map<String, dynamic> json) {
    return FoodOffer(
      id: json['id'] as String,
      restaurantId: (json['restaurant_id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      category: (json['category'] as String?) ?? 'Other',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : DateTime.now(),
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : DateTime.now().add(const Duration(hours: 2)),
      isActive: (json['is_active'] as bool?) ?? true,
      adminBlocked: (json['admin_blocked'] as bool?) ?? false,
      blockedReason: json['blocked_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      restaurantName: json['restaurant_name'] as String? ??
          (json['restaurants'] != null
              ? (json['restaurants'] as Map<String, dynamic>)['name'] as String?
              : null),
      restaurantAddress: json['restaurant_address'] as String? ??
          (json['restaurants'] != null
              ? (json['restaurants'] as Map<String, dynamic>)['address']
                  as String?
              : null),
      division: json['division'] as String? ??
          (json['restaurants'] != null
              ? (json['restaurants'] as Map<String, dynamic>)['division']
                  as String?
              : null),
      area: json['area'] as String? ??
          (json['restaurants'] != null
              ? (json['restaurants'] as Map<String, dynamic>)['area'] as String?
              : null),
      isBoosted: (json['is_boosted'] as bool?) ?? false,
      boostedUntil: json['boosted_until'] != null
          ? DateTime.tryParse(json['boosted_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'category': category,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'quantity': quantity,
      'available_from': availableFrom.toIso8601String(),
      'available_until': availableUntil.toIso8601String(),
      'is_active': isActive,
      'admin_blocked': adminBlocked,
      if (division != null) 'division': division,
      if (area != null) 'area': area,
      if (blockedReason != null) 'blocked_reason': blockedReason,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'is_boosted': isBoosted,
      if (boostedUntil != null) 'boosted_until': boostedUntil!.toIso8601String(),
    };
  }

  FoodOffer copyWith({
    String? id,
    String? restaurantId,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    double? originalPrice,
    double? discountedPrice,
    int? quantity,
    DateTime? availableFrom,
    DateTime? availableUntil,
    bool? isActive,
    bool? adminBlocked,
    String? blockedReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? restaurantName,
    String? restaurantAddress,
    String? division,
    String? area,
    bool? isBoosted,
    DateTime? boostedUntil,
  }) {
    return FoodOffer(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      quantity: quantity ?? this.quantity,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      isActive: isActive ?? this.isActive,
      adminBlocked: adminBlocked ?? this.adminBlocked,
      blockedReason: blockedReason ?? this.blockedReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      division: division ?? this.division,
      area: area ?? this.area,
      isBoosted: isBoosted ?? this.isBoosted,
      boostedUntil: boostedUntil ?? this.boostedUntil,
    );
  }
}
