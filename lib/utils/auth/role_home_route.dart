import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/profile/stored_profile_map.dart';

/// Resolves the post-auth home route from login/profile `role`.
///
/// Guide roles: `super_admin` | `agency` | `host` | `user`.
abstract final class RoleHomeRoute {
  RoleHomeRoute._();

  static UserSessionController _session() {
    return Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : Get.put(UserSessionController(), permanent: true);
  }

  /// Route for the current in-memory role (loads storage only if role is empty).
  static Future<String> resolve() async {
    final session = _session();
    if (session.role.isEmpty) {
      await session.loadFromStorage();
    }
    return _routeForSession(session);
  }

  /// Syncs [merged] profile into session, then returns home route without
  /// depending on a storage re-read (keeps login reliable after save).
  static Future<String> resolveAfterLogin(Map<String, dynamic> merged) async {
    final session = _session();
    final profile = coalesceStoredProfileMap(merged);
    await session.saveProfile(profile);
    return _routeForSession(session);
  }

  static Future<void> goHome() async {
    final route = await resolve();
    Get.offAllNamed(route);
  }

  static String _routeForSession(UserSessionController session) {
    if (session.isSuperAdmin) {
      return Routes.SUPER_ADMIN_BOTTOM_NAV;
    }
    // Isolation: agency owners only use the agency owner shell — never the
    // consumer bottom nav (guide: agency_super_admin_isolation_flow_v1.md).
    if (session.isAgency) {
      return Routes.AGENCY_OWNER;
    }
    // Host / user keep the standard consumer bottom nav.
    return Routes.BOTTOM_NAV;
  }
}
