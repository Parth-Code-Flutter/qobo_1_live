import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/family_controller.dart';

class FamilyView extends GetView<FamilyController> {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorAppBackground,
      appBar: CommonAppBarWidget(
        title: 'Family Hub',
        useMaterialAppBar: true,
        actions: [
          Obx(() {
            if (controller.hasFamily.value) {
              return IconButton(
                icon: const Icon(Icons.exit_to_app, color: kColorPrimary),
                onPressed: controller.leaveFamily,
                tooltip: 'Leave Family',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.hasFamily.value) {
          return _buildMyFamilyDashboard();
        } else {
          return _buildBrowseFamiliesView();
        }
      }),
      bottomNavigationBar: Obx(() {
        if (!controller.hasFamily.value) {
          return _buildBottomBar();
        }
        return const SizedBox.shrink();
      }),
    );
  }

  // ==========================================
  // BROWSE FAMILIES STATE UI
  // ==========================================

  Widget _buildBrowseFamiliesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderBanner(),
        _buildSearchBar(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPopularFamiliesSection(),
                Spacing.v24,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kColorPrimary, Color(0xFF9E2A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kColorWhite.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.diversity_3_rounded,
              color: kColorWhite,
              size: 56,
            ),
          ),
          Spacing.v16,
          const SemiBoldText(
            text: 'Find Your Tribe',
            fontSize: TextStyles.k22FontSize,
            color: kColorWhite,
          ),
          Spacing.v8,
          AppText(
            text: 'Stream together, compete in PK battles, and claim exclusive weekly bonuses.',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite.withOpacity(0.85),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        decoration: InputDecoration(
          hintText: 'Search families by name or ID...',
          hintStyle: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k14FontSize,
            colors: kColorHint,
          ),
          prefixIcon: const Icon(Icons.search, color: kColorPrimary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPopularFamiliesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 12, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SemiBoldText(
                  text: 'Trending Families',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorText,
                ),
                Obx(() {
                  return AppText(
                    text: '${controller.filteredFamilies.length} found',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorHint,
                  );
                }),
              ],
            ),
          ),
          Obx(() {
            final list = controller.filteredFamilies;
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: kColorHint.withOpacity(0.5)),
                      Spacing.v12,
                      const AppText(
                        text: 'No families matched your query.',
                        color: kColorHint,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => Spacing.v12,
              itemBuilder: (context, index) {
                final family = list[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kColorWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kColorBlack.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  kColorPrimary.withOpacity(0.2),
                                  const Color(0xFF9E2A8C).withOpacity(0.2)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SemiBoldText(
                                text: family['name'][0],
                                fontSize: TextStyles.k20FontSize,
                                color: kColorPrimary,
                              ),
                            ),
                          ),
                          Spacing.h12,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SemiBoldText(
                                  text: family['name'],
                                  fontSize: TextStyles.k16FontSize,
                                  color: kColorText,
                                ),
                                Spacing.v2,
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF8A48).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: BoldText(
                                        text: 'Lv. ${family['level']}',
                                        fontSize: 10,
                                        color: const Color(0xFFFF8A48),
                                      ),
                                    ),
                                    Spacing.h8,
                                    AppText(
                                      text: '${family['members']}/${family['maxMembers']} members',
                                      fontSize: TextStyles.k12FontSize,
                                      color: kColorHint,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 32,
                            width: 72,
                            child: appButton(
                              onPressed: () => controller.joinFamily(family['name']),
                              buttonText: 'Join',
                              buttonColor: kColorPrimary,
                              borderRadius: 16,
                              textStyle: TextStyles.kSemiBoldPoppins(
                                fontSize: TextStyles.k12FontSize,
                                colors: kColorWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (family['description'] != null) ...[
                        Spacing.v10,
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: AppText(
                            text: family['description'],
                            fontSize: TextStyles.k12FontSize,
                            color: kColorTextGrey,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kColorWhite,
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: appButton(
          onPressed: controller.showCreateFamilyDialog,
          buttonText: 'Create a Family (1,000 Coins)',
          buttonColor: Colors.transparent,
          textColor: kColorPrimary,
          buttonBorderColor: kColorPrimary,
          borderRadius: 24,
        ),
      ),
    );
  }

  // ==========================================
  // ACTIVE MEMBER MY FAMILY STATE UI
  // ==========================================

  Widget _buildMyFamilyDashboard() {
    final fam = controller.myFamily;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMyFamilyCard(fam),
          _buildAnnouncementCard(fam),
          _buildMyFamilyTabsAndContent(),
        ],
      ),
    );
  }

  Widget _buildMyFamilyCard(Map<String, dynamic> fam) {
    final xpProgress = fam['xp'] / fam['maxXp'];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF410D37), Color(0xFF761B65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                decoration: const BoxDecoration(
                  color: kColorWhite,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SemiBoldText(
                    text: fam['name'] != null && fam['name'].isNotEmpty ? fam['name'][0] : 'F',
                    fontSize: 28,
                    color: kColorPrimary,
                  ),
                ),
              ),
              Spacing.h16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: fam['name'] ?? 'Family Name',
                      fontSize: TextStyles.k20FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.v4,
                    AppText(
                      text: 'ID: ${fam['id']?.replaceFirst('fam_', 'QBO_') ?? 'QBO_8829'}',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withOpacity(0.7),
                    ),
                    Spacing.v4,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: BoldText(
                            text: 'Level ${fam['level'] ?? 1}',
                            fontSize: 10,
                            color: kColorBlack,
                          ),
                        ),
                        Spacing.h8,
                        AppText(
                          text: 'Leader: ${fam['leader'] ?? 'Admin'}',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withOpacity(0.85),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v20,
          const Divider(color: Colors.white24, height: 1),
          Spacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: 'Family Level Progress',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withOpacity(0.8),
              ),
              AppText(
                text: '${fam['xp']} / ${fam['maxXp']} XP',
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
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          Spacing.v16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: 'Members Count',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withOpacity(0.8),
              ),
              SemiBoldText(
                text: '${fam['members']} / ${fam['maxMembers']}',
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: kColorPrimary, size: 24),
              Spacing.h8,
              const SemiBoldText(
                text: 'Family Announcement',
                fontSize: TextStyles.k14FontSize,
                color: kColorText,
              ),
            ],
          ),
          Spacing.v8,
          AppText(
            text: fam['announcement'] ?? 'No announcements at the moment.',
            fontSize: TextStyles.k12FontSize,
            color: kColorTextGrey,
          ),
          Spacing.v12,
          const Divider(height: 1),
          Spacing.v12,
          GestureDetector(
            onTap: () {
              Get.snackbar(
                'Family Room',
                'Connecting to family live audio room...',
                backgroundColor: kColorPrimary.withOpacity(0.1),
                colorText: kColorPrimary,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: kColorPrimary, size: 20),
                Spacing.h6,
                SemiBoldText(
                  text: 'Enter Family Audio Room',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyFamilyTabsAndContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16),
            color: kColorWhite,
            child: TabBar(
              indicatorColor: kColorPrimary,
              labelColor: kColorPrimary,
              unselectedLabelColor: kColorHint,
              labelStyle: TextStyles.kSemiBoldPoppins(fontSize: TextStyles.k14FontSize),
              tabs: const [
                Tab(text: 'Members'),
                Tab(text: 'Ranks & Quests'),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildMembersTab(),
                _buildQuestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return Obx(() {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.familyMembers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = controller.familyMembers[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kColorPrimary.withOpacity(0.1),
                      child: Text(
                        member['avatar'] ?? 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kColorPrimary),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: member['isOnline'] == true ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: kColorWhite, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SemiBoldText(
                            text: member['name'],
                            fontSize: TextStyles.k14FontSize,
                            color: kColorText,
                          ),
                          Spacing.h6,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: kColorPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              text: 'Lv.${member['level'] ?? 1}',
                              fontSize: 9,
                              color: kColorPrimary,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Spacing.v2,
                      AppText(
                        text: 'Role: ${member['role']}',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorHint,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SemiBoldText(
                      text: '${member['contribution']}',
                      fontSize: TextStyles.k14FontSize,
                      color: const Color(0xFFFF8A48),
                    ),
                    const AppText(
                      text: 'points',
                      fontSize: 10,
                      color: kColorHint,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildQuestsTab() {
    final quests = [
      {'title': 'Daily Gathering', 'desc': 'Get 5 family members online together.', 'progress': '3/5', 'reward': '+200 XP', 'done': false},
      {'title': 'PK Dominance', 'desc': 'Win a co-hosted PK battle with another family.', 'progress': '1/1', 'reward': '+500 XP', 'done': true},
      {'title': 'Diamond Shower', 'desc': 'Total family members send 2,000 coins.', 'progress': '1250/2000', 'reward': '+800 XP', 'done': false},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final q = quests[index];
        final done = q['done'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done ? Colors.green.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.pending_outlined,
                color: done ? Colors.green : kColorHint,
                size: 28,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: q['title'] as String,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                    Spacing.v2,
                    AppText(
                      text: q['desc'] as String,
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                    Spacing.v4,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            q['reward'] as String,
                            style: const TextStyle(fontSize: 10, color: Colors.amberScaleDown, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                q['progress'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: done ? Colors.green : kColorText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Simple color helper extension to keep build working
extension on Colors {
  static const Color amberScaleDown = Color(0xFFD97706);
}
