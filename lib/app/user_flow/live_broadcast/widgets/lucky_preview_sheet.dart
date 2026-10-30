import 'package:flutter/material.dart';
import 'package:qobo_one_live/services/gifts/lucky_gift_session.dart';
import 'gift_icon_widget.dart';

/// Same room footprint as Gifts; the catalog scrolls without resizing the sheet.
class LuckyPreviewSheet extends StatefulWidget {
  const LuckyPreviewSheet({
    super.key,
    required this.session,
    required this.onSelected,
    this.onSoundStart,
    this.onSoundStop,
  });
  final LuckyGiftSession session;
  final void Function(LuckyGift gift, Offset origin) onSelected;

  /// Starts that gift's tune when the gift is chosen. It loops until the send settles.
  final void Function(LuckyGift gift)? onSoundStart;
  final VoidCallback? onSoundStop;
  @override
  State<LuckyPreviewSheet> createState() => _LuckyPreviewSheetState();
}

class _LuckyPreviewSheetState extends State<LuckyPreviewSheet> {
  String? selected;
  final Map<String, GlobalKey> _tileKeys = {};
  static const gold = Color(0xFFFFD976);
  bool _soundHeld = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  /// Stop the tune when the send that started it has settled. Do not restart.
  void _onSession() {
    final busy = widget.session.busy;
    if (_soundHeld && !busy) {
      _soundHeld = false;
      widget.onSoundStop?.call();
    }
    if (busy) _soundHeld = true;
  }
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('lucky-sheet-panel'),
    height: MediaQuery.sizeOf(context).height * .40,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2C193E), Color(0xFF161622)],
      ),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      border: Border(top: BorderSide(color: Color(0xFF75538C))),
    ),
    child: AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final s = widget.session;
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 6, 0),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: gold, size: 23),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lucky',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (s.balance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${s.balance} Diamonds',
                        style: const TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close Lucky',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFE9AEFF),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.busy
                          ? 'Sending • ${s.queued} queued'
                          : 'Tap a gift, then Send.',
                      style: const TextStyle(
                        color: Color(0xFFC6ACD7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (s.message.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: gold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: gold, fontSize: 11),
                      ),
                    ),
                    if (s.needsRetry)
                      TextButton(
                        onPressed: s.retry,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: s.loading
                  ? const Center(child: CircularProgressIndicator(color: gold))
                  : s.gifts.isEmpty
                  ? Center(
                      child: TextButton(
                        onPressed: s.load,
                        child: const Text('Reload Lucky gifts'),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final columns = constraints.maxWidth >= 360 ? 3 : 2;
                        final tileWidth =
                            (constraints.maxWidth -
                                24 -
                                spacing * (columns - 1)) /
                            columns;
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              for (final gift in s.gifts)
                                SizedBox(
                                  width: tileWidth,
                                  child: _giftTile(
                                    gift,
                                    blocked: s.needsRetry,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );

  Widget _giftTile(LuckyGift gift, {required bool blocked}) {
    final active = selected == gift.id;
    final tileKey = _tileKeys.putIfAbsent(gift.id, () => GlobalKey());
    return AnimatedContainer(
      key: tileKey,
      duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [const Color(0xFF614067), const Color(0xFF382444)]
                : [const Color(0xFF342540), const Color(0xFF211C2D)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? gold : Colors.white.withValues(alpha: .08),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: blocked ? null : () => _selectGift(gift),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GiftIconWidget(icon: gift.icon, size: 52),
                      const SizedBox(height: 4),
                      Text(
                        gift.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${gift.price} Coins',
                        style: const TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (active) ...[
                const SizedBox(height: 6),
                _tileSendButton(
                  blocked: blocked,
                  onTap: () => _sendGift(gift),
                ),
              ],
            ],
          ),
        ),
    );
  }

  Widget _tileSendButton({
    required bool blocked,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: blocked ? null : onTap,
        child: Ink(
          height: 30,
          decoration: BoxDecoration(
            gradient: blocked
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFFE08A), Color(0xFFFFB703)],
                  ),
            color: blocked ? Colors.white12 : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_rounded, color: Color(0xFF3A2408), size: 14),
              SizedBox(width: 4),
              Text(
                'Send',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF3A2408),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectGift(LuckyGift gift) {
    setState(() => selected = gift.id);
    widget.onSoundStart?.call(gift);
  }

  void _sendGift(LuckyGift gift) {
    if (widget.session.needsRetry) return;
    setState(() => selected = gift.id);
    final box =
        _tileKeys[gift.id]?.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? Offset.zero
        : box.localToGlobal(Offset(box.size.width / 2, 28));
    widget.onSelected(gift, origin);
    // A real send sets busy; the tune already playing keeps going until it settles.
    // A preview send finishes immediately, so stop here without starting a new play.
    if (!widget.session.busy) widget.onSoundStop?.call();
  }
}
