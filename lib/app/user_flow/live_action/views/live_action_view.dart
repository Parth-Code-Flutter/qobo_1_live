import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/live_action_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_search_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_action_controller.dart';

/// Figma-style live discovery map shown from the center heart tab.
class LiveActionView extends GetView<LiveActionController> {
  const LiveActionView({super.key});

  static const _mapUsers = <_MapUser>[
    _MapUser('Afrin Sabila', 'LV.10', kImgTemp2, Alignment(-0.68, -0.82)),
    _MapUser('Afrin Sabila', 'LV.08', kImgTemp3, Alignment(0.54, -0.84)),
    _MapUser('Afrin Sabila', 'LV.09', kImgTemp4, Alignment(-0.10, -0.42)),
    _MapUser('Afrin Sabila', 'LV.12', kImgTemp5, Alignment(0.62, -0.30)),
    _MapUser('Afrin Sabila', 'LV.07', kImgTemp3, Alignment(-0.78, 0.10)),
    _MapUser('Afrin Sabila', 'LV.14', kImgTemp2, Alignment(0.10, 0.10)),
    _MapUser('Afrin Sabila', 'LV.11', kImgTemp4, Alignment(0.56, 0.46)),
    _MapUser('Afrin Sabila', 'LV.06', kImgTemp5, Alignment(0.08, 0.78)),
  ];

  static const _suggestions = <String>[
    kImgTemp2,
    kImgTemp3,
    kImgTemp4,
    kImgTemp5,
    kImgTemp2,
    kImgTemp3,
    kImgTemp4,
  ];

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LiveActionController>()) {
      Get.put(LiveActionController());
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF5C0A68).withValues(alpha: 0.52),
              const Color(0xFF170D59).withValues(alpha: 0.72),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(context),
              Expanded(child: _mapStage()),
              _suggestionStrip(context),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 94),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _squareButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: controller.onBackPressed,
          ),
          Spacing.h10,
          Expanded(
            child: AppSearchField(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
          ),
          Spacing.h10,
          _squareButton(icon: Icons.tune_rounded, onTap: () {}),
        ],
      ),
    );
  }

  Widget _squareButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0x661B0F36),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: kColorWhite, size: 19),
        ),
      ),
    );
  }

  Widget _mapStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LiveMapPainter(
                  users: _mapUsers.map((user) => user.alignment).toList(),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.15, -0.05),
                    radius: 0.75,
                    colors: [
                      kColorWhite.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            for (final user in _mapUsers)
              Align(
                alignment: user.alignment,
                child: _MapUserNode(user: user),
              ),
          ],
        );
      },
    );
  }

  Widget _suggestionStrip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 148,
            height: 1,
            color: kColorWhite.withValues(alpha: 0.78),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: kColorWhite,
                size: 18,
              ),
              Spacing.h8,
              const SemiBoldText(
                text: 'Suggestion for you',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v10,
          Row(
            children: [
              for (final image in _suggestions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SuggestionAvatar(imageAsset: image),
                ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: kColorPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kColorPrimary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const SemiBoldText(
                  text: '+52',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapUserNode extends StatelessWidget {
  const _MapUserNode({required this.user});

  final _MapUser user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kColorWhite, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: kColorBlack.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(user.imageAsset, fit: BoxFit.cover),
            ),
          ),
          Spacing.v4,
          SemiBoldText(
            text: user.name,
            fontSize: 9,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            align: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF2D0D58).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LiveActionColors.diamondGold),
            ),
            child: SemiBoldText(
              text: user.level,
              fontSize: 7,
              color: LiveActionColors.diamondGold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionAvatar extends StatelessWidget {
  const _SuggestionAvatar({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kColorWhite.withValues(alpha: 0.85)),
      ),
      child: ClipOval(child: Image.asset(imageAsset, fit: BoxFit.cover)),
    );
  }
}

class _LiveMapPainter extends CustomPainter {
  const _LiveMapPainter({required this.users});

  final List<Alignment> users;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kColorWhite.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final nodes = users.map((alignment) {
      return Offset(
        size.width * (alignment.x + 1) / 2,
        size.height * (alignment.y + 1) / 2,
      );
    }).toList();

    for (var i = 0; i < nodes.length - 1; i++) {
      final path = Path()
        ..moveTo(nodes[i].dx, nodes[i].dy)
        ..quadraticBezierTo(
          size.width * (i.isEven ? 0.24 : 0.76),
          (nodes[i].dy + nodes[i + 1].dy) / 2,
          nodes[i + 1].dx,
          nodes[i + 1].dy,
        );
      _drawDashedPath(canvas, path, paint);
    }

    final accent = Paint()
      ..color = const Color(0xFFB875FF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final node in nodes) {
      canvas.drawCircle(node, 18, accent);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 7.0;
      const gap = 6.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter oldDelegate) => false;
}

class _MapUser {
  const _MapUser(this.name, this.level, this.imageAsset, this.alignment);

  final String name;
  final String level;
  final String imageAsset;
  final Alignment alignment;
}
