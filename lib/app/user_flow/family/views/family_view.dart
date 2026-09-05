import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/gift_icon_widget.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
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
  static const scaffold = Color(0xFFFFF6FB);
  static const incomingBubble = kColorWhite;
  static const composerField = Color(0xFFFFF5FA);
  static const rose = Color(0xFFFF2E83);
  static const plum = Color(0xFF7A1B76);
  static const lilac = Color(0xFF8B5CFF);
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
          Get.to(() => FamilyDetailDashboardPage(group: group));
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
                            if (!isMine)
                              _coinChip(
                                joiningCoins <= 0
                                    ? 'Free to join'
                                    : '$joiningCoins coins to join',
                              ),
                            if (isMine && joiningCoins > 0)
                              _coinChip('$joiningCoins join fee'),
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

class FamilyDetailDashboardPage extends StatefulWidget {
  const FamilyDetailDashboardPage({super.key, required this.group});

  final Map<String, dynamic> group;

  @override
  State<FamilyDetailDashboardPage> createState() =>
      _FamilyDetailDashboardPageState();
}

class _FamilyDetailDashboardPageState extends State<FamilyDetailDashboardPage> {
  late Map<String, dynamic> _group = widget.group;
  bool _loadingDetail = true;

  FamilyController get controller => Get.find<FamilyController>();

  bool get _isJoined {
    final joined = _group['isJoined'];
    if (joined is bool) return joined;

    final role = _group['myRole']?.toString().trim().toLowerCase() ?? '';
    return role.isNotEmpty && role != 'null';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final familyId = controller.familyIdOf(_group);
    if (familyId.isNotEmpty) {
      unawaited(controller.loadMembers(familyId, isShowLoader: false));
    }
    final detail = await controller.loadFamilyDetailMap(_group);
    if (!mounted) return;
    setState(() {
      _group = detail;
      _loadingDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _text(_group['name'], 'My Family');
    final familyId = controller.familyIdOf(_group);
    final displayId = familyId.isEmpty ? '123456' : familyId;
    final level = _int(_group['level']);
    final levelLabel = level <= 0 ? 'Lv.1 Family' : 'Lv.$level Family';

    return Scaffold(
      backgroundColor: _FamilyUi.bg,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
            opacity: 0.72,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _FamilyUi.violet.withValues(alpha: 0.22),
              _FamilyUi.bg,
              _FamilyUi.ink,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _purpleHeader(name, displayId, levelLabel),
              Expanded(
                child: RefreshIndicator(
                  color: _FamilyUi.violet,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                    children: [
                      _heroSummary(name),
                      if (!_isJoined) ...[Spacing.v12, _joinAccessCard()],
                      Spacing.v12,
                      _announcementCard(),
                      Spacing.v12,
                      _quickActions(),
                      Spacing.v12,
                      _topMembersCard(),
                      Spacing.v12,
                      _activityCard(),
                      const SizedBox(height: 88),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: SizedBox(
            height: 52,
            child: appButton(
              onPressed: _isJoined ? _openChat : _confirmJoinFromDetail,
              buttonText: _isJoined ? 'Open Family Chat' : _joinButtonText(),
              isGradient: true,
              gradientColors: const [Color(0xFF7B5CFF), Color(0xFFFF2E83)],
              borderRadius: 18,
              buttonIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  _isJoined ? Icons.chat_bubble_rounded : Icons.login_rounded,
                  color: kColorWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _purpleHeader(String name, String displayId, String levelLabel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _FamilyUi.panel2.withValues(alpha: 0.96),
            _FamilyUi.violet.withValues(alpha: 0.92),
            _FamilyUi.pink.withValues(alpha: 0.52),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border(
          bottom: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
        ),
        boxShadow: [
          BoxShadow(
            color: _FamilyUi.pink.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: kColorWhite,
              size: 28,
            ),
          ),
          Spacing.h8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: SemiBoldText(
                        text: name,
                        fontSize: TextStyles.k20FontSize,
                        color: kColorWhite,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Spacing.h6,
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFFFFD45B),
                      size: 19,
                    ),
                  ],
                ),
                Spacing.v2,
                AppText(
                  text: 'ID: $displayId  ·  $levelLabel',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.86),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _headerAction(Icons.workspace_premium_rounded),
          Spacing.h8,
          _headerAction(
            Icons.group_add_rounded,
            onTap: _openAddMembersFromHeader,
          ),
          // Overflow menu temporarily hidden.
          // Spacing.h4,
          // _headerAction(Icons.more_vert_rounded, transparent: true),
        ],
      ),
    );
  }

  Widget _headerAction(
    IconData icon, {
    bool transparent = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: transparent ? kColorWhite.withValues(alpha: 0.08) : null,
            gradient: transparent
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFFC239), Color(0xFFFF9D1D)],
                  ),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: kColorWhite, size: 24),
        ),
      ),
    );
  }

  void _openAddMembersFromHeader() {
    if (!controller.isAdmin(_group)) {
      unawaited(
        CommonAppDialog.showGet<void>(
          title: 'Admin only',
          message: 'Only the group admin can add members.',
          icon: Icons.group_add_rounded,
          iconAccent: const Color(0xFFFF5C8A),
          barrierDismissible: true,
          actions: const [CommonAppDialogAction(label: 'OK', isPrimary: true)],
        ),
      );
      return;
    }
    final familyId = controller.familyIdOf(_group);
    if (familyId.isEmpty) return;
    final searchController = TextEditingController();
    controller.selectedInitialMembers.clear();
    unawaited(controller.loadMembers(familyId, isShowLoader: false));
    controller.loadPickerUsers(followersOnly: true);
    Get.bottomSheet<void>(
      _FamilyAddMembersSheet(
        familyId: familyId,
        searchController: searchController,
        existingMemberIds: controller.familyMembers
            .map((m) => (m['userId'] ?? m['id'] ?? '').toString().trim())
            .where((id) => id.isNotEmpty)
            .toSet(),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(() {
      searchController.dispose();
      controller.selectedInitialMembers.clear();
      unawaited(_load());
    });
  }

  Future<void> _openEditGroupName() async {
    if (!controller.isAdmin(_group)) {
      await CommonAppDialog.showGet<void>(
        title: 'Admin only',
        message: 'Only the group admin can edit the group name.',
        icon: Icons.edit_rounded,
        iconAccent: const Color(0xFFFF5C8A),
        barrierDismissible: true,
        actions: const [CommonAppDialogAction(label: 'OK', isPrimary: true)],
      );
      return;
    }
    final familyId = controller.familyIdOf(_group);
    if (familyId.isEmpty) return;

    final result = await Get.bottomSheet<Map<String, String>>(
      _EditFamilyNameSheet(
        initialName: _text(_group['name'], ''),
        initialDescription: _text(_group['description'], ''),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (result == null || !mounted) return;

    final updated = await controller.updateFamilyProfile(
      familyId: familyId,
      name: result['name'] ?? '',
      description: result['description'] ?? '',
    );
    if (updated == null || !mounted) return;
    setState(() {
      _group = {..._group, ...updated};
    });
    unawaited(_load());
  }

  Widget _heroSummary(String name) {
    final description = _text(
      _group['description'],
      'We are together, we are family.',
    );
    final memberCount = _int(_group['memberCount']);
    final memberLimit = _int(_group['memberLimit']) <= 0
        ? 50
        : _int(_group['memberLimit']);
    final coins = _int(_group['familyCoins']);
    final points = _int(_group['familyPoints']);
    final rank = _int(_group['familyRank']);

    return Transform.translate(
      offset: const Offset(0, -1),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _familyBadge(),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SemiBoldText(
                              text: name,
                              fontSize: TextStyles.k18FontSize,
                              color: kColorWhite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _openEditGroupName,
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF7B5CFF),
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Spacing.v8,
                      AppText(
                        text: description,
                        fontSize: 13,
                        color: kColorWhite.withValues(alpha: 0.72),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF865DFF),
                            size: 25,
                          ),
                          Spacing.h8,
                          SemiBoldText(
                            text: '$memberCount/$memberLimit',
                            fontSize: TextStyles.k16FontSize,
                            color: kColorWhite,
                          ),
                          Spacing.h4,
                          AppText(
                            text: 'Members',
                            fontSize: TextStyles.k10FontSize,
                            color: kColorWhite.withValues(alpha: 0.58),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacing.v16,
            Divider(color: kColorWhite.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _statItem(
                  icon: Icons.stars_rounded,
                  value: _compact(coins),
                  label: 'Family Coins',
                  color: const Color(0xFFFFB521),
                ),
                _thinDivider(),
                _statItem(
                  icon: Icons.star_rounded,
                  value: _compact(points),
                  label: 'Family Points',
                  color: const Color(0xFFFFCA28),
                ),
                _thinDivider(),
                _statItem(
                  icon: Icons.emoji_events_rounded,
                  value: rank <= 0 ? '-' : '$rank',
                  label: 'Family Rank',
                  color: const Color(0xFFFFA000),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyBadge() {
    final logo = _text(_group['logo'], '');
    return SizedBox(
      width: 138,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD24D), Color(0xFF7B5CFF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB521).withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: logo.isEmpty
                    ? const Icon(
                        Icons.family_restroom_rounded,
                        color: Color(0xFF6C4CDE),
                        size: 48,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: _FamilyNetworkImage(
                          url: logo,
                          fit: BoxFit.cover,
                          fallback: const _FamilyImagePlaceholder(
                            icon: Icons.family_restroom_rounded,
                            iconColor: Color(0xFF6C4CDE),
                          ),
                        ),
                      ),
              ),
              const Positioned(
                top: -2,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFB521),
                  size: 34,
                ),
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB42FD7), Color(0xFFFF2E83)],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFD24D), width: 1.2),
              ),
              child: const SemiBoldText(
                text: 'MY FAMILY',
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              Spacing.h4,
              Flexible(
                child: SemiBoldText(
                  text: value,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Spacing.v4,
          AppText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.62),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _thinDivider() {
    return Container(
      width: 1,
      height: 36,
      color: kColorWhite.withValues(alpha: 0.08),
    );
  }

  Widget _announcementCard() {
    final text = _text(
      _group['announcement'],
      _loadingDetail
          ? 'Loading latest announcement...'
          : 'No announcement shared yet.',
    );
    return _whiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_rounded,
            color: Color(0xFF7B5CFF),
            size: 25,
          ),
          Spacing.h10,
          const SemiBoldText(
            text: 'Announcement',
            fontSize: 13,
            color: Color(0xFF7B5CFF),
          ),
          Spacing.h10,
          Expanded(
            child: AppText(
              text: text,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF7B5CFF),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _joinAccessCard() {
    final coins = _int(_group['joiningCoins']);
    final free = coins <= 0;
    return _whiteCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: free
                    ? const [Color(0xFF25D98F), Color(0xFF42E8E0)]
                    : const [Color(0xFFFFD45B), Color(0xFFFF8A48)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (free ? _FamilyUi.green : _FamilyUi.gold).withValues(
                    alpha: 0.22,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              free ? Icons.lock_open_rounded : Icons.monetization_on_rounded,
              color: kColorWhite,
              size: 25,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: free ? 'Free to join' : 'Joining coins required',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
                Spacing.v4,
                AppText(
                  text: free
                      ? 'Join this family to unlock chat, gifts, and member activity.'
                      : 'Pay $coins coins once to become a member and unlock family chat.',
                  fontSize: 11,
                  color: kColorWhite.withValues(alpha: 0.68),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Spacing.h10,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: (free ? _FamilyUi.green : _FamilyUi.gold).withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (free ? _FamilyUi.green : _FamilyUi.gold).withValues(
                  alpha: 0.30,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!free) const AppCoinIcon(size: 14, color: _FamilyUi.gold),
                if (!free) Spacing.h4,
                SemiBoldText(
                  text: free ? 'Free' : '$coins',
                  fontSize: TextStyles.k12FontSize,
                  color: free ? _FamilyUi.green : _FamilyUi.gold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      (
        Icons.chat_bubble_rounded,
        'Family Chat',
        const Color(0xFF7B5CFF),
        _isJoined ? _openChat : _confirmJoinFromDetail,
      ),
      (
        Icons.groups_rounded,
        'Members',
        const Color(0xFFFF3F78),
        _isJoined ? _openMembers : _confirmJoinFromDetail,
      ),
      (
        Icons.card_giftcard_rounded,
        'Family Gifts',
        const Color(0xFFFFA000),
        _openGifts,
      ),
      (
        Icons.assignment_turned_in_rounded,
        'Tasks',
        const Color(0xFF42A5F5),
        () => Get.toNamed(Routes.POINT_CENTER),
      ),
      (Icons.bar_chart_rounded, 'Rankings', const Color(0xFF33D35E), () {}),
    ];
    return _whiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: actions
            .map(
              (item) => Expanded(
                child: GestureDetector(
                  onTap: item.$4,
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.$3,
                          boxShadow: [
                            BoxShadow(
                              color: item.$3.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(item.$1, color: kColorWhite, size: 28),
                      ),
                      Spacing.v8,
                      SemiBoldText(
                        text: item.$2,
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite,
                        align: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _topMembersCard() {
    return Obx(() {
      final members = _topMembers();
      return _whiteCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: SemiBoldText(
                    text: 'Top Members',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ),
                AppText(
                  text: 'View All',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: AppText(
                  text: 'Top members will appear after activity starts.',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.62),
                  align: TextAlign.center,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: members
                    .take(5)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => Expanded(
                        child: _topMemberAvatar(entry.value, entry.key + 1),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );
    });
  }

  Widget _topMemberAvatar(Map<String, dynamic> member, int rank) {
    final name = _text(member['name'], 'Member');
    final coins = _int(member['contribution'] ?? member['coins']);
    final colors = const [
      Color(0xFFFFC107),
      Color(0xFF9EA7B8),
      Color(0xFFFF7043),
      Color(0xFF865DFF),
      Color(0xFFB66DFF),
    ];
    final color = colors[(rank - 1).clamp(0, colors.length - 1)];
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: ClipOval(
                child: _FamilyNetworkImage(
                  url: _text(member['displayPicture'], ''),
                  fit: BoxFit.cover,
                  fallback: _FamilyImagePlaceholder(
                    label: name.substring(0, 1).toUpperCase(),
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.82), _FamilyUi.violet],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: kColorWhite, width: 2),
                ),
                child: SemiBoldText(
                  text: '$rank',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                ),
              ),
            ),
          ],
        ),
        Spacing.v12,
        SemiBoldText(
          text: name,
          fontSize: 11,
          color: kColorWhite,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          align: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppCoinIcon(size: 11, color: Color(0xFFFFB521)),
            const SizedBox(width: 3),
            Flexible(
              child: AppText(
                text: coins <= 0 ? '-' : _compact(coins),
                fontSize: TextStyles.k10FontSize,
                color: kColorWhite.withValues(alpha: 0.70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _activityCard() {
    final activities = _activities();
    return _whiteCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Family Activity',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppText(
                text: 'No recent activity yet.',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.62),
              ),
            )
          else
            ...activities.take(3).map(_activityTile),
        ],
      ),
    );
  }

  Widget _activityTile(Map<String, dynamic> item) {
    final label = _text(
      item['message'] ?? item['title'] ?? item['text'],
      'Family activity updated',
    );
    final time = _text(item['time'] ?? item['createdAt'], '');
    final coins = _int(item['coins'] ?? item['points'] ?? item['amount']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF5C8A),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: kColorWhite,
              size: 19,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: label,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (time.isNotEmpty) ...[
                  Spacing.v2,
                  AppText(
                    text: time,
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.56),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (coins > 0) ...[
            SemiBoldText(
              text: '+$coins',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
            ),
            Spacing.h4,
            const AppCoinIcon(size: 15, color: Color(0xFFFFB521)),
          ],
        ],
      ),
    );
  }

  Widget _whiteCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  List<Map<String, dynamic>> _topMembers() {
    final raw = _group['topMembers'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final members = controller.familyMembers.toList();
    members.sort(
      (a, b) => _int(b['contribution']).compareTo(_int(a['contribution'])),
    );
    return members;
  }

  List<Map<String, dynamic>> _activities() {
    final raw = _group['activities'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  String _joinButtonText() {
    final coins = _int(_group['joiningCoins']);
    return coins <= 0 ? 'Join Family' : 'Pay $coins Coins & Join';
  }

  void _openChat() {
    Get.to(() => FamilyGroupChatPage(group: _group));
  }

  void _openMembers() {
    final familyId = controller.familyIdOf(_group);
    if (familyId.isNotEmpty) {
      controller.loadMembers(familyId, isShowLoader: false);
    }
    Get.to(() => FamilyGroupInfoPage(group: _group));
  }

  void _openGifts() {
    controller.loadGiftCatalog();
    Get.to(() => FamilyGiftsPage(group: _group));
  }

  void _confirmJoinFromDetail() {
    Get.bottomSheet<void>(
      _JoinFamilyConfirmSheet(
        group: _group,
        joiningCoins: _int(_group['joiningCoins']),
        onConfirm: () async {
          Get.back<void>();
          final joined = await controller.joinFamily(_group);
          if (!joined) return;
          if (!mounted) return;
          setState(() {
            _group = {..._group, 'isJoined': true, 'myRole': 'member'};
          });
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  String _text(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
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
    controller.loadGiftCatalog();
    unawaited(controller.startChatListen(familyId));
  }

  @override
  void dispose() {
    unawaited(controller.stopChatListen());
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8FC), Color(0xFFFFF1F8), Color(0xFFF7F2FF)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isLoadingChatMessages.value &&
                    controller.activeChatMessages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: kColorPrimary),
                  );
                }
                final messages = controller.activeChatMessages;
                if (messages.isEmpty) {
                  return _chatEmpty(
                    errorHint: controller.chatListenError.value,
                  );
                }
                // reverse:true keeps the latest message pinned at the bottom
                // (WhatsApp-style), while the list stays chronological.
                return ListView.builder(
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final message = messages[messages.length - 1 - index];
                    return _messageBubble(message);
                  },
                );
              }),
            ),
            Obx(() => _buildTypingBanner()),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBanner() {
    if (!controller.isAnyoneTyping) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFFFD4E8)),
          ),
          child: AppText(
            text: controller.typingStatusLabel,
            fontSize: TextStyles.k12FontSize,
            color: _FamilyChatUi.plum,
          ),
        ),
      ),
    );
  }

  Widget _chatHeader(String name) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _FamilyChatUi.plum,
              _FamilyChatUi.lilac,
              _FamilyChatUi.rose,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _FamilyChatUi.rose.withValues(alpha: 0.20),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: IconButton.filled(
          onPressed: Get.back,
          style: IconButton.styleFrom(
            backgroundColor: kColorWhite.withValues(alpha: 0.16),
          ),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kColorWhite,
            size: 18,
          ),
        ),
      ),
      title: GestureDetector(
        onTap: _openGroupInfo,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.kBoldPoppins(
                  fontSize: TextStyles.k18FontSize,
                  colors: kColorWhite,
                ),
              ),
              const SizedBox(height: 2),
              Obx(() {
                if (controller.isAnyoneTyping) {
                  return AppText(
                    text: controller.typingStatusLabel,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.88),
                    maxLines: 1,
                  );
                }
                final count = controller.familyMembers.isNotEmpty
                    ? controller.familyMembers.length
                    : (widget.group['memberCount'] ?? 0);
                return AppText(
                  text: '$count members',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.78),
                );
              }),
            ],
          ),
        ),
      ),
      actions: const [SizedBox(width: 48)],
    );
  }

  Widget _chatEmpty({String errorHint = ''}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_FamilyChatUi.lilac, _FamilyChatUi.rose],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _FamilyChatUi.rose.withValues(alpha: 0.24),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: kColorWhite,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const SemiBoldText(
              text: 'Start the family conversation',
              fontSize: TextStyles.k16FontSize,
              color: kColorText,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            AppText(
              text: errorHint.isNotEmpty
                  ? errorHint
                  : 'Messages will appear here when available.',
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
              align: TextAlign.center,
            ),
          ],
        ),
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
    final bubbleTextColor = mine ? kColorWhite : kColorText;

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
            child: AppText(text: text, fontSize: 11, color: kColorHint),
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
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: mine ? null : _FamilyChatUi.incomingBubble,
              gradient: mine
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_FamilyChatUi.rose, _FamilyChatUi.plum],
                    )
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(mine ? 22 : 6),
                bottomRight: Radius.circular(mine ? 6 : 22),
              ),
              border: Border.all(
                color: mine
                    ? kColorWhite.withValues(alpha: 0.10)
                    : const Color(0xFFFFD4E8),
              ),
              boxShadow: [
                BoxShadow(
                  color: (mine ? _FamilyChatUi.rose : kColorBlack).withValues(
                    alpha: mine ? 0.16 : 0.06,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
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
                      color: _FamilyChatUi.plum,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (media.isNotEmpty || type == 'gift') ...[
                  if (type == 'gift')
                    _InlineGiftMessageMedia(
                      media: media,
                      size: 132,
                      fallbackName: text,
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _FamilyNetworkImage(
                        url: media,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                        fallback: const _FamilyImagePlaceholder(
                          icon: Icons.emoji_emotions_rounded,
                        ),
                      ),
                    ),
                  Spacing.v6,
                ],
                AppText(
                  text: ProfanityMaskUtils.mask(PhoneMaskUtils.mask(text)),
                  fontSize: TextStyles.k14FontSize,
                  color: bubbleTextColor,
                ),
              ],
            ),
          ),
          Spacing.v4,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(text: time, fontSize: 10, color: const Color(0xFF77849D)),
              if (mine) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  color: _FamilyChatUi.plum,
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
      final direct =
          (message['giftAnimationUrl'] ??
                  message['giftThumbnailUrl'] ??
                  message['giftImage'] ??
                  message['giftIcon'] ??
                  message['image'] ??
                  '')
              .toString()
              .trim();
      if (direct.isNotEmpty) return direct;

      final giftId = (message['giftId'] ?? message['gift_id'] ?? '')
          .toString()
          .trim();
      final giftName = (message['giftName'] ?? message['gift_name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      for (final gift in controller.giftCatalog) {
        final id = (gift['id'] ?? '').trim();
        final name = (gift['name'] ?? '').trim().toLowerCase();
        if ((giftId.isNotEmpty && id == giftId) ||
            (giftName.isNotEmpty && name == giftName)) {
          return (gift['animationUrl']?.trim().isNotEmpty == true
                  ? gift['animationUrl']
                  : gift['icon']) ??
              '';
        }
      }
      return '';
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
        14,
        16,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: const Border(top: BorderSide(color: Color(0xFFFFE0EF))),
        boxShadow: [
          BoxShadow(
            color: _FamilyChatUi.rose.withValues(alpha: 0.10),
            offset: const Offset(0, -8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          _composerIcon(Icons.emoji_emotions_outlined, _showEmojiSheet),
          Spacing.h8,
          _composerIcon(Icons.card_giftcard_rounded, _showGiftSheet),
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
                  colors: const Color(0xFF8A7895),
                ),
                filled: true,
                fillColor: _FamilyChatUi.composerField,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFFFD8EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _FamilyChatUi.rose),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: controller.onComposerTextChanged,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_FamilyChatUi.rose, _FamilyChatUi.plum],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _FamilyChatUi.rose.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
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

  Widget _composerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _FamilyChatUi.composerField,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD8EA)),
        ),
        child: Icon(icon, color: _FamilyChatUi.plum, size: 22),
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
    controller.loadGiftCatalog(force: true);
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

  void _openGroupInfo() {
    controller.loadMembers(familyId);
    Get.to(() => FamilyGroupInfoPage(group: widget.group));
  }
}

class _InlineGiftMessageMedia extends StatefulWidget {
  const _InlineGiftMessageMedia({
    required this.media,
    required this.size,
    required this.fallbackName,
  });

  final String media;
  final double size;
  final String fallbackName;

  @override
  State<_InlineGiftMessageMedia> createState() =>
      _InlineGiftMessageMediaState();
}

class _InlineGiftMessageMediaState extends State<_InlineGiftMessageMedia> {
  int _playNonce = 0;

  @override
  Widget build(BuildContext context) {
    final media = widget.media.trim();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: const Color(0xFF251B3A),
                alignment: Alignment.center,
                child: _giftMedia(media),
              ),
            ),
          ),
          Positioned(
            right: 7,
            bottom: 7,
            child: GestureDetector(
              onTap: _replay,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kColorBlack.withValues(alpha: 0.54),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.replay_rounded,
                  color: kColorWhite,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _giftMedia(String media) {
    if (media.isEmpty) {
      return const GiftIconWidget(icon: '🎁', size: 74, emojiSize: 54);
    }
    if (_looksLikeNetworkImage(media)) {
      return _FamilyNetworkImage(
        key: ValueKey('family-gift-image-$media-$_playNonce'),
        url: media,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        fallback: const GiftIconWidget(icon: '🎁', size: 74, emojiSize: 54),
      );
    }
    return GiftIconWidget(
      key: ValueKey('family-gift-icon-$media-$_playNonce'),
      icon: media,
      size: 82,
      emojiSize: 54,
    );
  }

  void _replay() {
    setState(() => _playNonce++);
  }

  bool _looksLikeNetworkImage(String value) {
    final text = value.trim().toLowerCase();
    final network = text.startsWith('http://') || text.startsWith('https://');
    if (!network) return false;
    return text.endsWith('.png') ||
        text.endsWith('.jpg') ||
        text.endsWith('.jpeg') ||
        text.endsWith('.webp') ||
        text.endsWith('.gif') ||
        text.contains('.png?') ||
        text.contains('.jpg?') ||
        text.contains('.jpeg?') ||
        text.contains('.webp?') ||
        text.contains('.gif?');
  }
}

/// Full-screen gift catalog for family details.
class FamilyGiftsPage extends StatefulWidget {
  const FamilyGiftsPage({super.key, required this.group});

  final Map<String, dynamic> group;

  @override
  State<FamilyGiftsPage> createState() => _FamilyGiftsPageState();
}

class _FamilyGiftsPageState extends State<FamilyGiftsPage> {
  int _selectedTabIndex = 0;
  int _selectedGiftIndex = -1;

  FamilyController get controller => Get.find<FamilyController>();

  @override
  void initState() {
    super.initState();
    controller.loadGiftCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.group['name']?.toString() ?? 'Family Group';
    return Scaffold(
      backgroundColor: _FamilyUi.bg,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _FamilyUi.pink.withValues(alpha: 0.22),
              _FamilyUi.bg,
              _FamilyUi.ink,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(name),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingGifts.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: _FamilyUi.pink),
                    );
                  }
                  if (controller.giftCatalog.isEmpty) {
                    return _emptyState();
                  }
                  return Column(
                    children: [
                      _giftScope(),
                      Spacing.v10,
                      _tabBar(),
                      Spacing.v8,
                      Expanded(child: _giftGrid()),
                      _giftDetailsBar(),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String familyName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          _circleButton(Icons.arrow_back_ios_new_rounded, Get.back),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldText(
                  text: 'Family Gifts',
                  fontSize: TextStyles.k20FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v2,
                AppText(
                  text: familyName,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.72),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AdminAgencyUi.glowIcon(
            icon: Icons.card_giftcard_rounded,
            accent: _FamilyUi.pink,
            accentEnd: _FamilyUi.gold,
            size: 46,
            iconSize: 23,
          ),
        ],
      ),
    );
  }

  Widget _giftScope() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.pinkAccent,
            size: 18,
          ),
          Spacing.h8,
          Expanded(
            child: AppText(
              text: 'Family gifts are credited to the group admin.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    final tabs = _tabs();
    if (_selectedTabIndex >= tabs.length) {
      _selectedTabIndex = 0;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedTabIndex = index;
              _selectedGiftIndex = -1;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.pinkAccent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.pinkAccent : Colors.transparent,
                ),
              ),
              child: SemiBoldText(
                text: tabs[index],
                fontSize: TextStyles.k14FontSize,
                color: selected ? kColorWhite : kColorHint,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _giftGrid() {
    final gifts = _visibleGifts();
    if (gifts.isEmpty) {
      return Center(
        child: AppText(
          text: 'No gifts in this category.',
          fontSize: TextStyles.k14FontSize,
          color: kColorHint,
          align: TextAlign.center,
        ),
      );
    }
    return RefreshIndicator(
      color: _FamilyUi.pink,
      onRefresh: _refreshGifts,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          final selected = _selectedGiftIndex == index;
          final price = gift['price'] ?? '0';

          return GestureDetector(
            onTap: () => setState(() => _selectedGiftIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.pinkAccent.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Colors.pinkAccent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GiftIconWidget(icon: gift['icon']),
                  const SizedBox(height: 4),
                  AppText(
                    text: gift['name'] ?? 'Gift',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.diamond_outlined,
                        color: Colors.orange,
                        size: 10,
                      ),
                      Spacing.h2,
                      Flexible(
                        child: AppText(
                          text: price,
                          fontSize: 10,
                          color: kColorHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _giftDetailsBar() {
    final gifts = _visibleGifts();
    final selected =
        _selectedGiftIndex >= 0 && _selectedGiftIndex < gifts.length
        ? gifts[_selectedGiftIndex]
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2D),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          GiftIconWidget(icon: selected?['icon'], size: 42, emojiSize: 32),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SemiBoldText(
                  text: selected?['name'] ?? 'Select a gift',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                AppText(
                  text: selected == null
                      ? 'Gift details will appear here.'
                      : _giftDetailText(selected),
                  fontSize: 11,
                  color: kColorHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (selected != null) ...[
            Spacing.h8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.pinkAccent),
              ),
              child: SemiBoldText(
                text: '${selected['price'] ?? '0'} coins',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ),
            // TODO: Re-enable full-screen gift preview once backend media URLs
            // consistently provide playable animation/image assets.
            // Spacing.h8,
            // SizedBox(
            //   height: 36,
            //   child: ElevatedButton.icon(
            //     onPressed: () => _viewGift(selected),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.pinkAccent,
            //       foregroundColor: kColorWhite,
            //       padding: const EdgeInsets.symmetric(horizontal: 14),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(18),
            //       ),
            //     ),
            //     icon: const Icon(Icons.play_arrow_rounded, size: 18),
            //     label: const SemiBoldText(
            //       text: 'View',
            //       fontSize: TextStyles.k12FontSize,
            //       color: kColorWhite,
            //     ),
            //   ),
            // ),
          ],
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.82),
          shape: BoxShape.circle,
          border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: kColorWhite, size: 20),
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      color: _FamilyUi.pink,
      onRefresh: () async {
        controller.giftCatalog.clear();
        await controller.loadGiftCatalog();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.card_giftcard_rounded,
            accent: _FamilyUi.pink,
            accentEnd: _FamilyUi.gold,
            size: 72,
            iconSize: 34,
          ),
          Spacing.v16,
          const SemiBoldText(
            text: 'No gifts available',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v6,
          AppText(
            text: 'Family gifts will appear here once the catalog is loaded.',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.68),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshGifts() async {
    controller.giftCatalog.clear();
    await controller.loadGiftCatalog();
    if (!mounted) return;
    setState(() {
      _selectedTabIndex = 0;
      _selectedGiftIndex = -1;
    });
  }

  List<String> _tabs() {
    final categories = <String>[];
    for (final gift in controller.giftCatalog) {
      final category = gift['category']?.trim();
      if (category != null &&
          category.isNotEmpty &&
          !categories.contains(category)) {
        categories.add(category);
      }
    }
    return categories.isEmpty ? const ['Gifts'] : categories;
  }

  List<Map<String, String>> _visibleGifts() {
    final tabs = _tabs();
    if (tabs.isEmpty) return const [];
    final tab = tabs[_selectedTabIndex.clamp(0, tabs.length - 1)];
    final filtered = controller.giftCatalog
        .where((gift) => (gift['category'] ?? 'Gifts') == tab)
        .toList();
    return filtered.isEmpty ? controller.giftCatalog.toList() : filtered;
  }

  String _giftDetailText(Map<String, String> gift) {
    final category = gift['category']?.trim();
    final hasGif = gift['animationUrl']?.trim().isNotEmpty == true;
    final hasSound = gift['soundUrl']?.trim().isNotEmpty == true;
    final parts = <String>[
      if (category != null && category.isNotEmpty) category,
      if (hasGif) 'GIF',
      if (hasSound) 'Sound',
    ];
    return parts.isEmpty ? 'Family gift' : parts.join(' · ');
  }
}

/// Full-screen group info + members (opened from chat app bar title).
class FamilyGroupInfoPage extends StatelessWidget {
  const FamilyGroupInfoPage({super.key, required this.group});

  final Map<String, dynamic> group;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FamilyController>();
    final familyId = controller.familyIdOf(group);
    final name = group['name']?.toString() ?? 'Family Group';
    final description = group['description']?.toString().trim() ?? '';
    final joiningCoins = group['joiningCoins'] ?? 0;

    return Scaffold(
      backgroundColor: _FamilyUi.bg,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
            opacity: 0.55,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _FamilyUi.violet.withValues(alpha: 0.28),
              _FamilyUi.bg,
              _FamilyUi.ink,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _infoHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    _heroCard(
                      controller: controller,
                      name: name,
                      description: description,
                      joiningCoins: joiningCoins,
                    ),
                    Spacing.v16,
                    _membersSection(controller: controller, familyId: familyId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            child: SemiBoldText(
              text: 'Group info',
              fontSize: TextStyles.k20FontSize,
              color: kColorWhite,
            ),
          ),
          AdminAgencyUi.glowIcon(
            icon: Icons.info_outline_rounded,
            accent: _FamilyUi.cyan,
            accentEnd: _FamilyUi.violet,
            size: 42,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _heroCard({
    required FamilyController controller,
    required String name,
    required String description,
    required dynamic joiningCoins,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
      child: Column(
        children: [
          _Avatar(
            imageUrl: group['logo']?.toString() ?? '',
            name: name,
            size: 92,
          ),
          Spacing.v12,
          SemiBoldText(
            text: name,
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v6,
          Obx(() {
            final count = controller.familyMembers.isNotEmpty
                ? controller.familyMembers.length
                : (group['memberCount'] ?? 0);
            return AppText(
              text: 'Group · $count members',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.68),
              align: TextAlign.center,
            );
          }),
          if (description.isNotEmpty) ...[
            Spacing.v10,
            AppText(
              text: description,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
          ],
          Spacing.v12,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  _FamilyUi.gold.withValues(alpha: 0.22),
                  _FamilyUi.pink.withValues(alpha: 0.14),
                ],
              ),
              border: Border.all(color: _FamilyUi.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppCoinIcon(size: 16, color: _FamilyUi.gold),
                Spacing.h6,
                AppText(
                  text: 'Join coins: $joiningCoins',
                  fontSize: TextStyles.k12FontSize,
                  color: _FamilyUi.gold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _membersSection({
    required FamilyController controller,
    required String familyId,
  }) {
    return Obx(() {
      final admin = controller.isAdmin(group);
      final members = controller.familyMembers;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: _FamilyUi.panel.withValues(alpha: 0.92),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SemiBoldText(
                      text:
                          'Members${members.isEmpty ? '' : ' (${members.length})'}',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                  ),
                  if (admin)
                    TextButton.icon(
                      onPressed: () => _openAddMembersSheet(
                        controller: controller,
                        familyId: familyId,
                      ),
                      icon: const Icon(
                        Icons.group_add_rounded,
                        color: _FamilyUi.cyan,
                        size: 18,
                      ),
                      label: const AppText(
                        text: 'Add member',
                        fontSize: 13,
                        color: _FamilyUi.cyan,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => controller.leaveFamily(group),
                      child: const AppText(
                        text: 'Leave group',
                        fontSize: 13,
                        color: Color(0xFFFF6B8A),
                      ),
                    ),
                ],
              ),
            ),
            if (controller.isLoadingMembers.value && members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(color: _FamilyUi.pink),
                ),
              )
            else if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: AppText(
                  text: 'No members found.',
                  fontSize: 13,
                  color: kColorWhite.withValues(alpha: 0.55),
                  align: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                itemCount: members.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: kColorWhite.withValues(alpha: 0.06),
                ),
                itemBuilder: (_, index) {
                  final member = members[index];
                  return _memberTile(
                    controller: controller,
                    familyId: familyId,
                    member: member,
                    canManage: admin,
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  void _openAddMembersSheet({
    required FamilyController controller,
    required String familyId,
  }) {
    final searchController = TextEditingController();
    controller.selectedInitialMembers.clear();
    controller.loadPickerUsers(followersOnly: true);
    Get.bottomSheet<void>(
      _FamilyAddMembersSheet(
        familyId: familyId,
        searchController: searchController,
        existingMemberIds: _currentMemberIds(controller),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(() {
      searchController.dispose();
      controller.selectedInitialMembers.clear();
    });
  }

  Set<String> _currentMemberIds(FamilyController controller) {
    return controller.familyMembers
        .map((member) => (member['userId'] ?? member['id'] ?? '').toString())
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Widget _memberTile({
    required FamilyController controller,
    required String familyId,
    required Map<String, dynamic> member,
    required bool canManage,
  }) {
    final userId = member['userId']?.toString() ?? '';
    final self = userId == controller.currentUserId;
    final role = (member['role']?.toString() ?? 'member').toLowerCase();
    final name = member['name']?.toString() ?? 'Member';
    final memberIsAdmin = controller.isMemberAdmin(member);
    final canRemove = canManage && !self && !memberIsAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          _Avatar(
            imageUrl: member['displayPicture']?.toString() ?? '',
            frameUrl: member['avatarFrameUrl']?.toString() ?? '',
            name: name,
            size: 48,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: name,
                  fontSize: 14,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v2,
                AppText(
                  text: self ? '$role · You' : role,
                  fontSize: 12,
                  color: kColorWhite.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
          if (memberIsAdmin) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    _FamilyUi.violet.withValues(alpha: 0.45),
                    _FamilyUi.pink.withValues(alpha: 0.35),
                  ],
                ),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
              ),
              child: const AppText(
                text: 'Admin',
                fontSize: 11,
                color: kColorWhite,
              ),
            ),
            if (canRemove) Spacing.h8,
          ],
          if (canRemove)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => controller.removeMember(
                  familyId: familyId,
                  userId: userId,
                  memberName: name,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFFF5C8A).withValues(alpha: 0.14),
                    border: Border.all(
                      color: const Color(0xFFFF5C8A).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_remove_rounded,
                        size: 16,
                        color: Color(0xFFFF6B8A),
                      ),
                      SizedBox(width: 6),
                      AppText(
                        text: 'Remove',
                        fontSize: 12,
                        color: Color(0xFFFF6B8A),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditFamilyNameSheet extends StatefulWidget {
  const _EditFamilyNameSheet({
    required this.initialName,
    required this.initialDescription,
  });

  final String initialName;
  final String initialDescription;

  @override
  State<_EditFamilyNameSheet> createState() => _EditFamilyNameSheetState();
}

class _EditFamilyNameSheetState extends State<_EditFamilyNameSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.back<Map<String, String>>(
      result: {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF241833), _FamilyUi.bg],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                Row(
                  children: [
                    AdminAgencyUi.glowIcon(
                      icon: Icons.edit_rounded,
                      accent: _FamilyUi.violet,
                      accentEnd: _FamilyUi.pink,
                      size: 46,
                      iconSize: 22,
                    ),
                    Spacing.h12,
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: 'Edit group',
                            fontSize: TextStyles.k18FontSize,
                            color: kColorWhite,
                          ),
                          AppText(
                            text: 'Update name and description',
                            fontSize: 11,
                            color: Color(0xB3FFFFFF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacing.v16,
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  style: TextStyles.kRegularPoppins(
                    fontSize: 14,
                    colors: kColorWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Group name',
                    hintStyle: TextStyles.kRegularPoppins(
                      fontSize: 13,
                      colors: kColorWhite.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: kColorWhite.withValues(alpha: 0.07),
                    prefixIcon: const Icon(
                      Icons.badge_rounded,
                      color: _FamilyUi.violet,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Spacing.v12,
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyles.kRegularPoppins(
                    fontSize: 14,
                    colors: kColorWhite,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyles.kRegularPoppins(
                      fontSize: 13,
                      colors: kColorWhite.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: kColorWhite.withValues(alpha: 0.07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Spacing.v16,
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: Get.back,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: kColorWhite.withValues(alpha: 0.22),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: SemiBoldText(
                            text: 'Cancel',
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                    Spacing.h10,
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _FamilyUi.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const SemiBoldText(
                            text: 'Save',
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyAddMembersSheet extends StatelessWidget {
  const _FamilyAddMembersSheet({
    required this.familyId,
    required this.searchController,
    required this.existingMemberIds,
  });

  final String familyId;
  final TextEditingController searchController;
  final Set<String> existingMemberIds;

  FamilyController get controller => Get.find<FamilyController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241833), _FamilyUi.bg],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    icon: Icons.group_add_rounded,
                    accent: _FamilyUi.cyan,
                    accentEnd: _FamilyUi.violet,
                    size: 46,
                    iconSize: 23,
                  ),
                  Spacing.h12,
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldText(
                          text: 'Add members',
                          fontSize: TextStyles.k18FontSize,
                          color: kColorWhite,
                        ),
                        AppText(
                          text: 'Invite followers or search app users',
                          fontSize: 11,
                          color: Color(0xB3FFFFFF),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacing.v16,
              Obx(
                () => Row(
                  children: [
                    _modeButton(
                      'Followers',
                      Icons.favorite_rounded,
                      controller.pickerFollowersOnly.value,
                      () => controller.setPickerSearchMode(true),
                    ),
                    Spacing.h8,
                    _modeButton(
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
                final selectedUsers = _availableUsers()
                    .where(controller.isInitialMemberSelected)
                    .toList();
                if (selectedUsers.isEmpty) return Spacing.v12;
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedUsers.length,
                      separatorBuilder: (_, __) => Spacing.h8,
                      itemBuilder: (_, index) =>
                          _selectedChip(selectedUsers[index]),
                    ),
                  ),
                );
              }),
              Spacing.v10,
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingPickerUsers.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: _FamilyUi.pink),
                    );
                  }
                  final users = _availableUsers();
                  if (users.isEmpty) {
                    return _emptyState();
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (_, index) => _userTile(users[index]),
                  );
                }),
              ),
              Spacing.v12,
              Obx(() {
                final count = controller.selectedInitialMembers.length;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: count == 0
                        ? null
                        : () async {
                            final added = await controller.addMembersToFamily(
                              familyId: familyId,
                              userIds: controller.selectedInitialMembers
                                  .toList(),
                            );
                            if (added) {
                              Get.back<void>();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _FamilyUi.pink,
                      disabledBackgroundColor: kColorWhite.withValues(
                        alpha: 0.10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(
                      Icons.group_add_rounded,
                      color: kColorWhite,
                    ),
                    label: SemiBoldText(
                      text: count == 0
                          ? 'Select members'
                          : 'Add $count Members',
                      fontSize: TextStyles.k14FontSize,
                      color: count == 0
                          ? kColorWhite.withValues(alpha: 0.46)
                          : kColorWhite,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _availableUsers() {
    return controller.pickerUsers.where((user) {
      final id = controller.pickerUserId(user);
      return id.isNotEmpty && !existingMemberIds.contains(id);
    }).toList();
  }

  Widget _modeButton(
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
          height: 40,
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
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _FamilyUi.pink),
      ),
    );
  }

  Widget _selectedChip(Map<String, dynamic> user) {
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

  Widget _userTile(Map<String, dynamic> user) {
    final userId = controller.pickerUserId(user);
    return Obx(() {
      final selected = controller.isInitialMemberSelected(user);
      return Container(
        key: ValueKey('family-add-member-$userId-$selected'),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.person_search_rounded,
            accent: _FamilyUi.cyan,
            accentEnd: _FamilyUi.violet,
            size: 58,
            iconSize: 27,
          ),
          Spacing.v10,
          AppText(
            text: controller.pickerFollowersOnly.value
                ? 'No followers available to add'
                : 'No users available to add',
            fontSize: 12,
            color: kColorWhite.withValues(alpha: 0.72),
            align: TextAlign.center,
          ),
        ],
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

  bool get _isGiftSheet => title.toLowerCase().contains('gift');

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
                    final price = item['price']?.trim() ?? '';
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
                              child: _CatalogMedia(
                                item: item,
                                accent: accent,
                                isGift: _isGiftSheet,
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
                            if (_isGiftSheet && price.isNotEmpty) ...[
                              Spacing.v2,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.diamond_outlined,
                                    color: Colors.orange,
                                    size: 10,
                                  ),
                                  Spacing.h2,
                                  Flexible(
                                    child: AppText(
                                      text: price,
                                      fontSize: 10,
                                      color: kColorHint,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

class _CatalogMedia extends StatelessWidget {
  const _CatalogMedia({
    required this.item,
    required this.accent,
    required this.isGift,
  });

  final Map<String, String> item;
  final Color accent;
  final bool isGift;

  @override
  Widget build(BuildContext context) {
    if (isGift) {
      return GiftIconWidget(
        icon: item['icon']?.trim().isNotEmpty == true
            ? item['icon']
            : item['image'],
      );
    }
    return _FamilyNetworkImage(
      url: item['image']?.toString() ?? '',
      fit: BoxFit.contain,
      loaderColor: accent,
      fallback: _FamilyImagePlaceholder(
        icon: Icons.image_not_supported_rounded,
        iconColor: accent,
      ),
    );
  }
}

class _JoinFamilyConfirmSheet extends StatelessWidget {
  const _JoinFamilyConfirmSheet({
    required this.group,
    required this.joiningCoins,
    required this.onConfirm,
  });

  final Map<String, dynamic> group;
  final int joiningCoins;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final name = group['name']?.toString() ?? 'Family Group';
    final isPaid = joiningCoins > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241833), _FamilyUi.bg],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: kColorWhite.withValues(alpha: 0.10)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            AdminAgencyUi.glowIcon(
              icon: Icons.groups_rounded,
              accent: _FamilyUi.gold,
              accentEnd: _FamilyUi.pink,
              size: 60,
              iconSize: 30,
            ),
            Spacing.v12,
            SemiBoldText(
              text: 'Join $name',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v8,
            AppText(
              text: isPaid
                  ? 'This group requires joining coins. Your wallet will be debited and the admin receives the fee.'
                  : 'This group is free to join. No coins will be charged.',
              fontSize: 13,
              color: kColorWhite.withValues(alpha: 0.72),
              align: TextAlign.center,
            ),
            Spacing.v16,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    _FamilyUi.gold.withValues(alpha: 0.18),
                    _FamilyUi.pink.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: _FamilyUi.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const AppCoinIcon(size: 28, color: _FamilyUi.gold),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: isPaid ? 'Joining coins' : 'Join fee',
                          fontSize: TextStyles.k12FontSize,
                          color: kColorWhite.withValues(alpha: 0.7),
                        ),
                        Spacing.v2,
                        SemiBoldText(
                          text: isPaid ? '$joiningCoins coins' : 'Free',
                          fontSize: TextStyles.k18FontSize,
                          color: _FamilyUi.gold,
                        ),
                      ],
                    ),
                  ),
                  if (isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _FamilyUi.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const AppText(
                        text: 'Required',
                        fontSize: 11,
                        color: _FamilyUi.gold,
                      ),
                    ),
                ],
              ),
            ),
            Spacing.v16,
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: kColorWhite.withValues(alpha: 0.22),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: SemiBoldText(
                        text: 'Cancel',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _FamilyUi.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: SemiBoldText(
                        text: isPaid
                            ? 'Pay $joiningCoins & Join'
                            : 'Join Group',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyNetworkImage extends StatelessWidget {
  const _FamilyNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loaderColor = _FamilyUi.pink,
  });

  final String url;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color loaderColor;

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
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: loaderColor,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
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
