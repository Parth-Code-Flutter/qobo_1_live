import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';

/// A verification result belongs only to the exact input that was checked.
class RecruitmentCodeVerification {
  RecruitmentCodeVerification(this.input, this.verifyRequest) {
    input.addListener(_invalidate);
  }

  final TextEditingController input;
  final Future<Map<String, dynamic>?> Function(String) verifyRequest;
  final isChecking = false.obs;
  final isVerified = false.obs;
  final message = ''.obs;
  String _verifiedCode = '';
  bool _disposed = false;
  int _revision = 0;

  String get verifiedCode =>
      isVerified.value && input.text.trim() == _verifiedCode
      ? _verifiedCode
      : '';

  void _invalidate() {
    _revision++;
    _verifiedCode = '';
    isVerified.value = false;
    message.value = '';
  }

  Future<bool> verify() async {
    if (isChecking.value || _disposed) return false;
    final code = input.text.trim();
    if (code.isEmpty) {
      message.value = 'Enter a code first.';
      return false;
    }
    final revision = _revision;
    isChecking.value = true;
    isVerified.value = false;
    _verifiedCode = '';
    try {
      final response = await verifyRequest(code);
      if (_disposed || revision != _revision) return false;
      final data = response?['data'];
      if (!isAgencyApiSuccess(response) ||
          data is! Map ||
          data['valid'] != true) {
        message.value =
            agencyApiMessage(response) ?? 'Code could not be verified.';
        return false;
      }
      _verifiedCode = code;
      isVerified.value = true;
      final name = data['superAdminName'] ?? data['agencyName'];
      message.value = name == null ? 'Code verified.' : 'Verified: $name';
      return true;
    } catch (_) {
      if (!_disposed && revision == _revision) {
        message.value = 'Unable to verify code. Try again.';
      }
      return false;
    } finally {
      if (!_disposed) isChecking.value = false;
    }
  }

  void dispose() {
    _disposed = true;
    input.removeListener(_invalidate);
  }
}
