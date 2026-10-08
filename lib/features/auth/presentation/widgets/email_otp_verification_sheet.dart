import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/auth_state.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_controller.dart';

/// The purpose of the OTP verification request.
enum OtpPurpose {
  registration,
  deletion,
}

/// Modal bottom sheet for verifying user email with a 6-digit OTP during account registration or deletion.
class EmailOtpVerificationSheet extends ConsumerStatefulWidget {
  const EmailOtpVerificationSheet({
    required this.email,
    this.initialOtp,
    this.purpose = OtpPurpose.registration,
    super.key,
  });

  final String email;
  final String? initialOtp;
  final OtpPurpose purpose;

  /// Displays the modal sheet and returns true if OTP was verified successfully.
  static Future<bool> show({
    required BuildContext context,
    required String email,
    String? initialOtp,
    OtpPurpose purpose = OtpPurpose.registration,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => EmailOtpVerificationSheet(
        email: email,
        initialOtp: initialOtp,
        purpose: purpose,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<EmailOtpVerificationSheet> createState() =>
      _EmailOtpVerificationSheetState();
}

class _EmailOtpVerificationSheetState
    extends ConsumerState<EmailOtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isVerifying = false;
  String? _errorMessage;
  String? _currentOtpCode;

  Timer? _resendTimer;
  int _secondsRemaining = 45;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentOtpCode = widget.initialOtp;
    // The field starts empty so user must enter the OTP code sent to their email
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _secondsRemaining = 45;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    setState(() {
      _errorMessage = null;
    });

    final String newOtp;
    if (widget.purpose == OtpPurpose.deletion) {
      newOtp = await ref
          .read(authControllerProvider.notifier)
          .sendDeletionOtp(widget.email);
    } else {
      newOtp = await ref
          .read(authControllerProvider.notifier)
          .sendRegistrationOtp(widget.email);
    }

    if (!mounted) return;

    setState(() {
      _currentOtpCode = newOtp;
    });

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A fresh verification code was sent to ${widget.email}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final bool isValid;
    if (widget.purpose == OtpPurpose.deletion) {
      isValid = await ref
          .read(authControllerProvider.notifier)
          .verifyDeletionOtp(
            email: widget.email,
            otp: code,
          );
    } else {
      isValid = await ref
          .read(authControllerProvider.notifier)
          .verifyRegistrationOtp(
            email: widget.email,
            otp: code,
          );
    }

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (isValid) {
      Navigator.of(context).pop(true);
    } else {
      final authState = ref.read(authControllerProvider);
      setState(() {
        _errorMessage = (authState is AuthError)
            ? authState.message
            : 'Invalid verification code. Please check your email and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDeletion = widget.purpose == OtpPurpose.deletion;
    final accentColor = isDeletion ? const Color(0xFFDC2626) : AppColors.primary;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top drag handle
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),

                // Icon Badge
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.14),
                        accentColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isDeletion
                          ? Icons.delete_forever_rounded
                          : Icons.mark_email_read_rounded,
                      color: accentColor,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Heading
                Text(
                  isDeletion ? 'Confirm Account Deletion' : 'Verify Your Email',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle with highlighted email
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: isDeletion
                            ? 'Enter the 6-digit security code sent to\n'
                            : 'Enter the 6-digit confirmation code sent to\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isDeletion)
                        const TextSpan(
                          text: '\nto confirm permanent deletion of your account.',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6-BOX OTP INPUT PIN DISPLAY
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hidden Actual TextField
                      Opacity(
                        opacity: 0.0,
                        child: SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: TextField(
                            key: const Key('otp_input_field'),
                            controller: _otpController,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            autofocus: true,
                            onChanged: (val) {
                              setState(() {
                                _errorMessage = null;
                              });
                              if (val.length == 6) {
                                _handleVerify();
                              }
                            },
                          ),
                        ),
                      ),

                      // Visual 6 PIN Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final text = _otpController.text;
                          final hasValue = index < text.length;
                          final isCurrent = index == text.length;
                          final char = hasValue ? text[index] : '';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.5),
                            width: 44,
                            height: 52,
                            decoration: BoxDecoration(
                              color: hasValue
                                  ? accentColor.withValues(alpha: 0.05)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent
                                    ? accentColor
                                    : (hasValue
                                        ? accentColor.withValues(alpha: 0.6)
                                        : const Color(0xFFE2E8F0)),
                                width: isCurrent ? 2 : 1.2,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                char,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // Error Message if any
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Test / Demo helper pill (clickable to fill for easy test & dev)
                GestureDetector(
                  onTap: () {
                    final code = _currentOtpCode ?? '123456';
                    _otpController.text = code;
                    setState(() {
                      _errorMessage = null;
                    });
                    if (code.length == 6) {
                      _handleVerify();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Demo / Test Code: ${_currentOtpCode ?? "123456"}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Action Button
                if (isDeletion)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isVerifying ? null : _handleVerify,
                      child: _isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Verify & Delete Account',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  )
                else
                  PrimaryButton(
                    text: 'Verify & Activate Account',
                    isLoading: _isVerifying,
                    onPressed: _handleVerify,
                  ),
                const SizedBox(height: 12),

                // Resend Timer Row
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the email?",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _canResend
                        ? TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              foregroundColor: accentColor,
                            ),
                            onPressed: _handleResend,
                            child: const Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : Text(
                            'Resend in ${_secondsRemaining.toString().padLeft(2, '0')}s',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                  ],
                ),

                // Back / Cancel option
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    isDeletion
                        ? 'Cancel and keep my account'
                        : 'Wrong email? Go back and change',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
