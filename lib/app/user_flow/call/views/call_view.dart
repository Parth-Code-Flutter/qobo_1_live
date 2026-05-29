import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';

import '../controllers/call_controller.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  static const Color _bgTop = Color(0xFF160820);
  static const Color _bgMid = Color(0xFF0B1022);
  static const Color _bgBottom = Color(0xFF080914);
  static const Color _surface = Color(0xCC171625);
  static const Color _surfaceSoft = Color(0x991C1B2C);
  static const Color _accentPink = Color(0xFFFF3FA4);
  static const Color _accentPurple = Color(0xFF8A1B7A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgMid, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Obx(() {
                if (!controller.isOnboardingDone.value) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                  child: _buildSubTabs(),
                );
              }),
              Expanded(
                child: Obx(() {
                  if (!controller.isOnboardingDone.value) {
                    return _buildOnboardingPreferences();
                  }

                  if (controller.currentTab.value == 1) {
                    return _buildSwipeDeck();
                  } else {
                    return _buildMatchesList();
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          _headerButton(Icons.arrow_back_ios_new_rounded, Get.back),
          const Expanded(
            child: Center(
              child: BoldText(
                text: 'Qobo Call',
                fontSize: TextStyles.k22FontSize,
                color: kColorWhite,
              ),
            ),
          ),
          Obx(() {
            if (!controller.isOnboardingDone.value) {
              return const SizedBox(width: 46, height: 46);
            }
            return _headerButton(
              Icons.tune_rounded,
              controller.resetPreferences,
            );
          }),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: kColorWhite.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: kColorWhite, size: 20),
      ),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSubTabItem(
              icon: Icons.style_rounded,
              label: 'Discover',
              isActive: controller.currentTab.value == 1,
              onTap: () => controller.currentTab.value = 1,
            ),
          ),
          Expanded(
            child: _buildSubTabItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'My Matches',
              isActive: controller.currentTab.value == 2,
              onTap: () => controller.currentTab.value = 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? kColorWhite.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? _accentPink : Colors.white38,
              size: 18,
            ),
            Spacing.h6,
            AppText(
              text: label,
              style: TextStyles.kSemiBoldPoppins(
                fontSize: 12,
                colors: isActive ? kColorWhite : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPreferences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _introCard(),
          Spacing.v20,
          _sectionLabel('I want to discover', Icons.explore_rounded),
          Spacing.v12,
          Row(
            children: [
              _buildGenderChip('Female', Icons.female_rounded),
              Spacing.h10,
              _buildGenderChip('Male', Icons.male_rounded),
              Spacing.h10,
              _buildGenderChip('Everyone', Icons.groups_rounded),
            ],
          ),
          Spacing.v20,
          _ageRangeCard(),
          Spacing.v20,
          _sectionLabel('What are you looking for?', Icons.favorite_rounded),
          Spacing.v12,
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInterestChip('Chatting', Icons.chat_bubble_rounded),
              _buildInterestChip('Call', Icons.call_rounded),
              _buildInterestChip('Long-term', Icons.favorite_rounded),
              _buildInterestChip(
                'Gaming Partner',
                Icons.sports_esports_rounded,
              ),
            ],
          ),
          Spacing.v28,
          _findMatchesButton(),
        ],
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1237), Color(0xFF121B35)],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: _accentPink.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentPink.withValues(alpha: 0.16),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_accentPink, _accentPurple],
                  ),
                ),
                child: const Icon(Icons.video_call_rounded, color: kColorWhite),
              ),
              Spacing.v16,
              const BoldText(
                text: 'Find Your Perfect Match',
                fontSize: TextStyles.k22FontSize,
                color: kColorWhite,
              ),
              Spacing.v8,
              AppText(
                text:
                    'Tune your discovery preferences and start meeting people who match your vibe.',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite.withValues(alpha: 0.68),
                maxLines: 3,
              ),
              Spacing.v16,
              Row(
                children: [
                  _heroMetric('94%', 'match score'),
                  Spacing.h10,
                  _heroMetric('Live', 'call ready'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SemiBoldText(text: value, fontSize: 13, color: kColorWhite),
          Spacing.h6,
          AppText(
            text: label,
            fontSize: 10,
            color: kColorWhite.withValues(alpha: 0.58),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accentPink, size: 18),
        Spacing.h8,
        SemiBoldText(
          text: text,
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
      ],
    );
  }

  Widget _ageRangeCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SemiBoldText(
                text: 'Age Range Filter',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
              const Spacer(),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _accentPink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SemiBoldText(
                    text:
                        '${controller.minAge.value} - ${controller.maxAge.value} years',
                    fontSize: 12,
                    color: _accentPink,
                  ),
                ),
              ),
            ],
          ),
          Spacing.v12,
          Obx(() {
            return RangeSlider(
              values: RangeValues(
                controller.minAge.value.toDouble(),
                controller.maxAge.value.toDouble(),
              ),
              min: 18,
              max: 60,
              activeColor: _accentPink,
              inactiveColor: kColorWhite.withValues(alpha: 0.10),
              onChanged: (RangeValues vals) {
                controller.minAge.value = vals.start.round();
                controller.maxAge.value = vals.end.round();
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String gender, IconData icon) {
    return Expanded(
      child: Obx(() {
        final bool isSelected = controller.seekingGender.value == gender;
        return GestureDetector(
          onTap: () => controller.seekingGender.value = gender,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? _accentPink.withValues(alpha: 0.14)
                  : _surface,
              border: Border.all(
                color: isSelected
                    ? _accentPink
                    : kColorWhite.withValues(alpha: 0.06),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? _accentPink : Colors.white54),
                Spacing.v8,
                SemiBoldText(
                  text: gender,
                  fontSize: TextStyles.k12FontSize,
                  color: isSelected ? kColorWhite : Colors.white60,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInterestChip(String label, IconData icon) {
    return Obx(() {
      final bool isSelected = controller.interestedIn.contains(label);
      return GestureDetector(
        onTap: () => controller.toggleInterest(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? _accentPink.withValues(alpha: 0.16)
                : _surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _accentPink
                  : kColorWhite.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? _accentPink : Colors.white54,
                size: 17,
              ),
              Spacing.h8,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: isSelected ? kColorWhite : Colors.white60,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _findMatchesButton() {
    return GestureDetector(
      onTap: controller.savePreferences,
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [_accentPink, _accentPurple]),
          boxShadow: [
            BoxShadow(
              color: _accentPink.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, color: kColorWhite, size: 20),
            SizedBox(width: 8),
            BoldText(
              text: 'Find Matches',
              fontSize: TextStyles.k16FontSize,
              color: kColorWhite,
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Tinder style Swiper card deck
  Widget _buildSwipeDeck() {
    final idx = controller.currentProfileIndex.value;
    if (idx >= controller.profiles.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_protected_setup_rounded,
              color: Colors.white10,
              size: 72,
            ),
            Spacing.v16,
            const Text(
              'You\'ve swiped through everyone today!',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            Spacing.v24,
            appButton(
              onPressed: controller.resetSwiper,
              buttonText: 'Reset Cards Deck',
              buttonColor: kColorPrimary,
              borderRadius: 20,
              buttonHeight: 44,
              buttonWidth: 180,
            ),
          ],
        ),
      );
    }

    final prof = controller.profiles[idx];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main swipe card
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              color: const Color(0xFF161622),
              elevation: 4,
              child: Stack(
                children: [
                  // Profile Photo background
                  Positioned.fill(
                    child: prof['avatar'].toString().startsWith('http')
                        ? SafeNetworkAvatar(
                            url: prof['avatar'],
                            size: double.infinity,
                            fallback: Image.asset(
                              'assets/images/temp_img_2.png',
                              fit: BoxFit.cover,
                            ),
                            fit: BoxFit.cover,
                          )
                        : Image.asset(prof['avatar'], fit: BoxFit.cover),
                  ),
                  // Dark shadow gradient on bottom half
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Text and Info detail overlays
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Age row
                        Row(
                          children: [
                            BoldText(
                              text: '${prof['name']}, ${prof['age']}',
                              fontSize: TextStyles.k20FontSize,
                              color: kColorWhite,
                            ),
                            Spacing.h10,
                            // Match percentage badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.greenAccent,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '${prof['matchPercentage']}% Match',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Spacing.v6,
                        // Location info
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.pinkAccent,
                              size: 14,
                            ),
                            Spacing.h4,
                            Text(
                              prof['location'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Spacing.v10,
                        // Bio description
                        Text(
                          prof['bio'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Spacing.v16,
                        // Interest pills
                        Wrap(
                          spacing: 8,
                          children: (prof['interests'] as List<String>).map((
                            interest,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacing.v16,

          // Match control action buttons (Nope, Heart)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nope button (Red Cross)
              GestureDetector(
                onTap: controller.swipeLeft,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                ),
              ),
              Spacing.h32,
              // Super Like star button
              GestureDetector(
                onTap: () {
                  Get.snackbar(
                    'Super Like!',
                    'You sent a Super Like to ${prof['name']}!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.amber,
                    colorText: Colors.black,
                  );
                  controller.swipeRight();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: const Icon(Icons.star, color: Colors.amber, size: 20),
                ),
              ),
              Spacing.h32,
              // Heart Like button
              GestureDetector(
                onTap: controller.swipeRight,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.greenAccent, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.greenAccent,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          Spacing.v8,
        ],
      ),
    );
  }

  // TAB 2: Matches List view screen
  Widget _buildMatchesList() {
    if (controller.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.heart_broken_rounded,
              color: Colors.white10,
              size: 72,
            ),
            Spacing.v16,
            const Text(
              'No matches found yet.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            Spacing.v6,
            const Text(
              'Keep swiping on cards to get matching!',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.matches.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final match = controller.matches[index];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161622),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white10,
                child: ClipOval(
                  child: match['avatar'].toString().startsWith('http')
                      ? SafeNetworkAvatar(
                          url: match['avatar'],
                          size: 56,
                          fallback: Image.asset(
                            'assets/images/temp_img_2.png',
                            fit: BoxFit.cover,
                          ),
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          match['avatar'],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SemiBoldText(
                          text: '${match['name']}, ${match['age']}',
                          fontSize: TextStyles.k14FontSize,
                          color: kColorWhite,
                        ),
                        Text(
                          match['matchedTime'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    Spacing.v4,
                    Text(
                      match['lastMsg'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              // Direct Message button
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble,
                  color: kColorPrimary,
                  size: 22,
                ),
                onPressed: () => Get.toNamed(Routes.CHAT_DETAIL),
              ),
            ],
          ),
        );
      },
    );
  }
}
