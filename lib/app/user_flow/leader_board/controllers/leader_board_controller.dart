import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

import '../models/leader_board_models.dart';

class LeaderBoardController extends GetxController {
  static const List<LeaderBoardPodiumUser> podium = [
    LeaderBoardPodiumUser(rank: 2, name: 'Jessica', imageAsset: kImgTemp3),
    LeaderBoardPodiumUser(rank: 1, name: 'Parth', imageAsset: kImgTemp2),
    LeaderBoardPodiumUser(rank: 3, name: 'Bessie', imageAsset: kImgTemp4),
  ];

  static const List<LeaderBoardListEntry> runningUp = [
    LeaderBoardListEntry(
      displayRank: 1,
      name: 'Courteny Henry',
      subtitle: 'Active 2 hr',
      points: '54458989',
      imageAsset: kImgTemp2,
    ),
    LeaderBoardListEntry(
      displayRank: 2,
      name: 'Jane Cooper',
      subtitle: 'Active 2 hr',
      points: '54458989',
      imageAsset: kImgTemp3,
    ),
    LeaderBoardListEntry(
      displayRank: 3,
      name: 'Areina McCoy',
      subtitle: 'Active 2 hr',
      points: '54458989',
      imageAsset: kImgTemp4,
      highlighted: true,
    ),
    LeaderBoardListEntry(
      displayRank: 4,
      name: 'Darrell Steward',
      subtitle: 'Active 2 hr',
      points: '54458989',
      imageAsset: kImgTemp5,
    ),
    LeaderBoardListEntry(
      displayRank: 5,
      name: 'Devon Lane',
      subtitle: 'Active 2 hr',
      points: '54458989',
      imageAsset: kImgTemp2,
    ),
    LeaderBoardListEntry(
      displayRank: 6,
      name: 'Eleanor Pena',
      subtitle: 'Active 2 hr',
      points: '54458989',
      imageAsset: kImgTemp3,
    ),
    LeaderBoardListEntry(
      displayRank: 7,
      name: 'Floyd Miles',
      subtitle: 'Active 2 hr',
      points: '54458989',
      imageAsset: kImgTemp4,
    ),
  ];
}
