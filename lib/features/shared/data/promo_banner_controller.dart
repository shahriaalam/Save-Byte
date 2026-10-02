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

  /// Admin operation: resets all 3 banners to default configurations.
  Future<void> resetToDefaults() async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(promoBannerRepositoryProvider);
      return repo.resetToDefaults();
    });
  }
}
