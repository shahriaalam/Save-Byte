import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../models/reward.dart';
import 'reward_repository.dart';

/// Provider for active customer rewards (auto-filtered for non-expired items).
final activeRewardsProvider = FutureProvider<List<Reward>>((ref) async {
  final repo = ref.watch(rewardRepositoryProvider);
  final profile = ref.watch(currentUserProfileProvider);
  return repo.getActiveRewards(userId: profile?.id);
});

/// Provider for all rewards (used by Admin dashboard).
final allAdminRewardsProvider = FutureProvider<List<Reward>>((ref) async {
  final repo = ref.watch(rewardRepositoryProvider);
  return repo.getAllRewardsForAdmin();
});

/// Controller for Rewards state management, claim operations, and admin creation.
final rewardControllerProvider =
    AsyncNotifierProvider<RewardController, List<Reward>>(RewardController.new);

class RewardController extends AsyncNotifier<List<Reward>> {
  @override
  Future<List<Reward>> build() async {
    final repo = ref.watch(rewardRepositoryProvider);
    final profile = ref.watch(currentUserProfileProvider);
    return repo.getActiveRewards(userId: profile?.id);
  }

  /// Claims a reward for the logged-in customer.
  Future<bool> claimReward(String rewardId) async {
    final profile = ref.read(currentUserProfileProvider);
    final userId = profile?.id ?? 'guest-customer';
    final repo = ref.read(rewardRepositoryProvider);

    final success = await repo.claimReward(rewardId: rewardId, userId: userId);
    if (success) {
      ref.invalidate(activeRewardsProvider);
      state = AsyncData(await repo.getActiveRewards(userId: userId));
    }
    return success;
  }

  /// Marks a reward as redeemed upon order checkout completion.
  Future<void> redeemReward(String rewardId) async {
    final profile = ref.read(currentUserProfileProvider);
    final userId = profile?.id ?? 'guest-customer';
    final repo = ref.read(rewardRepositoryProvider);

    await repo.markRewardAsUsed(rewardId: rewardId, userId: userId);
    ref.invalidate(activeRewardsProvider);
    state = AsyncData(await repo.getActiveRewards(userId: userId));
  }

  /// Admin operation: Post a new reward with an expiration deadline.
  Future<Reward?> createReward({
    required String title,
    required String description,
    required double minOrderAmount,
    required double discountValue,
    String discountType = 'flat',
    required DateTime expiresAt,
  }) async {
    state = const AsyncLoading();
    try {
      final profile = ref.read(currentUserProfileProvider);
      final repo = ref.read(rewardRepositoryProvider);

      final newReward = await repo.createReward(
        title: title,
        description: description,
        minOrderAmount: minOrderAmount,
        discountValue: discountValue,
        discountType: discountType,
        expiresAt: expiresAt,
        createdBy: profile?.id,
      );

      ref.invalidate(activeRewardsProvider);
      ref.invalidate(allAdminRewardsProvider);
      state = AsyncData(await repo.getActiveRewards(userId: profile?.id));
      return newReward;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  /// Admin operation: Toggle reward active status.
  Future<void> toggleStatus(String id, bool isActive) async {
    final repo = ref.read(rewardRepositoryProvider);
    await repo.toggleRewardStatus(id, isActive);
    ref.invalidate(activeRewardsProvider);
    ref.invalidate(allAdminRewardsProvider);
    final profile = ref.read(currentUserProfileProvider);
    state = AsyncData(await repo.getActiveRewards(userId: profile?.id));
  }

  /// Admin operation: Delete reward.
  Future<void> deleteReward(String id) async {
    final repo = ref.read(rewardRepositoryProvider);
    await repo.deleteReward(id);
    ref.invalidate(activeRewardsProvider);
    ref.invalidate(allAdminRewardsProvider);
    final profile = ref.read(currentUserProfileProvider);
    state = AsyncData(await repo.getActiveRewards(userId: profile?.id));
  }
}
