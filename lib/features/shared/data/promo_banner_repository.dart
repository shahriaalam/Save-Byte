import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promo_banner.dart';

final promoBannerRepositoryProvider = Provider<PromoBannerRepository>((ref) {
  return PromoBannerRepository();
});

class PromoBannerRepository {
  static const String _storageKey = 'admin_promo_banners_v3';

  /// Loads the 3 promotional banners from storage or returns the curated defaults.
  Future<List<PromoBanner>> getBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List<dynamic>;
        final list = decoded
            .map((item) => PromoBanner.fromMap(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {
      // Fallback on defaults if decoding fails
    }
    return PromoBanner.defaultBanners;
  }

  /// Updates an individual banner (Admin only).
  Future<List<PromoBanner>> updateBanner(PromoBanner updatedBanner) async {
    final current = await getBanners();
    final updatedList = current.map((b) {
      return b.id == updatedBanner.id ? updatedBanner : b;
    }).toList();

    await _saveBanners(updatedList);
    return updatedList;
  }

  /// Adds or updates a promotional banner (e.g. for premium restaurants).
  Future<List<PromoBanner>> upsertBanner(PromoBanner banner) async {
    final current = await getBanners();
    final exists = current.any((b) => b.id == banner.id);
    List<PromoBanner> updatedList;
    if (exists) {
      updatedList = current.map((b) => b.id == banner.id ? banner : b).toList();
    } else {
      updatedList = [banner, ...current];
    }
    await _saveBanners(updatedList);
    return updatedList;
  }

  /// Submits a restaurant hero banner request for Admin approval (status = 'pending').
  Future<List<PromoBanner>> submitRestaurantBanner(PromoBanner banner) async {
    final current = await getBanners();
    final pendingBanner = banner.copyWith(
      status: 'pending',
      createdAt: DateTime.now(),
    );
    final exists = current.any((b) => b.id == banner.id);
    List<PromoBanner> updatedList;
    if (exists) {
      updatedList = current.map((b) => b.id == banner.id ? pendingBanner : b).toList();
    } else {
      updatedList = [pendingBanner, ...current];
    }
    await _saveBanners(updatedList);
    return updatedList;
  }

  /// Admin approval: marks banner as approved and live, sets startsAt.
  Future<List<PromoBanner>> approveBanner(String bannerId) async {
    final current = await getBanners();
    PromoBanner? approvedBanner;
    final otherBanners = <PromoBanner>[];

    for (final b in current) {
      if (b.id == bannerId) {
        approvedBanner = b.copyWith(
          status: 'approved',
          startsAt: DateTime.now(),
        );
      } else {
        otherBanners.add(b);
      }
    }

    if (approvedBanner != null) {
      // Place the approved banner at the front so it appears prominently in the carousel
      final updatedList = [approvedBanner, ...otherBanners];
      await _saveBanners(updatedList);
      return updatedList;
    }
    return current;
  }

  /// Ends an active banner campaign: marks banner as ended, sets endsAt.
  Future<List<PromoBanner>> endBanner(String bannerId) async {
    final current = await getBanners();
    final updatedList = current.map((b) {
      if (b.id == bannerId) {
        return b.copyWith(
          status: 'ended',
          endsAt: DateTime.now(),
        );
      }
      return b;
    }).toList();
    await _saveBanners(updatedList);
    return updatedList;
  }

  /// Rejects a pending banner with optional reason.
  Future<List<PromoBanner>> rejectBanner(String bannerId, {String? reason}) async {
    final current = await getBanners();
    final updatedList = current.map((b) {
      if (b.id == bannerId) {
        return b.copyWith(
          status: 'rejected',
          rejectionReason: reason,
        );
      }
      return b;
    }).toList();
    await _saveBanners(updatedList);
    return updatedList;
  }

  /// Replaces the entire list of banners (Admin only).
  Future<List<PromoBanner>> saveAllBanners(List<PromoBanner> banners) async {
    await _saveBanners(banners);
    return banners;
  }

  /// Resets the promotional banners to default configurations.
  Future<List<PromoBanner>> resetToDefaults() async {
    final defaults = PromoBanner.defaultBanners;
    await _saveBanners(defaults);
    return defaults;
  }

  Future<void> _saveBanners(List<PromoBanner> banners) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(banners.map((b) => b.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
