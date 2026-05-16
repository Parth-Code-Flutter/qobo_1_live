import 'package:get/get.dart';
import '../controllers/agency_revenue_controller.dart';

class AgencyRevenueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyRevenueController>(
      () => AgencyRevenueController(),
    );
  }
}
