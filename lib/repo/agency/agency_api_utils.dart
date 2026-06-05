import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';

/// Shared success checks for agency API JSON bodies.
bool isAgencyApiSuccess(Map<String, dynamic>? response) {
  if (response == null) return false;
  final code = ApiResponseUtils.tryGetBodyStatusCode(response);
  return code == 1 ||
      code == 200 ||
      StatusCodeConstants.isApiSuccess(code);
}

String agencyCurrentMonthParam() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  return '${now.year}-$month';
}

const agencyMonthLabels = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// UI month label → API `YYYY-MM` (uses current calendar year).
String agencyMonthLabelToApi(String monthLabel) {
  final index = agencyMonthLabels.indexOf(monthLabel);
  if (index < 0) return agencyCurrentMonthParam();
  final year = DateTime.now().year;
  return '$year-${(index + 1).toString().padLeft(2, '0')}';
}

String? agencyApiMessage(Map<String, dynamic>? response) {
  if (response == null) return null;
  final msg = response['message'];
  return msg?.toString();
}

bool isAgencyStatusApproved(String? status) {
  final value = status?.trim().toLowerCase() ?? '';
  return value == 'active' || value == 'approved';
}

bool isAgencyStatusPending(String? status) {
  final value = status?.trim().toLowerCase() ?? '';
  return value == 'pending' ||
      value == 'under_review' ||
      value == 'under review' ||
      value == 'submitted';
}

/// Backend `dob` field format (`yyyy-MM-dd`).
String formatAgencyHostDob(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String? parseHostApplicationId(Map<String, dynamic>? data) {
  if (data == null) return null;
  final id = data['id'] ?? data['_id'] ?? data['applicationId'];
  final value = id?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
