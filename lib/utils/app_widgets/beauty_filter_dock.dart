import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

typedef BeautyFilterChange = void Function({
  int? smooth,
  int? skinTone,
  int? blush,
  int? sharpen,
});

/// Compact beauty controls. The camera stays visible above this bar.
class BeautyFilterDock extends StatefulWidget {
  const BeautyFilterDock({
    super.key,
    required this.enabled,
    required this.smooth,
    required this.skinTone,
    required this.blush,
    required this.sharpen,
    required this.onEnabled,
    required this.onChanged,
    required this.onReset,
  });

  final bool enabled;
  final int smooth;
  final int skinTone;
  final int blush;
  final int sharpen;
  final ValueChanged<bool> onEnabled;
  final BeautyFilterChange onChanged;
  final VoidCallback onReset;

  @override
  State<BeautyFilterDock> createState() => _BeautyFilterDockState();
}

enum _BeautyKnob { smooth, skin, blush, sharpen }

class _BeautyFilterDockState extends State<BeautyFilterDock> {
  static const Color _accent = Color(0xFFE12BC5);

  _BeautyKnob _knob = _BeautyKnob.smooth;

  int get _value {
    switch (_knob) {
      case _BeautyKnob.smooth:
        return widget.smooth;
      case _BeautyKnob.skin:
        return widget.skinTone;
      case _BeautyKnob.blush:
        return widget.blush;
      case _BeautyKnob.sharpen:
        return widget.sharpen;
    }
  }

  String get _label {
    switch (_knob) {
      case _BeautyKnob.smooth:
        return 'Smooth';
      case _BeautyKnob.skin:
        return 'Skin tone';
      case _BeautyKnob.blush:
        return 'Blush';
      case _BeautyKnob.sharpen:
        return 'Sharpen';
    }
  }

  void _setValue(double raw) {
    final value = raw.round().clamp(0, 100);
    switch (_knob) {
      case _BeautyKnob.smooth:
        widget.onChanged(smooth: value);
      case _BeautyKnob.skin:
        widget.onChanged(skinTone: value);
      case _BeautyKnob.blush:
        widget.onChanged(blush: value);
      case _BeautyKnob.sharpen:
        widget.onChanged(sharpen: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF140818).withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(color: kColorWhite.withValues(alpha: 0.14)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _handle(),
                  const SizedBox(height: 10),
                  _header(),
                  _slider(),
                  const SizedBox(height: 4),
                  _chips(),
                  const SizedBox(height: 6),
                  _actions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _handle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: SemiBoldText(
            text: _label,
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppText(
          text: '$_value',
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        const SizedBox(width: 8),
        Switch(
          value: widget.enabled,
          activeThumbColor: kColorWhite,
          activeTrackColor: _accent,
          inactiveThumbColor: kColorWhite,
          inactiveTrackColor: Colors.white24,
          onChanged: widget.onEnabled,
        ),
      ],
    );
  }

  Widget _slider() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: _accent,
        inactiveTrackColor: kColorWhite.withValues(alpha: 0.16),
        thumbColor: kColorWhite,
        overlayColor: _accent.withValues(alpha: 0.18),
        trackHeight: 4,
      ),
      child: Slider(
        value: _value.clamp(0, 100).toDouble(),
        min: 0,
        max: 100,
        onChanged: _setValue,
      ),
    );
  }

  Widget _chips() {
    return Row(
      children: [
        _chip(_BeautyKnob.smooth, Icons.blur_on_rounded, 'Smooth'),
        _chip(_BeautyKnob.skin, Icons.wb_sunny_outlined, 'Skin'),
        _chip(_BeautyKnob.blush, Icons.favorite_border_rounded, 'Blush'),
        _chip(_BeautyKnob.sharpen, Icons.high_quality_rounded, 'Sharp'),
      ],
    );
  }

  Widget _chip(_BeautyKnob knob, IconData icon, String label) {
    final selected = _knob == knob;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _knob = knob),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF6AE0), Color(0xFFE12BC5)],
                      )
                    : null,
                color: selected ? null : kColorWhite.withValues(alpha: 0.10),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: kColorWhite, size: 22),
            ),
            const SizedBox(height: 6),
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k10FontSize,
              color: selected ? kColorWhite : kColorWhite.withValues(alpha: 0.62),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: widget.onReset,
            style: TextButton.styleFrom(
              foregroundColor: kColorWhite,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const SemiBoldText(
              text: 'Reset',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextButton(
            onPressed: Get.back,
            style: TextButton.styleFrom(
              foregroundColor: kColorWhite,
              backgroundColor: _accent,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const SemiBoldText(
              text: 'Done',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ),
        ),
      ],
    );
  }
}
