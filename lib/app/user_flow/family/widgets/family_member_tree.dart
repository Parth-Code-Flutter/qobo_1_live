import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Role-based org tree or sponsor/invite lineage (`parentId`).
class FamilyMemberTree extends StatelessWidget {
  const FamilyMemberTree.role({
    super.key,
    required this.leaders,
    required this.officers,
    required this.members,
    required this.onMemberTap,
  }) : mode = FamilyTreeMode.role,
       rankingMembers = const [],
       sponsorRoots = const [],
       childrenOf = null;

  const FamilyMemberTree.sponsor({
    super.key,
    required this.sponsorRoots,
    required this.childrenOf,
    required this.onMemberTap,
  }) : mode = FamilyTreeMode.sponsor,
       rankingMembers = const [],
       leaders = const [],
       officers = const [],
       members = const [];

  const FamilyMemberTree.ranking({
    super.key,
    required this.rankingMembers,
    required this.onMemberTap,
  }) : mode = FamilyTreeMode.ranking,
       leaders = const [],
       officers = const [],
       members = const [],
       sponsorRoots = const [],
       childrenOf = null;

  final FamilyTreeMode mode;
  final List<Map<String, dynamic>> leaders;
  final List<Map<String, dynamic>> officers;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> rankingMembers;
  final List<Map<String, dynamic>> sponsorRoots;
  final List<Map<String, dynamic>> Function(String userId)? childrenOf;
  final ValueChanged<Map<String, dynamic>> onMemberTap;

  static const _gold = AdminAgencyUi.gold;
  static const _pink = AdminAgencyUi.pink;
  static const _violet = AdminAgencyUi.violet;
  static const _cyan = AdminAgencyUi.cyan;
  static const _panel = [Color(0xFF2A1748), Color(0xFF1A0B2E)];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _panel,
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: switch (mode) {
        FamilyTreeMode.role => _buildRole(),
        FamilyTreeMode.sponsor => _buildSponsor(),
        FamilyTreeMode.ranking => _buildRanking(),
      },
    );
  }

  Widget _buildRanking() {
    if (rankingMembers.isEmpty) {
      return _empty('No ranking data available yet.');
    }
    final first = rankingMembers.take(1).toList();
    final secondTier = rankingMembers.skip(1).take(2).toList();
    final thirdTier = rankingMembers.skip(3).take(4).toList();

    return Column(
      children: [
        _tierLabel('TOP CONTRIBUTOR', _gold),
        Spacing.v10,
        _rankingTierRow(first, startRank: 1, accent: _gold, nodeSize: 72),
        if (secondTier.isNotEmpty) ...[
          Spacing.v6,
          const _TreeConnector(height: 28),
          _rankingTierRow(
            secondTier,
            startRank: 2,
            accent: _cyan,
            nodeSize: 58,
          ),
        ],
        if (thirdTier.isNotEmpty) ...[
          Spacing.v6,
          const _TreeConnector(height: 28),
          _rankingTierRow(thirdTier, startRank: 4, accent: _pink, nodeSize: 50),
        ],
        Spacing.v10,
        AppText(
          text: 'Top 7 members by contribution',
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.55),
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _rankingTierRow(
    List<Map<String, dynamic>> people, {
    required int startRank,
    required Color accent,
    required double nodeSize,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < people.length; i++) ...[
            if (i > 0) Spacing.h8,
            _MemberNode(
              member: {
                ...people[i],
                'role':
                    '#${startRank + i} · ${_compactContribution(people[i]['contribution'])}',
              },
              accent: accent,
              size: nodeSize,
              onTap: () => onMemberTap(people[i]),
              showPresence: false,
            ),
          ],
        ],
      ),
    );
  }

  String _compactContribution(dynamic raw) {
    final value = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '') ?? 0;
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  Widget _buildRole() {
    final hasAny =
        leaders.isNotEmpty || officers.isNotEmpty || members.isNotEmpty;
    if (!hasAny) return _empty('No members loaded yet.');

    return Column(
      children: [
        if (leaders.isNotEmpty) ...[
          _tierLabel('FAMILY LEADER', _gold),
          Spacing.v10,
          _tierRow(leaders, accent: _gold, nodeSize: 72),
        ],
        if (leaders.isNotEmpty &&
            (officers.isNotEmpty || members.isNotEmpty)) ...[
          Spacing.v6,
          const _TreeConnector(height: 28),
        ],
        if (officers.isNotEmpty) ...[
          _tierLabel('OFFICERS', _cyan),
          Spacing.v10,
          _tierRow(officers, accent: _cyan, nodeSize: 58),
        ],
        if (officers.isNotEmpty && members.isNotEmpty) ...[
          Spacing.v6,
          const _TreeConnector(height: 28),
        ],
        if (members.isNotEmpty) ...[
          _tierLabel('MEMBERS', _pink),
          Spacing.v10,
          _membersWrap(members, accent: _pink, size: 52),
        ],
        Spacing.v8,
        _hint(),
      ],
    );
  }

  Widget _buildSponsor() {
    if (sponsorRoots.isEmpty) {
      return _empty('No sponsor links yet. Invite members to grow the tree.');
    }

    return Column(
      children: [
        _tierLabel('SPONSOR TREE', _gold),
        Spacing.v12,
        for (final root in sponsorRoots) ...[
          _SponsorBranch(
            member: root,
            depth: 0,
            childrenOf: childrenOf!,
            onMemberTap: onMemberTap,
          ),
          Spacing.v10,
        ],
        Spacing.v4,
        _hint(),
      ],
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AppText(
        text: text,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.8),
        align: TextAlign.center,
      ),
    );
  }

  Widget _hint() {
    return AppText(
      text: 'Tap anyone to send a gift or message',
      fontSize: TextStyles.k10FontSize,
      color: kColorWhite.withValues(alpha: 0.55),
      align: TextAlign.center,
    );
  }

  Widget _tierLabel(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: SemiBoldText(text: text, fontSize: 10, color: accent),
    );
  }

  Widget _tierRow(
    List<Map<String, dynamic>> people, {
    required Color accent,
    required double nodeSize,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < people.length; i++) ...[
            if (i > 0) Spacing.h10,
            _MemberNode(
              member: people[i],
              accent: accent,
              size: nodeSize,
              onTap: () => onMemberTap(people[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _membersWrap(
    List<Map<String, dynamic>> people, {
    required Color accent,
    required double size,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 14,
      children: [
        for (final member in people)
          _MemberNode(
            member: member,
            accent: accent,
            size: size,
            onTap: () => onMemberTap(member),
          ),
      ],
    );
  }
}

enum FamilyTreeMode { role, sponsor, ranking }

class _SponsorBranch extends StatelessWidget {
  const _SponsorBranch({
    required this.member,
    required this.depth,
    required this.childrenOf,
    required this.onMemberTap,
  });

  final Map<String, dynamic> member;
  final int depth;
  final List<Map<String, dynamic>> Function(String userId) childrenOf;
  final ValueChanged<Map<String, dynamic>> onMemberTap;

  @override
  Widget build(BuildContext context) {
    final userId = member['userId']?.toString() ?? '';
    final kids = depth >= 6
        ? const <Map<String, dynamic>>[]
        : childrenOf(userId);
    final accent = depth == 0
        ? AdminAgencyUi.gold
        : depth == 1
        ? AdminAgencyUi.cyan
        : AdminAgencyUi.pink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _MemberNode(
          member: member,
          accent: accent,
          size: depth == 0 ? 68 : (depth == 1 ? 56 : 48),
          onTap: () => onMemberTap(member),
        ),
        if (kids.isNotEmpty) ...[
          Spacing.v6,
          const _TreeConnector(height: 22),
          Spacing.v6,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < kids.length; i++) ...[
                  if (i > 0) Spacing.h8,
                  _SponsorBranch(
                    member: kids[i],
                    depth: depth + 1,
                    childrenOf: childrenOf,
                    onMemberTap: onMemberTap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TreeConnector extends StatelessWidget {
  const _TreeConnector({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _ConnectorPainter(
        color: AdminAgencyUi.gold.withValues(alpha: 0.45),
      ),
      child: SizedBox(height: height, width: double.infinity),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), paint);

    final armY = size.height * 0.55;
    final path = Path()
      ..moveTo(midX - 48, armY)
      ..quadraticBezierTo(midX, armY, midX + 48, armY);
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(midX, armY), Offset(midX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MemberNode extends StatelessWidget {
  const _MemberNode({
    required this.member,
    required this.accent,
    required this.size,
    required this.onTap,
    this.showPresence = true,
  });

  final Map<String, dynamic> member;
  final Color accent;
  final double size;
  final VoidCallback onTap;
  final bool showPresence;

  @override
  Widget build(BuildContext context) {
    final name = member['name']?.toString() ?? 'Member';
    final role = member['role']?.toString() ?? '';
    final imageUrl = member['displayPicture']?.toString();
    final frameUrl = member['avatarFrameUrl']?.toString();
    final userId = member['userId']?.toString() ?? name;
    final online = member['isOnline'] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: size + 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  FramedUserAvatar(
                    name: name,
                    imageUrl: imageUrl,
                    frameUrl: frameUrl,
                    frameSeed: userId,
                    size: size,
                  ),
                  if (showPresence)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: online ? Colors.greenAccent : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: kColorWhite, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              Spacing.v6,
              SemiBoldText(
                text: name,
                fontSize: size >= 64 ? 12 : 10,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                align: TextAlign.center,
              ),
              if (role.isNotEmpty)
                AppText(
                  text: role,
                  fontSize: 9,
                  color: accent.withValues(alpha: 0.95),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
