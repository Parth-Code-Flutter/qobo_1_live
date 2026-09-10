import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/roles/recruitment_code_verification.dart';

class RecruitmentCodeField extends StatelessWidget {
  const RecruitmentCodeField({
    super.key,
    required this.verification,
    required this.label,
  });
  final RecruitmentCodeVerification verification;
  final String label;

  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorText,
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: verification.input,
          hintText: 'Enter code',
          borderColor: kColorHint,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          prefix: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.vpn_key_outlined, color: kColorHint, size: 20),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Code is required' : null,
        ),
        TextButton.icon(
          onPressed: verification.isChecking.value ? null : verification.verify,
          icon: Icon(
            verification.isVerified.value
                ? Icons.verified
                : Icons.check_circle_outline,
          ),
          label: Text(
            verification.isChecking.value ? 'Verifying…' : 'Verify code',
          ),
        ),
        if (verification.message.value.isNotEmpty)
          Text(
            verification.message.value,
            style: TextStyle(
              color: verification.isVerified.value
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
      ],
    ),
  );
}
