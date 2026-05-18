import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerServiceController extends GetxController {
  final isLoading = false.obs;

  // Selected tab: 0 = FAQs, 1 = My Tickets, 2 = Live Chat
  final selectedTab = 0.obs;

  // Support Tickets
  final tickets = <Map<String, dynamic>>[
    {
      'id': 'TKT-4890',
      'subject': 'Coin Recharge Delayed',
      'category': 'Payments',
      'status': 'Pending',
      'date': 'May 18, 2026 • 12:45 PM',
      'desc': 'Recharged 5000 Coins via Google Pay but they are not showing in my balance.',
    },
    {
      'id': 'TKT-3810',
      'subject': 'SVIP Badge Missing',
      'category': 'Account & VIP',
      'status': 'Resolved',
      'date': 'May 15, 2026 • 3:20 PM',
      'desc': 'My SVIP avatar ring disappeared. Support restored it successfully.',
    },
  ].obs;

  // FAQs
  final faqs = <Map<String, String>>[
    {
      'q': 'Why is my coin recharge delayed?',
      'a': 'Payment processors can sometimes take up to 10-15 minutes to sync balances. If your coins do not arrive within an hour, please submit a ticket with the transaction ID.'
    },
    {
      'q': 'How do I upgrade to SVIP rank?',
      'a': 'You can upgrade to SVIP through the VIP Store or SVIP tab on your profile page by exchanging Coins.'
    },
    {
      'q': 'How do I report a streamer?',
      'a': 'While inside a live stream, tap on the "Security SOS" or shield icon on the top-right corner to open moderation tools and report bad comments/actions.'
    },
    {
      'q': 'What are Diamond exchanges?',
      'a': 'Diamonds received from viewers during stream gifts can be exchanged directly for Coins inside the Wallet center.'
    },
  ].obs;

  // Search query for FAQs
  final searchController = TextEditingController();
  final filteredFaqs = <Map<String, String>>[].obs;

  // Live Chat messages
  final chatMessages = <Map<String, dynamic>>[
    {
      'sender': 'agent',
      'text': 'Hello! Thanks for reaching out to Qobo One Support. How can we help you today?',
      'time': '6:41 PM',
    },
  ].obs;

  final chatInputController = TextEditingController();
  final isAgentTyping = false.obs;

  @override
  void onInit() {
    super.onInit();
    filteredFaqs.assignAll(faqs);
    searchController.addListener(filterFaqs);
  }

  void filterFaqs() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredFaqs.assignAll(faqs);
    } else {
      filteredFaqs.assignAll(
        faqs.where((faq) => faq['q']!.toLowerCase().contains(query) || faq['a']!.toLowerCase().contains(query)),
      );
    }
  }

  void submitNewTicket(String category, String subject, String desc) {
    if (subject.isEmpty || desc.isEmpty) {
      Get.snackbar('Error', 'Please fill in all ticket details.');
      return;
    }

    final newTkt = {
      'id': 'TKT-${1000 + tickets.length}',
      'subject': subject,
      'category': category,
      'status': 'Open',
      'date': 'Just Now',
      'desc': desc,
    };

    tickets.insert(0, newTkt);
    Get.snackbar(
      'Ticket Submitted!',
      'Our team will review your ticket and reply shortly.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void sendLiveChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    chatMessages.add({
      'sender': 'user',
      'text': text.trim(),
      'time': 'Just Now',
    });
    chatInputController.clear();

    // Trigger mock agent reply
    isAgentTyping.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isAgentTyping.value = false;

    chatMessages.add({
      'sender': 'agent',
      'text': 'We have logged your query about "$text". A live support specialist is reviewing your account history now.',
      'time': 'Just Now',
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    chatInputController.dispose();
    super.onClose();
  }
}
