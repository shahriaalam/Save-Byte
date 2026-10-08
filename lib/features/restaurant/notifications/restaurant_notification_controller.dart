import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'restaurant_notification.dart';

final restaurantNotificationsProvider =
    AsyncNotifierProvider<RestaurantNotificationNotifier, List<RestaurantNotification>>(
  RestaurantNotificationNotifier.new,
);

class RestaurantNotificationNotifier extends AsyncNotifier<List<RestaurantNotification>> {
  static const String _storageKey = 'restaurant_notifications_v1';

  @override
  Future<List<RestaurantNotification>> build() async {
    return _loadNotifications();
  }

  Future<List<RestaurantNotification>> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List<dynamic>;
        final items = decoded
            .map((item) => RestaurantNotification.fromMap(item as Map<String, dynamic>))
            .toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      }
    } catch (_) {}

    // Default initial notification for fresh demo environments
    return [
      RestaurantNotification(
        id: 'initial_notif_1',
        restaurantId: 'blue_bell_cafe',
        title: 'Welcome to SaveBite Partner Portal 🏪',
        message: 'Manage your food drops, dish boosts, and homepage hero banner campaigns here.',
        type: 'general',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
      ),
    ];
  }

  Future<void> _save(List<RestaurantNotification> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(items.map((i) => i.toMap()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {}
  }

  /// Sends a new notification to the restaurant.
  Future<void> sendNotification(RestaurantNotification notification) async {
    final current = state.asData?.value ?? await _loadNotifications();
    final updated = [notification, ...current];
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Notification dispatched when an Admin approves a restaurant banner and it goes live on the carousel.
  Future<void> notifyBannerStarted({
    required String restaurantId,
    required String bannerHeadline,
    String? bannerId,
    String? restaurantName,
  }) async {
    final notif = RestaurantNotification(
      id: 'notif_banner_start_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurantId,
      bannerId: bannerId,
      title: '🎉 Hero Banner is Now Live!',
      message:
          'Your hero banner "$bannerHeadline" has been approved by admin and is now actively displaying on the Customer Home Carousel across Dhaka.',
      type: 'banner_started',
      createdAt: DateTime.now(),
      isRead: false,
      metadata: {
        'headline': bannerHeadline,
        'restaurantName': restaurantName,
      },
    );
    await sendNotification(notif);
  }

  /// Notification dispatched when a restaurant banner finishes displaying (expires or concluded).
  Future<void> notifyBannerEnded({
    required String restaurantId,
    required String bannerHeadline,
    String? bannerId,
    String? restaurantName,
  }) async {
    final notif = RestaurantNotification(
      id: 'notif_banner_end_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurantId,
      bannerId: bannerId,
      title: '🏁 Hero Banner Campaign Ended',
      message:
          'Your hero banner "$bannerHeadline" display period has concluded. Check your partner performance telemetry.',
      type: 'banner_ended',
      createdAt: DateTime.now(),
      isRead: false,
      metadata: {
        'headline': bannerHeadline,
        'restaurantName': restaurantName,
      },
    );
    await sendNotification(notif);
  }

  /// Notification dispatched when a restaurant upgrades to Gold Merchant.
  Future<void> notifyGoldMerchant({
    required String restaurantId,
    required String restaurantName,
  }) async {
    final notif = RestaurantNotification(
      id: 'notif_gold_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: restaurantId,
      title: '🌟 Welcome to Gold Merchant!',
      message:
          'Congratulations $restaurantName! You now have 1 Hero Banner ad quota and 5 monthly post boosts enabled.',
      type: 'gold_merchant',
      createdAt: DateTime.now(),
      isRead: false,
    );
    await sendNotification(notif);
  }

  /// Marks all notifications as read.
  Future<void> markAllRead() async {
    final current = state.asData?.value ?? [];
    final updated = current.map((item) => item.copyWith(isRead: true)).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id) async {
    final current = state.asData?.value ?? [];
    final updated = current
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  /// Clears all notifications.
  Future<void> clearAll() async {
    state = const AsyncData([]);
    await _save([]);
  }
}
