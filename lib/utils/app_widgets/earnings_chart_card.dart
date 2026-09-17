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

/// Light glossy earnings card — AppLightUi dating chrome (not dark navy).
class EarningsChartCard extends StatelessWidget {
  const EarningsChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.points,
    this.icon = Icons.analytics_rounded,
  });

  final String title;
  final String subtitle;
  final String totalLabel;
  final List<EarningsChartPoint> points;
  final IconData icon;

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppLightUi.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppLightUi.familyCtaGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: kColorWhite, size: 22),
              ),
              Spacing.h12,
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
                      color: AppLightUi.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppLightUi.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppLightUi.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: SemiBoldText(
                  text: totalLabel,
                  fontSize: TextStyles.k16FontSize,
                  color: const Color(0xFFB8860B),
                ),
              ),
            ],
          ),
          Spacing.v(14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppLightUi.cardSoft,
              border: Border.all(color: AppLightUi.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < sanitized.length; i++) ...[
                  _ChartBarRow(
                    point: sanitized[i],
                    maxValue: maxValue,
                    total: total,
                  ),
                  if (i != sanitized.length - 1) Spacing.v12,
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
  });

  final EarningsChartPoint point;
  final double maxValue;
  final double total;

  @override
  Widget build(BuildContext context) {
    final value = point.value.toDouble();
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    final percent = total <= 0 ? 0 : ((value / total) * 100).round();

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
                height: 10,
                color: AppLightUi.border.withValues(alpha: 0.85),
              ),
              FractionallySizedBox(
                widthFactor: math.max(fraction, value > 0 ? 0.08 : 0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        point.color.withValues(alpha: 0.85),
                        point.color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: point.color.withValues(alpha: 0.28),
                        blurRadius: 8,
                      ),
                    ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppLightUi.violet.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppLightUi.violet,
              size: 22,
            ),
          ),
          Spacing.v10,
          const AppText(
            text: 'No earnings data yet',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
