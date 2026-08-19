import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/referral/models/referral_models.dart';
import 'package:qobo_one_live/repo/referral/referral_repo.dart';
import 'package:qobo_one_live/utils/files_utils/file_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class ReferralController extends GetxController {
  ReferralController({ReferralRepo? referralRepo})
      : _referralRepo = referralRepo ?? ReferralRepo();

  final ReferralRepo _referralRepo;

  final isLoading = false.obs;
  final isGenerating = false.obs;
  final activeCode = ''.obs;
  final shareMessage = ''.obs;
  final totalReferralsCompleted = 0.obs;
  final totalCoinsEarned = 0.obs;
  final completedHistory = <ReferralCompletedEntry>[].obs;
  final earningHistory = <ReferralEarningEntry>[].obs;
  final selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDetails();
  }

  Future<void> loadDetails() async {
    isLoading.value = true;
    try {
      final details = await _referralRepo.getMyReferralCodeParsed(
        isShowLoader: false,
      );
      if (details != null) {
        _applyDetails(details);
      }
      final earnings = await _referralRepo.getReferralHistoryParsed(
        isShowLoader: false,
      );
      earningHistory.assignAll(earnings);
    } finally {
      isLoading.value = false;
    }
  }

  void _applyDetails(ReferralMyCodeDetails details) {
    activeCode.value = details.activeCode;
    shareMessage.value = details.shareMessage;
    totalReferralsCompleted.value = details.totalReferralsCompleted;
    totalCoinsEarned.value = details.totalCoinsEarned;
    completedHistory.assignAll(details.completedReferralsHistory);
  }

  Future<void> generateCode(BuildContext context) async {
    if (isGenerating.value) return;
    isGenerating.value = true;
    try {
      final payload = await _referralRepo.generateReferralCodeParsed(
        isShowLoader: false,
      );
      if (!context.mounted) return;
      if (payload != null && payload.code.isNotEmpty) {
        activeCode.value = payload.code;
        if (payload.shareMessage.isNotEmpty) {
          shareMessage.value = payload.shareMessage;
        }
        AppToast.showSuccess(context, 'Referral code ready to share!');
        await loadDetails();
      } else {
        AppToast.showError(context, 'Could not generate referral code.');
      }
    } finally {
      isGenerating.value = false;
    }
  }

  void copyCode(BuildContext context) {
    if (activeCode.value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: activeCode.value));
    AppToast.showSuccess(context, 'Referral code copied!');
  }

  void copyShareMessage(BuildContext context) {
    final text = _resolvedShareText();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    AppToast.showSuccess(context, 'Share message copied!');
  }

  Future<void> shareOnWhatsApp(BuildContext context) async {
    final text = _resolvedShareText();
    if (text.isEmpty) {
      AppToast.showError(context, 'Generate a referral code first.');
      return;
    }
    await FileUtils.openFileOrLink(
      'https://wa.me/?text=${Uri.encodeComponent(text)}',
    );
  }

  String _resolvedShareText() {
    if (shareMessage.value.trim().isNotEmpty) return shareMessage.value.trim();
    if (activeCode.value.isEmpty) return '';
    return 'Use my referral code ${activeCode.value} on Qobo One Live to get bonus coins on signup!';
  }

  void selectTab(int index) => selectedTab.value = index;
}
