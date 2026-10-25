import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Player-facing rules. Opened from the info button on the Food Wheel screen.
class FoodWheelHelpSheet {
  const FoodWheelHelpSheet._();

  static void show() {
    Get.bottomSheet<void>(
      const _HelpBody(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _HelpBody extends StatelessWidget {
  const _HelpBody();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: EdgeInsets.fromLTRB(18, 12, 18, 16 + bottom),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2C27A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'How to play',
              style: TextStyle(
                color: Color(0xFF5C3B16),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Play coins only. Nothing on this screen is real money.',
              style: TextStyle(
                color: Color(0xFF8A5A12),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const _Step(
              number: '1',
              title: 'Choose a coin',
              body: 'Tap 10, 50, 100, or 1000. That is how many play coins each tap spends.',
            ),
            const _Step(
              number: '2',
              title: 'Tap the foods you want',
              body: 'Each tap puts that coin on the food. Tap again to add more. You can back more than one food.',
            ),
            const _Step(
              number: '3',
              title: 'Read the prize before you start',
              body: 'x5 pays 5 times what you put on that food. x45 pays more, and it comes up less often. A gold label like 10 → 450 means 10 spent, 450 back if that food wins.',
            ),
            const _Step(
              number: '4',
              title: 'Start the round',
              body: 'You get 5 seconds to add more coins. Then one food is picked.',
            ),
            const _Step(
              number: '5',
              title: 'Only the winning food pays',
              body: 'Coins on that food come back times its x. Coins on the other foods are spent.',
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Text(
                'Example: you put 50 on Drumstick (x25) and 10 on Tomato (x5). Drumstick wins. You receive 1,250 play coins. The 10 on Tomato is gone.',
                style: TextStyle(
                  color: Color(0xFF5C3B16),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Refill puts 5,000 play coins back so you can try again.',
              style: TextStyle(color: Color(0xFF8A5A12), fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: Get.back,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE2184E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE2184E),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF5C3B16),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF6B4A28),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
