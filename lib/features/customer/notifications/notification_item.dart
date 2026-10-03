/// In-app notification item representing a new food offer posted by a nearby restaurant.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.offerId,
    required this.restaurantName,
    required this.offerTitle,
    required this.discountPercentage,
    required this.area,
    required this.createdAt,
    this.imageUrl,
    this.isRead = false,
  });

  final String id;
  final String offerId;
  final String restaurantName;
  final String offerTitle;
  final int discountPercentage;
  final String area;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      offerId: offerId,
      restaurantName: restaurantName,
      offerTitle: offerTitle,
      discountPercentage: discountPercentage,
      area: area,
      createdAt: createdAt,
      imageUrl: imageUrl,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'offerId': offerId,
        'restaurantName': restaurantName,
        'offerTitle': offerTitle,
        'discountPercentage': discountPercentage,
        'area': area,
        'createdAt': createdAt.toIso8601String(),
        'imageUrl': imageUrl,
        'isRead': isRead,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      offerId: json['offerId'] as String,
      restaurantName: json['restaurantName'] as String,
      offerTitle: json['offerTitle'] as String,
      discountPercentage: (json['discountPercentage'] as num).toInt(),
      area: json['area'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      isRead: (json['isRead'] as bool?) ?? false,
    );
  }
}
