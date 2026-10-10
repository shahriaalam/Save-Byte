/// Review model representing customer feedback, ratings, and verified review badges.
class Review {
  const Review({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    this.customerAvatarUrl,
    required this.restaurantId,
    required this.restaurantName,
    this.offerId,
    this.offerTitle,
    required this.rating,
    required this.comment,
    this.imageUrl,
    this.isVerified = true,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String? customerAvatarUrl;
  final String restaurantId;
  final String restaurantName;
  final String? offerId;
  final String? offerTitle;
  final double rating;
  final String comment;
  final String? imageUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  /// Returns 1-5 integer star value for display
  int get starCount => rating.clamp(1.0, 5.0).round();
  String get starsDisplay => '★' * starCount;

  /// Human-friendly relative or formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final mins = difference.inMinutes.clamp(1, 60);
        return '$mins min${mins > 1 ? 's' : ''} ago';
      }
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}';
    }
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  Review copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? customerName,
    String? customerAvatarUrl,
    String? restaurantId,
    String? restaurantName,
    String? offerId,
    String? offerTitle,
    double? rating,
    String? comment,
    String? imageUrl,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAvatarUrl: customerAvatarUrl ?? this.customerAvatarUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      offerId: offerId ?? this.offerId,
      offerTitle: offerTitle ?? this.offerTitle,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as String?) ?? '',
      orderId: (json['order_id'] as String?) ?? '',
      customerId: (json['customer_id'] as String?) ?? '',
      customerName: (json['customer_name'] as String?) ?? 'Customer',
      customerAvatarUrl: json['customer_avatar_url'] as String?,
      restaurantId: (json['restaurant_id'] as String?) ?? '',
      restaurantName: (json['restaurant_name'] as String?) ?? 'Restaurant',
      offerId: json['offer_id'] as String?,
      offerTitle: json['offer_title'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: (json['comment'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_avatar_url': customerAvatarUrl,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'offer_id': offerId,
      'offer_title': offerTitle,
      'rating': rating,
      'comment': comment,
      'image_url': imageUrl,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory Review.fromMap(Map<String, dynamic> map) => Review.fromJson(map);
}

/// Aggregated restaurant ratings data
class RestaurantRatingSummary {
  const RestaurantRatingSummary({
    required this.restaurantId,
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    this.verifiedRescueCount = 0,
  });

  final String restaurantId;
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  final int verifiedRescueCount;

  double get fiveStarRatio => totalReviews == 0 ? 0 : fiveStarCount / totalReviews;
  double get fourStarRatio => totalReviews == 0 ? 0 : fourStarCount / totalReviews;
  double get threeStarRatio => totalReviews == 0 ? 0 : threeStarCount / totalReviews;
  double get twoStarRatio => totalReviews == 0 ? 0 : twoStarCount / totalReviews;
  double get oneStarRatio => totalReviews == 0 ? 0 : oneStarCount / totalReviews;

  String get formattedAverage => averageRating.toStringAsFixed(1);
}
