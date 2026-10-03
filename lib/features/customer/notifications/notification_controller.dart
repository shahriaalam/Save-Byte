import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../../shared/models/food_offer.dart';
import '../location/user_location_controller.dart';
import 'notification_item.dart';

const _kStorageKey = 'savebite_notifications_v2';
const _kReadIdsKey = 'savebite_read_notification_ids';
const _kMaxNotifications = 50;

/// Notification controller state.
@immutable
class NotificationState {
  const NotificationState({
    this.items = const [],
    this.isLoading = false,
  });

  final List<NotificationItem> items;
  final bool isLoading;

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
  }) {
    return NotificationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages in-app notifications for new nearby food offers.
///
/// Listens to Supabase Realtime on the `offers` table (INSERT events).
/// Notifications are filtered to only show offers in the user's current area.
/// Persisted across sessions via SharedPreferences.
class NotificationNotifier extends Notifier<NotificationState> {
  RealtimeChannel? _channel;
  Timer? _pollTimer;

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  @override
  NotificationState build() {
    // Load persisted notifications and start listening
    _initialize();
    // Cleanup on disposal
    ref.onDispose(() {
      _channel?.unsubscribe();
      _pollTimer?.cancel();
    });
    return const NotificationState(isLoading: true);
  }

  Future<void> _initialize() async {
    await _loadFromStorage();
    _startRealtimeSubscription();
    _startPolling();
  }

  // ─── Storage ──────────────────────────────────────────────────────────────

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_kStorageKey) ?? [];
      final readIds = (prefs.getStringList(_kReadIdsKey) ?? []).toSet();

      final items = rawList
          .map((s) {
            try {
              return NotificationItem.fromJson(
                  jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<NotificationItem>()
          .map((n) => readIds.contains(n.id) ? n.copyWith(isRead: true) : n)
          .toList();

      // Most recent first
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      debugPrint('[NotificationController] load error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _persistToStorage(List<NotificationItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = items
          .take(_kMaxNotifications)
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      final readIds =
          items.where((n) => n.isRead).map((n) => n.id).toList();
      await prefs.setStringList(_kStorageKey, rawList);
      await prefs.setStringList(_kReadIdsKey, readIds);
    } catch (e) {
      debugPrint('[NotificationController] persist error: $e');
    }
  }

  // ─── Realtime ────────────────────────────────────────────────────────────

  void _startRealtimeSubscription() {
    try {
      _channel = _client
          .channel('public:offers:insert')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConstants.tableOffers,
            callback: (payload) {
              _handleNewOffer(payload.newRecord);
            },
          )
          .subscribe((status, [error]) {
        debugPrint('[NotificationController] realtime: $status ${error ?? ''}');
      });
    } catch (e) {
      debugPrint('[NotificationController] realtime subscription error: $e');
    }
  }

  void _handleNewOffer(Map<String, dynamic> record) {
    try {
      final offer = FoodOffer.fromJson(record);

      // Only notify if this offer is in the user's current area or nearby
      final locationState = ref.read(userLocationControllerProvider);
      final userArea = locationState.detectedArea;

      bool isNearby = false;
      if (userArea == null || userArea == 'All' || userArea == 'Dhaka') {
        // Show all Dhaka offers when no specific area
        isNearby = true;
      } else if (offer.area != null) {
        isNearby = offer.area!.toLowerCase() == userArea.toLowerCase();
      } else if (offer.restaurantAddress != null) {
        isNearby = offer.restaurantAddress!
            .toLowerCase()
            .contains(userArea.toLowerCase());
      }

      if (!isNearby) return;
      if (!offer.isVisibleToCustomer()) return;

      _addNotification(NotificationItem(
        id: 'offer_${offer.id}_${DateTime.now().millisecondsSinceEpoch}',
        offerId: offer.id,
        restaurantName: offer.restaurantName ?? 'Nearby Restaurant',
        offerTitle: offer.title,
        discountPercentage: offer.discountPercentage,
        area: offer.area ?? userArea ?? 'Dhaka',
        createdAt: offer.createdAt ?? DateTime.now(),
        imageUrl: offer.imageUrl,
        isRead: false,
      ));
    } catch (e) {
      debugPrint('[NotificationController] offer parse error: $e');
    }
  }

  // ─── Polling fallback (for when realtime is unavailable) ─────────────────

  DateTime? _lastPollTime;

  void _startPolling() {
    _lastPollTime = DateTime.now().subtract(const Duration(minutes: 5));
    // Poll every 2 minutes for new offers as realtime fallback
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final since = _lastPollTime ?? DateTime.now().subtract(
            const Duration(minutes: 5),
          );
      _lastPollTime = DateTime.now();

      final locationState = ref.read(userLocationControllerProvider);
      final userArea = locationState.detectedArea;

      // Check if client is connected to real Supabase (not placeholder)
      if (_client.rest.url.contains('placeholder')) return;

      final now = DateTime.now().toIso8601String();
      final sinceStr = since.toIso8601String();

      var query = _client
          .from(SupabaseConstants.tableOffers)
          .select('*, restaurants!inner(name, address, area, status)')
          .eq('is_active', true)
          .eq('admin_blocked', false)
          .gt('available_until', now)
          .gt('created_at', sinceStr)
          .eq('restaurants.status', 'approved');

      if (userArea != null && userArea != 'All' && userArea != 'Dhaka') {
        query = query.ilike('restaurants.address', '%$userArea%');
      }

      final List<dynamic> response = await query;

      for (final row in response) {
        _handleNewOffer(row as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[NotificationController] poll error: $e');
    }
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  void _addNotification(NotificationItem notification) {
    // Deduplicate by offer ID
    final existingIds =
        state.items.map((n) => n.offerId).toSet();
    if (existingIds.contains(notification.offerId)) return;

    final updated = [notification, ...state.items]
        .take(_kMaxNotifications)
        .toList();
    state = state.copyWith(items: updated);
    _persistToStorage(updated);
  }

  /// Mark a single notification as read.
  void markRead(String notificationId) {
    final updated = state.items
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(items: updated);
    _persistToStorage(updated);
  }

  /// Mark ALL notifications as read.
  void markAllRead() {
    final updated =
        state.items.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(items: updated);
    _persistToStorage(updated);
  }

  /// Manually add a notification (used for testing or seeding).
  void addTestNotification(NotificationItem item) => _addNotification(item);

  /// Clears all notifications.
  void clearAll() {
    state = state.copyWith(items: []);
    _persistToStorage([]);
  }

  /// Force a manual poll for new offers.
  Future<void> refresh() async {
    _lastPollTime = DateTime.now().subtract(const Duration(hours: 1));
    await _poll();
  }
}

/// Provider for [NotificationNotifier].
final notificationControllerProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

/// Convenience provider for unread count — drives the badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationControllerProvider).unreadCount;
});
