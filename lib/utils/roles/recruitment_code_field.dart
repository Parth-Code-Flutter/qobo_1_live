import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
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
    this.readOnly = false,
  });
  final RecruitmentCodeVerification verification;
  final String label;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Obx(
    () {
      final verified = verification.isVerified.value;
      final checking = verification.isChecking.value;
      final message = verification.message.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.title,
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: verification.input,
            readOnly: readOnly,
            hintText: 'Enter code',
            borderColor: AppLightUi.borderStrong,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            prefix: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                Icons.vpn_key_outlined,
                color: AppLightUi.muted,
                size: 20,
              ),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Code is required' : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: checking ? null : verification.verify,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: verified
                        ? const LinearGradient(
                            colors: [Color(0xFF2E9F6E), Color(0xFF1F7A54)],
                          )
                        : AppLightUi.familyCtaGradient,
                    boxShadow: AppLightUi.cardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        verified
                            ? Icons.verified_rounded
                            : Icons.check_circle_outline_rounded,
                        color: kColorWhite,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        checking
                            ? 'Verifying…'
                            : verified
                            ? 'Verified'
                            : 'Verify code',
                        style: TextStyles.kSemiBoldPoppins(
                          colors: kColorWhite,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyles.kRegularPoppins(
                colors: verified
                    ? const Color(0xFF1F7A54)
                    : Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    },
  );
}
