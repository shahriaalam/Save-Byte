import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../models/promo_code.dart';

/// Provider for PromoCodeRepository.
final promoCodeRepositoryProvider = Provider<PromoCodeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PromoCodeRepository(client);
});

class PromoCodeRepository {
  PromoCodeRepository(this._client);

  final supa.SupabaseClient _client;

  bool get _isLocalOnly =>
      _client.rest.url.contains('placeholder') ||
      _client.rest.url.contains('test');

  // In-memory list shared across the app session
  static final List<PromoCode> _cachedPromoCodes = List.from(PromoCode.defaultPromoCodes);

  /// Fetches all promo codes.
  Future<List<PromoCode>> getPromoCodes({bool activeOnly = false}) async {
    if (!_isLocalOnly) {
      try {
        var query = _client.from(SupabaseConstants.tableVouchers).select();
        if (activeOnly) {
          query = query.eq('is_active', true);
        }
        final response = await query.order('created_at', ascending: false);
        final list = (response as List<dynamic>)
            .map((e) => PromoCode.fromJson(e as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) {
          // Merge or update local cache
          for (final item in list) {
            final idx = _cachedPromoCodes.indexWhere((c) => c.code == item.code);
            if (idx != -1) {
              _cachedPromoCodes[idx] = item;
            } else {
              _cachedPromoCodes.add(item);
            }
          }
          return activeOnly
              ? list.where((p) => p.isActive).toList()
              : list;
        }
      } catch (e) {
        debugPrint('PromoCodeRepository.getPromoCodes remote fallback: $e');
      }
    }

    // Return in-memory cached promo codes
    return activeOnly
        ? _cachedPromoCodes.where((c) => c.isActive).toList()
        : List.unmodifiable(_cachedPromoCodes);
  }

  /// Validates a customer-entered promo code against active codes and subtotal amount.
  Future<PromoCodeValidationResult> validatePromoCode({
    required String code,
    required double orderAmount,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return PromoCodeValidationResult.failure('Please enter a promo code');
    }

    final allCodes = await getPromoCodes(activeOnly: false);
    final match = allCodes.cast<PromoCode?>().firstWhere(
      (p) => p?.code.toUpperCase() == cleanCode,
      orElse: () => null,
    );

    if (match == null) {
      return PromoCodeValidationResult.failure(
        'Invalid promo code "$cleanCode". Please check and try again.',
      );
    }

    if (!match.isActive) {
      return PromoCodeValidationResult.failure(
        'Promo code "$cleanCode" is no longer active.',
      );
    }

    if (match.expiresAt != null && match.expiresAt!.isBefore(DateTime.now())) {
      return PromoCodeValidationResult.failure(
        'Promo code "$cleanCode" has expired.',
      );
    }

    if (orderAmount < match.minOrderAmount) {
      return PromoCodeValidationResult.failure(
        'Code "$cleanCode" requires a minimum order of ৳${match.minOrderAmount.toStringAsFixed(0)}. Add ৳${(match.minOrderAmount - orderAmount).toStringAsFixed(0)} more!',
      );
    }

    final discount = match.calculateDiscount(orderAmount);
    if (discount <= 0) {
      return PromoCodeValidationResult.failure('No discount applicable for this order.');
    }

    return PromoCodeValidationResult.success(
      promo: match,
      discount: discount,
    );
  }

  /// Admin operation: Create and publish a new promo code.
  Future<PromoCode> createPromoCode(PromoCode promo) async {
    // 1. Add to local memory cache
    final existingIdx = _cachedPromoCodes.indexWhere((c) => c.code.toUpperCase() == promo.code.toUpperCase());
    if (existingIdx != -1) {
      _cachedPromoCodes[existingIdx] = promo;
    } else {
      _cachedPromoCodes.insert(0, promo);
    }

    // 2. Persist to Supabase if available
    if (!_isLocalOnly) {
      try {
        await _client.from(SupabaseConstants.tableVouchers).upsert(promo.toJson());
      } catch (e) {
        debugPrint('PromoCodeRepository.createPromoCode remote sync: $e');
      }
    }

    return promo;
  }

  /// Admin operation: Toggle promo code active status.
  Future<void> togglePromoCode(String id, bool isActive) async {
    final idx = _cachedPromoCodes.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _cachedPromoCodes[idx] = _cachedPromoCodes[idx].copyWith(isActive: isActive);
    }

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableVouchers)
            .update({'is_active': isActive})
            .eq('id', id);
      } catch (e) {
        debugPrint('PromoCodeRepository.togglePromoCode remote sync: $e');
      }
    }
  }

  /// Admin operation: Delete a promo code.
  Future<void> deletePromoCode(String id) async {
    _cachedPromoCodes.removeWhere((c) => c.id == id);

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableVouchers)
            .delete()
            .eq('id', id);
      } catch (e) {
        debugPrint('PromoCodeRepository.deletePromoCode remote sync: $e');
      }
    }
  }

  /// Records usage count increment when an order with promo code is completed.
  Future<void> recordPromoUsage(String code) async {
    final cleanCode = code.trim().toUpperCase();
    final idx = _cachedPromoCodes.indexWhere((c) => c.code.toUpperCase() == cleanCode);
    if (idx != -1) {
      final updated = _cachedPromoCodes[idx].copyWith(
        usedCount: _cachedPromoCodes[idx].usedCount + 1,
      );
      _cachedPromoCodes[idx] = updated;

      if (!_isLocalOnly) {
        try {
          await _client
              .from(SupabaseConstants.tableVouchers)
              .update({'used_count': updated.usedCount})
              .eq('code', cleanCode);
        } catch (_) {}
      }
    }
  }
}
