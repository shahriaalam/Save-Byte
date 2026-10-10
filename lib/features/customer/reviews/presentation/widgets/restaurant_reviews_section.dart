import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:save_bite/core/constants/app_colors.dart';
import '../../../../shared/data/review_controller.dart';
import '../../../../shared/models/review.dart';
import 'review_card.dart';

/// Embedded section on the Restaurant Details screen rendering aggregated customer
/// reviews, star breakdown bars, verified badges, and reviews with attached food photos.
class RestaurantReviewsSection extends ConsumerStatefulWidget {
  const RestaurantReviewsSection({
    required this.restaurantId,
    required this.restaurantName,
    super.key,
  });

  final String restaurantId;
  final String restaurantName;

  @override
  ConsumerState<RestaurantReviewsSection> createState() =>
      _RestaurantReviewsSectionState();
}

class _RestaurantReviewsSectionState
    extends ConsumerState<RestaurantReviewsSection> {
  bool _onlyWithPhotos = false;

  @override
  Widget build(BuildContext context) {
    final reviewsAsync =
        ref.watch(restaurantReviewsProvider(widget.restaurantId));
    final summaryAsync =
        ref.watch(restaurantRatingSummaryProvider(widget.restaurantId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                const SizedBox(width: 6),
                const Text(
                  'Reviews & Ratings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 6),
                reviewsAsync.maybeWhen(
                  data: (reviews) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${reviews.length}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Rating Summary Card
        summaryAsync.when(
          data: (summary) => _buildRatingSummaryCard(summary),
          loading: () => const SizedBox(height: 80),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),

        // Filter chips (All vs With Photos)
        Row(
          children: [
            ChoiceChip(
              label: const Text('All Reviews', style: TextStyle(fontSize: 11.5)),
              selected: !_onlyWithPhotos,
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              onSelected: (val) {
                if (val) setState(() => _onlyWithPhotos = false);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: const Icon(Icons.photo_camera_outlined, size: 14),
              label: const Text('With Photos', style: TextStyle(fontSize: 11.5)),
              selected: _onlyWithPhotos,
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              onSelected: (val) {
                setState(() => _onlyWithPhotos = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Reviews List
        reviewsAsync.when(
          data: (reviews) {
            final filtered = _onlyWithPhotos
                ? reviews.where((r) => r.hasImage).toList()
                : reviews;

            if (filtered.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        size: 36, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      _onlyWithPhotos
                          ? 'No reviews with photos yet.'
                          : 'No reviews yet for this restaurant.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Reviews appear here after verified meal pickups.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: filtered.map((r) => ReviewCard(review: r)).toList(),
            );
          },
          loading: () => const SizedBox(height: 60),
          error: (err, _) => Center(
            child: Text(
              'Could not load reviews: $err',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummaryCard(RestaurantRatingSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          // Left: Big Rating Score & Stars
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    summary.formattedAverage,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ 5.0',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  return const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.totalReviews} verified reviews',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Vertical divider
          Container(
            height: 60,
            width: 1,
            color: const Color(0xFFFDE68A),
          ),
          const SizedBox(width: 16),
          // Right: Star Breakdown Bars
          Expanded(
            child: Column(
              children: [
                _buildStarRow(5, summary.fiveStarRatio, summary.fiveStarCount),
                _buildStarRow(4, summary.fourStarRatio, summary.fourStarCount),
                _buildStarRow(3, summary.threeStarRatio, summary.threeStarCount),
                _buildStarRow(2, summary.twoStarRatio, summary.twoStarCount),
                _buildStarRow(1, summary.oneStarRatio, summary.oneStarCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(int stars, double ratio, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            '$stars★',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF78350F),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFFEF3C7),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 16,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
