import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/pk_battle_controller.dart';

class PKBattleView extends GetView<PKBattleController> {
  const PKBattleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: const CommonAppBarWidget(
        title: 'PK Battle Arena',
        useMaterialAppBar: true,
      ),
      body: Obx(() {
        switch (controller.pkState.value) {
          case PKState.idle:
            return _buildIdleLobby();
          case PKState.searching:
            return _buildSearchingRadar();
          case PKState.incomingRequest:
            return _buildIncomingRequest();
          case PKState.outgoingRequest:
            return _buildOutgoingRequest();
          case PKState.inBattle:
            return _buildInBattleScreen();
          case PKState.completed:
            return const Center(child: CircularProgressIndicator(color: kColorPrimary));
        }
      }),
    );
  }

  // LOBBY STATE: Search & Opponents grid
  Widget _buildIdleLobby() {
    return Column(
      children: [
        // Quick matchmaking button
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A00E0).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BoldText(
                text: 'Quick PK Matchmaking',
                fontSize: TextStyles.k18FontSize,
                color: kColorWhite,
              ),
              Spacing.v6,
              Text(
                'Instantly find an active host to challenge right now!',
                style: TextStyle(color: kColorWhite.withValues(alpha: 0.8), fontSize: 12),
              ),
              Spacing.v16,
              SizedBox(
                width: double.infinity,
                height: 44,
                child: appButton(
                  onPressed: controller.startMatchmaking,
                  buttonText: 'Find Opponent',
                  buttonColor: kColorWhite,
                  textColor: const Color(0xFF4A00E0),
                  borderRadius: 12,
                  textStyle: TextStyles.kBoldPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: const Color(0xFF4A00E0),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search Opponent Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppTextField(
            hintText: 'Search online hosts...',
            fillColor: const Color(0xFF1E1E2C),
            borderColor: Colors.transparent,
            inputBorderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            textStyle: TextStyles.kRegularPoppins(colors: kColorWhite, fontSize: 13),
            hintStyle: TextStyles.kRegularPoppins(colors: Colors.white54, fontSize: 13),
            prefix: Icon(Icons.search, color: Colors.grey.shade400),
            onChanged: (val) => controller.searchQuery.value = val,
          ),
        ),

        Spacing.v12,

        // Opponent list title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SemiBoldText(
              text: 'Available Streamers',
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ),
        ),

        Spacing.v8,

        // Opponents scroll list
        Expanded(
          child: controller.filteredOpponents.isEmpty
              ? _buildNoOpponentsFound()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredOpponents.length,
                  separatorBuilder: (_, __) => Spacing.v12,
                  itemBuilder: (context, index) {
                    final opp = controller.filteredOpponents[index];
                    final bool isOnline = opp['isOnline'] ?? false;
                    final bool hasVip = (opp['vip'] ?? '').toString().isNotEmpty;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161622),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOnline ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar with online dot
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(opp['avatar']),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF161622), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Spacing.h12,
                          // Streamer Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: SemiBoldText(
                                        text: opp['name'],
                                        fontSize: TextStyles.k14FontSize,
                                        color: kColorWhite,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasVip) ...[
                                      Spacing.h6,
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          opp['vip'],
                                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Spacing.v4,
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: kColorPrimary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Lv.${opp['level']}',
                                        style: const TextStyle(fontSize: 9, color: kColorPrimary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Spacing.h8,
                                    Icon(Icons.people, color: Colors.white38, size: 12),
                                    Spacing.h4,
                                    Text(
                                      opp['followers'],
                                      style: const TextStyle(fontSize: 10, color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Spacing.h12,
                          // Challenge Button
                          SizedBox(
                            height: 32,
                            width: 86,
                            child: appButton(
                              onPressed: isOnline ? () => controller.sendInvitation(opp) : () {},
                              buttonText: 'Challenge',
                              buttonColor: isOnline ? kColorPrimary : Colors.grey.shade800,
                              borderRadius: 16,
                              textStyle: TextStyles.kBoldPoppins(
                                fontSize: TextStyles.k12FontSize,
                                colors: isOnline ? kColorWhite : Colors.white24,
                              ),
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
  }

  Widget _buildNoOpponentsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, color: Colors.white10, size: 64),
          Spacing.v12,
          const Text('No online hosts match your query', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  // RADAR STATE: Matchmaking loader animation
  Widget _buildSearchingRadar() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar loader graphics
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kColorPrimary.withValues(alpha: 0.05),
                  border: Border.all(color: kColorPrimary.withValues(alpha: 0.2), width: 1.5),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kColorPrimary.withValues(alpha: 0.08),
                  border: Border.all(color: kColorPrimary.withValues(alpha: 0.35), width: 1.5),
                ),
              ),
              const CircleAvatar(
                radius: 32,
                backgroundImage: AssetImage('assets/images/temp_img_2.png'),
              ),
              const Positioned.fill(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
                ),
              ),
            ],
          ),
          Spacing.v24,
          const SemiBoldText(
            text: 'Searching for opponents...',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          Spacing.v8,
          const Text('Connecting to active streamers...', style: TextStyle(color: Colors.white38, fontSize: 12)),
          Spacing.v32,
          appButton(
            onPressed: () {
              controller.pkState.value = PKState.idle;
            },
            buttonText: 'Cancel Matchmaking',
            buttonColor: const Color(0xFF1E1E2C),
            textColor: Colors.redAccent,
            borderRadius: 20,
            buttonHeight: 40,
            buttonWidth: 180,
            textStyle: TextStyles.kBoldPoppins(fontSize: TextStyles.k12FontSize, colors: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // INCOMING CHALLENGE: Request Dialog View
  Widget _buildIncomingRequest() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161622),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kColorPrimary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('CHALLENGE REQUEST', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
            Spacing.v24,
            CircleAvatar(
              radius: 48,
              backgroundImage: AssetImage(controller.currentOpponentAvatar.value),
            ),
            Spacing.v16,
            SemiBoldText(
              text: controller.currentOpponentName.value,
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
            ),
            Spacing.v6,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Lv.${controller.currentOpponentLevel.value}',
                    style: const TextStyle(fontSize: 10, color: kColorPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                if (controller.currentOpponentVip.value.isNotEmpty) ...[
                  Spacing.h8,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      controller.currentOpponentVip.value,
                      style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            Spacing.v12,
            const Text(
              'wants to challenge you in a 3-minute gift combat!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Spacing.v32,
            Row(
              children: [
                Expanded(
                  child: appButton(
                    onPressed: controller.rejectChallenge,
                    buttonText: 'Decline',
                    buttonColor: Colors.transparent,
                    buttonBorderColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    borderRadius: 16,
                    buttonHeight: 48,
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: appButton(
                    onPressed: controller.acceptChallenge,
                    buttonText: 'Accept',
                    buttonColor: kColorPrimary,
                    borderRadius: 16,
                    buttonHeight: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // OUTGOING CHALLENGE: Waiting loop
  Widget _buildOutgoingRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: AssetImage(controller.currentOpponentAvatar.value),
          ),
          Spacing.v16,
          SemiBoldText(
            text: 'Challenging ${controller.currentOpponentName.value}',
            fontSize: TextStyles.k16FontSize,
            color: kColorWhite,
          ),
          Spacing.v8,
          const Text('Waiting for opponent to accept...', style: TextStyle(color: Colors.white38, fontSize: 12)),
          Spacing.v32,
          const CircularProgressIndicator(color: kColorPrimary),
          Spacing.v40,
          appButton(
            onPressed: controller.cancelOutgoing,
            buttonText: 'Cancel Invite',
            buttonColor: const Color(0xFF1E1E2C),
            textColor: Colors.redAccent,
            borderRadius: 20,
            buttonHeight: 40,
            buttonWidth: 160,
            textStyle: TextStyles.kBoldPoppins(fontSize: TextStyles.k12FontSize, colors: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // ACTIVE PK SCREEN: Interactive side-by-side battle split screen
  Widget _buildInBattleScreen() {
    return Column(
      children: [
        Spacing.v12,
        
        // Timer countdown header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9900).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF9900).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Color(0xFFFF9900), size: 16),
              Spacing.h6,
              BoldText(
                text: controller.formattedTime,
                fontSize: TextStyles.k14FontSize,
                color: const Color(0xFFFF9900),
              ),
            ],
          ),
        ),

        Spacing.v12,

        // PK POINTS PROGRESS BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Point label numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Me: ${controller.myPoints.value} Pts',
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Opponent: ${controller.opponentPoints.value} Pts',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Spacing.v6,
              // Glowing sliding bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 14,
                  width: double.infinity,
                  color: Colors.grey.shade900,
                  child: Row(
                    children: [
                      Flexible(
                        flex: (controller.myPercentage * 100).toInt(),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.cyan],
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: ((1 - controller.myPercentage) * 100).toInt(),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepOrange, Colors.red],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Spacing.v16,

        // SIDE-BY-SIDE VIDEO PLACES
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Me screen (Left)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.15,
                            child: Image.asset('assets/images/temp_img_3.png', fit: BoxFit.cover),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage('assets/images/temp_img_2.png'),
                            ),
                            Spacing.v8,
                            const Text('Me (Host)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        // Winner status banner
                        if (controller.myPoints.value >= controller.opponentPoints.value)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('WINNING', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Spacing.h12,
                // Opponent screen (Right)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.25,
                            child: Image.asset(controller.currentOpponentAvatar.value, fit: BoxFit.cover),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(controller.currentOpponentAvatar.value),
                            ),
                            Spacing.v8,
                            Text(controller.currentOpponentName.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        // Winner status banner
                        if (controller.opponentPoints.value > controller.myPoints.value)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('WINNING', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // TESTING CONTROL BOX: Simulator buttons to increase points
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161622),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SemiBoldText(
                text: 'Gift Combat Simulator (Testing)',
                fontSize: TextStyles.k12FontSize,
                color: Colors.white70,
              ),
              Spacing.v12,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                        foregroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => controller.simulateGift(100, true),
                      child: const Text('+100 Rose', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Spacing.h8,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.withValues(alpha: 0.15),
                        foregroundColor: Colors.cyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => controller.simulateGift(500, true),
                      child: const Text('+500 Diamond', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Spacing.h8,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => controller.simulateGift(300, false),
                      child: const Text('+300 Opponent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
