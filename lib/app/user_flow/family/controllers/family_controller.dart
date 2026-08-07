import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/family/family_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/direct_gift_bottom_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/family_member_actions_sheet.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class FamilyController extends GetxController {
  FamilyController({FamilyRepo? familyRepo})
    : _familyRepo = familyRepo ?? FamilyRepo();

  final FamilyRepo _familyRepo;
  final isLoading = true.obs;

  final hasFamily = false.obs;
  final searchQuery = ''.obs;

  /// 0 = This Week, 1 = Last Week, 2 = Rewards
  final rankingTab = 0.obs;

  final RxList<Map<String, dynamic>> popularFamilies =
      <Map<String, dynamic>>[].obs;

  // Active family user details (populated when hasFamily is true)
  final RxMap<String, dynamic> myFamily = <String, dynamic>{}.obs;

  final RxList<Map<String, dynamic>> familyMembers =
      <Map<String, dynamic>>[].obs;

  /// Sponsor / invite lineage from `sponsor_tree` / `parentId`.
  final RxList<Map<String, dynamic>> sponsorNodes =
      <Map<String, dynamic>>[].obs;

  /// 0 = Role tree, 1 = Sponsor tree
  final treeMode = 0.obs;

  String get _currentUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId.trim();
  }

  /// Role-based tree: leaders (creator/owner/leader) → officers → members.
  List<Map<String, dynamic>> get treeLeaders =>
      familyMembers.where((m) => _roleTier(m['role']) == 0).toList();

  List<Map<String, dynamic>> get treeOfficers =>
      familyMembers.where((m) => _roleTier(m['role']) == 1).toList();

  List<Map<String, dynamic>> get treeMembers =>
      familyMembers.where((m) => _roleTier(m['role']) >= 2).toList();

  /// Roots of sponsor tree (no parent, or parent not in roster).
  List<Map<String, dynamic>> get sponsorRoots {
    final ids = sponsorNodes
        .map((m) => m['userId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    return sponsorNodes.where((m) {
      final parent = m['parentId']?.toString().trim() ?? '';
      return parent.isEmpty || !ids.contains(parent);
    }).toList();
  }

  List<Map<String, dynamic>> sponsorChildrenOf(String userId) {
    if (userId.isEmpty) return const [];
    return sponsorNodes
        .where((m) => (m['parentId']?.toString().trim() ?? '') == userId)
        .toList();
  }

  void selectTreeMode(int index) {
    treeMode.value = index.clamp(0, 1);
  }

  @override
  void onInit() {
    super.onInit();
    loadFamilyHub();
  }

  /// Tap a tree node → gift / DM sheet.
  Future<void> onFamilyMemberTap(
    BuildContext context,
    Map<String, dynamic> member,
  ) async {
    final userId = member['userId']?.toString().trim() ?? '';
    final isSelf = userId.isNotEmpty && userId == _currentUserId;

    final action = await FamilyMemberActionsSheet.show(
      member: member,
      isSelf: isSelf,
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case FamilyMemberAction.directMessage:
        await openMemberDirectMessage(context, member);
      case FamilyMemberAction.sendGift:
        await openMemberSendGift(member);
    }
  }

  Future<void> openMemberDirectMessage(
    BuildContext context,
    Map<String, dynamic> member,
  ) async {
    final userId = member['userId']?.toString().trim() ?? '';
    if (userId.isEmpty) {
      Get.snackbar(
        'Message',
        'This member has no user id from the API yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await ChatNavigationHelper.openDirectChat(
      context,
      targetId: userId,
      name: member['name']?.toString() ?? 'Member',
      imageUrl: member['displayPicture']?.toString(),
    );
  }

  Future<void> openMemberSendGift(Map<String, dynamic> member) async {
    final userId = member['userId']?.toString().trim() ?? '';
    final familyId = myFamily['id']?.toString().trim() ?? '';
    if (userId.isEmpty) {
      Get.snackbar(
        'Gift',
        'This member has no user id from the API yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (familyId.isEmpty) {
      Get.snackbar(
        'Gift',
        'Family id is missing — cannot send gift context.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Confirmed backend: roomId = familyId, sessionType/scope = family.
    await DirectGiftBottomSheet.show(
      receiverId: userId,
      receiverName: member['name']?.toString() ?? 'Member',
      roomId: familyId,
      sessionType: 'family',
    );
  }

  // Filtered popular families for search
  List<Map<String, dynamic>> get filteredFamilies {
    if (searchQuery.value.isEmpty) {
      return popularFamilies;
    }
    return popularFamilies.where((f) {
      final name = f['name'].toString().toLowerCase();
      final id = f['id'].toString().toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  /// Families sorted for ranking display (level + members).
  List<Map<String, dynamic>> get rankedFamilies {
    final list = List<Map<String, dynamic>>.from(filteredFamilies);
    list.sort((a, b) {
      final scoreA = _toInt(a['level']) * 1000 + _toInt(a['members']);
      final scoreB = _toInt(b['level']) * 1000 + _toInt(b['members']);
      return scoreB.compareTo(scoreA);
    });
    // Last-week tab: soft alternate order until a dedicated API exists.
    if (rankingTab.value == 1 && list.length > 1) {
      return list.reversed.toList();
    }
    return list;
  }

  Map<String, dynamic>? get topRankedFamily {
    final ranked = rankedFamilies;
    return ranked.isEmpty ? null : ranked.first;
  }

  /// Days / hours / mins / secs until next Monday 00:00 local.
  ({int days, int hours, int minutes, int seconds}) get weekCountdown {
    final now = DateTime.now();
    var daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    if (daysUntilMonday == 0) {
      daysUntilMonday = 7;
    }
    final end = DateTime(now.year, now.month, now.day)
        .add(Duration(days: daysUntilMonday));
    final diff = end.difference(now);
    return (
      days: diff.inDays,
      hours: diff.inHours % 24,
      minutes: diff.inMinutes % 60,
      seconds: diff.inSeconds % 60,
    );
  }

  void selectRankingTab(int index) {
    rankingTab.value = index.clamp(0, 2);
  }

  Future<void> loadFamilyHub() async {
    isLoading.value = true;
    try {
      final myResponse = await _familyRepo.getMyFamily(isShowLoader: false);
      final myData = myResponse?['data'];
      if (myData is Map && myData.isNotEmpty) {
        hasFamily.value = true;
        myFamily.assignAll(_mapFamily(myData));
        await _loadFamilyMembers(myFamily['id']?.toString() ?? '');
      } else {
        hasFamily.value = false;
        myFamily.clear();
      }

      final listResponse = await _familyRepo.getFamilies(isShowLoader: false);
      final listData = listResponse?['data'];
      final list = listData is Map ? listData['items'] : listData;
      if (list is List) {
        popularFamilies.assignAll(
          list
              .whereType<Map>()
              .map(_mapFamily)
              .where((family) => family['name'].toString().isNotEmpty),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinFamily(String name) async {
    Map<String, dynamic>? family;
    for (final item in popularFamilies) {
      if (item['name'] == name) {
        family = item;
        break;
      }
    }
    final familyId = family?['id']?.toString() ?? '';
    if (familyId.isEmpty) return;

    CommonAppDialog.showGet(
      title: 'Join Family',
      message: 'Send your request to join "$name"?',
      icon: Icons.groups_rounded,
      iconAccent: AdminAgencyUi.pink,
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Join',
          isPrimary: true,
          onPressed: () async {
            final response = await _familyRepo.joinFamily(
              familyId: familyId,
              isShowLoader: true,
            );
            if (response == null || response['statusCode'] == 0) {
              Get.snackbar('Family', 'Could not join this family.');
              return;
            }
            await loadFamilyHub();
            Get.snackbar(
              'Welcome!',
              response['message']?.toString() ??
                  'Your family request was submitted.',
              backgroundColor: const Color(0xFF761B65).withValues(alpha: 0.1),
              colorText: const Color(0xFF761B65),
            );
          },
        ),
      ],
    );
  }

  void leaveFamily() {
    CommonAppDialog.showGet(
      title: 'Leave Family?',
      message:
          'Are you sure you want to leave this family? You will lose access to family chats, tasks and bonuses.',
      icon: Icons.logout_rounded,
      iconAccent: AdminAgencyUi.rose,
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Leave',
          isPrimary: true,
          isDestructive: true,
          onPressed: () async {
            final response = await _familyRepo.leaveFamily(
              isShowLoader: true,
            );
            if (response == null || response['statusCode'] == 0) {
              Get.snackbar('Family', 'Could not leave this family.');
              return;
            }
            await loadFamilyHub();
            Get.snackbar(
              'Left Family',
              response['message']?.toString() ?? 'You have left the family.',
            );
          },
        ),
      ],
    );
  }

  void showCreateFamilyDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    CommonAppDialog.showGet(
      title: 'Create a Family',
      message:
          'Creation cost: 1,000 Coins. Build your community and climb the weekly ranks!',
      icon: Icons.diversity_3_rounded,
      iconAccent: AdminAgencyUi.goldDeep,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            maxLength: 20,
            style: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorWhite,
            ),
            decoration: InputDecoration(
              labelText: 'Family Name',
              labelStyle: TextStyle(color: kColorWhite.withValues(alpha: 0.7)),
              prefixIcon: const Icon(Icons.group, color: AdminAgencyUi.gold),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: kColorWhite.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminAgencyUi.gold),
              ),
            ),
          ),
          Spacing.v12,
          TextField(
            controller: descController,
            maxLength: 100,
            maxLines: 2,
            style: TextStyles.kRegularPoppins(
              fontSize: TextStyles.k14FontSize,
              colors: kColorWhite,
            ),
            decoration: InputDecoration(
              labelText: 'Family Description',
              labelStyle: TextStyle(color: kColorWhite.withValues(alpha: 0.7)),
              prefixIcon: const Icon(
                Icons.description,
                color: AdminAgencyUi.violet,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: kColorWhite.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminAgencyUi.violet),
              ),
            ),
          ),
        ],
      ),
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Create',
          isPrimary: true,
          onPressed: () async {
            final name = nameController.text.trim();
            final desc = descController.text.trim();
            if (name.isEmpty) {
              Get.snackbar('Error', 'Family name cannot be empty');
              return;
            }
            final response = await _familyRepo.createFamily(
              name: name,
              description: desc.isNotEmpty
                  ? desc
                  : 'A brand new Qobo Live family.',
              isShowLoader: true,
            );
            if (response == null || response['statusCode'] == 0) {
              Get.snackbar('Family', 'Could not create family.');
              return;
            }
            await loadFamilyHub();
            Get.snackbar(
              'Congratulations!',
              response['message']?.toString() ??
                  'Family "$name" created successfully!',
              backgroundColor: const Color(0xFF761B65).withValues(alpha: 0.1),
              colorText: const Color(0xFF761B65),
            );
          },
        ),
      ],
    );
  }

  Future<void> _loadFamilyMembers(String familyId) async {
    if (familyId.isEmpty) return;

    // Prefer dedicated roster API (explicit userId / parentId).
    List? rawList;
    final membersResponse = await _familyRepo.getFamilyMembers(
      familyId: familyId,
      isShowLoader: false,
    );
    final membersData = membersResponse?['data'];
    if (membersData is List) {
      rawList = membersData;
    }

    // Tree API: role_tree + sponsor_tree.
    final treeResponse = await _familyRepo.getFamilyTree(
      familyId: familyId,
      isShowLoader: false,
    );
    final treeData = treeResponse?['data'];
    if (treeData is Map) {
      _applySponsorTree(treeData['sponsor_tree'] ?? treeData['sponsorTree']);
      if (rawList == null || rawList.isEmpty) {
        final fromRole = _flattenRoleTree(
          treeData['role_tree'] ?? treeData['roleTree'],
        );
        if (fromRole.isNotEmpty) rawList = fromRole;
      }
    }

    // Fallback: detail payload (also may include role_tree / sponsor_tree).
    if (rawList == null || rawList.isEmpty) {
      final detailResponse = await _familyRepo.getFamilyDetail(
        familyId: familyId,
        isShowLoader: false,
      );
      final data = detailResponse?['data'];
      if (data is Map) {
        rawList = data['members'] is List
            ? data['members'] as List
            : data['memberList'] is List
            ? data['memberList'] as List
            : null;
        if (sponsorNodes.isEmpty) {
          _applySponsorTree(data['sponsor_tree'] ?? data['sponsorTree']);
        }
        if ((rawList == null || rawList.isEmpty)) {
          final fromRole = _flattenRoleTree(
            data['role_tree'] ?? data['roleTree'],
          );
          if (fromRole.isNotEmpty) rawList = fromRole;
        }
        final count = _toInt(data['membersCount'] ?? data['members']);
        if (count > 0) myFamily['members'] = count;
      }
    }

    if (rawList == null) {
      familyMembers.clear();
      return;
    }

    final mapped = rawList
        .whereType<Map>()
        .map(_mapMember)
        .where((m) => (m['name'] as String).isNotEmpty)
        .toList();

    mapped.sort((a, b) {
      final tierCmp = _roleTier(a['role']).compareTo(_roleTier(b['role']));
      if (tierCmp != 0) return tierCmp;
      return _toInt(b['contribution']).compareTo(_toInt(a['contribution']));
    });

    familyMembers.assignAll(mapped);
    myFamily['members'] = mapped.length;

    // If sponsor_tree was empty, derive from roster parentId links.
    if (sponsorNodes.isEmpty) {
      sponsorNodes.assignAll(mapped);
    }

    if (treeLeaders.isNotEmpty) {
      final leaderName = treeLeaders.first['name']?.toString() ?? '';
      if (leaderName.isNotEmpty) {
        myFamily['leader'] = leaderName;
      }
    }
  }

  void _applySponsorTree(dynamic raw) {
    if (raw is! List) {
      sponsorNodes.clear();
      return;
    }
    final mapped = raw
        .whereType<Map>()
        .map(_mapMember)
        .where((m) => (m['name'] as String).isNotEmpty)
        .toList();
    sponsorNodes.assignAll(mapped);
  }

  List<Map> _flattenRoleTree(dynamic roleTree) {
    if (roleTree is! Map) return const [];
    final out = <Map>[];
    final creator = roleTree['creator'];
    if (creator is Map) out.add(Map<String, dynamic>.from(creator));
    final coLeaders =
        roleTree['coLeaders'] ?? roleTree['co_leaders'] ?? roleTree['officers'];
    if (coLeaders is List) {
      for (final item in coLeaders.whereType<Map>()) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    final members = roleTree['members'];
    if (members is List) {
      for (final item in members.whereType<Map>()) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  Map<String, dynamic> _mapMember(Map raw) {
    final user = raw['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : const {};

    String pickText(List<dynamic> candidates) {
      for (final c in candidates) {
        final s = c?.toString().trim() ?? '';
        if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
      }
      return '';
    }

    // Never use membership relation `id` as userId — prefer nested user / userId fields.
    final resolvedUserId = pickText([
      userMap['id'],
      userMap['userId'],
      userMap['user_id'],
      raw['userId'],
      raw['user_id'],
    ]);

    final name = pickText([userMap['name'], raw['name']]);
    final displayName = name.isEmpty ? 'Member' : name;

    final displayPicture = pickText([
      userMap['displayPicture'],
      userMap['display_picture'],
      userMap['avatar'],
      raw['displayPicture'],
      raw['display_picture'],
      raw['avatar'],
    ]);

    final avatarFrameUrl = pickText([
      userMap['avatarFrameUrl'],
      userMap['avatar_frame_url'],
      userMap['profileFrameUrl'],
      raw['avatarFrameUrl'],
      raw['avatar_frame_url'],
    ]);

    final role = pickText([
      raw['role'],
      raw['myRole'],
      userMap['role'],
    ]);
    final resolvedRole = role.isEmpty ? 'member' : role;

    final parentId = pickText([
      raw['parentId'],
      raw['parent_id'],
      raw['invitedBy'],
      raw['invited_by'],
    ]);

    return <String, dynamic>{
      'userId': resolvedUserId,
      'name': displayName,
      'role': resolvedRole,
      'contribution': _toInt(raw['contribution']),
      'avatar': displayName.isNotEmpty
          ? displayName.substring(0, 1).toUpperCase()
          : 'M',
      'displayPicture': displayPicture.isEmpty ? null : displayPicture,
      'avatarFrameUrl': avatarFrameUrl.isEmpty ? null : avatarFrameUrl,
      'isOnline':
          raw['isOnline'] == true ||
          raw['is_online'] == true ||
          userMap['isOnline'] == true,
      'level': _toInt(userMap['level'] ?? raw['level']),
      'parentId': parentId,
      'bio': pickText([userMap['bio'], raw['bio']]),
    };
  }

  /// 0 = leader, 1 = officer, 2 = member.
  static int _roleTier(dynamic role) {
    final r = role?.toString().trim().toLowerCase() ?? '';
    if (r.contains('creator') ||
        r.contains('owner') ||
        r.contains('leader') ||
        r == 'superadmin' ||
        r == 'super_admin') {
      return 0;
    }
    if (r.contains('officer') ||
        r.contains('vice') ||
        r.contains('deputy') ||
        r.contains('elder') ||
        r.contains('co-leader') ||
        r.contains('coleader') ||
        r == 'admin') {
      return 1;
    }
    return 2;
  }

  Map<String, dynamic> _mapFamily(Map raw) {
    return <String, dynamic>{
      'id': raw['id']?.toString() ?? '',
      'name': raw['name']?.toString() ?? '',
      'members': _toInt(raw['members'] ?? raw['memberCount']),
      'maxMembers': _toInt(raw['maxMembers']) == 0
          ? 500
          : _toInt(raw['maxMembers']),
      'level': _toInt(raw['level']) == 0 ? 1 : _toInt(raw['level']),
      'leader':
          raw['leader']?.toString() ??
          raw['creatorName']?.toString() ??
          raw['creatorId']?.toString() ??
          '',
      'description': raw['description']?.toString() ?? '',
      'announcement': raw['announcement']?.toString() ?? '',
      'createdDate': raw['createdAt']?.toString() ?? '',
      'xp': _toInt(raw['xp']),
      'maxXp': _toInt(raw['maxXp']) == 0 ? 1000 : _toInt(raw['maxXp']),
      'role': raw['role']?.toString() ?? '',
    };
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
