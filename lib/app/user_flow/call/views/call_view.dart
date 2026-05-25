import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';

import '../controllers/call_controller.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: CommonAppBarWidget(
        title: 'Qobo Call',
        useMaterialAppBar: true,
        actions: [
          Obx(() {
            if (controller.isOnboardingDone.value) {
              return IconButton(
                icon: const Icon(Icons.tune, color: kColorWhite),
                onPressed: controller.resetPreferences,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          // Sub tabs for Swipe Deck vs Matches List
          Obx(() {
            if (!controller.isOnboardingDone.value) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFF161622),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? kColorPrimary : Colors.white38,
            size: 20,
          ),
          Spacing.v4,
          AppText(
            text: label,
            style: TextStyles.kRegularPoppins(
              fontSize: 11,
              colors: isActive ? kColorPrimary : Colors.white38,
            ).copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Spacing.v6,
          Container(
            height: 2,
            width: 40,
            color: isActive ? kColorPrimary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // TAB 0: Onboarding / Filter preferences
  Widget _buildOnboardingPreferences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BoldText(
            text: 'Find Your Perfect Match 💖',
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
          ),
          Spacing.v6,
          const Text(
            'Set up your call profile details and matchmaking preferences to begin.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Spacing.v24,

          // Seeking Gender selector
          const SemiBoldText(
            text: 'I want to discover',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          Row(
            children: [
              _buildGenderChip('Female'),
              Spacing.h12,
              _buildGenderChip('Male'),
              Spacing.h12,
              _buildGenderChip('Everyone'),
            ],
          ),

          Spacing.v24,

          // Age slider selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SemiBoldText(
                text: 'Age Range Filter',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
              Obx(() => Text(
                    '${controller.minAge.value} - ${controller.maxAge.value} years',
                    style: const TextStyle(color: kColorPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  )),
            ],
          ),
          Spacing.v8,
          Obx(() {
            return RangeSlider(
              values: RangeValues(controller.minAge.value.toDouble(), controller.maxAge.value.toDouble()),
              min: 18,
              max: 60,
              activeColor: kColorPrimary,
              inactiveColor: Colors.white10,
              onChanged: (RangeValues vals) {
                controller.minAge.value = vals.start.round();
                controller.maxAge.value = vals.end.round();
              },
            );
          }),

          Spacing.v24,

          // Seeking goal
          const SemiBoldText(
            text: 'What are you looking for?',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInterestChip('Chatting'),
              _buildInterestChip('Call'),
              _buildInterestChip('Long-term'),
              _buildInterestChip('Gaming Partner'),
            ],
          ),

          Spacing.v40,

          // Save Preference button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: appButton(
              onPressed: controller.savePreferences,
              buttonText: 'Find Matches',
              buttonColor: kColorPrimary,
              borderRadius: 16,
              textStyle: TextStyles.kBoldPoppins(fontSize: TextStyles.k16FontSize, colors: kColorWhite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String gender) {
    return Expanded(
      child: Obx(() {
        final bool isSelected = controller.seekingGender.value == gender;
        return GestureDetector(
          onTap: () => controller.seekingGender.value = gender,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? kColorPrimary.withValues(alpha: 0.15) : const Color(0xFF161622),
              border: Border.all(color: isSelected ? kColorPrimary : Colors.transparent, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                gender,
                style: TextStyle(
                  color: isSelected ? kColorPrimary : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInterestChip(String label) {
    return Obx(() {
      final bool isSelected = controller.interestedIn.contains(label);
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected ? kColorWhite : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (_) => controller.toggleInterest(label),
        selectedColor: kColorPrimary,
        backgroundColor: const Color(0xFF161622),
        checkmarkColor: kColorWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.transparent),
        ),
      );
    });
  }

  // TAB 1: Tinder style Swiper card deck
  Widget _buildSwipeDeck() {
    final idx = controller.currentProfileIndex.value;
    if (idx >= controller.profiles.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_protected_setup_rounded, color: Colors.white10, size: 72),
            Spacing.v16,
            const Text('You\'ve swiped through everyone today!', style: TextStyle(color: Colors.white38, fontSize: 14)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                            fallback: Image.asset('assets/images/temp_img_2.png', fit: BoxFit.cover),
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            prof['avatar'],
                            fit: BoxFit.cover,
                          ),
                  ),
                  // Dark shadow gradient on bottom half
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.greenAccent, width: 0.5),
                              ),
                              child: Text(
                                '${prof['matchPercentage']}% Match',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Spacing.v6,
                        // Location info
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.pinkAccent, size: 14),
                            Spacing.h4,
                            Text(
                              prof['location'],
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        Spacing.v10,
                        // Bio description
                        Text(
                          prof['bio'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Spacing.v16,
                        // Interest pills
                        Wrap(
                          spacing: 8,
                          children: (prof['interests'] as List<String>).map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
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
                  child: const Icon(Icons.close, color: Colors.redAccent, size: 28),
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
                  child: const Icon(Icons.favorite, color: Colors.greenAccent, size: 28),
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
            const Icon(Icons.heart_broken_rounded, color: Colors.white10, size: 72),
            Spacing.v16,
            const Text('No matches found yet.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            Spacing.v6,
            const Text('Keep swiping on cards to get matching!', style: TextStyle(color: Colors.white24, fontSize: 11)),
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
                          fallback: Image.asset('assets/images/temp_img_2.png', fit: BoxFit.cover),
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
                          style: const TextStyle(fontSize: 10, color: Colors.white38),
                        ),
                      ],
                    ),
                    Spacing.v4,
                    Text(
                      match['lastMsg'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              // Direct Message button
              IconButton(
                icon: const Icon(Icons.chat_bubble, color: kColorPrimary, size: 22),
                onPressed: () => Get.toNamed(Routes.CHAT_DETAIL),
              ),
            ],
          ),
        );
      },
    );
  }
}
