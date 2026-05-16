import 'package:get/get.dart';
import '../controllers/agency_recruit_link_controller.dart';

class AgencyRecruitLinkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyRecruitLinkController>(
      () => AgencyRecruitLinkController(),
    );
  }
}
