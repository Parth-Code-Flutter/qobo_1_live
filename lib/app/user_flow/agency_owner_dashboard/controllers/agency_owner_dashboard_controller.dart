import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_dashboard_data.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/auth/role_home_route.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

class AgencyOwnerDashboardController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();
  final AuthRepo _authRepo = AuthRepo();

  AgencySessionController get _session => Get.find<AgencySessionController>();

  UserSessionController get _userSession =>
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController(), permanent: true);

  final isLoading = true.obs;
  final loadError = ''.obs;
  final dashboard = Rxn<AgencyDashboardData>();

  final isApplicationPending = false.obs;
  final pendingAgencyName = ''.obs;
  final pendingMessage = ''.obs;
  final isLoggingOut = false.obs;

  /// Required for Super Admin (`GET /api/agency/dashboard?agency_id=`).
  String _viewAsAgencyId = '';

  @override
  void onInit() {
    super.onInit();
    _readRouteAgencyId();
    if (!_assertAgencyOwnerAccess()) return;
    if (_userSession.isSuperAdmin && _viewAsAgencyId.isEmpty) {
      isLoading.value = false;
      loadError.value =
          'Select an agency to view its dashboard. Super Admin must pass agency_id.';
      return;
    }
    loadDashboard();
  }

  void _readRouteAgencyId() {
    final args = Get.arguments;
    if (args is! Map) return;
    final id =
        args['agencyId']?.toString().trim() ??
        args['agency_id']?.toString().trim() ??
        '';
    _viewAsAgencyId = id;
  }

  /// Isolation: host/coin-seller must not use agency-owner APIs or shell.
  /// Agency owners and super admins may open the dashboard.
  bool _assertAgencyOwnerAccess() {
    if (!Get.isRegistered<UserSessionController>()) return true;
    final session = Get.find<UserSessionController>();
    if (session.isAgency || session.isSuperAdmin || session.role.isEmpty) {
      return true;
    }
    // Mid-registration users may still open status/dashboard after apply.
    if (session.role.toLowerCase() == 'user') return true;
    RoleHomeRoute.goHome();
    return false;
  }

  Future<void> loadDashboard({bool showLoader = true}) async {
    isLoading.value = true;
    loadError.value = '';
    isApplicationPending.value = false;
    try {
      if (_userSession.isSuperAdmin && _viewAsAgencyId.isEmpty) {
        loadError.value =
            'Select an agency to view its dashboard. Super Admin must pass agency_id.';
        dashboard.value = null;
        return;
      }

      final response = await _agencyRepo.getAgencyDashboard(
        agencyId: _viewAsAgencyId.isNotEmpty ? _viewAsAgencyId : null,
        isShowLoader: showLoader,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        final parsed = AgencyDashboardData.fromJson(
          Map<String, dynamic>.from(data),
        );
        if (parsed.isApproved) {
          dashboard.value = parsed;
          isApplicationPending.value = false;
          await _session.applyDashboardResponse(parsed);
          return;
        }
        if (parsed.isPending || isAgencyStatusPending(parsed.agencyStatus)) {
          dashboard.value = null;
          isApplicationPending.value = true;
          pendingAgencyName.value = parsed.agencyName.isNotEmpty
              ? parsed.agencyName
              : _session.appliedAgencyName.value;
          pendingMessage.value =
              agencyApiMessage(response) ??
              'Your agency application is pending. Super admin will review it soon.';
          await _session.applyDashboardResponse(parsed);
          return;
        }
      }

      if (_session.isApplicationPending) {
        isApplicationPending.value = true;
        pendingAgencyName.value = _session.appliedAgencyName.value;
        pendingMessage.value =
            agencyApiMessage(response) ??
            'Your agency application is pending. Super admin will review it soon.';
        dashboard.value = null;
        return;
      }

      dashboard.value = null;
      loadError.value =
          agencyApiMessage(response) ?? 'Unable to load agency dashboard.';
    } catch (_) {
      if (_session.isApplicationPending) {
        isApplicationPending.value = true;
        pendingAgencyName.value = _session.appliedAgencyName.value;
        pendingMessage.value =
            'Your agency application is pending. Pull to refresh after approval.';
        dashboard.value = null;
      } else {
        dashboard.value = null;
        loadError.value = 'Network error. Please try again.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasDashboard => dashboard.value != null;

  String get displayAgencyName {
    final fromApi = dashboard.value?.agencyName.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final cached = _session.agencyName.value.trim();
    return cached.isNotEmpty ? cached : '—';
  }

  String get displayAgencyCode {
    final fromApi = dashboard.value?.agencyCode.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final cached = _session.agencyCode.value.trim();
    return cached.isNotEmpty ? cached : '—';
  }

  String get displayOwnerName {
    final name = dashboard.value?.ownerName.trim();
    return (name != null && name.isNotEmpty) ? name : '—';
  }

  String get displayMonth => dashboard.value?.month.trim() ?? '';

  int get ownerCoinsPerSecond => dashboard.value?.ownerCoinsPerSecond ?? 0;

  AgencyCallSample? get latestCall => dashboard.value?.latestCall;

  List<AgencyHostRevenueDemo> get hosts => dashboard.value?.hosts ?? const [];

  int get totalAgencyEarnings => dashboard.value?.totalAgencyEarnings ?? 0;

  int get companyShare => dashboard.value?.companyShare ?? 0;

  int get hostCallShare => dashboard.value?.hostCallShare ?? 0;

  int get ownerCommission => dashboard.value?.ownerCommissionCoins ?? 0;

  int get totalGifts => dashboard.value?.totalGiftsVolume ?? 0;

  int get availableForPayout => dashboard.value?.availableForPayout ?? 0;

  int get activeHostsCount => dashboard.value?.activeHosts ?? 0;

  int get hostRecruitmentEarningsCoins =>
      dashboard.value?.hostRecruitmentEarningsCoins ?? 0;

  double get hostRecruitmentEarningsDollars =>
      dashboard.value?.hostRecruitmentEarningsDollars ?? 0;

  void openRecruitLink() {
    Get.toNamed(Routes.AGENCY_RECRUIT_LINK);
  }

  void openHostList() {
    Get.toNamed(Routes.AGENCY_HOST_LIST);
  }

  Future<void> openPendingHosts() async {
    await Get.toNamed<void>(Routes.AGENCY_PENDING_HOSTS);
    if (isClosed) return;
    await loadDashboard(showLoader: false);
  }

  int get pendingHostApplicationsCount =>
      dashboard.value?.pendingHostApplications ?? 0;

  List<AgencyPendingApplicationPreview> get pendingApplicationsPreview =>
      dashboard.value?.pendingApplications ?? const [];

  void openRevenue() {
    Get.toNamed(Routes.AGENCY_REVENUE);
  }

  void openRegisterAgency() {
    Get.toNamed(Routes.AGENCY_OWNER_REGISTER);
  }

  void openHostDetail(AgencyHostRevenueDemo host) {
    openHostList();
  }

  /// Edit profile (same update-profile screen as consumer / super admin).
  void openEditProfile() {
    Get.toNamed(Routes.UPDATE_PROFILE);
  }

  /// Clears agency + user session and returns to login (same path as bottom nav).
  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    try {
      final storage = LocalStorage.shared;
      await _authRepo.logout(isShowLoader: false);
      if (Get.isRegistered<ChatSessionService>()) {
        await Get.find<ChatSessionService>().signOut();
      }
      await UserRealtimeSocketService.ensureDisconnected();
      if (Get.isRegistered<FcmTokenSyncService>()) {
        Get.find<FcmTokenSyncService>().clearCachedToken();
      }
      if (Get.isRegistered<AgencySessionController>()) {
        await Get.find<AgencySessionController>().clearAgency();
      }
      await _userSession.clearSession();
      await storage.clearAllData();
      Get.offAllNamed(Routes.AUTH_LOGIN);
    } finally {
      isLoggingOut.value = false;
    }
  }
}
