import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/user_role.dart';

/// Shared account-role tag: User, Host, Super Admin, Agency, Coin Seller.
///
/// Pass [userId] for the person on screen. When that person is the signed-in
/// account, the tag uses their account role instead of a room seat label.
/// [useMyRole] does the same when the seat belongs to the current host but
/// the id on the seat does not match the profile id.
/// Name and role tag on one line. The name ellipsizes, and the pair scales
/// down together when a long tag such as Super Admin does not fit the tile.
class RoleBadgeLine extends StatelessWidget {
  const RoleBadgeLine({
    super.key,
    required this.label,
    required this.badge,
    this.centered = false,
    this.alignEnd = false,
    this.gap = 4,
  });

  final Widget label;
  final Widget badge;
  final bool centered;
  final bool alignEnd;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final bounded = maxWidth.isFinite;
        final nameCap = bounded
            ? (maxWidth - 92).clamp(32.0, maxWidth)
            : double.infinity;
        final alignment = centered
            ? Alignment.center
            : alignEnd
            ? Alignment.centerRight
            : Alignment.centerLeft;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: nameCap),
                child: label,
              ),
              SizedBox(width: gap),
              badge,
            ],
          ),
        );
      },
    );
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.compact = false,
    this.userId,
    this.useMyRole = false,
  });

  final String role;
  final bool compact;
  final String? userId;
  final bool useMyRole;

  @override
  Widget build(BuildContext context) {
    final look = _lookFor(_resolvedRole());
    final fontSize = compact ? 10.0 : TextStyles.k12FontSize;
    final disc = compact ? 14.0 : 18.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: look.colors,
        ),
        border: Border.all(
          color: look.text == kColorWhite
              ? kColorWhite.withValues(alpha: 0.85)
              : const Color(0xFFFFF6D8),
          width: 1,
        ),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: look.colors.last.withValues(alpha: 0.32),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 3 : 5,
          compact ? 2 : 3,
          compact ? 8 : 10,
          compact ? 2 : 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: disc,
              height: disc,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kColorWhite.withValues(alpha: 0.42),
                    look.text.withValues(alpha: 0.16),
                  ],
                ),
              ),
              child: Icon(
                look.icon,
                size: compact ? 10 : 12,
                color: look.text,
              ),
            ),
            SizedBox(width: compact ? 4 : 5),
            Text(
              look.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                height: 1,
                fontWeight: FontWeight.w700,
                color: look.text,
                fontFamily: Font.AsapSemiBold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolvedRole() {
    if (!Get.isRegistered<UserSessionController>()) {
      return normalizeUserRole(role);
    }
    final session = Get.find<UserSessionController>();
    return roleShownForPerson(
      fallbackRole: role,
      personId: userId ?? '',
      sessionUserId: session.userId,
      sessionRole: session.effectiveRole,
      forceSessionRole: useMyRole,
    );
  }
}

class _RoleLook {
  const _RoleLook({
    required this.label,
    required this.icon,
    required this.colors,
    required this.text,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color text;
}

_RoleLook _lookFor(String role) {
  return switch (role) {
    'super_admin' => const _RoleLook(
      label: 'Super Admin',
      icon: Icons.workspace_premium_rounded,
      colors: [Color(0xFFFFF3B0), Color(0xFFFFC44D), Color(0xFFE56B00)],
      text: Color(0xFF3A2408),
    ),
    'coins_seller' => const _RoleLook(
      label: 'Coin Seller',
      icon: Icons.paid_rounded,
      colors: [Color(0xFFFFF1A8), Color(0xFFF5C451), Color(0xFFD97706)],
      text: Color(0xFF3A2408),
    ),
    'agency' => const _RoleLook(
      label: 'Agency',
      icon: Icons.apartment_rounded,
      colors: [Color(0xFF7DD3FC), Color(0xFF2563EB), Color(0xFF1E3A8A)],
      text: kColorWhite,
    ),
    'host' => const _RoleLook(
      label: 'Host',
      icon: Icons.mic_rounded,
      colors: [Color(0xFFFF8AC4), Color(0xFFFF3D8A), Color(0xFFBE185D)],
      text: kColorWhite,
    ),
    _ => const _RoleLook(
      label: 'User',
      icon: Icons.person_rounded,
      colors: [Color(0xFFC4B5FD), Color(0xFF8B5CF6), Color(0xFF5B21B6)],
      text: kColorWhite,
    ),
  };
}
