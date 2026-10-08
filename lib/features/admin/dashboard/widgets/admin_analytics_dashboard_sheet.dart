import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../shared/data/admin_financial_controller.dart';

/// Opens the comprehensive Admin Financial & Platform Analytics Dashboard sheet.
void showAdminAnalyticsDashboardSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AdminAnalyticsDashboardSheet(),
  );
}

class _AdminAnalyticsDashboardSheet extends ConsumerStatefulWidget {
  const _AdminAnalyticsDashboardSheet();

  @override
  ConsumerState<_AdminAnalyticsDashboardSheet> createState() =>
      _AdminAnalyticsDashboardSheetState();
}

class _AdminAnalyticsDashboardSheetState
    extends ConsumerState<_AdminAnalyticsDashboardSheet> {
  int _selectedPeriodIndex = 0; // 0 = Oct 2026, 1 = Sep 2026, 2 = Year-to-Date
  int _chartMode = 0; // 0 = Total Revenue, 1 = Subscriptions Only
  int _selectedDataPointIndex = 5; // Default Oct (latest)

  final List<String> _periods = const [
    'October 2026 (Live)',
    'September 2026',
    'Year-To-Date (2026)',
  ];

  @override
  Widget build(BuildContext context) {
    final finState = ref.watch(adminFinancialProvider);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          _buildHeader(context),

          // Scrollable Dashboard Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector Chips
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),

                  // 4 Hero KPI Cards
                  _buildKpiGrid(finState),
                  const SizedBox(height: 20),

                  // Section: Monthly Earnings Trend Graph
                  _buildGraphSection(finState),
                  const SizedBox(height: 20),

                  // Section: Revenue Streams Breakdown Pie Chart
                  _buildPieChartSection(finState),
                  const SizedBox(height: 20),

                  // Section: Hero Banner Runs This Month
                  _buildBannerRunsSection(finState),
                  const SizedBox(height: 20),

                  // Section: Recent Real-Time Subscription Transactions
                  _buildTransactionsSection(finState),
                  const SizedBox(height: 20),

                  // Export & Action Bar
                  _buildBottomActionBar(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Financial Dashboard',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                        SizedBox(width: 5),
                        Text(
                          'Live Monetization & Subscription Telemetry',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Color(0xFF64748B), size: 22),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = _selectedPeriodIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_periods[index]),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedPeriodIndex = index);
              },
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              selectedColor: const Color(0xFF1E293B),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKpiGrid(AdminFinancialState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Monthly Subscription Earning',
                value:
                    '${AppConstants.currencySymbol}${state.monthlySubscriptionEarnings.toStringAsFixed(0)}',
                badgeText: '+24.6% MoM',
                badgeColor: const Color(0xFF16A34A),
                subtext:
                    '${state.activeGoldMerchants} Gold Partners • ${state.activeSuperSaverMembers} Super Savers',
                icon: Icons.card_membership_rounded,
                gradient: const [Color(0xFFD97706), Color(0xFFB45309)],
                bgLight: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Platform Earning',
                value:
                    '${AppConstants.currencySymbol}${state.totalPlatformEarnings.toStringAsFixed(0)}',
                badgeText: 'Live GMV',
                badgeColor: const Color(0xFF2563EB),
                subtext: 'Subs + Banners + 5% Order Fees',
                icon: Icons.account_balance_wallet_rounded,
                gradient: const [Color(0xFF059669), Color(0xFF047857)],
                bgLight: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Partners',
                value: '${state.totalPartners} Kitchens',
                badgeText: '${state.activeGoldMerchants} Gold Active',
                badgeColor: const Color(0xFFD97706),
                subtext:
                    '${state.verifiedPartners} Verified • ${state.pendingPartners} Pending Review',
                icon: Icons.storefront_rounded,
                gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                bgLight: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFBFDBFE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Hero Banner Runs',
                value: '${state.heroBannersRunThisMonth} Runs',
                badgeText: 'This Month',
                badgeColor: const Color(0xFF8B5CF6),
                subtext:
                    '${state.totalBannerImpressions.toString()} Views • 3 Active Slots',
                icon: Icons.view_carousel_rounded,
                gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                bgLight: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFDDD6FE),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required String subtext,
    required IconData icon,
    required List<Color> gradient,
    required Color bgLight,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection(AdminFinancialState state) {
    final history = state.monthlyHistory;
    final selectedPoint = history[_selectedDataPointIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Earnings Growth',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Interactive Trend: May – Oct 2026',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              // Toggle Mode
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildGraphModeTab('Total', 0),
                    _buildGraphModeTab('Subs Only', 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Selected Month Tooltip Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedPoint.month} 2026 Focus',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Text(
                  _chartMode == 0
                      ? 'Total: ${AppConstants.currencySymbol}${selectedPoint.totalEarnings.toStringAsFixed(0)}'
                      : 'Subs: ${AppConstants.currencySymbol}${selectedPoint.subscriptionEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Custom Painted Chart
          SizedBox(
            height: 180,
            width: double.infinity,
            child: GestureDetector(
              onTapUp: (details) {
                final boxWidth = context.size?.width ?? 320;
                final tapX = details.localPosition.dx;
                final index = ((tapX / boxWidth) * history.length)
                    .floor()
                    .clamp(0, history.length - 1);
                setState(() => _selectedDataPointIndex = index);
              },
              child: CustomPaint(
                painter: _EarningsGraphPainter(
                  history: history,
                  selectedIndex: _selectedDataPointIndex,
                  showSubscriptionsOnly: _chartMode == 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // X-Axis Month Selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(history.length, (i) {
              final isSel = _selectedDataPointIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedDataPointIndex = i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    history[i].month,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphModeTab(String label, int mode) {
    final isSelected = _chartMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _chartMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF1E293B)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartSection(AdminFinancialState state) {
    // Slices configuration
    final slices = [
      RevenueSlice(
        category: 'Partner Gold Subscriptions',
        amount: state.activeGoldMerchants * 999.0 * 4.2, // ~34.5k
        colorHex: 0xFFF59E0B, // Amber
        iconKey: 'gold',
      ),
      RevenueSlice(
        category: 'Super Saver VIP Club',
        amount: state.activeSuperSaverMembers * 99.0 * 1.5, // ~16.6k
        colorHex: 0xFFE11D48, // Rose
        iconKey: 'club',
      ),
      RevenueSlice(
        category: 'Hero Banners & Ad Placements',
        amount: 22500.0,
        colorHex: 0xFF6366F1, // Indigo
        iconKey: 'banner',
      ),
      RevenueSlice(
        category: 'Order Rescue Commission (5%)',
        amount: 28400.0,
        colorHex: 0xFF10B981, // Emerald
        iconKey: 'fee',
      ),
    ];

    final totalRev = slices.fold<double>(0, (sum, s) => sum + s.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Streams Breakdown (Pie Chart)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Proportion of subscriptions, ad fees, and platform GMV',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Donut Chart & Center Text
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _RevenueDonutPainter(slices: slices),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL NET',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppConstants.currencySymbol}${(totalRev / 1000).toStringAsFixed(1)}k',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'October Net',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend Items
          Column(
            children: slices.map((s) {
              final pct = ((s.amount / totalRev) * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(s.colorHex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${AppConstants.currencySymbol}${(s.amount / 1000).toStringAsFixed(1)}k)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerRunsSection(AdminFinancialState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hero Banners Run for That Month',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Active carousel impressions, duration & ad fees',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.bannerRuns.length} Active Slots',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7E22CE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner Runs Cards
          Column(
            children: state.bannerRuns.map((run) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            run.slotId,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  size: 6, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                'LIVE ON APP',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      run.bannerTitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Promoted by ${run.merchantName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBannerMetricPill(
                            Icons.calendar_today_rounded,
                            '${run.daysActiveThisMonth} Days Run'),
                        _buildBannerMetricPill(Icons.visibility_rounded,
                            '${run.impressions} Views'),
                        _buildBannerMetricPill(Icons.payments_rounded,
                            'Fee: ${AppConstants.currencySymbol}${run.feeCharged.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerMetricPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(AdminFinancialState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-Time Subscription Feed',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Recent gateway clearances (bKash, Nagad, Cards)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Column(
            children: state.recentTransactions.map((tx) {
              final isBkash = tx.paymentGateway.toLowerCase().contains('bkash');
              final isNagad = tx.paymentGateway.toLowerCase().contains('nagad');
              final badgeColor = isBkash
                  ? const Color(0xFFD12053)
                  : (isNagad
                      ? const Color(0xFFF7921E)
                      : const Color(0xFF2563EB));

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        tx.payerType == 'restaurant'
                            ? Icons.storefront_rounded
                            : Icons.person_rounded,
                        color: badgeColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.payerName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${tx.planName} • ${tx.paymentGateway} (${tx.transactionId})',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${AppConstants.currencySymbol}${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              minimumSize: const Size(0, 46),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Financial summary statement exported (PDF/CSV). 📄'),
                  backgroundColor: Color(0xFF1E293B),
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text(
              'Export Audit CSV',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(0, 46),
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'Done',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering a smooth Bézier line and area gradient chart for monthly earnings.
class _EarningsGraphPainter extends CustomPainter {
  final List<MonthlyEarningsPoint> history;
  final int selectedIndex;
  final bool showSubscriptionsOnly;

  _EarningsGraphPainter({
    required this.history,
    required this.selectedIndex,
    required this.showSubscriptionsOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final values = history
        .map((p) =>
            showSubscriptionsOnly ? p.subscriptionEarnings : p.totalEarnings)
        .toList();

    final maxVal = values.reduce(max) * 1.15;
    final minVal = values.reduce(min) * 0.85;
    final range = maxVal - minVal;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dx = size.width / (values.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final normalized = (values[i] - minVal) / (range == 0 ? 1 : range);
      final y = size.height - (normalized * (size.height - 24)) - 12;
      points.add(Offset(i * dx, y));
    }

    // Gradient fill path under curve
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      path.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (showSubscriptionsOnly
                  ? const Color(0xFFD97706)
                  : const Color(0xFF6366F1))
              .withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke path
    final strokePaint = Paint()
      ..color = showSubscriptionsOnly
          ? const Color(0xFFD97706)
          : const Color(0xFF6366F1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Draw circular dots
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = i == selectedIndex;

      final dotBgPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final dotStrokePaint = Paint()
        ..color = isSelected
            ? const Color(0xFF1E293B)
            : (showSubscriptionsOnly
                ? const Color(0xFFD97706)
                : const Color(0xFF6366F1))
        ..strokeWidth = isSelected ? 3.5 : 2.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(pt, isSelected ? 7 : 4.5, dotBgPaint);
      canvas.drawCircle(pt, isSelected ? 7 : 4.5, dotStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsGraphPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.showSubscriptionsOnly != showSubscriptionsOnly ||
        oldDelegate.history != history;
  }
}

/// Custom painter rendering a segmented donut / pie chart with gaps.
class _RevenueDonutPainter extends CustomPainter {
  final List<RevenueSlice> slices;

  _RevenueDonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 24.0;

    final total = slices.fold<double>(0, (sum, s) => sum + s.amount);
    if (total == 0) return;

    double startAngle = -pi / 2;
    const gapAngle = 0.06; // Radians gap between slices

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    for (final slice in slices) {
      final sweepAngle = ((slice.amount / total) * 2 * pi) - gapAngle;

      final paint = Paint()
        ..color = Color(slice.colorHex)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (sweepAngle > 0) {
        canvas.drawArc(rect, startAngle + (gapAngle / 2), sweepAngle, false, paint);
      }

      startAngle += (slice.amount / total) * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueDonutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
