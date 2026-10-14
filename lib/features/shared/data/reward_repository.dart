import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../core/constants/supabase_constants.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../models/reward.dart';

/// Provider for RewardRepository
final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RewardRepository(client);
});

class RewardRepository {
  RewardRepository(this._client);

  final supa.SupabaseClient _client;

  bool get _isLocalOnly =>
      _client.rest.url.contains('placeholder') ||
      _client.rest.url.contains('test');

  // Shared in-memory list across the application session
  static final List<Reward> _cachedRewards = Reward.defaultRewards();
  static final Set<String> _cachedClaimedRewardIds = {};
  static final Set<String> _cachedUsedRewardIds = {};

  /// Fetches all active, non-expired rewards.
  /// If [userId] is provided, resolves whether the user has claimed/used them.
  Future<List<Reward>> getActiveRewards({String? userId}) async {
    final now = DateTime.now();

    if (!_isLocalOnly) {
      try {
        // Query active rewards where expires_at is in the future
        final response = await _client
            .from(SupabaseConstants.tableRewards)
            .select()
            .eq('is_active', true)
            .gt('expires_at', now.toIso8601String())
            .order('created_at', ascending: false);

        final rawList = (response as List<dynamic>);

        // Query user claimed status if userId is available
        Map<String, bool> userClaimMap = {}; // rewardId -> isUsed
        if (userId != null && userId.isNotEmpty) {
          try {
            final claimsResponse = await _client
                .from(SupabaseConstants.tableUserRewards)
                .select('reward_id, is_used')
                .eq('user_id', userId);

            for (final row in (claimsResponse as List<dynamic>)) {
              final rId = row['reward_id'] as String;
              final used = (row['is_used'] as bool?) ?? false;
              userClaimMap[rId] = used;
              _cachedClaimedRewardIds.add(rId);
              if (used) _cachedUsedRewardIds.add(rId);
            }
          } catch (claimErr) {
            debugPrint('RewardRepository.claims query note: $claimErr');
          }
        }

        final remoteList = rawList.map((e) {
          final map = e as Map<String, dynamic>;
          final id = map['id'] as String;
          final isClaimed = userClaimMap.containsKey(id) || _cachedClaimedRewardIds.contains(id);
          final isUsed = userClaimMap[id] == true || _cachedUsedRewardIds.contains(id);
          return Reward.fromJson(map, isClaimed: isClaimed, isUsed: isUsed);
        }).toList();

        if (remoteList.isNotEmpty) {
          // Sync into local cache
          for (final item in remoteList) {
            final idx = _cachedRewards.indexWhere((r) => r.id == item.id);
            if (idx != -1) {
              _cachedRewards[idx] = item;
            } else {
              _cachedRewards.add(item);
            }
          }
          return remoteList.where((r) => r.isValid).toList();
        }
      } catch (e) {
        debugPrint('RewardRepository.getActiveRewards remote fallback: $e');
      }
    }

    // Fallback: Return in-memory active rewards that haven't expired
    return _cachedRewards
        .where((r) => r.isValid)
        .map((r) => r.copyWith(
              isClaimed: _cachedClaimedRewardIds.contains(r.id),
              isUsed: _cachedUsedRewardIds.contains(r.id),
            ))
        .toList();
  }

  /// Fetches all rewards (including expired and inactive) for Admin management.
  Future<List<Reward>> getAllRewardsForAdmin() async {
    if (!_isLocalOnly) {
      try {
        final response = await _client
            .from(SupabaseConstants.tableRewards)
            .select()
            .order('created_at', ascending: false);

        final list = (response as List<dynamic>)
            .map((e) => Reward.fromJson(e as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) {
          for (final item in list) {
            final idx = _cachedRewards.indexWhere((r) => r.id == item.id);
            if (idx != -1) {
              _cachedRewards[idx] = item;
            } else {
              _cachedRewards.add(item);
            }
          }
          return list;
        }
      } catch (e) {
        debugPrint('RewardRepository.getAllRewardsForAdmin fallback: $e');
      }
    }

    return List.unmodifiable(_cachedRewards);
  }

  /// Claims a reward for a customer.
  Future<bool> claimReward({required String rewardId, required String userId}) async {
    _cachedClaimedRewardIds.add(rewardId);

    // Update in-memory reward item
    final idx = _cachedRewards.indexWhere((r) => r.id == rewardId);
    if (idx != -1) {
      _cachedRewards[idx] = _cachedRewards[idx].copyWith(isClaimed: true);
    }

    if (!_isLocalOnly && userId.isNotEmpty) {
      try {
        await _client.from(SupabaseConstants.tableUserRewards).upsert({
          'user_id': userId,
          'reward_id': rewardId,
          'is_used': false,
          'claimed_at': DateTime.now().toIso8601String(),
        });
        return true;
      } catch (e) {
        debugPrint('RewardRepository.claimReward remote error: $e');
      }
    }
    return true;
  }

  /// Marks a claimed reward as used on a completed checkout order.
  Future<void> markRewardAsUsed({required String rewardId, required String userId}) async {
    _cachedUsedRewardIds.add(rewardId);

    final idx = _cachedRewards.indexWhere((r) => r.id == rewardId);
    if (idx != -1) {
      _cachedRewards[idx] = _cachedRewards[idx].copyWith(isUsed: true);
    }

    if (!_isLocalOnly && userId.isNotEmpty) {
      try {
        await _client
            .from(SupabaseConstants.tableUserRewards)
            .update({
              'is_used': true,
              'used_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('reward_id', rewardId);
      } catch (e) {
        debugPrint('RewardRepository.markRewardAsUsed error: $e');
      }
    }
  }

  /// Admin posts a new reward with a set deadline.
  Future<Reward> createReward({
    required String title,
    required String description,
    required double minOrderAmount,
    required double discountValue,
    String discountType = 'flat',
    required DateTime expiresAt,
    String? createdBy,
  }) async {
    final newReward = Reward(
      id: 'rew-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      minOrderAmount: minOrderAmount,
      discountValue: discountValue,
      discountType: discountType,
      expiresAt: expiresAt,
      isActive: true,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    _cachedRewards.insert(0, newReward);

    if (!_isLocalOnly) {
      try {
        final inserted = await _client
            .from(SupabaseConstants.tableRewards)
            .insert(newReward.toJson())
            .select()
            .single();

        return Reward.fromJson(inserted);
      } catch (e) {
        debugPrint('RewardRepository.createReward remote error: $e');
      }
    }

    return newReward;
  }

  /// Admin toggles a reward active/inactive.
  Future<void> toggleRewardStatus(String rewardId, bool isActive) async {
    final idx = _cachedRewards.indexWhere((r) => r.id == rewardId);
    if (idx != -1) {
      _cachedRewards[idx] = _cachedRewards[idx].copyWith(isActive: isActive);
    }

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableRewards)
            .update({'is_active': isActive})
            .eq('id', rewardId);
      } catch (e) {
        debugPrint('RewardRepository.toggleRewardStatus error: $e');
      }
    }
  }

  /// Admin deletes a reward.
  Future<void> deleteReward(String rewardId) async {
    _cachedRewards.removeWhere((r) => r.id == rewardId);

    if (!_isLocalOnly) {
      try {
        await _client
            .from(SupabaseConstants.tableRewards)
            .delete()
            .eq('id', rewardId);
      } catch (e) {
        debugPrint('RewardRepository.deleteReward error: $e');
      }
    }
  }
}
