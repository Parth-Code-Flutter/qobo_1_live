import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

class EarningsChartPoint {
  const EarningsChartPoint({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final num value;
  final Color color;
}

/// Compact light earnings card — dense bars, readable contrast.
class EarningsChartCard extends StatelessWidget {
  const EarningsChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.points,
    this.icon = Icons.analytics_rounded,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String totalLabel;
  final List<EarningsChartPoint> points;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sanitized = points.where((p) => p.value >= 0).toList();
    final maxValue = sanitized.isEmpty
        ? 1.0
        : math.max(
            1.0,
            sanitized.map((p) => p.value.toDouble()).reduce(math.max),
          );
    final total = sanitized.fold<double>(
      0,
      (sum, point) => sum + point.value.toDouble(),
    );
    final pad = compact ? 12.0 : 16.0;
    final iconSize = compact ? 34.0 : 42.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: AppLightUi.cardDecoration(radius: compact ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 11 : 14),
                  gradient: AppLightUi.familyCtaGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: kColorWhite, size: compact ? 18 : 22),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: title,
                      fontSize: TextStyles.k14FontSize,
                      color: AppLightUi.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.v2,
                    AppText(
                      text: subtitle,
                      fontSize: TextStyles.k10FontSize,
                      color: AppLightUi.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: AppLightUi.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppLightUi.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: SemiBoldText(
                  text: totalLabel,
                  fontSize: compact
                      ? TextStyles.k14FontSize
                      : TextStyles.k16FontSize,
                  color: const Color(0xFF9A6B00),
                ),
              ),
            ],
          ),
          Spacing.v(compact ? 10 : 14),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 8 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 14 : 20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppLightUi.cardSoft,
                  AppLightUi.violet.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: AppLightUi.borderStrong),
            ),
            child: Column(
              children: [
                for (var i = 0; i < sanitized.length; i++) ...[
                  _ChartBarRow(
                    point: sanitized[i],
                    maxValue: maxValue,
                    total: total,
                    compact: compact,
                  ),
                  if (i != sanitized.length - 1)
                    Spacing.v(compact ? 8 : 12),
                ],
                if (sanitized.isEmpty) const _EmptyChartState(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBarRow extends StatelessWidget {
  const _ChartBarRow({
    required this.point,
    required this.maxValue,
    required this.total,
    this.compact = false,
  });

  final EarningsChartPoint point;
  final double maxValue;
  final double total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final value = point.value.toDouble();
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    final percent = total <= 0 ? 0 : ((value / total) * 100).round();
    final barH = compact ? 6.0 : 10.0;

    if (compact) {
      // Single dense row: label · bar · value%
      return Row(
        children: [
          SizedBox(
            width: 52,
            child: SemiBoldText(
              text: point.label,
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Spacing.h8,
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(height: barH, color: AppLightUi.borderStrong),
                  FractionallySizedBox(
                    widthFactor: math.max(fraction, value > 0 ? 0.06 : 0),
                    child: Container(
                      height: barH,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            point.color.withValues(alpha: 0.75),
                            point.color,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Spacing.h8,
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SemiBoldText(
                  text: _formatValue(point.value),
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.title,
                ),
                AppText(
                  text: '$percent%',
                  fontSize: TextStyles.k8FontSize,
                  color: point.color,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: point.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: point.color.withValues(alpha: 0.35)),
              ),
              child: Icon(Icons.circle, size: 8, color: point.color),
            ),
            Spacing.h10,
            Expanded(
              child: SemiBoldText(
                text: point.label,
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Spacing.h8,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SemiBoldText(
                  text: _formatValue(point.value),
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.title,
                ),
                AppText(
                  text: '$percent%',
                  fontSize: TextStyles.k10FontSize,
                  color: point.color,
                ),
              ],
            ),
          ],
        ),
        Spacing.v8,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                height: barH,
                color: AppLightUi.border.withValues(alpha: 0.85),
              ),
              FractionallySizedBox(
                widthFactor: math.max(fraction, value > 0 ? 0.08 : 0),
                child: Container(
                  height: barH,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        point.color.withValues(alpha: 0.85),
                        point.color,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatValue(num value) {
    final rounded = value.round();
    if (rounded >= 1000000) {
      final compact = rounded / 1000000;
      return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}M';
    }
    if (rounded >= 1000) {
      final compact = rounded / 1000;
      return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}K';
    }
    return '$rounded';
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            color: AppLightUi.violet.withValues(alpha: 0.7),
            size: 28,
          ),
          Spacing.v8,
          const AppText(
            text: 'No earnings data yet',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.body,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
