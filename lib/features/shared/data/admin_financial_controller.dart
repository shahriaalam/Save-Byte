import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a single subscription or platform monetization transaction.
class SubscriptionTransaction {
  final String id;
  final String payerName;
  final String payerType; // 'restaurant' | 'customer'
  final String planName; // 'Gold Merchant Monthly' | 'Super Saver VIP Club' | 'Hero Banner 24h'
  final double amount;
  final String paymentGateway; // 'bKash' | 'Nagad' | 'Rocket' | 'Card'
  final String transactionId;
  final DateTime timestamp;
  final bool isSuccessful;

  const SubscriptionTransaction({
    required this.id,
    required this.payerName,
    required this.payerType,
    required this.planName,
    required this.amount,
    required this.paymentGateway,
    required this.transactionId,
    required this.timestamp,
    this.isSuccessful = true,
  });
}

/// Monthly earnings breakdown point for trend charts.
class MonthlyEarningsPoint {
  final String month;
  final double subscriptionEarnings;
  final double bannerEarnings;
  final double commissionEarnings;

  double get totalEarnings =>
      subscriptionEarnings + bannerEarnings + commissionEarnings;

  const MonthlyEarningsPoint({
    required this.month,
    required this.subscriptionEarnings,
    required this.bannerEarnings,
    required this.commissionEarnings,
  });
}

/// Revenue stream slice for pie/donut charts.
class RevenueSlice {
  final String category;
  final double amount;
  final int colorHex;
  final String iconKey;

  const RevenueSlice({
    required this.category,
    required this.amount,
    required this.colorHex,
    required this.iconKey,
  });
}

/// Banner run record tracking monthly performance.
class HeroBannerRun {
  final String slotId;
  final String bannerTitle;
  final String merchantName;
  final int daysActiveThisMonth;
  final int impressions;
  final double feeCharged;
  final String status; // 'ACTIVE' | 'SCHEDULED' | 'COMPLETED'
  final String themeKey;

  const HeroBannerRun({
    required this.slotId,
    required this.bannerTitle,
    required this.merchantName,
    required this.daysActiveThisMonth,
    required this.impressions,
    required this.feeCharged,
    required this.status,
    required this.themeKey,
  });
}

/// Holds all financial and telemetry data for Admin Dashboard.
class AdminFinancialState {
  final double monthlySubscriptionEarnings;
  final double totalPlatformEarnings;
  final int totalPartners;
  final int activeGoldMerchants;
  final int verifiedPartners;
  final int pendingPartners;
  final int heroBannersRunThisMonth;
  final int totalBannerImpressions;
  final int activeSuperSaverMembers;
  final List<SubscriptionTransaction> recentTransactions;
  final List<MonthlyEarningsPoint> monthlyHistory;
  final List<HeroBannerRun> bannerRuns;

  const AdminFinancialState({
    required this.monthlySubscriptionEarnings,
    required this.totalPlatformEarnings,
    required this.totalPartners,
    required this.activeGoldMerchants,
    required this.verifiedPartners,
    required this.pendingPartners,
    required this.heroBannersRunThisMonth,
    required this.totalBannerImpressions,
    required this.activeSuperSaverMembers,
    required this.recentTransactions,
    required this.monthlyHistory,
    required this.bannerRuns,
  });

  AdminFinancialState copyWith({
    double? monthlySubscriptionEarnings,
    double? totalPlatformEarnings,
    int? totalPartners,
    int? activeGoldMerchants,
    int? verifiedPartners,
    int? pendingPartners,
    int? heroBannersRunThisMonth,
    int? totalBannerImpressions,
    int? activeSuperSaverMembers,
    List<SubscriptionTransaction>? recentTransactions,
    List<MonthlyEarningsPoint>? monthlyHistory,
    List<HeroBannerRun>? bannerRuns,
  }) {
    return AdminFinancialState(
      monthlySubscriptionEarnings:
          monthlySubscriptionEarnings ?? this.monthlySubscriptionEarnings,
      totalPlatformEarnings:
          totalPlatformEarnings ?? this.totalPlatformEarnings,
      totalPartners: totalPartners ?? this.totalPartners,
      activeGoldMerchants: activeGoldMerchants ?? this.activeGoldMerchants,
      verifiedPartners: verifiedPartners ?? this.verifiedPartners,
      pendingPartners: pendingPartners ?? this.pendingPartners,
      heroBannersRunThisMonth:
          heroBannersRunThisMonth ?? this.heroBannersRunThisMonth,
      totalBannerImpressions:
          totalBannerImpressions ?? this.totalBannerImpressions,
      activeSuperSaverMembers:
          activeSuperSaverMembers ?? this.activeSuperSaverMembers,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      monthlyHistory: monthlyHistory ?? this.monthlyHistory,
      bannerRuns: bannerRuns ?? this.bannerRuns,
    );
  }

  /// Breakdown of revenue sources for donut/pie chart presentation.
  List<RevenueSlice> get revenueSlices {
    final bannerTotal =
        bannerRuns.fold<double>(0, (sum, b) => sum + b.feeCharged);
    return [
      RevenueSlice(
        category: 'Partner Gold Subscriptions',
        amount: activeGoldMerchants * 999.0 * 4.2,
        colorHex: 0xFFF59E0B,
        iconKey: 'gold',
      ),
      RevenueSlice(
        category: 'Super Saver VIP Club',
        amount: activeSuperSaverMembers * 99.0 * 1.5,
        colorHex: 0xFFE11D48,
        iconKey: 'club',
      ),
      RevenueSlice(
        category: 'Hero Banners & Ad Placements',
        amount: bannerTotal > 0 ? bannerTotal : 22500.0,
        colorHex: 0xFF6366F1,
        iconKey: 'banner',
      ),
      const RevenueSlice(
        category: 'Order Commission (5%)',
        amount: 28400.0,
        colorHex: 0xFF10B981,
        iconKey: 'fee',
      ),
    ];
  }
}

/// Manages live administrative financial state and real-time subscription recording.
class AdminFinancialController extends Notifier<AdminFinancialState> {
  @override
  AdminFinancialState build() {
    return AdminFinancialState(
      monthlySubscriptionEarnings: 52800.0,
      totalPlatformEarnings: 218500.0,
      totalPartners: 14,
      activeGoldMerchants: 8,
      verifiedPartners: 12,
      pendingPartners: 2,
      heroBannersRunThisMonth: 18,
      totalBannerImpressions: 42800,
      activeSuperSaverMembers: 112,
      bannerRuns: const [
        HeroBannerRun(
          slotId: 'SLOT #1',
          bannerTitle: 'International Coffee Day - North End 10% OFF',
          merchantName: 'North End Coffee Roasters',
          daysActiveThisMonth: 28,
          impressions: 16400,
          feeCharged: 6000.0,
          status: 'ACTIVE',
          themeKey: 'burgundy',
        ),
        HeroBannerRun(
          slotId: 'SLOT #2',
          bannerTitle: 'Fresh Surplus & Groceries',
          merchantName: 'Teal Mart Banasree',
          daysActiveThisMonth: 24,
          impressions: 14100,
          feeCharged: 4000.0,
          status: 'ACTIVE',
          themeKey: 'teal',
        ),
        HeroBannerRun(
          slotId: 'SLOT #3',
          bannerTitle: 'Pay Day Special - 55% to 75% OFF',
          merchantName: 'Kacchi Bhai Express',
          daysActiveThisMonth: 19,
          impressions: 12300,
          feeCharged: 4000.0,
          status: 'ACTIVE',
          themeKey: 'yellow',
        ),
      ],
      monthlyHistory: const [
        MonthlyEarningsPoint(
          month: 'May',
          subscriptionEarnings: 28000,
          bannerEarnings: 12000,
          commissionEarnings: 98000,
        ),
        MonthlyEarningsPoint(
          month: 'Jun',
          subscriptionEarnings: 34000,
          bannerEarnings: 14000,
          commissionEarnings: 112000,
        ),
        MonthlyEarningsPoint(
          month: 'Jul',
          subscriptionEarnings: 39000,
          bannerEarnings: 15500,
          commissionEarnings: 126000,
        ),
        MonthlyEarningsPoint(
          month: 'Aug',
          subscriptionEarnings: 44000,
          bannerEarnings: 16800,
          commissionEarnings: 139000,
        ),
        MonthlyEarningsPoint(
          month: 'Sep',
          subscriptionEarnings: 48500,
          bannerEarnings: 18200,
          commissionEarnings: 148500,
        ),
        MonthlyEarningsPoint(
          month: 'Oct',
          subscriptionEarnings: 52800,
          bannerEarnings: 22500,
          commissionEarnings: 143200,
        ),
      ],
      recentTransactions: [
        SubscriptionTransaction(
          id: 'tx-101',
          payerName: "Sultan's Dine Banasree",
          payerType: 'restaurant',
          planName: 'Gold Merchant Monthly',
          amount: 999.0,
          paymentGateway: 'bKash',
          transactionId: 'BK-8921-X99',
          timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
        SubscriptionTransaction(
          id: 'tx-102',
          payerName: 'Chillox Banani',
          payerType: 'restaurant',
          planName: 'Gold Merchant Monthly',
          amount: 999.0,
          paymentGateway: 'Nagad',
          transactionId: 'NG-4412-M03',
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        ),
        SubscriptionTransaction(
          id: 'tx-103',
          payerName: 'Farhan Ahmed (Consumer)',
          payerType: 'customer',
          planName: 'Super Saver VIP Club',
          amount: 99.0,
          paymentGateway: 'bKash',
          transactionId: 'BK-0923-C42',
          timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 12)),
        ),
        SubscriptionTransaction(
          id: 'tx-104',
          payerName: 'North End Coffee Roasters',
          payerType: 'restaurant',
          planName: 'Hero Banner Ad Slot (24h)',
          amount: 2000.0,
          paymentGateway: 'Card',
          transactionId: 'VISA-7781-B10',
          timestamp: DateTime.now().subtract(const Duration(hours: 7)),
        ),
        SubscriptionTransaction(
          id: 'tx-105',
          payerName: 'Nusrat Jahan (Consumer)',
          payerType: 'customer',
          planName: 'Super Saver VIP Club',
          amount: 99.0,
          paymentGateway: 'Nagad',
          transactionId: 'NG-8891-K19',
          timestamp: DateTime.now().subtract(const Duration(hours: 11)),
        ),
      ],
    );
  }

  /// Records a newly verified payment into the platform dashboard live.
  void recordSubscriptionPayment({
    required String payerName,
    required String payerType,
    required String planName,
    required double amount,
    required String paymentGateway,
    required String transactionId,
  }) {
    final newTx = SubscriptionTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      payerName: payerName,
      payerType: payerType,
      planName: planName,
      amount: amount,
      paymentGateway: paymentGateway,
      transactionId: transactionId,
      timestamp: DateTime.now(),
      isSuccessful: true,
    );

    final isSubscription = planName.toLowerCase().contains('gold') ||
        planName.toLowerCase().contains('saver') ||
        planName.toLowerCase().contains('subscription') ||
        planName.toLowerCase().contains('membership');

    final updatedTxList = [newTx, ...state.recentTransactions];

    state = state.copyWith(
      monthlySubscriptionEarnings: isSubscription
          ? state.monthlySubscriptionEarnings + amount
          : state.monthlySubscriptionEarnings,
      totalPlatformEarnings: state.totalPlatformEarnings + amount,
      activeGoldMerchants: payerType == 'restaurant' && isSubscription
          ? state.activeGoldMerchants + 1
          : state.activeGoldMerchants,
      activeSuperSaverMembers: payerType == 'customer' && isSubscription
          ? state.activeSuperSaverMembers + 1
          : state.activeSuperSaverMembers,
      recentTransactions: updatedTxList,
    );
  }

  /// Updates partner counts based on active restaurants directory.
  void updatePartnerCounts({
    required int total,
    required int gold,
    required int verified,
    required int pending,
  }) {
    state = state.copyWith(
      totalPartners: total,
      activeGoldMerchants: gold,
      verifiedPartners: verified,
      pendingPartners: pending,
    );
  }
}

final adminFinancialProvider =
    NotifierProvider<AdminFinancialController, AdminFinancialState>(
  AdminFinancialController.new,
);
