import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

enum AdProvider { adMob, facebook }

class AppMockAdBannerWidget extends StatefulWidget {
  final AdProvider provider;
  const AppMockAdBannerWidget({super.key, this.provider = AdProvider.adMob});

  @override
  State<AppMockAdBannerWidget> createState() => _AppMockAdBannerWidgetState();
}

class _AppMockAdBannerWidgetState extends State<AppMockAdBannerWidget> {
  late bool isAdMob;
  
  final List<Map<String, String>> adMobAds = [
    {
      'title': 'Google Cloud Credits',
      'desc': 'Get \$300 free credits to build and scale your next startup.',
      'cta': 'Claim Now',
      'url': 'cloud.google.com',
    },
    {
      'title': 'Learn Flutter 3.3',
      'desc': 'Master cross-platform development with the official courses.',
      'cta': 'Enroll',
      'url': 'flutter.dev',
    },
  ];

  final List<Map<String, String>> facebookAds = [
    {
      'title': 'Meta Quest 3',
      'desc': 'Expand your world with breakthrough mixed reality. Pre-order.',
      'cta': 'Shop Now',
      'url': 'meta.com/quest',
    },
    {
      'title': 'WhatsApp Business',
      'desc': 'Reach customers worldwide. Download WhatsApp Business today.',
      'cta': 'Install',
      'url': 'whatsapp.com/biz',
    },
  ];

  int currentAdIndex = 0;
  Timer? rotateTimer;

  @override
  void initState() {
    super.initState();
    isAdMob = widget.provider == AdProvider.adMob;
    rotateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          currentAdIndex = (currentAdIndex + 1) % 2;
        });
      }
    });
  }

  @override
  void dispose() {
    rotateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adList = isAdMob ? adMobAds : facebookAds;
    final ad = adList[currentAdIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdMob ? Colors.blue.withValues(alpha: 0.3) : Colors.purple.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Ad Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isAdMob ? Colors.blue : Colors.purple,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isAdMob ? 'AdMob' : 'Sponsored',
              style: const TextStyle(
                color: kColorWhite,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: SemiBoldText(
                        text: ad['title'] ?? '',
                        fontSize: 12,
                        color: kColorWhite,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• ${ad['url']}',
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                  ],
                ),
                Spacing.v2,
                AppText(
                  text: ad['desc'] ?? '',
                  fontSize: 10,
                  color: Colors.white70,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Spacing.h10,
          // CTA Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdMob ? Colors.blue.shade700 : Colors.purple.shade700,
              foregroundColor: kColorWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {},
            child: Text(
              ad['cta'] ?? 'Open',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
