import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/repo/pk/pk_repo.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';

class CallController extends GetxController {
  // Navigation / Tab state
  final currentTab = 0.obs; // 0: Preferences Onboarding, 1: Swipe Deck, 2: Matches List

  // Onboarding Preference Form States
  final seekingGender = 'Female'.obs; // Female, Male, Everyone
  final minAge = 18.obs;
  final maxAge = 35.obs;
  final interestedIn = <String>[].obs; // Chat, Call, Long-term, Gaming Partner
  final isOnboardingDone = false.obs;

  // Swipe Deck States
  final profiles = <Map<String, dynamic>>[].obs;
  final currentProfileIndex = 0.obs;

  // Matches List State
  final matches = <Map<String, dynamic>>[].obs;

  final PkRepo _pkRepo = PkRepo();

  @override
  void onInit() {
    super.onInit();
    loadCallProfiles();
    loadMockMatches();
  }

  Future<void> loadCallProfiles() async {
    try {
      final response = await _pkRepo.getCallList(isShowLoader: false);
      if (response != null && response['statusCode'] == 1 && response['data'] != null) {
        final list = response['data'];
        if (list is List) {
          final mapped = list.map((e) {
            final map = e as Map<String, dynamic>;
            return {
              'name': map['name'] ?? 'User',
              'age': map['age'] ?? 22,
              'location': map['location'] ?? 'Dhaka, Bangladesh',
              'bio': map['bio'] ?? 'Hello!',
              'avatar': map['displayPicture'] != null && map['displayPicture'].toString().isNotEmpty
                  ? (map['displayPicture'].toString().startsWith('http')
                      ? map['displayPicture'].toString()
                      : 'https://my-backend-api-960q.onrender.com${map['displayPicture']}')
                  : 'assets/images/temp_img_2.png',
              'matchPercentage': map['matchPercentage'] ?? 90,
              'interests': List<String>.from(map['interests'] ?? []),
            };
          }).toList();
          if (mapped.isNotEmpty) {
            profiles.assignAll(mapped);
            return;
          }
        }
      }
    } catch (_) {}
    loadMockProfiles();
  }

  void loadMockProfiles() {
    profiles.assignAll([
      {
        'name': 'Aria Sen',
        'age': 22,
        'location': 'Dhaka, Bangladesh',
        'bio': 'Love listening to music, watching live streams, and making new friends!',
        'avatar': 'assets/images/temp_img_2.png',
        'matchPercentage': 94,
        'interests': ['Music', 'Gaming', 'Coffee'],
      },
      {
        'name': 'Riya Sharma',
        'age': 24,
        'location': 'Mumbai, India',
        'bio': 'Foodie, traveler, and looking for someone to talk to on video calls.',
        'avatar': 'assets/images/temp_img_4.png',
        'matchPercentage': 88,
        'interests': ['Travel', 'Food', 'Movies'],
      },
      {
        'name': 'Neha Khan',
        'age': 21,
        'location': 'Sylhet, Bangladesh',
        'bio': 'Solo broadcaster. Swipe right to join my live streams!',
        'avatar': 'assets/images/temp_img_2.png',
        'matchPercentage': 91,
        'interests': ['Broadcasting', 'Chatting', 'Pop'],
      },
      {
        'name': 'Aisha Ahmed',
        'age': 26,
        'location': 'Lahore, Pakistan',
        'bio': 'Looking for genuine conversations and long-term friendship.',
        'avatar': 'assets/images/temp_img_4.png',
        'matchPercentage': 85,
        'interests': ['Reading', 'Art', 'Nature'],
      },
    ]);
  }

  void loadMockMatches() {
    matches.assignAll([
      {
        'name': 'Zara Qureshi',
        'age': 23,
        'location': 'Dhaka',
        'avatar': 'assets/images/temp_img_2.png',
        'matchedTime': '2 hours ago',
        'lastMsg': 'Hey! How are you doing today?',
      },
      {
        'name': 'Elena Roy',
        'age': 25,
        'location': 'Kolkata',
        'avatar': 'assets/images/temp_img_4.png',
        'matchedTime': 'Yesterday',
        'lastMsg': 'Would love to join your stream sometime!',
      },
    ]);
  }

  // Action: Complete Onboarding & go to Swipe Deck
  Future<void> savePreferences() async {
    if (interestedIn.isEmpty) {
      Get.snackbar(
        'Preferences',
        'Please select at least one interest or goal.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: kColorWhite,
      );
      return;
    }

    final response = await _pkRepo.callOnboarding(
      interests: interestedIn.toList(),
      lookingFor: seekingGender.value,
      aboutMe: 'Seeking matches aged ${minAge.value} to ${maxAge.value}.',
      isShowLoader: true,
    );

    isOnboardingDone.value = true;
    currentTab.value = 1; // Open Swipe Deck

    await loadCallProfiles();

    Get.snackbar(
      'Call Preferences Saved',
      response?['message'] ?? 'Discovering matches matching your criteria...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: kColorWhite,
    );
  }

  // Action: Reset preferences to re-edit onboarding
  void resetPreferences() {
    isOnboardingDone.value = false;
    currentTab.value = 0;
  }

  // Action: Swipe Left (Nope/Dislike)
  void swipeLeft() {
    if (currentProfileIndex.value < profiles.length) {
      final name = profiles[currentProfileIndex.value]['name'];
      Get.snackbar(
        'Passed',
        'You passed on $name',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black54,
        colorText: kColorWhite,
      );
      nextProfile();
    }
  }

  // Action: Swipe Right (Like)
  void swipeRight() {
    if (currentProfileIndex.value < profiles.length) {
      final profile = profiles[currentProfileIndex.value];
      final name = profile['name'];

      // Simulate a 50% match chance for high-fidelity engagement
      final bool isMatch = currentProfileIndex.value % 2 == 0;

      if (isMatch) {
        // Add to matches list
        matches.insert(0, {
          'name': profile['name'],
          'age': profile['age'],
          'location': profile['location'].split(',').first,
          'avatar': profile['avatar'],
          'matchedTime': 'Just Now',
          'lastMsg': 'Say hello to your new match!',
        });
        showMatchCelebration(profile);
      } else {
        Get.snackbar(
          'Liked',
          'You liked $name. Waiting for response...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.pinkAccent,
          colorText: kColorWhite,
        );
      }
      nextProfile();
    }
  }

  // Move to next card
  void nextProfile() {
    if (currentProfileIndex.value < profiles.length) {
      currentProfileIndex.value++;
    }
  }

  // Reset Swiper deck to retry
  void resetSwiper() {
    currentProfileIndex.value = 0;
    loadMockProfiles();
  }

  // Match celebration dialog
  void showMatchCelebration(Map<String, dynamic> profile) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BoldText(
                text: '🎉 IT\'S A MATCH! 🎉',
                fontSize: 22,
                color: kColorWhite,
              ),
              Spacing.v16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('assets/images/temp_img_2.png'), // Me
                  ),
                  Spacing.h12,
                  const Icon(Icons.favorite, color: Colors.white, size: 28),
                  Spacing.h12,
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white10,
                    child: ClipOval(
                      child: profile['avatar'].toString().startsWith('http')
                          ? SafeNetworkAvatar(
                              url: profile['avatar'],
                              size: 72,
                              fallback: Image.asset('assets/images/temp_img_2.png', fit: BoxFit.cover),
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              profile['avatar'],
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ],
              ),
              Spacing.v20,
              Text(
                'You and ${profile['name']} liked each other!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kColorWhite, fontSize: 13),
              ),
              Spacing.v24,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: kColorWhite,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text('Keep Swiping', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Spacing.h12,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE91E63),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Get.back();
                        Get.toNamed(Routes.CHAT_DETAIL);
                      },
                      child: const Text('Say Hello', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void toggleInterest(String interest) {
    if (interestedIn.contains(interest)) {
      interestedIn.remove(interest);
    } else {
      interestedIn.add(interest);
    }
  }
}
