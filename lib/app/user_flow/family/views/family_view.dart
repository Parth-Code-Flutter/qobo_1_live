import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
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
}

class FamilyView extends GetView<FamilyController> {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FamilyUi.bg,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
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
        onPressed: () => _showCreateSheet(context),
        backgroundColor: _FamilyUi.pink,
        child: const Icon(Icons.add_rounded, color: kColorWhite),
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
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_FamilyUi.panel2, Color(0xFF130B21)],
            ),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: _FamilyUi.pink.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
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
                      text: group['description']?.toString().isNotEmpty == true
                          ? group['description'].toString()
                          : 'Group chat community',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite.withValues(alpha: 0.65),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v10,
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
              Icon(
                isMine ? Icons.chat_bubble_rounded : Icons.login_rounded,
                color: isMine ? _FamilyUi.cyan : _FamilyUi.gold,
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
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_FamilyUi.gold, _FamilyUi.pink],
        ),
        border: Border.all(
          color: kColorWhite.withValues(alpha: 0.75),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: logo.isNotEmpty
          ? Image.network(logo, fit: BoxFit.cover)
          : Center(
              child: SemiBoldText(
                text: name.substring(0, 1).toUpperCase(),
                fontSize: TextStyles.k22FontSize,
                color: kColorWhite,
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

  void _showCreateSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final coinsController = TextEditingController(text: '0');
    controller.selectedInitialMembers.clear();
    controller.loadPickerUsers();

    Get.bottomSheet<void>(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: _FamilyUi.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                const SemiBoldText(
                  text: 'Create Family Group',
                  fontSize: TextStyles.k20FontSize,
                  color: kColorWhite,
                ),
                Spacing.v12,
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
                TextField(
                  onSubmitted: (value) => controller.loadPickerUsers(
                    query: value,
                    followersOnly: false,
                  ),
                  style: TextStyles.kRegularPoppins(
                    fontSize: 13,
                    colors: kColorWhite,
                  ),
                  decoration: _inputDecoration(
                    'Search followers or app users',
                    Icons.person_search_rounded,
                  ),
                ),
                Spacing.v10,
                Flexible(
                  child: Obx(() {
                    if (controller.isLoadingPickerUsers.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: _FamilyUi.pink),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.pickerUsers.length,
                      itemBuilder: (_, index) {
                        final user = controller.pickerUsers[index];
                        final id = user['userId']?.toString() ?? '';
                        final selected = controller.selectedInitialMembers
                            .contains(id);
                        return _userPickTile(user, selected);
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
    );
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

  Widget _userPickTile(Map<String, dynamic> user, bool selected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
        selected
            ? Icons.check_circle_rounded
            : Icons.add_circle_outline_rounded,
        color: selected ? _FamilyUi.green : _FamilyUi.cyan,
      ),
      onTap: () =>
          controller.toggleInitialMember(user['userId']?.toString() ?? ''),
    );
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
      backgroundColor: _FamilyUi.bg,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _chatHeader(name),
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
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      itemCount: messages.length,
                      itemBuilder: (_, index) =>
                          _messageBubble(messages[index]),
                    );
                  },
                ),
              ),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatHeader(String name) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _FamilyUi.panel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: kColorWhite,
            ),
          ),
          _Avatar(
            imageUrl: widget.group['logo']?.toString() ?? '',
            name: name,
            size: 44,
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: name,
                  fontSize: 15,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppText(
                  text: '${widget.group['memberCount'] ?? 0} members',
                  fontSize: 11,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showMembersSheet,
            icon: const Icon(Icons.settings_rounded, color: _FamilyUi.cyan),
          ),
        ],
      ),
    );
  }

  Widget _chatEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.forum_rounded,
              accent: _FamilyUi.cyan,
              accentEnd: _FamilyUi.violet,
              size: 72,
              iconSize: 34,
            ),
            Spacing.v12,
            const SemiBoldText(
              text: 'Start the family chat',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: 'Messages, emojis, and gifts will appear here in realtime.',
              fontSize: 13,
              color: kColorWhite.withValues(alpha: 0.68),
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

    if (type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AppText(
              text: text,
              fontSize: 11,
              color: kColorWhite.withValues(alpha: 0.75),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine
              ? _FamilyUi.pink
              : _FamilyUi.panel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              AppText(
                text: sender,
                fontSize: TextStyles.k10FontSize,
                color: _FamilyUi.gold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (media.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  media,
                  width: type == 'emoji' ? 92 : 120,
                  height: type == 'emoji' ? 92 : 120,
                  fit: BoxFit.cover,
                ),
              ),
              Spacing.v6,
            ],
            AppText(text: text, fontSize: 13, color: kColorWhite),
          ],
        ),
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

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: _FamilyUi.bg.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: kColorWhite.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          _roundAction(
            Icons.emoji_emotions_rounded,
            _FamilyUi.gold,
            _showEmojiSheet,
          ),
          Spacing.h8,
          _roundAction(
            Icons.card_giftcard_rounded,
            _FamilyUi.pink,
            _showGiftSheet,
          ),
          Spacing.h8,
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: kColorWhite,
              ),
              decoration: InputDecoration(
                hintText: 'Message the family...',
                hintStyle: TextStyles.kRegularPoppins(
                  fontSize: 13,
                  colors: kColorWhite.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: _FamilyUi.panel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
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
          Spacing.h8,
          Obx(
            () => _roundAction(
              controller.isSendingMessage.value
                  ? Icons.more_horiz_rounded
                  : Icons.send_rounded,
              _FamilyUi.cyan,
              () => controller.sendTextMessage(
                familyId: familyId,
                textController: _textController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _FamilyUi.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, color: color, size: 21),
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
                              child: Image.network(
                                item['image'] ?? '',
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image_rounded,
                                  color: accent,
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
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Center(
                    child: SemiBoldText(
                      text: initial,
                      fontSize: size * 0.34,
                      color: kColorWhite,
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
