import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/pk_battle/controllers/pk_v1_history_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class PkV1HistoryView extends GetView<PkV1HistoryController> {
  const PkV1HistoryView({super.key});

  static const _pkGold = Color(0xFFFFC857);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150421),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kColorWhite),
        title: SemiBoldText(
          text: 'PK History',
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _pkGold));
        }
        if (controller.items.isEmpty) {
          return Center(
            child: AppText(
              text: 'No PK battles yet.',
              color: kColorWhite.withValues(alpha: 0.6),
            ),
          );
        }
        return RefreshIndicator(
          color: _pkGold,
          onRefresh: controller.loadHistory,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _historyCard(controller.items[i]),
          ),
        );
      }),
    );
  }

  Widget _historyCard(PkHistoryItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          AppUserAvatar(
            name: item.opponentName.isEmpty ? 'Host' : item.opponentName,
            imageUrl: item.opponentAvatar,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: item.opponentName.isEmpty
                      ? 'Opponent'
                      : item.opponentName,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AppText(
                  text:
                      '${item.scoreA} - ${item.scoreB}${item.dateLabel.isNotEmpty ? '  •  ${item.dateLabel}' : ''}',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
          _resultTag(item.outcome.isNotEmpty ? item.outcome : item.winnerSide),
        ],
      ),
    );
  }

  Widget _resultTag(String winnerSide) {
    Color color;
    String label;
    switch (winnerSide) {
      case 'TIE':
        color = _pkGold;
        label = 'TIE';
        break;
      case 'WIN':
      case 'WON':
      case 'A':
        color = const Color(0xFF2ED47A);
        label = 'WON';
        break;
      case 'LOSE':
      case 'LOST':
      case 'B':
        color = const Color(0xFFFF3B5C);
        label = 'LOST';
        break;
      default:
        color = Colors.white54;
        label = winnerSide.isEmpty ? '—' : winnerSide;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: BoldText(text: label, fontSize: TextStyles.k12FontSize, color: color),
    );
  }
}
