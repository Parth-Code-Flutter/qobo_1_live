import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/phone_mask_utils.dart';
import 'package:qobo_one_live/utils/text_utils/profanity_mask_utils.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/family_controller.dart';

abstract final class _FamilyUi {
  static const bg = Color(0xFF090516);
  static const panel = Color(0xFF171025);
  static const panel2 = Color(0xFF241436);
  static const pink = Color(0xFFFF2E83);
  static const violet = Color(0xFF865DFF);
  static const cyan = Color(0xFF42E8E0);
  static const gold = Color(0xFFFFCF5D);
  static const green = Color(0xFF25D98F);
  static const ink = Color(0xFF10091D);
}

/// Light chat tokens — match 1:1 [ChatDetailView] look for family group chat only.
abstract final class _FamilyChatUi {
  static const scaffold = kColorWhite;
  static const incomingBubble = Color(0xFFF3F4F8);
  static const outgoingBubble = Color(0xFFF5E6F1);
  static const composerField = Color(0xFFF5F5F5);
}

class FamilyView extends GetView<FamilyController> {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FamilyUi.bg,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              _tabs(),
              _searchBar(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: kColorWhite),
                    );
                  }
                  final list = controller.selectedTab.value == 0
                      ? controller.myGroups
                      : controller.discoverGroups;
                  return RefreshIndicator(
                    color: _FamilyUi.pink,
                    onRefresh: controller.loadFamilyHub,
                    child: list.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => Spacing.v12,
                            itemBuilder: (_, index) =>
                                _groupCard(context, list[index]),
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const FamilyGroupCreatePage());
        },
        elevation: 14,
        backgroundColor: _FamilyUi.pink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.add_rounded, color: kColorWhite, size: 30),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          AdminAgencyUi.glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: Get.back,
            accent: _FamilyUi.violet,
            size: 44,
            iconSize: 18,
          ),
          Spacing.h12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Family Groups',
                  fontSize: TextStyles.k20FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Chat, gifts, emojis, and members',
                  fontSize: TextStyles.k12FontSize,
                  color: Color(0xB3FFFFFF),
                ),
              ],
            ),
          ),
          AdminAgencyUi.glowIcon(
            icon: Icons.groups_3_rounded,
            accent: _FamilyUi.cyan,
            accentEnd: _FamilyUi.violet,
            size: 44,
            iconSize: 22,
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _tabButton('My Groups', 0, controller.myGroups.length),
            Spacing.h10,
            _tabButton('Discover', 1, controller.discoverGroups.length),
          ],
        ),
      );
    });
  }

  Widget _tabButton(String label, int index, int count) {
    final selected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? const LinearGradient(
                    colors: [_FamilyUi.pink, _FamilyUi.violet],
                  )
                : LinearGradient(
                    colors: [
                      kColorWhite.withValues(alpha: 0.12),
                      kColorWhite.withValues(alpha: 0.06),
                    ],
                  ),
            border: Border.all(
              color: selected
                  ? kColorWhite.withValues(alpha: 0.16)
                  : kColorWhite.withValues(alpha: 0.08),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _FamilyUi.pink.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: SemiBoldText(
              text: '$label ($count)',
              fontSize: 13,
              color: kColorWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Obx(() {
      if (controller.selectedTab.value == 0) return Spacing.v12;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
        child: TextField(
          onSubmitted: controller.updateSearch,
          style: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k14FontSize,
            colors: kColorWhite,
          ),
          decoration: InputDecoration(
            hintText: 'Search new groups...',
            hintStyle: TextStyles.kRegularPoppins(
              fontSize: 13,
              colors: kColorWhite.withValues(alpha: 0.55),
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: _FamilyUi.gold),
            filled: true,
            fillColor: _FamilyUi.panel.withValues(alpha: 0.88),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _FamilyUi.pink),
            ),
          ),
        ),
      );
    });
  }

  Widget _emptyState() {
    final isMine = controller.selectedTab.value == 0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 24),
      children: [
        AdminAgencyUi.glowIcon(
          icon: isMine ? Icons.forum_rounded : Icons.travel_explore_rounded,
          accent: isMine ? _FamilyUi.cyan : _FamilyUi.gold,
          accentEnd: _FamilyUi.violet,
          size: 76,
          iconSize: 36,
        ),
        Spacing.v16,
        SemiBoldText(
          text: isMine ? 'No groups joined yet' : 'No new groups found',
          fontSize: TextStyles.k18FontSize,
          color: kColorWhite,
          align: TextAlign.center,
        ),
        Spacing.v8,
        AppText(
          text: isMine
              ? 'Create your own family or discover a group to start chatting.'
              : 'Try another search or come back when more families are live.',
          fontSize: 13,
          color: kColorWhite.withValues(alpha: 0.72),
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _groupCard(BuildContext context, Map<String, dynamic> group) {
    final isMine =
        controller.selectedTab.value == 0 || group['isJoined'] == true;
    final joiningCoins = group['joiningCoins'] ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isMine) {
            Get.to(() => FamilyGroupChatPage(group: group));
          } else {
            _confirmJoin(group);
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _FamilyUi.panel2.withValues(alpha: 0.98),
                _FamilyUi.ink.withValues(alpha: 0.96),
              ],
            ),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -30,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _FamilyUi.pink.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _groupAvatar(group),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldText(
                          text: group['name']?.toString() ?? 'Family Group',
                          fontSize: TextStyles.k16FontSize,
                          color: kColorWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacing.v4,
                        AppText(
                          text:
                              group['description']?.toString().isNotEmpty ==
                                  true
                              ? group['description'].toString()
                              : 'Group chat community',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.68),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Spacing.v12,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _metaChip(
                              Icons.people_alt_rounded,
                              '${group['memberCount'] ?? 0} members',
                            ),
                            _coinChip('$joiningCoins join'),
                            if ((group['myRole']?.toString() ?? '').isNotEmpty)
                              _metaChip(
                                Icons.shield_rounded,
                                group['myRole'].toString(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Spacing.h8,
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isMine ? _FamilyUi.cyan : _FamilyUi.gold)
                          .withValues(alpha: 0.13),
                      border: Border.all(
                        color: (isMine ? _FamilyUi.cyan : _FamilyUi.gold)
                            .withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(
                      isMine ? Icons.chat_bubble_rounded : Icons.login_rounded,
                      size: 20,
                      color: isMine ? _FamilyUi.cyan : _FamilyUi.gold,
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

  Widget _groupAvatar(Map<String, dynamic> group) {
    final logo = group['logo']?.toString() ?? '';
    final name = group['name']?.toString() ?? 'F';
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'F';
    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_FamilyUi.gold, _FamilyUi.pink, _FamilyUi.violet],
        ),
        boxShadow: [
          BoxShadow(
            color: _FamilyUi.pink.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: _FamilyNetworkImage(
          url: logo,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          fallback: _FamilyImagePlaceholder(
            icon: Icons.groups_2_rounded,
            label: initial,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_FamilyUi.violet, _FamilyUi.pink],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _FamilyUi.cyan),
          Spacing.h4,
          AppText(
            text: text,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _coinChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _FamilyUi.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppCoinIcon(size: 13, color: _FamilyUi.gold),
          Spacing.h4,
          AppText(
            text: text,
            fontSize: TextStyles.k10FontSize,
            color: _FamilyUi.gold,
          ),
        ],
      ),
    );
  }

  void _confirmJoin(Map<String, dynamic> group) {
    final coins = group['joiningCoins'] ?? 0;
    Get.bottomSheet<void>(
      _ActionSheet(
        title: 'Join ${group['name']}',
        subtitle: coins == 0
            ? 'This group is free to join.'
            : 'Joining will debit $coins coins from your wallet.',
        icon: Icons.groups_rounded,
        actionLabel: 'Join Group',
        onAction: () {
          Get.back<void>();
          controller.joinFamily(group);
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void showCreateSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final coinsController = TextEditingController(text: '0');
    final searchController = TextEditingController();
    controller.selectedInitialMembers.clear();
    controller.loadPickerUsers(followersOnly: true);

    Get.bottomSheet<void>(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D142B), _FamilyUi.bg],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                Row(
                  children: [
                    AdminAgencyUi.glowIcon(
                      icon: Icons.diversity_3_rounded,
                      accent: _FamilyUi.pink,
                      accentEnd: _FamilyUi.violet,
                      size: 42,
                      iconSize: 21,
                    ),
                    Spacing.h10,
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: 'Create Family Group',
                            fontSize: TextStyles.k20FontSize,
                            color: kColorWhite,
                          ),
                          AppText(
                            text: 'Add followers or search app users',
                            fontSize: 11,
                            color: Color(0xB3FFFFFF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacing.v16,
                _input(nameController, 'Group name', Icons.groups_rounded),
                Spacing.v10,
                _input(descController, 'Description', Icons.notes_rounded),
                Spacing.v10,
                _input(
                  coinsController,
                  'Joining coins',
                  Icons.monetization_on_rounded,
                  keyboardType: TextInputType.number,
                ),
                Spacing.v12,
                Row(
                  children: [
                    const SemiBoldText(
                      text: 'Add members',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    const Spacer(),
                    Obx(
                      () => AppText(
                        text:
                            '${controller.selectedInitialMembers.length} selected',
                        fontSize: 11,
                        color: _FamilyUi.cyan,
                      ),
                    ),
                  ],
                ),
                Spacing.v8,
                Obx(
                  () => Row(
                    children: [
                      _pickerModeButton(
                        'Followers',
                        Icons.favorite_rounded,
                        controller.pickerFollowersOnly.value,
                        () => controller.setPickerSearchMode(true),
                      ),
                      Spacing.h8,
                      _pickerModeButton(
                        'All users',
                        Icons.travel_explore_rounded,
                        !controller.pickerFollowersOnly.value,
                        () => controller.setPickerSearchMode(false),
                      ),
                    ],
                  ),
                ),
                Spacing.v10,
                TextField(
                  controller: searchController,
                  onChanged: controller.searchPickerUsers,
                  style: TextStyles.kRegularPoppins(
                    fontSize: 13,
                    colors: kColorWhite,
                  ),
                  decoration: _inputDecoration(
                    'Search followers or app users',
                    Icons.person_search_rounded,
                  ),
                ),
                Obx(() {
                  final selectedUsers = controller.pickerUsers
                      .where(controller.isInitialMemberSelected)
                      .toList();
                  if (selectedUsers.isEmpty) return Spacing.v10;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedUsers.length,
                        separatorBuilder: (_, __) => Spacing.h8,
                        itemBuilder: (_, index) {
                          final user = selectedUsers[index];
                          return _selectedUserChip(user);
                        },
                      ),
                    ),
                  );
                }),
                Spacing.v10,
                Flexible(
                  child: Obx(() {
                    if (controller.isLoadingPickerUsers.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: _FamilyUi.pink),
                      );
                    }
                    if (controller.pickerUsers.isEmpty) {
                      return _pickerEmptyState();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.pickerUsers.length,
                      itemBuilder: (_, index) {
                        final user = controller.pickerUsers[index];
                        return _userPickTile(user);
                      },
                    );
                  }),
                ),
                Spacing.v12,
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _FamilyUi.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      controller.createFamilyGroup(
                        name: nameController.text,
                        description: descController.text,
                        joiningCoins: int.tryParse(coinsController.text) ?? 0,
                      );
                    },
                    icon: const Icon(Icons.add_rounded, color: kColorWhite),
                    label: const SemiBoldText(
                      text: 'Create Group',
                      fontSize: 15,
                      color: kColorWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(() {
      nameController.dispose();
      descController.dispose();
      coinsController.dispose();
      searchController.dispose();
    });
  }

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyles.kRegularPoppins(fontSize: 13, colors: kColorWhite),
      decoration: _inputDecoration(hint, icon),
    );
  }

  Widget _pickerModeButton(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    colors: [_FamilyUi.pink, _FamilyUi.violet],
                  )
                : null,
            color: selected ? null : kColorWhite.withValues(alpha: 0.07),
            border: Border.all(
              color: selected
                  ? kColorWhite.withValues(alpha: 0.16)
                  : kColorWhite.withValues(alpha: 0.09),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: kColorWhite),
              Spacing.h6,
              SemiBoldText(text: label, fontSize: 12, color: kColorWhite),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k12FontSize,
        colors: kColorWhite.withValues(alpha: 0.5),
      ),
      prefixIcon: Icon(icon, color: _FamilyUi.gold, size: 20),
      filled: true,
      fillColor: kColorWhite.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _FamilyUi.pink),
      ),
    );
  }

  Widget _userPickTile(Map<String, dynamic> user) {
    final userId = controller.pickerUserId(user);
    return Obx(() {
      final selected = controller.isInitialMemberSelected(user);
      return Container(
        key: ValueKey('family-picker-$userId-$selected'),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: kColorWhite.withValues(alpha: selected ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _FamilyUi.green.withValues(alpha: 0.45)
                : kColorWhite.withValues(alpha: 0.08),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          leading: _Avatar(
            imageUrl: user['displayPicture']?.toString() ?? '',
            frameUrl: user['avatarFrameUrl']?.toString() ?? '',
            name: user['name']?.toString() ?? 'U',
            size: 42,
          ),
          title: SemiBoldText(
            text: user['name']?.toString() ?? 'User',
            fontSize: 13,
            color: kColorWhite,
          ),
          trailing: Icon(
            selected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
            color: selected
                ? _FamilyUi.green
                : kColorWhite.withValues(alpha: 0.62),
          ),
          onTap: () => controller.toggleInitialMember(userId),
        ),
      );
    });
  }

  Widget _selectedUserChip(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'User';
    return GestureDetector(
      onTap: () =>
          controller.toggleInitialMember(controller.pickerUserId(user)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
        decoration: BoxDecoration(
          color: _FamilyUi.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _FamilyUi.green.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(
              imageUrl: user['displayPicture']?.toString() ?? '',
              frameUrl: user['avatarFrameUrl']?.toString() ?? '',
              name: name,
              size: 30,
            ),
            Spacing.h6,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 88),
              child: SemiBoldText(
                text: name,
                fontSize: 11,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Spacing.h4,
            const Icon(Icons.close_rounded, size: 14, color: kColorWhite),
          ],
        ),
      ),
    );
  }

  Widget _pickerEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.person_search_rounded,
              accent: _FamilyUi.cyan,
              accentEnd: _FamilyUi.violet,
              size: 52,
              iconSize: 24,
            ),
            Spacing.v10,
            AppText(
              text: controller.pickerFollowersOnly.value
                  ? 'No followers found'
                  : 'No users found',
              fontSize: 12,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FamilyGroupCreatePage extends StatefulWidget {
  const FamilyGroupCreatePage({super.key});

  @override
  State<FamilyGroupCreatePage> createState() => _FamilyGroupCreatePageState();
}

class _FamilyGroupCreatePageState extends State<FamilyGroupCreatePage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _coinsController = TextEditingController(text: '0');
  final _searchController = TextEditingController();

  FamilyController get controller => Get.find<FamilyController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.selectedInitialMembers.clear();
      controller.loadPickerUsers(followersOnly: true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _coinsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FamilyUi.bg,
      body: Stack(
        children: [
          Container(
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Group Details', required: true),
                          Spacing.v10,
                          _sectionCard(
                            child: Column(
                              children: [
                                _input(
                                  _nameController,
                                  'Group name',
                                  Icons.groups_rounded,
                                ),
                                Spacing.v10,
                                _input(
                                  _descController,
                                  'Description',
                                  Icons.notes_rounded,
                                  maxLines: 3,
                                ),
                                Spacing.v10,
                                _input(
                                  _coinsController,
                                  'Joining coins',
                                  Icons.monetization_on_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                                Spacing.v10,
                                _infoStrip(),
                              ],
                            ),
                          ),
                          Spacing.v20,
                          _sectionLabel('Add Members'),
                          Spacing.v10,
                          _membersHeader(),
                          Spacing.v8,
                          _memberTools(),
                          Spacing.v12,
                          _selectedMembersStrip(),
                          Spacing.v12,
                          _membersList(),
                          Spacing.v24,
                          _createButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (!controller.isCreatingFamily.value) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.52),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: LiveRoomUiColors.cardSurface.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: LiveRoomUiColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: _FamilyUi.pink.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: _FamilyUi.pink,
                              strokeWidth: 2.4,
                            ),
                          ),
                          SizedBox(width: 14),
                          SemiBoldText(
                            text: 'Creating group...',
                            fontSize: 13,
                            color: kColorWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      child: Row(
        children: [
          _backButton(),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Create Family Group',
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
                Spacing.v4,
                const SemiBoldText(
                  text: 'Invite followers or search app users',
                  fontSize: TextStyles.k14FontSize,
                  color: Color(0xFFFF9AD5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: Get.back,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kColorWhite.withValues(alpha: 0.08),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kColorWhite,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF4DC4), Color(0xFF7B5CFF)],
            ),
          ),
        ),
        Spacing.h8,
        SemiBoldText(
          text: text,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        if (required)
          const AppText(
            text: ' *',
            fontSize: TextStyles.k14FontSize,
            color: Color(0xFFFF6A3D),
          ),
      ],
    );
  }

  Widget _infoStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_FamilyUi.pink, _FamilyUi.violet],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.forum_outlined,
              color: kColorWhite,
              size: 20,
            ),
          ),
          Spacing.h12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Build your family space',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Set entry coins, add members, and start chatting.',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorHint,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.72),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
      ),
      child: child,
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyles.kRegularPoppins(fontSize: 13, colors: kColorWhite),
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k12FontSize,
        colors: kColorWhite.withValues(alpha: 0.52),
      ),
      prefixIcon: Icon(icon, color: _FamilyUi.gold, size: 20),
      filled: true,
      fillColor: LiveRoomUiColors.cardSurface.withValues(alpha: 0.70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _FamilyUi.pink),
      ),
    );
  }

  Widget _membersHeader() {
    return Row(
      children: [
        const SemiBoldText(
          text: 'Add members',
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        const Spacer(),
        Obx(
          () => AppText(
            text: '${controller.selectedInitialMembers.length} selected',
            fontSize: 11,
            color: _FamilyUi.cyan,
          ),
        ),
      ],
    );
  }

  Widget _memberTools() {
    return _sectionCard(
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                _pickerModeButton(
                  'Followers',
                  Icons.favorite_rounded,
                  controller.pickerFollowersOnly.value,
                  () => controller.setPickerSearchMode(true),
                ),
                Spacing.h8,
                _pickerModeButton(
                  'All users',
                  Icons.travel_explore_rounded,
                  !controller.pickerFollowersOnly.value,
                  () => controller.setPickerSearchMode(false),
                ),
              ],
            ),
          ),
          Spacing.v10,
          TextField(
            controller: _searchController,
            onChanged: controller.searchPickerUsers,
            style: TextStyles.kRegularPoppins(
              fontSize: 13,
              colors: kColorWhite,
            ),
            decoration: _inputDecoration(
              'Search followers or app users',
              Icons.person_search_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerModeButton(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    colors: [_FamilyUi.pink, _FamilyUi.violet],
                  )
                : null,
            color: selected
                ? null
                : LiveRoomUiColors.cardSurface.withValues(alpha: 0.70),
            border: Border.all(
              color: selected
                  ? kColorWhite.withValues(alpha: 0.18)
                  : kColorWhite.withValues(alpha: 0.09),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: kColorWhite),
              Spacing.h6,
              SemiBoldText(text: label, fontSize: 12, color: kColorWhite),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedMembersStrip() {
    return Obx(() {
      final selectedUsers = controller.pickerUsers
          .where(controller.isInitialMemberSelected)
          .toList();
      if (selectedUsers.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: selectedUsers.length,
          separatorBuilder: (_, __) => Spacing.h8,
          itemBuilder: (_, index) => _selectedUserChip(selectedUsers[index]),
        ),
      );
    });
  }

  Widget _membersList() {
    return Obx(() {
      if (controller.isLoadingPickerUsers.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 34),
          child: Center(
            child: CircularProgressIndicator(color: _FamilyUi.pink),
          ),
        );
      }
      if (controller.pickerUsers.isEmpty) {
        return _pickerEmptyState();
      }
      return ListView.builder(
        itemCount: controller.pickerUsers.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, index) {
          final user = controller.pickerUsers[index];
          return _userPickTile(user);
        },
      );
    });
  }

  Widget _userPickTile(Map<String, dynamic> user) {
    final userId = controller.pickerUserId(user);
    return Obx(() {
      final selected = controller.isInitialMemberSelected(user);
      return Container(
        key: ValueKey('family-create-picker-$userId-$selected'),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: LiveRoomUiColors.cardSurface.withValues(
            alpha: selected ? 0.88 : 0.68,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _FamilyUi.green.withValues(alpha: 0.45)
                : kColorWhite.withValues(alpha: 0.08),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          leading: _Avatar(
            imageUrl: user['displayPicture']?.toString() ?? '',
            frameUrl: user['avatarFrameUrl']?.toString() ?? '',
            name: user['name']?.toString() ?? 'U',
            size: 42,
          ),
          title: SemiBoldText(
            text: user['name']?.toString() ?? 'User',
            fontSize: 13,
            color: kColorWhite,
          ),
          trailing: Icon(
            selected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
            color: selected
                ? _FamilyUi.green
                : kColorWhite.withValues(alpha: 0.62),
          ),
          onTap: () => controller.toggleInitialMember(userId),
        ),
      );
    });
  }

  Widget _selectedUserChip(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'User';
    return GestureDetector(
      onTap: () =>
          controller.toggleInitialMember(controller.pickerUserId(user)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
        decoration: BoxDecoration(
          color: _FamilyUi.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _FamilyUi.green.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(
              imageUrl: user['displayPicture']?.toString() ?? '',
              frameUrl: user['avatarFrameUrl']?.toString() ?? '',
              name: name,
              size: 30,
            ),
            Spacing.h6,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: SemiBoldText(
                text: name,
                fontSize: 11,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Spacing.h4,
            const Icon(Icons.close_rounded, size: 14, color: kColorWhite),
          ],
        ),
      ),
    );
  }

  Widget _pickerEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.person_search_rounded,
              accent: _FamilyUi.cyan,
              accentEnd: _FamilyUi.violet,
              size: 56,
              iconSize: 26,
            ),
            Spacing.v10,
            AppText(
              text: controller.pickerFollowersOnly.value
                  ? 'No followers found'
                  : 'No users found',
              fontSize: 12,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _createButton() {
    return Obx(() {
      final isCreating = controller.isCreatingFamily.value;
      return Opacity(
        opacity: isCreating ? 0.72 : 1,
        child: appButton(
          onPressed: isCreating
              ? () {}
              : () {
                  controller.createFamilyGroup(
                    name: _nameController.text,
                    description: _descController.text,
                    joiningCoins: int.tryParse(_coinsController.text) ?? 0,
                  );
                },
          buttonText: isCreating ? 'Creating...' : 'Create Group',
          isGradient: true,
          buttonIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: kColorWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.groups_rounded,
                    color: kColorWhite,
                    size: 20,
                  ),
          ),
          gradientColors: const [
            Color(0xFFFF4DC4),
            Color(0xFFFF2D7B),
            Color(0xFFFF6A3D),
          ],
        ),
      );
    });
  }
}

class FamilyGroupChatPage extends StatefulWidget {
  const FamilyGroupChatPage({super.key, required this.group});

  final Map<String, dynamic> group;

  @override
  State<FamilyGroupChatPage> createState() => _FamilyGroupChatPageState();
}

class _FamilyGroupChatPageState extends State<FamilyGroupChatPage> {
  final _textController = TextEditingController();

  FamilyController get controller => Get.find<FamilyController>();

  String get familyId => controller.familyIdOf(widget.group);

  @override
  void initState() {
    super.initState();
    controller.loadMembers(familyId);
    controller.markRead(familyId: familyId);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.group['name']?.toString() ?? 'Family Group';
    return Scaffold(
      backgroundColor: _FamilyChatUi.scaffold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _chatHeader(name),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: controller.watchMessages(familyId),
              builder: (_, snapshot) {
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return _chatEmpty();
                }
                return ListView.builder(
                  reverse: false,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, index) => _messageBubble(messages[index]),
                );
              },
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _chatHeader(String name) {
    return AppBar(
      backgroundColor: kColorWhite,
      surfaceTintColor: kColorWhite,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: IconButton(
          onPressed: Get.back,
          icon: SvgPicture.asset(kIconArrowBack),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.kBoldPoppins(
              fontSize: TextStyles.k18FontSize,
              colors: kColorText,
            ),
          ),
          const SizedBox(height: 2),
          AppText(
            text: '${widget.group['memberCount'] ?? 0} members',
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showMembersSheet,
          icon: const Icon(Icons.settings_rounded, color: kColorText),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _chatEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: kColorHint, size: 56),
          SizedBox(height: 12),
          SemiBoldText(
            text: 'Start the family chat',
            fontSize: TextStyles.k16FontSize,
            color: kColorText,
            align: TextAlign.center,
          ),
          SizedBox(height: 6),
          AppText(
            text: 'Messages will appear here when available.',
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final type = message['type']?.toString().toLowerCase() ?? 'text';
    final sender = message['senderName']?.toString() ?? 'Member';
    final mine = message['senderId']?.toString() == controller.currentUserId;
    final text = _messageText(message, type);
    final media = _messageMedia(message, type);
    final time = _messageTimeLabel(message);

    if (type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _FamilyChatUi.incomingBubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AppText(
              text: text,
              fontSize: 11,
              color: kColorHint,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.74,
            ),
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: mine
                  ? _FamilyChatUi.outgoingBubble
                  : _FamilyChatUi.incomingBubble,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AppText(
                      text: sender,
                      fontSize: TextStyles.k10FontSize,
                      color: kColorPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (media.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _FamilyNetworkImage(
                      url: media,
                      width: type == 'emoji' ? 92 : 120,
                      height: type == 'emoji' ? 92 : 120,
                      fit: BoxFit.cover,
                      fallback: _FamilyImagePlaceholder(
                        icon: type == 'emoji'
                            ? Icons.emoji_emotions_rounded
                            : Icons.card_giftcard_rounded,
                      ),
                    ),
                  ),
                  Spacing.v6,
                ],
                AppText(
                  text: ProfanityMaskUtils.mask(PhoneMaskUtils.mask(text)),
                  fontSize: TextStyles.k14FontSize,
                  color: kColorText,
                ),
              ],
            ),
          ),
          Spacing.v4,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(text: time, fontSize: 10, color: kColorHint),
              if (mine) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  color: kColorHint,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _messageText(Map<String, dynamic> message, String type) {
    if (type == 'emoji') {
      return message['emojiName']?.toString() ?? 'sent emoji';
    }
    if (type == 'gift') return message['giftName']?.toString() ?? 'sent gift';
    return message['text']?.toString() ?? '';
  }

  String _messageMedia(Map<String, dynamic> message, String type) {
    if (type == 'emoji') {
      return (message['emojiAnimationUrl'] ??
              message['emojiUrl'] ??
              message['emojiImageUrl'] ??
              '')
          .toString();
    }
    if (type == 'gift') {
      return (message['giftAnimationUrl'] ??
              message['giftThumbnailUrl'] ??
              message['giftImage'] ??
              '')
          .toString();
    }
    return '';
  }

  String _messageTimeLabel(Map<String, dynamic> message) {
    final time = controller.messageDate(message);
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Widget _composer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kColorWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _composerIcon(
            Icons.emoji_emotions_outlined,
            kColorHint,
            _showEmojiSheet,
          ),
          Spacing.h8,
          _composerIcon(
            Icons.card_giftcard_rounded,
            kColorHint,
            _showGiftSheet,
          ),
          Spacing.h12,
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: kColorText,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: 13,
                  colors: kColorHint,
                ),
                filled: true,
                fillColor: _FamilyChatUi.composerField,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => controller.sendTextMessage(
                familyId: familyId,
                textController: _textController,
              ),
            ),
          ),
          Spacing.h12,
          Obx(() {
            final sending = controller.isSendingMessage.value;
            return GestureDetector(
              onTap: sending
                  ? null
                  : () => controller.sendTextMessage(
                      familyId: familyId,
                      textController: _textController,
                    ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: kColorPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sending ? Icons.more_horiz_rounded : Icons.send_rounded,
                  color: kColorWhite,
                  size: 20,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _composerIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: _FamilyChatUi.composerField,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showEmojiSheet() {
    controller.loadEmojiCatalog();
    Get.bottomSheet<void>(
      _CatalogSheet(
        title: 'Send emoji',
        loading: controller.isLoadingEmojis,
        items: controller.emojiCatalog,
        accent: _FamilyUi.gold,
        onTap: (emoji) {
          Get.back<void>();
          controller.sendEmoji(familyId: familyId, emoji: emoji);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showGiftSheet() {
    controller.loadGiftCatalog();
    Get.bottomSheet<void>(
      _CatalogSheet(
        title: 'Gift to group admin',
        loading: controller.isLoadingGifts,
        items: controller.giftCatalog,
        accent: _FamilyUi.pink,
        onTap: (gift) => controller.sendGift(familyId: familyId, gift: gift),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showMembersSheet() {
    controller.loadMembers(familyId);
    Get.bottomSheet<void>(
      _MembersSheet(group: widget.group),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _MembersSheet extends GetView<FamilyController> {
  const _MembersSheet({required this.group});

  final Map<String, dynamic> group;

  @override
  Widget build(BuildContext context) {
    final familyId = controller.familyIdOf(group);
    final admin = controller.isAdmin(group);
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.68,
      decoration: const BoxDecoration(
        color: _FamilyUi.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: SemiBoldText(
                      text: 'Group Settings',
                      fontSize: TextStyles.k18FontSize,
                      color: kColorWhite,
                    ),
                  ),
                  if (!admin)
                    TextButton(
                      onPressed: () => controller.leaveFamily(group),
                      child: const AppText(
                        text: 'Leave',
                        fontSize: 13,
                        color: _FamilyUi.pink,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingMembers.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: _FamilyUi.pink),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: controller.familyMembers.length,
                  itemBuilder: (_, index) {
                    final member = controller.familyMembers[index];
                    final userId = member['userId']?.toString() ?? '';
                    final self = userId == controller.currentUserId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _Avatar(
                        imageUrl: member['displayPicture']?.toString() ?? '',
                        frameUrl: member['avatarFrameUrl']?.toString() ?? '',
                        name: member['name']?.toString() ?? 'M',
                        size: 44,
                      ),
                      title: SemiBoldText(
                        text: member['name']?.toString() ?? 'Member',
                        fontSize: 13,
                        color: kColorWhite,
                      ),
                      subtitle: AppText(
                        text: member['role']?.toString() ?? 'member',
                        fontSize: 11,
                        color: kColorWhite.withValues(alpha: 0.55),
                      ),
                      trailing: admin && !self
                          ? IconButton(
                              onPressed: () => controller.removeMember(
                                familyId: familyId,
                                userId: userId,
                              ),
                              icon: const Icon(
                                Icons.person_remove_rounded,
                                color: _FamilyUi.pink,
                              ),
                            )
                          : null,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogSheet extends StatelessWidget {
  const _CatalogSheet({
    required this.title,
    required this.loading,
    required this.items,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final RxBool loading;
  final RxList<Map<String, String>> items;
  final Color accent;
  final ValueChanged<Map<String, String>> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.56,
      decoration: const BoxDecoration(
        color: _FamilyUi.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const _SheetHandle(),
            SemiBoldText(
              text: title,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            Expanded(
              child: Obx(() {
                if (loading.value) {
                  return Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }
                if (items.isEmpty) {
                  return Center(
                    child: AppText(
                      text: 'No items available right now.',
                      fontSize: 13,
                      color: kColorWhite.withValues(alpha: 0.65),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () => onTap(item),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kColorWhite.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: _FamilyNetworkImage(
                                url: item['image']?.toString() ?? '',
                                fit: BoxFit.contain,
                                fallback: _FamilyImagePlaceholder(
                                  icon: Icons.image_not_supported_rounded,
                                  iconColor: accent,
                                ),
                              ),
                            ),
                            Spacing.v6,
                            AppText(
                              text: item['name'] ?? 'Item',
                              fontSize: TextStyles.k10FontSize,
                              color: kColorWhite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: _FamilyUi.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            AdminAgencyUi.glowIcon(
              icon: icon,
              accent: _FamilyUi.gold,
              accentEnd: _FamilyUi.pink,
              size: 60,
              iconSize: 30,
            ),
            Spacing.v12,
            SemiBoldText(
              text: title,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: subtitle,
              fontSize: 13,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
            Spacing.v16,
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _FamilyUi.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: SemiBoldText(
                  text: actionLabel,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyNetworkImage extends StatelessWidget {
  const _FamilyNetworkImage({
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final source = url.trim();
    if (source.isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }
    return Image.network(
      source,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(width: width, height: height, child: fallback);
      },
      errorBuilder: (_, __, ___) {
        return SizedBox(width: width, height: height, child: fallback);
      },
    );
  }
}

class _FamilyImagePlaceholder extends StatelessWidget {
  const _FamilyImagePlaceholder({
    this.icon = Icons.groups_2_rounded,
    this.label,
    this.gradient,
    this.iconColor = kColorWhite,
  });

  final IconData icon;
  final String? label;
  final Gradient? gradient;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _FamilyUi.violet.withValues(alpha: 0.9),
                _FamilyUi.panel2.withValues(alpha: 0.96),
              ],
            ),
      ),
      child: Center(
        child: label?.isNotEmpty == true
            ? SemiBoldText(
                text: label!,
                fontSize: TextStyles.k20FontSize,
                color: kColorWhite,
              )
            : Icon(icon, color: iconColor.withValues(alpha: 0.88), size: 30),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.name,
    this.frameUrl = '',
    this.size = 48,
  });

  final String imageUrl;
  final String frameUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Container(
            margin: EdgeInsets.all(size * 0.08),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _FamilyUi.violet,
              border: Border.all(color: kColorWhite.withValues(alpha: 0.7)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _FamilyNetworkImage(
              url: imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              fallback: Center(
                child: SemiBoldText(
                  text: initial,
                  fontSize: size * 0.34,
                  color: kColorWhite,
                ),
              ),
            ),
          ),
          if (frameUrl.isNotEmpty)
            Image.network(
              frameUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: kColorWhite.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
