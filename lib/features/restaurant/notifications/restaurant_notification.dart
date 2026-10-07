import 'dart:convert';

/// In-app notification item for restaurant partners.
/// Dispatched on critical lifecycle events (e.g., hero banner live, campaign ended, etc.)
class RestaurantNotification {
  const RestaurantNotification({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.bannerId,
    this.metadata,
  });

  final String id;
  final String restaurantId;
  final String title;
  final String message;
  final String type; // 'banner_started', 'banner_ended', 'gold_merchant', 'general'
  final DateTime createdAt;
  final bool isRead;
  final String? bannerId;
  final Map<String, dynamic>? metadata;

  bool get isBannerStarted => type == 'banner_started';
  bool get isBannerEnded => type == 'banner_ended';

  RestaurantNotification copyWith({
    String? id,
    String? restaurantId,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    String? bannerId,
    Map<String, dynamic>? metadata,
  }) {
    return RestaurantNotification(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      bannerId: bannerId ?? this.bannerId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'bannerId': bannerId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory RestaurantNotification.fromMap(Map<String, dynamic> map) {
    return RestaurantNotification(
      id: (map['id'] as String?) ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: (map['restaurantId'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'SaveBite Partner Alert',
      message: (map['message'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'general',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: (map['isRead'] as bool?) ?? false,
      bannerId: map['bannerId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RestaurantNotification.fromJson(String source) =>
      RestaurantNotification.fromMap(json.decode(source) as Map<String, dynamic>);
}
