import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';

/// Self-service host dashboard; financial details use the existing wallet flow.
class HostDashboardView extends StatelessWidget {
  const HostDashboardView({super.key});

  TextStyle _text(
    double size, {
    Color color = Colors.white,
    bool bold = false,
  }) => TextStyle(
    fontFamily: 'Poppins',
    fontSize: size,
    color: color,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
  );

  Widget _action({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: appShellGlassDecoration(radius: 20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  AdminAgencyUi.glowIcon(icon: icon, accent: accent, size: 46),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: _text(14, bold: true)),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: _text(11, color: AdminAgencyUi.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AdminAgencyUi.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppShellBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Row(
                  children: [
                    Semantics(
                      label: 'Back',
                      button: true,
                      child: AdminAgencyUi.glassIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => Get.back(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Host Dashboard', style: _text(20, bold: true)),
                          Text(
                            'Your space to shine',
                            style: _text(12, color: AdminAgencyUi.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GetBuilder<UserSessionController>(
                  builder: (session) {
                    if (!session.isHost) {
                      return Center(
                        child: Text(
                          'Host approval is required.',
                          style: _text(14),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AdminAgencyUi.violet,
                      onRefresh: () async {
                        await session.refreshProfileFromApi();
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: appShellGlassDecoration(radius: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppUserAvatar(
                                      name: session.displayName,
                                      imageUrl: session.displayPicturePath,
                                      size: 62,
                                      border: Border.all(
                                        color: AdminAgencyUi.gold,
                                        width: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.displayName,
                                            style: _text(19, bold: true),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Approved Host',
                                            style: _text(
                                              11,
                                              color: AdminAgencyUi.gold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (session.agencyCode.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  const Divider(
                                    color: Color(0x26FFFFFF),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.apartment_rounded,
                                        color: AdminAgencyUi.violet,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Agency · ${session.agencyCode}',
                                          style: _text(
                                            12,
                                            color: AdminAgencyUi.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF68208A), Color(0xFF392068)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AdminAgencyUi.pink.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.live_tv_rounded,
                                  color: AdminAgencyUi.gold,
                                  size: 32,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ready for your next live?',
                                  style: _text(20, bold: true),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Connect with your audience and share your moment.',
                                  style: _text(
                                    12,
                                    color: AdminAgencyUi.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                AdminGoldCtaButton(
                                  label: 'Go live',
                                  icon: Icons.videocam_rounded,
                                  expanded: true,
                                  onTap: () {
                                    // Use the same access-checked entry point as
                                    // the main Go Live button, not the old map.
                                    final live =
                                        Get.isRegistered<LiveRoomController>()
                                        ? Get.find<LiveRoomController>()
                                        : Get.put(LiveRoomController());
                                    live.openGoLive();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text('Your activity', style: _text(17, bold: true)),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your wallet and explore your gifts.',
                            style: _text(12, color: AdminAgencyUi.textMuted),
                          ),
                          const SizedBox(height: 16),
                          _action(
                            title: 'Wallet & withdrawals',
                            subtitle:
                                'View your balance and manage withdrawals',
                            icon: Icons.account_balance_wallet_outlined,
                            accent: AdminAgencyUi.violet,
                            onTap: () => Get.to(
                              () => const WalletView(),
                              binding: WalletBinding(),
                            ),
                          ),
                          _action(
                            title: 'Gift transactions',
                            subtitle: 'See your gift transaction history',
                            icon: Icons.redeem_rounded,
                            accent: AdminAgencyUi.pink,
                            onTap: () => Get.toNamed(Routes.GIFT_TRANSACTIONS),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
