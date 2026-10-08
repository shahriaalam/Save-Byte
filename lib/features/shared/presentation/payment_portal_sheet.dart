import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// The result returned by the payment gateway flow.
class PaymentResult {
  final bool isSuccess;
  final String? gateway;
  final String? transactionId;
  final double amount;
  final String? errorMessage;

  const PaymentResult({
    required this.isSuccess,
    this.gateway,
    this.transactionId,
    required this.amount,
    this.errorMessage,
  });
}

/// Opens the high-fidelity SaveBite Payment Portal modal sheet.
///
/// Returns [PaymentResult] indicating whether the transaction was approved
/// and verified, or cancelled/failed.
Future<PaymentResult?> showPaymentPortalSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required double amount,
  required String customerOrBusinessName,
  List<String> perkHighlights = const [],
  String itemType = 'subscription',
}) {
  return showModalBottomSheet<PaymentResult>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PaymentPortalModal(
      title: title,
      subtitle: subtitle,
      amount: amount,
      customerOrBusinessName: customerOrBusinessName,
      perkHighlights: perkHighlights,
      itemType: itemType,
    ),
  );
}

class _PaymentPortalModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String customerOrBusinessName;
  final List<String> perkHighlights;
  final String itemType;

  const _PaymentPortalModal({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.customerOrBusinessName,
    required this.perkHighlights,
    required this.itemType,
  });

  @override
  State<_PaymentPortalModal> createState() => _PaymentPortalModalState();
}

class _PaymentPortalModalState extends State<_PaymentPortalModal>
    with SingleTickerProviderStateMixin {
  // Selected gateway: 'bkash', 'nagad', 'rocket', 'card'
  String _selectedGateway = 'bkash';

  // Form controllers
  final TextEditingController _accountCtrl =
      TextEditingController(text: '01712345678');
  final TextEditingController _pinCtrl = TextEditingController(text: '1234');
  final TextEditingController _cardNumberCtrl =
      TextEditingController(text: '4242 •••• •••• 4242');
  final TextEditingController _cardExpiryCtrl =
      TextEditingController(text: '09/28');
  final TextEditingController _cardCvvCtrl = TextEditingController(text: '881');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Payment execution state: 'idle', 'processing', 'success', 'failed'
  String _paymentState = 'idle';
  String _processingMessage = 'Connecting to Secure Gateway...';
  String? _generatedTxnId;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _pinCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _executePayment() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _paymentState = 'processing';
      _processingMessage = 'Connecting to Bangladesh Bank NPSB...';
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() {
      _processingMessage =
          'Validating $_gatewayDisplayName Account & Credentials...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _processingMessage = 'Authorizing ${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(0)} Transfer...';
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final randomId =
        '${_selectedGateway.toUpperCase()}-${Random().nextInt(8999) + 1000}-${Random().nextInt(89999) + 10000}';
    _generatedTxnId = randomId;

    setState(() {
      _paymentState = 'success';
    });

    _animCtrl.forward();

    // Auto-complete after showing green success confirmation
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    Navigator.of(context).pop(
      PaymentResult(
        isSuccess: true,
        gateway: _gatewayDisplayName,
        transactionId: _generatedTxnId,
        amount: widget.amount,
      ),
    );
  }

  String get _gatewayDisplayName {
    switch (_selectedGateway) {
      case 'bkash':
        return 'bKash';
      case 'nagad':
        return 'Nagad';
      case 'rocket':
        return 'Rocket';
      case 'card':
        return 'Visa / Mastercard';
      default:
        return 'bKash';
    }
  }

  Color get _gatewayBrandColor {
    switch (_selectedGateway) {
      case 'bkash':
        return const Color(0xFFD12053); // bKash iconic magenta
      case 'nagad':
        return const Color(0xFFF7921E); // Nagad iconic orange
      case 'rocket':
        return const Color(0xFF8C3494); // Rocket iconic purple
      case 'card':
        return const Color(0xFF1E3A8A); // Card rich navy
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _paymentState == 'processing' || _paymentState == 'success'
              ? _buildProcessingOverlay()
              : _buildCheckoutContent(),
        ),
      ),
    );
  }

  Widget _buildCheckoutContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle
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
            const SizedBox(height: 14),

            // Header row with SSL badge & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SaveBite Secure Pay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '256-Bit SSL Encrypted Payment Portal',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.of(context).pop(
                    PaymentResult(isSuccess: false, amount: widget.amount),
                  ),
                  splashRadius: 20,
                  tooltip: 'Cancel Payment',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Order / Subscription Plan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.subtitle} • For ${widget.customerOrBusinessName}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          '${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (widget.perkHighlights.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.perkHighlights.map((perk) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 13, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  perk,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Gateway Header
            const Text(
              'SELECT PAYMENT GATEWAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            // 4 Gateway Selection Chips
            Row(
              children: [
                Expanded(
                  child: _buildGatewayTab(
                    key: 'bkash',
                    name: 'bKash',
                    color: const Color(0xFFD12053),
                    icon: Icons.account_balance_wallet_rounded,
                    tag: 'Popular',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGatewayTab(
                    key: 'nagad',
                    name: 'Nagad',
                    color: const Color(0xFFF7921E),
                    icon: Icons.payments_rounded,
                    tag: 'Direct',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGatewayTab(
                    key: 'rocket',
                    name: 'Rocket',
                    color: const Color(0xFF8C3494),
                    icon: Icons.phone_android_rounded,
                    tag: 'DBBL',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGatewayTab(
                    key: 'card',
                    name: 'Card',
                    color: const Color(0xFF1E3A8A),
                    icon: Icons.credit_card_rounded,
                    tag: 'Visa/MC',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Interactive Gateway Form Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _gatewayBrandColor.withValues(alpha: 0.35),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gatewayBrandColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _gatewayBrandColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_gatewayDisplayName Checkout',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _gatewayBrandColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gatewayBrandColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sandbox / Verified',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _gatewayBrandColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_selectedGateway == 'card') ...[
                    // Card Fields
                    TextFormField(
                      controller: _cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        hintText: '4242 4242 4242 4242',
                        prefixIcon: const Icon(Icons.credit_card, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter card number'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cardExpiryCtrl,
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(
                              labelText: 'MM/YY',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _cardCvvCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Mobile Banking Fields (bKash / Nagad / Rocket)
                    TextFormField(
                      controller: _accountCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: '$_gatewayDisplayName Mobile Number',
                        hintText: '017XXXXXXXX',
                        prefixIcon: const Icon(Icons.phone_iphone_rounded,
                            size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter valid mobile number'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '4-Digit $_gatewayDisplayName PIN',
                        hintText: '••••',
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 20),
                        helperText: 'Sandbox verification: enter any 4 digits',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 4) ? 'Enter 4-digit PIN' : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _gatewayBrandColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _executePayment,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pay ${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(0)} via $_gatewayDisplayName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Disclaimer & Terms
            Center(
              child: Text(
                'By confirming, you agree to SaveBite Payment Terms. Features activate automatically upon verified gateway clearance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B).withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayTab({
    required String key,
    required String name,
    required Color color,
    required IconData icon,
    required String tag,
  }) {
    final isSelected = _selectedGateway == key;

    return InkWell(
      onTap: () => setState(() => _selectedGateway = key),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
            const SizedBox(height: 3),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              tag,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    final isSuccess = _paymentState == 'success';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSuccess) ...[
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _gatewayBrandColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: _gatewayBrandColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Payment...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _processingMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please do not close or leave this screen.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ] else ...[
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _animCtrl,
                curve: Curves.elasticOut,
              ),
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Approved! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paid ${AppConstants.currencySymbol}${widget.amount.toStringAsFixed(0)} via $_gatewayDisplayName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 6),
            if (_generatedTxnId != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Transaction ID: $_generatedTxnId',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'Unlocking premium features now...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
