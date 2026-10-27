import 'package:flutter/material.dart';
import 'package:qobo_one_live/services/gifts/lucky_gift_session.dart';
import 'gift_icon_widget.dart';

/// Same room footprint as Gifts; the catalog scrolls without resizing the sheet.
class LuckyPreviewSheet extends StatefulWidget {
  const LuckyPreviewSheet({
    super.key,
    required this.session,
    required this.onSelected,
  });
  final LuckyGiftSession session;
  final void Function(LuckyGift gift, Offset origin) onSelected;
  @override
  State<LuckyPreviewSheet> createState() => _LuckyPreviewSheetState();
}

class _LuckyPreviewSheetState extends State<LuckyPreviewSheet> {
  String? selected;
  final Map<String, GlobalKey> _tileKeys = {};
  static const gold = Color(0xFFFFD976);
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
                          : 'Tap a gift to send it.',
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
                      builder: (context, constraints) => GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth >= 360 ? 3 : 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          mainAxisExtent:
                              116 +
                              (MediaQuery.textScalerOf(context).scale(12) - 12)
                                      .clamp(0, 24) *
                                  3,
                        ),
                        itemCount: s.gifts.length,
                        itemBuilder: (context, i) {
                          final gift = s.gifts[i];
                          final active = selected == gift.id;
                          final tileKey = _tileKeys.putIfAbsent(
                            gift.id,
                            () => GlobalKey(),
                          );
                          return AnimatedContainer(
                            key: tileKey,
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: active
                                    ? [
                                        const Color(0xFF614067),
                                        const Color(0xFF382444),
                                      ]
                                    : [
                                        const Color(0xFF342540),
                                        const Color(0xFF211C2D),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: active
                                    ? gold
                                    : Colors.white.withValues(alpha: .08),
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: s.needsRetry
                                    ? null
                                    : () {
                                        setState(() => selected = gift.id);
                                        final box =
                                            tileKey.currentContext!
                                                    .findRenderObject()
                                                as RenderBox;
                                        widget.onSelected(
                                          gift,
                                          box.localToGlobal(
                                            Offset(box.size.width / 2, 37),
                                          ),
                                        );
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      GiftIconWidget(icon: gift.icon, size: 58),
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
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Text(
                'Each send costs the displayed coins',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        );
      },
    ),
  );
}
