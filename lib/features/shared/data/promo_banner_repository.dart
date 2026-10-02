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

  /// Replaces the entire list of 3 banners (Admin only).
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
