import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/family_controller.dart';
import '../widgets/family_member_tree.dart';

/// Family Hub — honor / ranking vibe on main-app [kImgBG] + brand accents.
abstract final class _FamilyUi {
  static const gold = AdminAgencyUi.gold;
  static const goldDeep = AdminAgencyUi.goldDeep;
  static const pink = AdminAgencyUi.pink;
  static const violet = AdminAgencyUi.violet;
  static const cyan = AdminAgencyUi.cyan;
  static const sky = AdminAgencyUi.sky;

  static const heroGradient = [Color(0xFF6A1B9A), Color(0xFFC2185B)];
  static const topCardGradient = [Color(0xFF4527A0), Color(0xFF6A1B9A)];
  static const rowGradient = [Color(0xFF3D2068), Color(0xFF25143F)];
  static const panelGradient = [Color(0xFF2A1748), Color(0xFF1A0B2E)];
}

class FamilyView extends GetView<FamilyController> {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: kColorWhite),
                    );
                  }
                  if (controller.hasFamily.value) {
                    return _buildMyFamilyDashboard(context);
                  }
                  return _buildBrowseFamiliesView();
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(() {
        if (controller.isLoading.value || controller.hasFamily.value) {
          return const SizedBox.shrink();
        }
        return _buildBottomBar();
      }),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          AdminAgencyUi.glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: Get.back,
            accent: _FamilyUi.sky,
            size: 40,
            iconSize: 16,
          ),
          const Expanded(
            child: Column(
              children: [
                SemiBoldText(
                  text: 'Family Honor',
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Rank · battle · claim rewards',
                  fontSize: TextStyles.k10FontSize,
                  color: Color(0xB3FFFFFF),
                ),
              ],
            ),
          ),
          Obx(() {
            if (!controller.hasFamily.value) {
              return AdminAgencyUi.glowIcon(
                icon: Icons.emoji_events_rounded,
                accent: _FamilyUi.goldDeep,
                accentEnd: _FamilyUi.gold,
                size: 40,
                iconSize: 20,
              );
            }
            return AdminAgencyUi.glassIconButton(
              icon: Icons.exit_to_app_rounded,
              onTap: controller.leaveFamily,
              accent: AdminAgencyUi.rose,
              size: 40,
              iconSize: 18,
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // BROWSE / RANKING STATE
  // ==========================================

  Widget _buildBrowseFamiliesView() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: kColorPrimary,
            onRefresh: controller.loadFamilyHub,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _honorHero(),
                Spacing.v16,
                _rankingTabs(),
                Spacing.v12,
                _countdownBar(),
                Spacing.v16,
                _searchBar(),
                Spacing.v16,
                Obx(() {
                  if (controller.rankingTab.value == 2) {
                    return _rewardsSection();
                  }
                  return _rankingList();
                }),
                Spacing.v24,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _honorHero() {
    return Obx(() {
      final top = controller.topRankedFamily;
      final name = top?['name']?.toString() ?? 'Your Tribe Awaits';
      final members = top?['members'] ?? 0;
      final level = top?['level'] ?? 1;
      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

      return Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _FamilyUi.heroGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: _FamilyUi.pink.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const SemiBoldText(
              text: 'HONOR',
              fontSize: TextStyles.k22FontSize,
              color: _FamilyUi.gold,
            ),
            Spacing.v16,
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_FamilyUi.gold, _FamilyUi.goldDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _FamilyUi.gold.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: kColorWhite, width: 3),
              ),
              alignment: Alignment.center,
              child: SemiBoldText(
                text: initial,
                fontSize: 36,
                color: const Color(0xFF1A1200),
              ),
            ),
            Spacing.v10,
            // Member avatar strip
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final colors = [
                  _FamilyUi.cyan,
                  _FamilyUi.pink,
                  _FamilyUi.violet,
                  _FamilyUi.sky,
                  _FamilyUi.gold,
                ];
                return Transform.translate(
                  offset: Offset(i == 0 ? 0 : -8.0 * i, 0),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i],
                      border: Border.all(color: kColorWhite, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: const TextStyle(
                        color: kColorWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Spacing.v12,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _FamilyUi.cyan.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _FamilyUi.cyan.withValues(alpha: 0.7)),
              ),
              child: const SemiBoldText(
                text: 'THIS WEEK TOP 1',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
              ),
            ),
            Spacing.v10,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    kColorBlack.withValues(alpha: 0.35),
                    kColorBlack.withValues(alpha: 0.18),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.double_arrow, color: _FamilyUi.pink, size: 16),
                  Spacing.h8,
                  Flexible(
                    child: SemiBoldText(
                      text: name,
                      fontSize: TextStyles.k16FontSize,
                      color: _FamilyUi.gold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      align: TextAlign.center,
                    ),
                  ),
                  Spacing.h8,
                  const Icon(Icons.double_arrow, color: _FamilyUi.pink, size: 16),
                ],
              ),
            ),
            Spacing.v8,
            AppText(
              text: 'Lv.$level · $members members · stream · PK · bonuses',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.88),
              align: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }

  Widget _rankingTabs() {
    return Obx(() {
      final selected = controller.rankingTab.value;
      final tabs = ['This Week', 'Last Week', 'Reward'];
      return Row(
        children: List.generate(tabs.length, (i) {
          final active = selected == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 4,
                right: i == tabs.length - 1 ? 0 : 4,
              ),
              child: GestureDetector(
                onTap: () => controller.selectRankingTab(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: active
                        ? const LinearGradient(
                            colors: [_FamilyUi.sky, _FamilyUi.violet],
                          )
                        : LinearGradient(
                            colors: [
                              kColorWhite.withValues(alpha: 0.12),
                              kColorWhite.withValues(alpha: 0.06),
                            ],
                          ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: _FamilyUi.sky.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: SemiBoldText(
                    text: tabs[i],
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                    align: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _countdownBar() {
    final c = controller.weekCountdown;
    String two(int n) => n.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: kColorBlack.withValues(alpha: 0.35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: _FamilyUi.gold, size: 18),
          Spacing.h8,
          AppText(
            text: 'Countdown  ${c.days} Days  |  ',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.9),
          ),
          _timeBox(two(c.hours)),
          const AppText(text: ' : ', color: kColorWhite, fontSize: TextStyles.k12FontSize),
          _timeBox(two(c.minutes)),
          const AppText(text: ' : ', color: kColorWhite, fontSize: TextStyles.k12FontSize),
          _timeBox(two(c.seconds)),
        ],
      ),
    );
  }

  Widget _timeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1038),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SemiBoldText(
        text: value,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.18)),
      ),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: kColorWhite,
        ),
        cursorColor: _FamilyUi.gold,
        decoration: InputDecoration(
          hintText: 'Search families by name or ID...',
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k14FontSize,
            colors: kColorWhite.withValues(alpha: 0.45),
          ),
          prefixIcon: const Icon(Icons.search, color: _FamilyUi.gold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _rankingList() {
    return Obx(() {
      final list = controller.rankedFamilies;
      if (list.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: _FamilyUi.panelGradient),
          ),
          child: Column(
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.groups_rounded,
                accent: _FamilyUi.violet,
                size: 56,
                iconSize: 28,
              ),
              Spacing.v16,
              const SemiBoldText(
                text: 'No families yet',
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
              ),
              Spacing.v6,
              AppText(
                text: 'Be the first to create a family and claim TOP 1.',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.8),
                align: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.leaderboard_rounded,
                accent: _FamilyUi.cyan,
                size: 28,
                iconSize: 14,
              ),
              Spacing.h8,
              SemiBoldText(
                text: controller.rankingTab.value == 0
                    ? 'THIS WEEK RANKING'
                    : 'LAST WEEK RANKING',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
              const Spacer(),
              AppText(
                text: '${list.length} families',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.7),
              ),
            ],
          ),
          Spacing.v12,
          ...List.generate(list.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _rankRow(list[index], index + 1),
            );
          }),
        ],
      );
    });
  }

  Widget _rankRow(Map<String, dynamic> family, int rank) {
    final isTop = rank == 1;
    final name = family['name']?.toString() ?? 'Family';
    final members = family['members'] ?? 0;
    final maxMembers = family['maxMembers'] ?? 500;
    final level = family['level'] ?? 1;
    final score = (level as int) * 1000 + (members as int);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.joinFamily(name),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: isTop
                  ? _FamilyUi.topCardGradient
                  : _FamilyUi.rowGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: (isTop ? _FamilyUi.gold : _FamilyUi.violet)
                    .withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    SemiBoldText(
                      text: 'TOP$rank',
                      fontSize: TextStyles.k10FontSize,
                      color: isTop ? _FamilyUi.gold : _FamilyUi.cyan,
                    ),
                    Spacing.v4,
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isTop
                              ? const [_FamilyUi.gold, _FamilyUi.goldDeep]
                              : const [_FamilyUi.violet, _FamilyUi.pink],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isTop
                          ? const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFF1A1200),
                              size: 22,
                            )
                          : SemiBoldText(
                              text: initial,
                              fontSize: TextStyles.k16FontSize,
                              color: kColorWhite,
                            ),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: name,
                      fontSize: TextStyles.k14FontSize,
                      color: isTop ? _FamilyUi.gold : kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v4,
                    Row(
                      children: List.generate(4, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: [
                              _FamilyUi.cyan,
                              _FamilyUi.pink,
                              _FamilyUi.violet,
                              _FamilyUi.sky,
                            ][i],
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: const TextStyle(
                                fontSize: 8,
                                color: kColorWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    Spacing.v4,
                    AppText(
                      text: 'Lv.$level · $members/$maxMembers members',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: _FamilyUi.gold,
                        size: 16,
                      ),
                      Spacing.h4,
                      SemiBoldText(
                        text: _formatScore(score),
                        fontSize: TextStyles.k14FontSize,
                        color: _FamilyUi.gold,
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [_FamilyUi.pink, _FamilyUi.violet],
                      ),
                    ),
                    child: const SemiBoldText(
                      text: 'Join',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardsSection() {
    final rewards = [
      {
        'title': 'TOP 1 Family',
        'desc': 'Exclusive frame · 50,000 coins · Honor badge',
        'color': _FamilyUi.gold,
      },
      {
        'title': 'TOP 2–3',
        'desc': 'Golden banner · 20,000 coins',
        'color': _FamilyUi.cyan,
      },
      {
        'title': 'TOP 4–10',
        'desc': 'Family boost · 5,000 coins',
        'color': _FamilyUi.pink,
      },
      {
        'title': 'Join any Family',
        'desc': 'Weekly quests · PK bonuses · tribe chat',
        'color': _FamilyUi.violet,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.card_giftcard_rounded,
              accent: _FamilyUi.goldDeep,
              accentEnd: _FamilyUi.gold,
              size: 28,
              iconSize: 14,
            ),
            Spacing.h8,
            const SemiBoldText(
              text: 'WEEKLY REWARDS',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ],
        ),
        Spacing.v12,
        ...rewards.map((r) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: _FamilyUi.rowGradient),
            ),
            child: Row(
              children: [
                AdminAgencyUi.glowIcon(
                  icon: Icons.military_tech_rounded,
                  accent: r['color'] as Color,
                  size: 44,
                  iconSize: 22,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: r['title'] as String,
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v4,
                      AppText(
                        text: r['desc'] as String,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xE6120B24),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              text: 'Build your tribe · climb the honor board',
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.7),
              align: TextAlign.center,
            ),
            Spacing.v8,
            AdminGoldCtaButton(
              label: 'Create My Family (1,000 Coins)',
              icon: Icons.sentiment_satisfied_alt_rounded,
              expanded: true,
              height: 52,
              onTap: controller.showCreateFamilyDialog,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MY FAMILY DASHBOARD
  // ==========================================

  Widget _buildMyFamilyDashboard(BuildContext context) {
    final fam = controller.myFamily;
    return RefreshIndicator(
      color: kColorPrimary,
      onRefresh: controller.loadFamilyHub,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _buildMyFamilyCard(fam),
          Spacing.v16,
          _buildAnnouncementCard(fam),
          Spacing.v16,
          _buildMembersSection(context),
          Spacing.v16,
          _buildQuestsSection(),
        ],
      ),
    );
  }

  Widget _buildMyFamilyCard(Map<String, dynamic> fam) {
    final xp = (fam['xp'] is num) ? (fam['xp'] as num).toDouble() : 0.0;
    final maxXp = (fam['maxXp'] is num) ? (fam['maxXp'] as num).toDouble() : 1000.0;
    final xpProgress = maxXp <= 0 ? 0.0 : (xp / maxXp).clamp(0.0, 1.0);
    final name = fam['name']?.toString() ?? 'Family';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _FamilyUi.heroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: _FamilyUi.pink.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_FamilyUi.gold, _FamilyUi.goldDeep],
                  ),
                  border: Border.all(color: kColorWhite, width: 2),
                ),
                alignment: Alignment.center,
                child: SemiBoldText(
                  text: initial,
                  fontSize: 28,
                  color: const Color(0xFF1A1200),
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: name,
                      fontSize: TextStyles.k20FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v4,
                    AppText(
                      text: 'ID: ${fam['id'] ?? '—'}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.85),
                    ),
                    Spacing.v6,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _FamilyUi.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: BoldText(
                            text: 'Level ${fam['level'] ?? 1}',
                            fontSize: 10,
                            color: const Color(0xFF1A1200),
                          ),
                        ),
                        Spacing.h8,
                        Flexible(
                          child: AppText(
                            text: 'Leader: ${fam['leader'] ?? 'Admin'}',
                            fontSize: TextStyles.k12FontSize,
                            color: kColorWhite.withValues(alpha: 0.9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: 'Family XP',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.9),
              ),
              AppText(
                text: '${fam['xp'] ?? 0} / ${fam['maxXp'] ?? 1000}',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v6,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 6,
              backgroundColor: kColorWhite.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(_FamilyUi.gold),
            ),
          ),
          Spacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: 'Members',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.9),
              ),
              SemiBoldText(
                text: '${fam['members'] ?? 0} / ${fam['maxMembers'] ?? 500}',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> fam) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: _FamilyUi.rowGradient),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.campaign_rounded,
                accent: _FamilyUi.pink,
                size: 36,
                iconSize: 18,
              ),
              Spacing.h10,
              const SemiBoldText(
                text: 'Family Announcement',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v10,
          AppText(
            text: (fam['announcement']?.toString().isNotEmpty == true)
                ? fam['announcement'].toString()
                : 'No announcements at the moment.',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.88),
          ),
          Spacing.v16,
          GestureDetector(
            onTap: () {
              Get.snackbar(
                'Family Room',
                'Connecting to family live audio room...',
                backgroundColor: _FamilyUi.violet.withValues(alpha: 0.35),
                colorText: kColorWhite,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [_FamilyUi.pink, _FamilyUi.violet],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_rounded, color: kColorWhite, size: 18),
                  SizedBox(width: 8),
                  SemiBoldText(
                    text: 'Enter Family Audio Room',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.account_tree_rounded,
              accent: _FamilyUi.cyan,
              size: 28,
              iconSize: 14,
            ),
            Spacing.h8,
            const SemiBoldText(
              text: 'FAMILY TREE',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
            const Spacer(),
            Obx(
              () => AppText(
                text: '${controller.familyMembers.length}',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Spacing.v10,
        Obx(() {
          final mode = controller.treeMode.value;
          return Row(
            children: [
              Expanded(
                child: _treeModeChip(
                  label: 'Role',
                  selected: mode == 0,
                  onTap: () => controller.selectTreeMode(0),
                ),
              ),
              Spacing.h8,
              Expanded(
                child: _treeModeChip(
                  label: 'Sponsor',
                  selected: mode == 1,
                  onTap: () => controller.selectTreeMode(1),
                ),
              ),
            ],
          );
        }),
        Spacing.v10,
        Obx(() {
          if (controller.treeMode.value == 1) {
            return FamilyMemberTree.sponsor(
              sponsorRoots: controller.sponsorRoots,
              childrenOf: controller.sponsorChildrenOf,
              onMemberTap: (member) =>
                  controller.onFamilyMemberTap(context, member),
            );
          }
          return FamilyMemberTree.role(
            leaders: controller.treeLeaders,
            officers: controller.treeOfficers,
            members: controller.treeMembers,
            onMemberTap: (member) =>
                controller.onFamilyMemberTap(context, member),
          );
        }),
      ],
    );
  }

  Widget _treeModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: [_FamilyUi.violet, _FamilyUi.pink],
                  )
                : const LinearGradient(colors: _FamilyUi.rowGradient),
            border: Border.all(
              color: selected
                  ? _FamilyUi.gold.withValues(alpha: 0.55)
                  : kColorWhite.withValues(alpha: 0.12),
            ),
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestsSection() {
    final quests = [
      {
        'title': 'Daily Gathering',
        'desc': 'Get 5 family members online together.',
        'progress': '3/5',
        'reward': '+200 XP',
        'done': false,
      },
      {
        'title': 'PK Dominance',
        'desc': 'Win a co-hosted PK battle with another family.',
        'progress': '1/1',
        'reward': '+500 XP',
        'done': true,
      },
      {
        'title': 'Diamond Shower',
        'desc': 'Total family members send 2,000 coins.',
        'progress': '1250/2000',
        'reward': '+800 XP',
        'done': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.flag_rounded,
              accent: _FamilyUi.goldDeep,
              accentEnd: _FamilyUi.gold,
              size: 28,
              iconSize: 14,
            ),
            Spacing.h8,
            const SemiBoldText(
              text: 'RANKS & QUESTS',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
          ],
        ),
        Spacing.v10,
        ...quests.map((q) {
          final done = q['done'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: _FamilyUi.rowGradient),
            ),
            child: Row(
              children: [
                Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.pending_outlined,
                  color: done ? Colors.greenAccent : _FamilyUi.gold,
                  size: 26,
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: q['title'] as String,
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                      Spacing.v2,
                      AppText(
                        text: q['desc'] as String,
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.8),
                      ),
                      Spacing.v6,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _FamilyUi.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SemiBoldText(
                          text: q['reward'] as String,
                          fontSize: TextStyles.k10FontSize,
                          color: _FamilyUi.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                SemiBoldText(
                  text: q['progress'] as String,
                  fontSize: TextStyles.k12FontSize,
                  color: done ? Colors.greenAccent : kColorWhite,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatScore(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
