import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/point_center_controller.dart';

class PointCenterView extends GetView<PointCenterController> {
  const PointCenterView({super.key});

  static const _frequencies = [
    ('DAILY', 'Daily'),
    ('WEEKLY', 'Weekly'),
    ('MONTHLY', 'Monthly'),
    ('ONE_TIME', 'One-time'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _frequencies.length,
      child: Scaffold(
        backgroundColor: const Color(0xFF090516),
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
                const Color(0xFFFF2E83).withValues(alpha: 0.20),
                const Color(0xFF090516),
                const Color(0xFF10091D),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(),
                _balanceCard(),
                const SizedBox(height: 14),
                _tabs(),
                Expanded(
                  child: TabBarView(
                    children: _frequencies
                        .map((item) => _tasksList(item.$1))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kColorWhite,
                size: 20,
              ),
            ),
          ),
          Spacing.h12,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: 'Task Targets',
                  fontSize: TextStyles.k22FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Complete targets and earn bonus coins',
                  fontSize: TextStyles.k12FontSize,
                  color: Color(0xB8FFFFFF),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFCF5D), Color(0xFFFF8A48)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.26),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: kColorWhite,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _balanceItem(
                icon: const AppCoinIcon(size: 26, color: Color(0xFFFFCF5D)),
                label: 'Coins Balance',
                value: _formatNumber(controller.coinsBalance.value),
                accent: const Color(0xFFFFCF5D),
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: kColorWhite.withValues(alpha: 0.08),
            ),
            Expanded(
              child: _balanceItem(
                icon: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF42E8E0),
                  size: 28,
                ),
                label: 'Points Balance',
                value: _formatNumber(controller.pointsBalance.value),
                accent: const Color(0xFF42E8E0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceItem({
    required Widget icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.24)),
          ),
          child: Center(child: icon),
        ),
        Spacing.h10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: label,
                fontSize: 11,
                color: kColorWhite.withValues(alpha: 0.60),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SemiBoldText(
                text: value,
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2E83), Color(0xFF865DFF)],
          ),
        ),
        labelColor: kColorWhite,
        unselectedLabelColor: kColorWhite.withValues(alpha: 0.58),
        labelStyle: TextStyles.kSemiBoldPoppins(fontSize: 11),
        unselectedLabelStyle: TextStyles.kSemiBoldPoppins(fontSize: 11),
        tabs: _frequencies.map((item) => Tab(text: item.$2)).toList(),
      ),
    );
  }

  Widget _tasksList(String frequency) {
    return Obx(() {
      if (controller.isLoading.value && controller.tasks.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2E83)),
        );
      }
      final tasks = controller.tasksForFrequency(frequency);
      if (tasks.isEmpty) {
        return RefreshIndicator(
          color: const Color(0xFFFF2E83),
          onRefresh: controller.fetchTasks,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 84, 20, 24),
            children: [
              const Icon(
                Icons.flag_circle_rounded,
                color: Color(0xFFFFCF5D),
                size: 58,
              ),
              Spacing.v12,
              const SemiBoldText(
                text: 'No targets found',
                fontSize: TextStyles.k16FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              Spacing.v6,
              AppText(
                text: 'Targets assigned by admin will appear here.',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.62),
                align: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: const Color(0xFFFF2E83),
        onRefresh: controller.fetchTasks,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => Spacing.v12,
          itemBuilder: (_, index) => _taskCard(tasks[index]),
        ),
      );
    });
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final ratio = (task['progressRatio'] as double? ?? 0).clamp(0.0, 1.0);
    final completed = task['isCompleted'] == true;
    final claimed = task['isClaimed'] == true;
    final rewardType = task['rewardType']?.toString().toLowerCase() ?? 'coins';
    final accent = completed
        ? const Color(0xFF25D98F)
        : const Color(0xFFFFCF5D);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: completed
                        ? const [Color(0xFF25D98F), Color(0xFF42E8E0)]
                        : const [Color(0xFFFFCF5D), Color(0xFFFF8A48)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _metricIcon(task['targetMetric']?.toString()),
                  color: kColorWhite,
                  size: 24,
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: task['title']?.toString() ?? 'Target Task',
                      fontSize: 15,
                      color: kColorWhite,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    AppText(
                      text: task['description']?.toString() ?? '',
                      fontSize: 11,
                      color: kColorWhite.withValues(alpha: 0.64),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Spacing.h10,
              _statusBadge(completed: completed, claimed: claimed),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoPill(_label(task['targetCategory']), Icons.person_rounded),
              _infoPill(_label(task['roomType']), Icons.live_tv_rounded),
              _infoPill(_label(task['targetMetric']), Icons.track_changes),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppText(
                  text:
                      '${_formatTarget(task['progressValue'])} / ${_formatTarget(task['targetValue'])} ${_unit(task['targetMetric'])}',
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite.withValues(alpha: 0.72),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SemiBoldText(
                text: '${(ratio * 100).round()}%',
                fontSize: TextStyles.k12FontSize,
                color: accent,
              ),
            ],
          ),
          Spacing.v8,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: kColorWhite.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (rewardType == 'coins')
                      const AppCoinIcon(size: 17, color: Color(0xFFFFCF5D))
                    else
                      const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFFFCF5D),
                        size: 18,
                      ),
                    Spacing.h6,
                    SemiBoldText(
                      text: '+${task['reward']} ${_label(rewardType)}',
                      fontSize: 13,
                      color: const Color(0xFFFFCF5D),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                width: 92,
                child: appButton(
                  onPressed: completed && !claimed
                      ? () {
                          final taskIndex = controller.tasks.indexWhere(
                            (item) => item['id'] == task['id'],
                          );
                          if (taskIndex >= 0) {
                            controller.claimPoints(taskIndex);
                          }
                        }
                      : () {},
                  buttonText: claimed
                      ? 'Claimed'
                      : completed
                      ? 'Claim'
                      : 'Pending',
                  buttonColor: claimed
                      ? kColorWhite.withValues(alpha: 0.10)
                      : completed
                      ? const Color(0xFFFF2E83)
                      : kColorWhite.withValues(alpha: 0.08),
                  borderRadius: 18,
                  textStyle: TextStyles.kSemiBoldPoppins(
                    fontSize: 11,
                    colors: claimed || !completed
                        ? kColorWhite.withValues(alpha: 0.64)
                        : kColorWhite,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge({required bool completed, required bool claimed}) {
    final text = claimed
        ? 'Claimed'
        : completed
        ? 'Done'
        : 'Active';
    final color = claimed || completed
        ? const Color(0xFF25D98F)
        : const Color(0xFFFFCF5D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: AppText(
        text: text,
        fontSize: TextStyles.k10FontSize,
        color: color,
      ),
    );
  }

  Widget _infoPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF42E8E0)),
          const SizedBox(width: 5),
          AppText(
            text: text,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.78),
          ),
        ],
      ),
    );
  }

  IconData _metricIcon(String? metric) {
    final value = metric?.toUpperCase() ?? '';
    if (value.contains('DURATION')) return Icons.timer_rounded;
    if (value.contains('SESSION')) return Icons.video_camera_front_rounded;
    if (value.contains('COIN')) return Icons.monetization_on_rounded;
    return Icons.flag_rounded;
  }

  String _unit(dynamic metric) {
    final value = metric?.toString().toUpperCase() ?? '';
    if (value.contains('DURATION')) return 'mins';
    if (value.contains('SESSION')) return 'sessions';
    if (value.contains('COIN')) return 'coins';
    return '';
  }

  String _label(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '-';
    return text
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatNumber(num value) {
    final rounded = value.round();
    return rounded.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _formatTarget(dynamic value) {
    final number = value is num
        ? value
        : num.tryParse(value?.toString() ?? '') ?? 0;
    if (number % 1 == 0) return _formatNumber(number);
    return number.toStringAsFixed(1);
  }
}
