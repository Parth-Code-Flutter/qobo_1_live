import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        TextFormField(
          controller: verification.input,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null,
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
