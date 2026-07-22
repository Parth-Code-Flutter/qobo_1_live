import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

// Validation error messages
const String kEmptyEmail = 'Email is required';
const String kValidEmail = 'Please enter a valid email address';
const String kEmptyPhone = 'Phone number is required';
const String kValidPhone = 'Please enter a valid phone number';
const String kEmptyName = 'Name is required';
const String kEmptyPassword = 'Password is required';
const String kEmptyConfirmPassword = 'Confirm password is required';
const String kValidConfirmPassword = 'Passwords do not match';
const String kEmptyOtp = 'OTP is required';
const String kValidOtp = 'Please enter a valid OTP';
const String kOtpNumbersOnly = 'OTP must contain numbers only';
const String kEmptyOrgId = 'Organization ID is required';
const String kPhone10Digits = 'Please enter a valid 10-digit phone number';

class Validate {
  /// EMAIL ID VALIDATION
  static emailValidation(BuildContext context, String v) {
    final email = v.trim();
    if (email.isEmpty) {
      return kEmptyEmail;
    } else if (!email.isEmail) {
      return kValidEmail;
    } else {
      return null;
    }
  }

  /// PHONE NUMBER VALIDATION
  static phoneValidation(BuildContext context, String v) {
    if (v.trim().isEmpty) {
      return kEmptyPhone;
    } else if (!v.isPhoneNumber) {
      return kValidPhone;
    } else {
      return null;
    }
  }

  /// 10-DIGIT PHONE / WHATSAPP VALIDATION (digits only).
  static phone10DigitValidation(BuildContext context, String v) {
    final phone = v.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      return kEmptyPhone;
    } else if (phone.length != 10) {
      return kPhone10Digits;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      // Indian mobile numbers typically start with 6–9.
      return kPhone10Digits;
    } else {
      return null;
    }
  }

  /// NAME VALIDATION
  static nameValidation(BuildContext context, String v,
      {bool isOrgId = false, String label = 'Name'}) {
    final name = v.trim();
    if (name.isEmpty) {
      return isOrgId ? kEmptyOrgId : '$label is required';
    }
    if (name.length < 2) {
      return 'Enter at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s.'.-]+$").hasMatch(name)) {
      return 'Enter a valid $label';
    }
    return null;
  }

  /// Agency / business display name.
  static agencyNameValidation(BuildContext context, String v) {
    final name = v.trim();
    if (name.isEmpty) return 'Agency name is required';
    if (name.length < 2) return 'Agency name must be at least 2 characters';
    if (name.length > 80) return 'Agency name must be under 80 characters';
    return null;
  }

  /// PASSWORD VALIDATION
  static passwordValidation(BuildContext context, String v,
      {String? customMsg, int minLength = 6}) {
    final password = v.trim();
    if (password.isEmpty) {
      return customMsg ?? kEmptyPassword;
    }
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Country dial code like `+91` or `91`.
  static countryCodeValidation(BuildContext context, String v) {
    final code = v.trim();
    if (code.isEmpty) return 'Country code is required';
    if (!RegExp(r'^\+?\d{1,4}$').hasMatch(code)) {
      return 'Enter a valid country code (e.g. +91)';
    }
    return null;
  }

  /// CONFIRM PASSWORD VALIDATION
  static confirmPasswordValidation(BuildContext context, String v1, String v2) {
    if (v1.isEmpty) {
      return kEmptyConfirmPassword;
    } else if (v1 != v2) {
      return kValidConfirmPassword;
    } else {
      return null;
    }
  }

  /// OTP VALIDATION (digits only, fixed length).
  static otpValidation(BuildContext context, String v, {int otpLength = 6}) {
    final otp = v.trim();
    if (otp.isEmpty) {
      return kEmptyOtp;
    }
    if (!RegExp(r'^\d+$').hasMatch(otp)) {
      return kOtpNumbersOnly;
    }
    if (otp.length != otpLength) {
      return 'Please enter a valid $otpLength-digit OTP';
    }
    return null;
  }
}
