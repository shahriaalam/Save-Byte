import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerMembershipState {
  final bool isSuperSaver;
  final String planName;
  final DateTime? expiresAt;
  final DateTime? activatedAt;
  final double lastPaidAmount;

  const CustomerMembershipState({
    required this.isSuperSaver,
    required this.planName,
    this.expiresAt,
    this.activatedAt,
    this.lastPaidAmount = 99.0,
  });

  CustomerMembershipState copyWith({
    bool? isSuperSaver,
    String? planName,
    DateTime? expiresAt,
    DateTime? activatedAt,
    double? lastPaidAmount,
    bool clearDates = false,
  }) {
    return CustomerMembershipState(
      isSuperSaver: isSuperSaver ?? this.isSuperSaver,
      planName: planName ?? this.planName,
      expiresAt: clearDates ? null : (expiresAt ?? this.expiresAt),
      activatedAt: clearDates ? null : (activatedAt ?? this.activatedAt),
      lastPaidAmount: lastPaidAmount ?? this.lastPaidAmount,
    );
  }
}

class CustomerMembershipController
    extends Notifier<CustomerMembershipState> {
  static const _keyIsActive = 'customer_is_super_saver';
  static const _keyExpires = 'customer_super_saver_expires';
  static const _keyPlan = 'customer_super_saver_plan';

  @override
  CustomerMembershipState build() {
    _loadFromStorage();
    return const CustomerMembershipState(
      isSuperSaver: false,
      planName: 'Super Saver Monthly',
      expiresAt: null,
      activatedAt: null,
      lastPaidAmount: 99.0,
    );
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_keyIsActive) ?? false;
      final expiresIso = prefs.getString(_keyExpires);
      final plan = prefs.getString(_keyPlan) ?? 'Super Saver Monthly';

      DateTime? expires;
      if (expiresIso != null) {
        expires = DateTime.tryParse(expiresIso);
      }

      final valid = isActive && (expires == null || expires.isAfter(DateTime.now()));

      state = state.copyWith(
        isSuperSaver: valid,
        planName: plan,
        expiresAt: expires,
        activatedAt: valid ? DateTime.now().subtract(const Duration(days: 1)) : null,
      );
    } catch (_) {}
  }

  Future<void> activateMembership({
    double amount = 99.0,
    String plan = 'Super Saver Monthly',
  }) async {
    final now = DateTime.now();
    final expires = now.add(const Duration(days: 30));

    state = state.copyWith(
      isSuperSaver: true,
      planName: plan,
      activatedAt: now,
      expiresAt: expires,
      lastPaidAmount: amount,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsActive, true);
      await prefs.setString(_keyExpires, expires.toIso8601String());
      await prefs.setString(_keyPlan, plan);
    } catch (_) {}
  }

  Future<void> cancelMembership() async {
    state = state.copyWith(
      isSuperSaver: false,
      clearDates: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsActive, false);
      await prefs.remove(_keyExpires);
    } catch (_) {}
  }
}

final customerMembershipProvider =
    NotifierProvider<CustomerMembershipController, CustomerMembershipState>(
  CustomerMembershipController.new,
);
