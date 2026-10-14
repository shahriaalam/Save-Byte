import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promo_code.dart';
import 'promo_code_repository.dart';

/// Provider for all promo codes (for Admin management).
final allPromoCodesProvider = FutureProvider<List<PromoCode>>((ref) async {
  final repo = ref.watch(promoCodeRepositoryProvider);
  return repo.getPromoCodes(activeOnly: false);
});

/// Provider for active promo codes (for Customer checkout / suggestions).
final activePromoCodesProvider = FutureProvider<List<PromoCode>>((ref) async {
  final repo = ref.watch(promoCodeRepositoryProvider);
  return repo.getPromoCodes(activeOnly: true);
});

/// Controller for admin operations on promo codes and customer validation.
final promoCodeControllerProvider =
    AsyncNotifierProvider<PromoCodeController, List<PromoCode>>(
  PromoCodeController.new,
);

class PromoCodeController extends AsyncNotifier<List<PromoCode>> {
  @override
  Future<List<PromoCode>> build() async {
    final repo = ref.watch(promoCodeRepositoryProvider);
    return repo.getPromoCodes(activeOnly: false);
  }

  /// Admin operation: Create and publish a promo code.
  Future<PromoCode?> createPromoCode({
    required String code,
    required String title,
    required String description,
    String discountType = 'flat',
    required double discountValue,
    double minOrderAmount = 0.0,
    double? maxDiscount,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(promoCodeRepositoryProvider);
      final newPromo = PromoCode(
        id: 'promo-${DateTime.now().millisecondsSinceEpoch}',
        code: code.trim().toUpperCase(),
        title: title.trim(),
        description: description.trim(),
        discountType: discountType,
        discountValue: discountValue,
        minOrderAmount: minOrderAmount,
        maxDiscount: maxDiscount,
        isActive: true,
        usedCount: 0,
        isPlatformSponsored: true, // App authority absorbs the cost
      );

      final created = await repo.createPromoCode(newPromo);

      // Refresh providers
      ref.invalidate(allPromoCodesProvider);
      ref.invalidate(activePromoCodesProvider);
      state = AsyncData(await repo.getPromoCodes(activeOnly: false));
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Admin operation: Toggle active status.
  Future<void> toggleStatus(String id, bool isActive) async {
    final repo = ref.read(promoCodeRepositoryProvider);
    await repo.togglePromoCode(id, isActive);
    ref.invalidate(allPromoCodesProvider);
    ref.invalidate(activePromoCodesProvider);
    state = AsyncData(await repo.getPromoCodes(activeOnly: false));
  }

  /// Admin operation: Delete promo code.
  Future<void> deletePromoCode(String id) async {
    final repo = ref.read(promoCodeRepositoryProvider);
    await repo.deletePromoCode(id);
    ref.invalidate(allPromoCodesProvider);
    ref.invalidate(activePromoCodesProvider);
    state = AsyncData(await repo.getPromoCodes(activeOnly: false));
  }

  /// Customer operation: Validate and calculate discount for an order.
  Future<PromoCodeValidationResult> validatePromo({
    required String code,
    required double orderAmount,
  }) async {
    final repo = ref.read(promoCodeRepositoryProvider);
    return repo.validatePromoCode(code: code, orderAmount: orderAmount);
  }
}
