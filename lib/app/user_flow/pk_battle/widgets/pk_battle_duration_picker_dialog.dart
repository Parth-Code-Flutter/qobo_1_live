import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Challenger picks PK battle length before the invite is sent.
///
/// Returns duration in **seconds**, or `null` if cancelled.
/// Presets: 2 / 5 / 10 minutes. Custom = digits-only minutes.
class PkBattleDurationPickerDialog extends StatefulWidget {
  const PkBattleDurationPickerDialog({
    super.key,
    this.opponentName,
  });

  final String? opponentName;

  /// Shows the picker. Returns seconds, or `null` if dismissed / cancel.
  static Future<int?> show({String? opponentName}) {
    return Get.dialog<int?>(
      PkBattleDurationPickerDialog(opponentName: opponentName),
      barrierDismissible: true,
    );
  }

  static const presetsMinutes = <int>[2, 5, 10];
  static const minCustomMinutes = 1;
  static const maxCustomMinutes = 30;
  static const defaultPresetMinutes = 5;

  @override
  State<PkBattleDurationPickerDialog> createState() =>
      _PkBattleDurationPickerDialogState();
}

class _PkBattleDurationPickerDialogState
    extends State<PkBattleDurationPickerDialog> {
  static const _pkGold = Color(0xFFFFC857);
  static const _pkRed = Color(0xFFFF3B5C);

  /// Selected preset minutes, or `null` when custom is selected.
  int? _presetMinutes = PkBattleDurationPickerDialog.defaultPresetMinutes;
  final _customController = TextEditingController();
  final _customFocus = FocusNode();

  bool get _isCustom => _presetMinutes == null;

  @override
  void dispose() {
    _customController.dispose();
    _customFocus.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    setState(() {
      _presetMinutes = minutes;
      _customController.clear();
      _customFocus.unfocus();
    });
  }

  void _selectCustom() {
    setState(() => _presetMinutes = null);
    _customFocus.requestFocus();
  }

  int? _resolveMinutes() {
    if (!_isCustom) return _presetMinutes;
    final raw = _customController.text.trim();
    if (raw.isEmpty) return null;
    final minutes = int.tryParse(raw);
    if (minutes == null) return null;
    if (minutes < PkBattleDurationPickerDialog.minCustomMinutes ||
        minutes > PkBattleDurationPickerDialog.maxCustomMinutes) {
      return null;
    }
    return minutes;
  }

  void _confirm() {
    final minutes = _resolveMinutes();
    if (minutes == null) {
      Get.snackbar(
        'PK Battle',
        _isCustom
            ? 'Enter ${PkBattleDurationPickerDialog.minCustomMinutes}–${PkBattleDurationPickerDialog.maxCustomMinutes} minutes (digits only).'
            : 'Select a battle duration.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.back(result: minutes * 60);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.opponentName?.trim();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0737), Color(0xFF3B0D2E)],
          ),
          border: Border.all(color: _pkGold.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _pkRed.withValues(alpha: 0.28),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(colors: [_pkGold, _pkRed]),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  BoldText(
                    text: 'BATTLE DURATION',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SemiBoldText(
              text: name != null && name.isNotEmpty
                  ? 'Challenge $name'
                  : 'Choose PK length',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            const SizedBox(height: 6),
            AppText(
              text: 'How long should this PK battle run?',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.75),
              align: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: PkBattleDurationPickerDialog.presetsMinutes
                  .map((m) => Expanded(child: _presetChip(m)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _customField(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: appButton(
                    onPressed: () => Get.back(result: null),
                    buttonText: 'Cancel',
                    buttonHeight: 48,
                    isGradient: false,
                    buttonColor: Colors.white.withValues(alpha: 0.10),
                    buttonBorderColor: Colors.white.withValues(alpha: 0.18),
                    borderRadius: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: appButton(
                    onPressed: _confirm,
                    buttonText: 'Send Challenge',
                    buttonHeight: 48,
                    isGradient: true,
                    gradientColors: const [_pkGold, _pkRed],
                    borderRadius: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(int minutes) {
    final selected = _presetMinutes == minutes;
    return Padding(
      padding: EdgeInsets.only(right: minutes == 10 ? 0 : 8),
      child: GestureDetector(
        onTap: () => _selectPreset(minutes),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(colors: [_pkGold, _pkRed])
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: SemiBoldText(
            text: '$minutes min',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
          ),
        ),
      ),
    );
  }

  Widget _customField() {
    final selected = _isCustom;
    return GestureDetector(
      onTap: _selectCustom,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: selected ? 0.12 : 0.06),
          border: Border.all(
            color: selected
                ? _pkGold.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.18),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_calendar_rounded,
              size: 18,
              color: selected ? _pkGold : kColorWhite.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _customController,
                focusNode: _customFocus,
                onTap: _selectCustom,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: TextStyles.kSemiBoldPoppins(
                  fontSize: TextStyles.k14FontSize,
                  colors: kColorWhite,
                ),
                cursorColor: _pkGold,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText:
                      'Custom minutes (${PkBattleDurationPickerDialog.minCustomMinutes}–${PkBattleDurationPickerDialog.maxCustomMinutes})',
                  hintStyle: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: kColorWhite.withValues(alpha: 0.45),
                  ),
                ),
                onChanged: (_) {
                  if (!_isCustom) {
                    setState(() => _presetMinutes = null);
                  } else {
                    setState(() {});
                  }
                },
              ),
            ),
            AppText(
              text: 'min',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
