import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/dating_empty_hero.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/customer_service_controller.dart';

class CustomerServiceView extends GetView<CustomerServiceController> {
  const CustomerServiceView({super.key});

  static const _tabs = ['FAQs', 'Tickets', 'Chat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Customer Support',
        subtitle: 'FAQs, tickets & live help',
        trailingIcon: Icons.support_agent_rounded,
      ),
      body: Column(
        children: [
          Spacing.v12,
          _tabBar(),
          Expanded(
            child: Obx(() {
              switch (controller.selectedTab.value) {
                case 0:
                  return _faqsTab();
                case 1:
                  return _ticketsTab();
                case 2:
                  return _liveChatTab();
                default:
                  return const SizedBox.shrink();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppLightUi.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppLightUi.border),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: Obx(() {
        return Row(
          children: List.generate(_tabs.length, (index) {
            final selected = controller.selectedTab.value == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedTab.value = index,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: selected ? AppLightUi.familyCtaGradient : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppLightUi.pink.withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: SemiBoldText(
                    text: _tabs[index],
                    fontSize: TextStyles.k12FontSize,
                    color: selected ? kColorWhite : AppLightUi.subtitle,
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // ── FAQs ──────────────────────────────────────────────────────────

  Widget _faqsTab() {
    return Column(
      children: [
        _searchField(),
        Expanded(
          child: Obx(() {
            if (controller.filteredFaqs.isEmpty) {
              return _emptyPanel(
                style: DatingEmptyHeroStyle.sparks,
                accent: AppLightUi.violet,
                title: 'No results found',
                subtitle: 'Try another keyword or browse all FAQs.',
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: controller.filteredFaqs.length,
              separatorBuilder: (_, __) => Spacing.v10,
              itemBuilder: (context, index) {
                final faq = controller.filteredFaqs[index];
                return _faqCard(context, faq);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _searchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppLightUi.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppLightUi.border),
        boxShadow: AppLightUi.cardShadow,
      ),
      child: TextField(
        controller: controller.searchController,
        style: TextStyles.kRegularPoppins(
          fontSize: TextStyles.k14FontSize,
          colors: AppLightUi.title,
        ),
        decoration: InputDecoration(
          icon: Icon(
            Icons.search_rounded,
            color: AppLightUi.pink.withValues(alpha: 0.85),
          ),
          hintText: 'Search FAQ questions...',
          hintStyle: TextStyles.kRegularPoppins(
            colors: AppLightUi.muted,
            fontSize: TextStyles.k12FontSize,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _faqCard(BuildContext context, Map<String, String> faq) {
    return Container(
      decoration: AppLightUi.cardDecoration(radius: 18),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppLightUi.violet.withValues(alpha: 0.16),
                  AppLightUi.pink.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: AppLightUi.violet.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: AppLightUi.violet,
              size: 20,
            ),
          ),
          title: SemiBoldText(
            text: faq['q'] ?? '',
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          iconColor: AppLightUi.pink,
          collapsedIconColor: AppLightUi.muted,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppLightUi.cardSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppLightUi.border),
              ),
              child: AppText(
                text: faq['a'] ?? '',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tickets ───────────────────────────────────────────────────────

  Widget _ticketsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: appButton(
              onPressed: _showCreateTicketSheet,
              buttonText: 'Submit New Ticket',
              buttonIcon: const Icon(
                Icons.add_rounded,
                color: kColorWhite,
                size: 18,
              ),
              borderRadius: 16,
              isGradient: true,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.tickets.isEmpty) {
              return _emptyPanel(
                style: DatingEmptyHeroStyle.messages,
                accent: AppLightUi.pink,
                title: 'No tickets yet',
                subtitle: 'Submit a ticket and our team will reply soon.',
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: controller.tickets.length,
              separatorBuilder: (_, __) => Spacing.v12,
              itemBuilder: (_, index) => _ticketCard(controller.tickets[index]),
            );
          }),
        ),
      ],
    );
  }

  Widget _ticketCard(Map<String, dynamic> tkt) {
    final status = tkt['status']?.toString() ?? 'Open';
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppLightUi.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppLightUi.cardSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppLightUi.border),
                ),
                child: SemiBoldText(
                  text: tkt['id']?.toString() ?? '',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.body,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.28),
                  ),
                ),
                child: SemiBoldText(
                  text: status,
                  fontSize: TextStyles.k10FontSize,
                  color: statusColor,
                ),
              ),
            ],
          ),
          Spacing.v12,
          SemiBoldText(
            text: tkt['subject']?.toString() ?? '',
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v6,
          AppText(
            text: tkt['desc']?.toString() ?? '',
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          Spacing.v12,
          Container(height: 1, color: AppLightUi.border),
          Spacing.v10,
          Row(
            children: [
              Icon(Icons.category_rounded, size: 14, color: AppLightUi.violet),
              const SizedBox(width: 5),
              Expanded(
                child: AppText(
                  text: tkt['category']?.toString() ?? 'Support',
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppText(
                text: tkt['date']?.toString() ?? '',
                fontSize: TextStyles.k10FontSize,
                color: AppLightUi.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return const Color(0xFF25D98F);
      case 'pending':
        return const Color(0xFFFFB020);
      default:
        return AppLightUi.cyan;
    }
  }

  void _showCreateTicketSheet() {
    final subCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Payments';

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: AppLightUi.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppLightUi.borderStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Spacing.v16,
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: AppLightUi.familyCtaGradient,
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: kColorWhite,
                        size: 22,
                      ),
                    ),
                    Spacing.h12,
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: 'Create support ticket',
                            fontSize: TextStyles.k16FontSize,
                            color: AppLightUi.title,
                          ),
                          SizedBox(height: 2),
                          AppText(
                            text: 'Our team usually replies within a day.',
                            fontSize: TextStyles.k12FontSize,
                            color: AppLightUi.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacing.v20,
                _sheetFieldLabel('Category'),
                Spacing.v8,
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: _inputDecoration(),
                  dropdownColor: AppLightUi.card,
                  style: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: AppLightUi.title,
                  ),
                  items: ['Payments', 'Account & VIP', 'Streaming', 'General']
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => category = val ?? 'General',
                ),
                Spacing.v16,
                _sheetFieldLabel('Subject'),
                Spacing.v8,
                TextField(
                  controller: subCtrl,
                  style: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: AppLightUi.title,
                  ),
                  decoration: _inputDecoration(hint: 'Short summary'),
                ),
                Spacing.v16,
                _sheetFieldLabel('Description'),
                Spacing.v8,
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  style: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: AppLightUi.title,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Share details so we can help faster',
                  ),
                ),
                Spacing.v24,
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: appButton(
                    onPressed: () {
                      controller.submitNewTicket(
                        category,
                        subCtrl.text,
                        descCtrl.text,
                      );
                      Get.back();
                    },
                    buttonText: 'Submit Ticket',
                    borderRadius: 16,
                    isGradient: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _sheetFieldLabel(String text) {
    return SemiBoldText(
      text: text,
      fontSize: TextStyles.k12FontSize,
      color: AppLightUi.body,
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyles.kRegularPoppins(
        fontSize: TextStyles.k12FontSize,
        colors: AppLightUi.muted,
      ),
      filled: true,
      fillColor: AppLightUi.cardSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppLightUi.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppLightUi.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppLightUi.pink.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  // ── Live Chat ─────────────────────────────────────────────────────

  Widget _liveChatTab() {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.chatMessages.isEmpty) {
              return _emptyPanel(
                style: DatingEmptyHeroStyle.messages,
                accent: AppLightUi.cyan,
                title: 'Start a conversation',
                subtitle: 'Ask anything — an agent will reply here.',
              );
            }

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              itemCount: controller.chatMessages.length +
                  (controller.isAgentTyping.value ? 1 : 0),
              separatorBuilder: (_, __) => Spacing.v12,
              itemBuilder: (context, index) {
                if (index == controller.chatMessages.length &&
                    controller.isAgentTyping.value) {
                  return _agentTypingBubble();
                }

                final msg = controller.chatMessages[index];
                final isUser = msg['sender'] == 'user';
                return _chatBubble(
                  text: msg['text']?.toString() ?? '',
                  isUser: isUser,
                );
              },
            );
          }),
        ),
        _chatComposer(),
      ],
    );
  }

  Widget _chatBubble({required String text, required bool isUser}) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppLightUi.familyCtaGradient,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: kColorWhite,
              size: 18,
            ),
          ),
          Spacing.h8,
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: isUser ? AppLightUi.familyCtaGradient : null,
              color: isUser ? null : AppLightUi.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(color: AppLightUi.border),
              boxShadow: [
                BoxShadow(
                  color: (isUser ? AppLightUi.pink : AppLightUi.title)
                      .withValues(alpha: isUser ? 0.22 : 0.05),
                  blurRadius: isUser ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isUser ? kColorWhite : AppLightUi.title,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chatComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: AppLightUi.card,
          border: const Border(top: BorderSide(color: AppLightUi.border)),
          boxShadow: [
            BoxShadow(
              color: AppLightUi.title.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppLightUi.cardSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppLightUi.border),
                ),
                child: TextField(
                  controller: controller.chatInputController,
                  style: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k14FontSize,
                    colors: AppLightUi.title,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyles.kRegularPoppins(
                      colors: AppLightUi.muted,
                      fontSize: TextStyles.k12FontSize,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: controller.sendLiveChatMessage,
                ),
              ),
            ),
            Spacing.h10,
            GestureDetector(
              onTap: () => controller.sendLiveChatMessage(
                controller.chatInputController.text,
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppLightUi.familyCtaGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppLightUi.pink.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: kColorWhite,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _agentTypingBubble() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppLightUi.familyCtaGradient,
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: kColorWhite,
            size: 18,
          ),
        ),
        Spacing.h8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppLightUi.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppLightUi.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppLightUi.pink,
                ),
              ),
              Spacing.h8,
              const AppText(
                text: 'Agent is typing...',
                fontSize: TextStyles.k10FontSize,
                color: AppLightUi.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyPanel({
    required DatingEmptyHeroStyle style,
    required Color accent,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            decoration: BoxDecoration(
              color: AppLightUi.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppLightUi.border),
              boxShadow: AppLightUi.cardShadow,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppLightUi.card,
                  accent.withValues(alpha: 0.08),
                  AppLightUi.card,
                ],
              ),
            ),
            child: Column(
              children: [
                DatingEmptyHero(
                  style: style,
                  size: 140,
                  accentColors: [accent, AppLightUi.violet],
                ),
                Spacing.v16,
                SemiBoldText(
                  text: title,
                  fontSize: TextStyles.k16FontSize,
                  color: AppLightUi.title,
                  align: TextAlign.center,
                ),
                Spacing.v8,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
