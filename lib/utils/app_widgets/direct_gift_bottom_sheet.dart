import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/gift_icon_widget.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';

/// Standalone gift picker (not tied to LiveBroadcastController).
///
/// Family gifts: `roomId` = familyId, `sessionType` / `scope` = `family`
/// per backend Family API walkthrough.
class DirectGiftBottomSheet extends StatefulWidget {
  const DirectGiftBottomSheet({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.roomId,
    this.sessionType = 'family',
  });

  final String receiverId;
  final String receiverName;
  final String roomId;
  final String sessionType;

  static Future<bool?> show({
    required String receiverId,
    required String receiverName,
    required String roomId,
    String sessionType = 'family',
  }) {
    return Get.bottomSheet<bool>(
      DirectGiftBottomSheet(
        receiverId: receiverId,
        receiverName: receiverName,
        roomId: roomId,
        sessionType: sessionType,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  State<DirectGiftBottomSheet> createState() => _DirectGiftBottomSheetState();
}

class _DirectGiftBottomSheetState extends State<DirectGiftBottomSheet> {
  final _economyRepo = EconomyRepo();
  final _gifts = <Map<String, String>>[].obs;
  final _loading = true.obs;
  final _sending = false.obs;
  final _coins = 0.obs;
  var _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _loading.value = true;
    try {
      final wallet = await _economyRepo.getWalletBalances(isShowLoader: false);
      final walletData = wallet?['data'];
      if (isEconomyApiSuccess(wallet) && walletData is Map) {
        _coins.value = parseWalletAmount(
          walletData['coins'] ??
              walletData['coin'] ??
              walletData['balance'] ??
              walletData['coinBalance'],
        );
      }

      final response = await _economyRepo.getGiftList(isShowLoader: false);
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is List) {
        _gifts.assignAll(
          data
              .whereType<Map>()
              .map(
                (raw) =>
                    GiftMediaUtils.mapGiftFromApi(Map<String, dynamic>.from(raw)),
              )
              .where((gift) => (gift['id'] ?? '').isNotEmpty)
              .toList(),
        );
      }
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _send() async {
    if (_selectedIndex < 0 || _selectedIndex >= _gifts.length) return;
    final gift = _gifts[_selectedIndex];
    final giftId = gift['id']?.trim() ?? '';
    if (giftId.isEmpty ||
        widget.receiverId.isEmpty ||
        widget.roomId.isEmpty) {
      Get.snackbar(
        'Gift not sent',
        'Gift, receiver, or family room context is missing.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final price = int.tryParse(gift['price'] ?? '0') ?? 0;
    if (_coins.value < price) {
      Get.snackbar(
        'Insufficient Coins',
        'You need ${formatLedgerAmount(price - _coins.value)} more coins.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _sending.value = true;
    try {
      final isFamily = widget.sessionType.trim().toLowerCase() == 'family';
      final response = await _economyRepo.sendGift(
        receiverId: widget.receiverId,
        giftId: giftId,
        roomId: widget.roomId,
        scope: isFamily ? 'family' : 'user',
        sessionType: widget.sessionType,
        isShowLoader: false,
      );
      if (!isEconomyApiSuccess(response)) {
        Get.snackbar(
          'Gift not sent',
          response?['message']?.toString() ??
              'Could not send gift. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final data = response?['data'];
      if (data is Map && data['coinsBalance'] != null) {
        _coins.value = parseWalletAmount(data['coinsBalance']);
      } else {
        _coins.value = (_coins.value - price).clamp(0, 1 << 30);
      }

      final animationUrl = GiftMediaUtils.animationUrlFromResponse(
        response,
        gift,
      );
      final soundUrl = GiftMediaUtils.soundUrlFromResponse(response, gift);

      // Same flow as live rooms / 1:1 calls: close sheet, then SVGA celebration.
      await GiftMediaUtils.dismissSheetThenCelebrate(
        giftName: gift['name'],
        animationUrl: animationUrl,
        soundUrl: soundUrl,
      );
    } finally {
      _sending.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.52,
      decoration: const BoxDecoration(
        color: Color(0xFF171321),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Spacing.v12,
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Spacing.v12,
            SemiBoldText(
              text: 'Gift ${widget.receiverName}',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            Spacing.v4,
            AppText(
              text: 'Pick a gift to send',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.65),
            ),
            Expanded(
              child: Obx(() {
                if (_loading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: kColorPrimary),
                  );
                }
                if (_gifts.isEmpty) {
                  return Center(
                    child: AppText(
                      text: 'No gifts available right now.',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite.withValues(alpha: 0.65),
                      align: TextAlign.center,
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: _gifts.length,
                  itemBuilder: (context, index) {
                    final gift = _gifts[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: selected
                              ? kColorPrimary.withValues(alpha: 0.24)
                              : kColorWhite.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? kColorPrimary
                                : kColorWhite.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GiftIconWidget(icon: gift['icon'], size: 30),
                            Spacing.v4,
                            AppText(
                              text: gift['name'] ?? 'Gift',
                              fontSize: 9,
                              color: kColorWhite,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              align: TextAlign.center,
                            ),
                            Spacing.v2,
                            AppText(
                              text: gift['price'] ?? '0',
                              fontSize: 9,
                              color: Colors.amber,
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
            Obx(
              () => Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  border: Border(
                    top: BorderSide(color: kColorWhite.withValues(alpha: 0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.diamond_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    Spacing.h6,
                    SemiBoldText(
                      text: formatLedgerAmount(_coins.value),
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      width: 104,
                      child: TextButton(
                        onPressed: !_sending.value &&
                                _selectedIndex >= 0 &&
                                _selectedIndex < _gifts.length
                            ? _send
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: kColorPrimary,
                          disabledBackgroundColor:
                              kColorWhite.withValues(alpha: 0.10),
                          foregroundColor: kColorWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _sending.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kColorWhite,
                                ),
                              )
                            : const SemiBoldText(
                                text: 'Send',
                                fontSize: 13,
                                color: kColorWhite,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
