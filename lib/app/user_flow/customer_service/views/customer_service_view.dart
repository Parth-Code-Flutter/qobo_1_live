import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/customer_service_controller.dart';

class CustomerServiceView extends GetView<CustomerServiceController> {
  const CustomerServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBarWidget(
        title: 'Customer Support',
        useMaterialAppBar: true,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Obx(() {
              switch (controller.selectedTab.value) {
                case 0:
                  return _buildFaqsTab();
                case 1:
                  return _buildTicketsTab();
                case 2:
                  return _buildLiveChatTab();
                default:
                  return const SizedBox.shrink();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: 48,
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          children: [
            Expanded(child: _tabButton('FAQs', 0)),
            Expanded(child: _tabButton('Tickets', 1)),
            Expanded(child: _tabButton('Live Chat', 2)),
          ],
        );
      }),
    );
  }

  Widget _tabButton(String text, int index) {
    final bool isSelected = controller.selectedTab.value == index;
    return GestureDetector(
      onTap: () => controller.selectedTab.value = index,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [kColorPrimary, Color(0xFFC04B9F)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
        ),
        child: SemiBoldText(
          text: text,
          fontSize: TextStyles.k14FontSize,
          color: isSelected ? kColorWhite : kColorText.withOpacity(0.7),
        ),
      ),
    );
  }

  // FAQ LIST
  Widget _buildFaqsTab() {
    return Column(
      children: [
        // FAQ Search Input
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              icon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
              hintText: 'Search FAQ questions...',
              hintStyle: TextStyles.kBoldPoppins(colors: kColorHint, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.filteredFaqs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.find_in_page_rounded, color: Colors.grey.shade300, size: 64),
                    Spacing.v12,
                    const SemiBoldText(text: 'No Results Found', fontSize: 16, color: kColorText),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.filteredFaqs.length,
              separatorBuilder: (_, __) => Spacing.v12,
              itemBuilder: (context, index) {
                final faq = controller.filteredFaqs[index];
                return Container(
                  decoration: BoxDecoration(
                    color: kColorWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kColorBlack.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.help_outline_rounded, color: kColorPrimary),
                      title: SemiBoldText(
                        text: faq['q'] ?? '',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorText,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: AppText(
                            text: faq['a'] ?? '',
                            fontSize: TextStyles.k12FontSize,
                            color: kColorHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // TICKETS TAB
  Widget _buildTicketsTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          width: double.infinity,
          height: 48,
          child: appButton(
            onPressed: () => _showCreateTicketSheet(),
            buttonText: 'Submit New Ticket',
            buttonColor: kColorPrimary,
            borderRadius: 24,
          ),
        ),
        Expanded(
          child: Obx(() {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.tickets.length,
              separatorBuilder: (_, __) => Spacing.v12,
              itemBuilder: (context, index) {
                final tkt = controller.tickets[index];
                final status = tkt['status'] ?? 'Open';
                final statusColor = status.toString().toLowerCase() == 'resolved'
                    ? Colors.green
                    : (status.toString().toLowerCase() == 'pending' ? Colors.orange : Colors.blue);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kColorWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: kColorBlack.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kColorBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: BoldText(
                              text: tkt['id'] ?? '',
                              fontSize: 10,
                              color: kColorText.withOpacity(0.7),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: BoldText(
                              text: status,
                              fontSize: 9,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      Spacing.v12,
                      SemiBoldText(
                        text: tkt['subject'] ?? '',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorText,
                      ),
                      Spacing.v4,
                      AppText(
                        text: tkt['desc'] ?? '',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorHint,
                      ),
                      Spacing.v12,
                      const Divider(height: 1, color: kColorBackground),
                      Spacing.v8,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            text: 'Category: ${tkt['category']}',
                            fontSize: 10,
                            color: kColorHint,
                          ),
                          AppText(
                            text: tkt['date'] ?? '',
                            fontSize: 10,
                            color: kColorHint,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  void _showCreateTicketSheet() {
    final subCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Payments';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SemiBoldText(
                text: 'Create Support Ticket',
                fontSize: TextStyles.k18FontSize,
                color: kColorText,
              ),
              Spacing.v16,
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Payments', 'Account & VIP', 'Streaming', 'General']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => category = val ?? 'General',
              ),
              Spacing.v16,
              TextField(
                controller: subCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              Spacing.v16,
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              Spacing.v24,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: appButton(
                  onPressed: () {
                    controller.submitNewTicket(category, subCtrl.text, descCtrl.text);
                    Get.back();
                  },
                  buttonText: 'Submit Ticket',
                  buttonColor: kColorPrimary,
                  borderRadius: 24,
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // LIVE CHAT TAB
  Widget _buildLiveChatTab() {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.chatMessages.length + (controller.isAgentTyping.value ? 1 : 0),
              separatorBuilder: (_, __) => Spacing.v12,
              itemBuilder: (context, index) {
                if (index == controller.chatMessages.length && controller.isAgentTyping.value) {
                  return _buildAgentTypingBubble();
                }

                final msg = controller.chatMessages[index];
                final isUser = msg['sender'] == 'user';

                return Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: kColorPrimary.withOpacity(0.1),
                        child: const Icon(Icons.support_agent_rounded, color: kColorPrimary, size: 16),
                      ),
                      Spacing.h8,
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser ? kColorPrimary : Colors.grey.shade100,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? kColorWhite : kColorText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),
        ),
        // Live Chat Message Input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: const BoxDecoration(
            color: kColorWhite,
            border: Border(top: BorderSide(color: kColorBackground)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: controller.chatInputController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyles.kBoldPoppins(colors: kColorHint, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Spacing.h12,
              GestureDetector(
                onTap: () => controller.sendLiveChatMessage(controller.chatInputController.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: kColorPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: kColorWhite, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentTypingBubble() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: kColorPrimary.withOpacity(0.1),
          child: const Icon(Icons.support_agent_rounded, color: kColorPrimary, size: 16),
        ),
        Spacing.h8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(kColorPrimary)),
              ),
              Spacing.h8,
              AppText(text: 'Agent is typing...', fontSize: 11, color: kColorHint),
            ],
          ),
        ),
      ],
    );
  }
}
