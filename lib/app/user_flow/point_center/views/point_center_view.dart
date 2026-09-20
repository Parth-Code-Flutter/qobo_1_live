import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/point_center_controller.dart';

class PointCenterView extends GetView<PointCenterController> {
  const PointCenterView({super.key});

  static const _frequencies = [
    ('DAILY', 'Daily'),
    ('WEEKLY', 'Weekly'),
    ('MONTHLY', 'Monthly'),
    ('ONE_TIME', 'Once'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _frequencies.length,
      child: Scaffold(
        backgroundColor: kColorLavenderBg,
        appBar: const CommonAppBarWidget(
          title: 'Task Targets',
          subtitle: 'Complete targets and earn bonus coins',
          trailingIcon: Icons.assignment_turned_in_rounded,
        ),
        body: Column(
          children: [
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
    );
  }

  Widget _balanceCard() {
    return Obx(
      () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppLightUi.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppLightUi.border),
          boxShadow: AppLightUi.cardShadow,
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
              color: AppLightUi.border,
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
                color: AppLightUi.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SemiBoldText(
                text: value,
                fontSize: TextStyles.k16FontSize,
                color: AppLightUi.title,
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
        color: AppLightUi.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppLightUi.border),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2E83), Color(0xFF865DFF)],
          ),
        ),
        labelColor: kColorWhite,
        unselectedLabelColor: AppLightUi.subtitle,
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
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
            children: [_emptyState(frequency)],
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
        color: AppLightUi.card,
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
                      color: AppLightUi.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    AppText(
                      text: task['description']?.toString() ?? '',
                      fontSize: 11,
                      color: AppLightUi.subtitle,
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
                  color: AppLightUi.body,
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
              backgroundColor: AppLightUi.border.withValues(alpha: 0.55),
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
              _actionButton(
                claimed: claimed,
                completed: completed,
                onClaim: () {
                  final taskIndex = controller.tasks.indexWhere(
                    (item) => item['id'] == task['id'],
                  );
                  if (taskIndex >= 0) {
                    controller.claimPoints(taskIndex);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required bool claimed,
    required bool completed,
    required VoidCallback onClaim,
  }) {
    final canClaim = completed && !claimed;
    final label = claimed
        ? 'Claimed'
        : completed
        ? 'Claim'
        : 'Pending';

    // Pending / Claimed stay soft solid (readable). Only Claim uses CTA gradient.
    if (!canClaim) {
      final isPending = !completed;
      return Container(
        height: 36,
        width: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPending
              ? const Color(0xFFFFF6E8)
              : AppLightUi.cardSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPending
                ? const Color(0xFFFFCF5D).withValues(alpha: 0.55)
                : AppLightUi.border,
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: isPending
              ? const Color(0xFFB86A00)
              : AppLightUi.muted,
        ),
      );
    }

    return SizedBox(
      height: 36,
      width: 96,
      child: appButton(
        onPressed: onClaim,
        buttonText: label,
        buttonHeight: 36,
        buttonWidth: 96,
        borderRadius: 18,
        isGradient: true,
        textStyle: TextStyles.kSemiBoldPoppins(
          fontSize: 11,
          colors: kColorWhite,
        ),
      ),
    );
  }

  Widget _emptyState(String frequency) {
    final config = _emptyConfig(frequency);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        decoration: BoxDecoration(
          color: AppLightUi.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppLightUi.border),
          boxShadow: AppLightUi.cardShadow,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppLightUi.card,
              config.accent.withValues(alpha: 0.08),
              AppLightUi.card,
            ],
          ),
        ),
        child: Column(
          children: [
            DatingEmptyHero(
              style: config.heroStyle,
              size: 156,
              accentColors: [config.accent, config.accentEnd],
            ),
            Spacing.v12,
            SemiBoldText(
              text: config.title,
              fontSize: TextStyles.k16FontSize,
              color: AppLightUi.title,
              align: TextAlign.center,
            ),
            Spacing.v8,
            AppText(
              text: config.subtitle,
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.subtitle,
              align: TextAlign.center,
            ),
            Spacing.v10,
            AppText(
              text: 'Pull down to refresh',
              fontSize: TextStyles.k10FontSize,
              color: AppLightUi.muted,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  _TaskEmptyConfig _emptyConfig(String frequency) {
    switch (frequency) {
      case 'WEEKLY':
        return const _TaskEmptyConfig(
          title: 'No weekly targets',
          subtitle: 'Weekly goals from admin will show up here.',
          accent: Color(0xFF42E8E0),
          accentEnd: Color(0xFF7C9CFF),
          heroStyle: DatingEmptyHeroStyle.sparks,
        );
      case 'MONTHLY':
        return const _TaskEmptyConfig(
          title: 'No monthly targets',
          subtitle: 'Big monthly challenges will appear in this tab.',
          accent: Color(0xFF865DFF),
          accentEnd: Color(0xFFFF2E83),
          heroStyle: DatingEmptyHeroStyle.agency,
        );
      case 'ONE_TIME':
        return const _TaskEmptyConfig(
          title: 'No special targets',
          subtitle: 'Special once-only bonuses will land here.',
          accent: Color(0xFFFFCF5D),
          accentEnd: Color(0xFFFF8A48),
          heroStyle: DatingEmptyHeroStyle.host,
        );
      case 'DAILY':
      default:
        return const _TaskEmptyConfig(
          title: 'No daily targets',
          subtitle: 'Fresh daily targets from admin will appear here.',
          accent: Color(0xFFFF2E83),
          accentEnd: Color(0xFFFFCF5D),
          heroStyle: DatingEmptyHeroStyle.live,
        );
    }
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
        color: AppLightUi.cardSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppLightUi.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppLightUi.cyan),
          const SizedBox(width: 5),
          AppText(
            text: text,
            fontSize: TextStyles.k10FontSize,
            color: AppLightUi.body,
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

class _TaskEmptyConfig {
  const _TaskEmptyConfig({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.accentEnd,
    required this.heroStyle,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Color accentEnd;
  final DatingEmptyHeroStyle heroStyle;
}
