import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promo_banner.dart';
import 'promo_banner_repository.dart';

final promoBannersControllerProvider =
    AsyncNotifierProvider<PromoBannersNotifier, List<PromoBanner>>(
  PromoBannersNotifier.new,
);

class PromoBannersNotifier extends AsyncNotifier<List<PromoBanner>> {
  @override
  Future<List<PromoBanner>> build() async {
    final repo = ref.watch(promoBannerRepositoryProvider);
    return repo.getBanners();
  }

  Future<void> loadBanners() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.getBanners();
    });
  }

  /// Admin operation: updates an individual promotional banner.
  Future<void> updateBanner(PromoBanner updatedBanner) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.updateBanner(updatedBanner);
    });
  }

  /// Premium restaurant or Admin operation: adds or updates a promo banner.
  Future<void> upsertBanner(PromoBanner banner) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.upsertBanner(banner);
    });
  }

  /// Restaurant operation: submits a hero banner for Admin approval (status = 'pending').
  Future<void> submitRestaurantBanner(PromoBanner banner) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.submitRestaurantBanner(banner);
    });
  }

  /// Admin operation: approves a pending banner and publishes it live to customer carousel.
  Future<void> approveBanner(String bannerId) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.approveBanner(bannerId);
    });
  }

  /// Admin operation: ends/deactivates an active banner campaign.
  Future<void> endBanner(String bannerId) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.endBanner(bannerId);
    });
  }

  /// Admin operation: rejects a pending banner.
  Future<void> rejectBanner(String bannerId, {String? reason}) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.rejectBanner(bannerId, reason: reason);
    });
  }

  /// Admin operation: resets all 3 banners to default configurations.
  Future<void> resetToDefaults() async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.resetToDefaults();
    });
  }
}
