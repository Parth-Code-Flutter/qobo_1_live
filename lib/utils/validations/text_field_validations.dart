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
const String kEmptyOrgId = 'Organization ID is required';

class Validate {
  /// EMAIL ID VALIDATION
  static emailValidation(BuildContext context, String v) {
    if (v.trim().isEmpty) {
      return kEmptyEmail;
    } else if (!v.isEmail) {
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

  /// 10-DIGIT PHONE NUMBER VALIDATION
  static phone10DigitValidation(BuildContext context, String v) {
    final phone = v.trim();
    if (phone.isEmpty) {
      return kEmptyPhone;
    } else if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Please enter a valid 10-digit phone number';
    } else {
      return null;
    }
  }

  /// NAME VALIDATION
  static nameValidation(BuildContext context, String v,
      {bool isOrgId = false}) {
    if (v.isEmpty) {
      return isOrgId ? kEmptyOrgId : kEmptyName;
    } else {
      return null;
    }
  }

  /// PASSWORD VALIDATION
  static passwordValidation(BuildContext context, String v,
      {String? customMsg}) {
    if (v.isEmpty) {
      return customMsg ?? kEmptyPassword;
    } else {
      return null;
    }
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

  /// OTP VALIDATION
  static otpValidation(BuildContext context, String v, {int otpLength = 6}) {
    if (v.trim().isEmpty) {
      return kEmptyOtp;
    } else if (v.length != otpLength) {
      return 'Please enter a valid $otpLength-digit OTP';
    } else {
      return null;
    }
  }
}
