import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/widgets/coin_seller_ui_kit.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

/// Searchable user list for choosing a coins-seller buyer.
class CoinSellerBuyerPickerSheet extends StatefulWidget {
  const CoinSellerBuyerPickerSheet({super.key, this.selectedUserId});

  final String? selectedUserId;

  static Future<SocialUserCard?> show({String? selectedUserId}) {
    return Get.bottomSheet<SocialUserCard>(
      CoinSellerBuyerPickerSheet(selectedUserId: selectedUserId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<CoinSellerBuyerPickerSheet> createState() =>
      _CoinSellerBuyerPickerSheetState();
}

class _CoinSellerBuyerPickerSheetState
    extends State<CoinSellerBuyerPickerSheet> {
  final _authRepo = AuthRepo();
  final _userRepo = UserRepo();
  final _searchController = TextEditingController();

  final _users = <SocialUserCard>[].obs;
  final _isLoading = true.obs;
  final _isSearching = false.obs;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadSuggestedUsers());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String get _myUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId.trim();
  }

  Future<void> _loadSuggestedUsers() async {
    _isLoading.value = true;
    try {
      final friends = await _userRepo.getFriends(page: 1, limit: 40);
      var list = <SocialUserCard>[];
      if (isSocialApiSuccess(friends)) {
        list = SocialUserCard.listFromResponseData(friends?['data']);
      }
      if (list.isEmpty) {
        final followers = await _userRepo.getFollowers(page: 1, limit: 40);
        if (isSocialApiSuccess(followers)) {
          list = SocialUserCard.listFromResponseData(followers?['data']);
        }
      }
      if (list.isEmpty) {
        final following = await _userRepo.getFollowing(page: 1, limit: 40);
        if (isSocialApiSuccess(following)) {
          list = SocialUserCard.listFromResponseData(following?['data']);
        }
      }
      _users.assignAll(_withoutSelf(list));
    } finally {
      _isLoading.value = false;
    }
  }

  List<SocialUserCard> _withoutSelf(List<SocialUserCard> list) {
    final me = _myUserId;
    if (me.isEmpty) return list;
    return list.where((u) => u.id != me).toList();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_runSearch(value.trim()));
    });
  }

  Future<void> _runSearch(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;

    if (query.isEmpty) {
      await _loadSuggestedUsers();
      return;
    }
    if (query.length < 2) return;

    _isSearching.value = true;
    try {
      final response = await _authRepo.searchUsers(
        query: query,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        _users.assignAll(
          _withoutSelf(SocialUserCard.listFromResponseData(response?['data'])),
        );
      } else {
        _users.clear();
      }
    } finally {
      _isSearching.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1638), Color(0xFF120A1E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Spacing.v10,
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v12,
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SemiBoldText(
                  text: 'Select buyer',
                  fontSize: 17,
                  color: kColorWhite,
                ),
              ),
            ),
            Spacing.v4,
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  text: 'Search by name, or pick from friends / followers',
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
            ),
            Spacing.v12,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: kColorWhite, fontSize: 14),
                onChanged: _onSearchChanged,
                onSubmitted: (v) => unawaited(_runSearch(v.trim())),
                decoration: InputDecoration(
                  hintText: 'Search users…',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  suffixIcon: Obx(
                    () => _isSearching.value
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CoinSellerUi.gold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Spacing.v10,
            Expanded(
              child: Obx(() {
                if (_isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: CoinSellerUi.gold),
                  );
                }
                if (_users.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: AppText(
                        text:
                            'No users found. Try searching by name or phone.',
                        fontSize: 12,
                        color: Colors.white54,
                        align: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => Spacing.v8,
                  itemBuilder: (_, index) {
                    final user = _users[index];
                    final selected = widget.selectedUserId == user.id;
                    return _BuyerTile(
                      user: user,
                      selected: selected,
                      onTap: () => Get.back(result: user),
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

class _BuyerTile extends StatelessWidget {
  const _BuyerTile({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  final SocialUserCard user;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? CoinSellerUi.gold.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? CoinSellerUi.gold.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              AppUserAvatar(
                name: user.name,
                imageUrl: user.displayPicture,
                size: 44,
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: user.name,
                      fontSize: 13,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v2,
                    AppText(
                      text: user.id,
                      fontSize: 10,
                      color: Colors.white38,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: CoinSellerUi.gold,
                  size: 22,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
