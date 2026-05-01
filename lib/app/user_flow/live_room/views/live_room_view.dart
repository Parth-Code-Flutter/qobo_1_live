import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../widgets/common_live_room_widget.dart';

class LiveRoomView extends StatelessWidget {
  const LiveRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = <Map<String, dynamic>>[
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Premier',
        'location': 'Roha',
        'points': '2105',
        'favorite': false,
        'image':
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600',
      },
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Premier',
        'location': 'Roha',
        'points': '2105',
        'favorite': true,
        'image':
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=600',
      },
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Hourly',
        'location': 'Roha',
        'points': '2105',
        'favorite': false,
        'image':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
      },
      {
        'nameAge': 'Mariana, 25',
        'badge': 'Supreme',
        'location': 'Roha',
        'points': '2105',
        'favorite': false,
        'image':
            'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600',
      },
    ];

    return Container(
      color: kColorWhite,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    AppText(
                      text: 'Live Rooms',
                      fontSize: TextStyles.k18FontSize,
                      color: kColorWhite,
                      style: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k18FontSize,
                        colors: kColorWhite,
                      ),
                    ),
                    Spacing.v12,
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final room = rooms[index];
                    return CommonLiveRoomWidget(
                      imageUrl: room['image'] as String,
                      userNameAge: room['nameAge'] as String,
                      badgeText: room['badge'] as String,
                      locationText: room['location'] as String,
                      pointsText: room['points'] as String,
                      isFavorite: room['favorite'] as bool,
                    );
                  },
                  childCount: rooms.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
