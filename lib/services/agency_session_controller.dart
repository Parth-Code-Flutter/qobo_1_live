import 'package:get/get.dart';

/// In-memory agency context for owner UI (register → dashboard → sub-screens).
/// API binding will hydrate this from backend later.
class AgencySessionController extends GetxController {
  final hasAgency = false.obs;
  final agencyId = ''.obs;
  final agencyName = ''.obs;
  final agencyCode = ''.obs;
  final commissionRate = 0.0.obs;
  final status = ''.obs;
  final recruitLink = ''.obs;

  void setAgency({
    required String id,
    required String name,
    required String code,
    double commission = 0.10,
    String agencyStatus = 'active',
    String? link,
  }) {
    agencyId.value = id;
    agencyName.value = name;
    agencyCode.value = code;
    commissionRate.value = commission;
    status.value = agencyStatus;
    recruitLink.value =
        link ?? 'https://qobo1.live/invite/${code.trim().toUpperCase()}';
    hasAgency.value = true;
  }

  void clearAgency() {
    hasAgency.value = false;
    agencyId.value = '';
    agencyName.value = '';
    agencyCode.value = '';
    commissionRate.value = 0;
    status.value = '';
    recruitLink.value = '';
  }

  String get commissionPercentLabel {
    final pct = (commissionRate.value * 100).round();
    return '$pct%';
  }
}
