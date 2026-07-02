import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class EmailOtpDialog extends StatefulWidget {
  const EmailOtpDialog({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
  });

  final String email;
  final Future<bool> Function(String otp) onVerify;
  final Future<bool> Function() onResend;

  @override
  State<EmailOtpDialog> createState() => _EmailOtpDialogState();
}

class _EmailOtpDialogState extends State<EmailOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  String? _errorText;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String get _maskedEmail {
    final parts = widget.email.trim().split('@');
    if (parts.length != 2 || parts.first.isEmpty) return '****';
    final name = parts.first;
    final visible = name.length <= 2
        ? name.characters.first
        : name.substring(0, 2);
    return '$visible****@${parts.last}';
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(otp)) {
      setState(() => _errorText = 'Please enter a valid OTP');
      return;
    }

    setState(() {
      _errorText = null;
      _isVerifying = true;
    });

    final verified = await widget.onVerify(otp);
    if (!mounted) return;

    setState(() => _isVerifying = false);
    if (verified) Get.back(result: true);
  }

  Future<void> _resendOtp() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    await widget.onResend();
    if (!mounted) return;
    setState(() => _isResending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SemiBoldText(
              text: 'Please enter otp which sent to this mail $_maskedEmail',
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
              align: TextAlign.center,
            ),
            Spacing.v8,
            AppText(
              text: 'Verify your email to continue registration.',
              fontSize: TextStyles.k12FontSize,
              color: kColorTextGrey,
              align: TextAlign.center,
            ),
            Spacing.v20,
            TextField(
              controller: _otpController,
              focusNode: _otpFocusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyles.kSemiBoldPoppins(
                fontSize: TextStyles.k22FontSize,
                colors: kColorText,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'OTP',
                errorText: _errorText,
                filled: true,
                fillColor: kColorWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kColorTextFieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kColorTextFieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kColorPrimary),
                ),
              ),
              onSubmitted: (_) => _verifyOtp(),
            ),
            Spacing.v20,
            appButton(
              onPressed: _isVerifying ? () {} : _verifyOtp,
              buttonText: _isVerifying ? 'Verifying...' : 'Verify OTP',
            ),
            Spacing.v12,
            TextButton(
              onPressed: _isResending ? null : _resendOtp,
              child: AppText(
                text: _isResending ? 'Sending...' : 'Resend OTP',
                fontSize: TextStyles.k14FontSize,
                color: kColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
