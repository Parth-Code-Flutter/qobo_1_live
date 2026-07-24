import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/coin_seller_controller.dart';

class CoinSellerView extends GetView<CoinSellerController> {
  const CoinSellerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isBootstrapping.value) {
              return const Center(
                child: CircularProgressIndicator(color: kColorPrimary),
              );
            }
            return Column(
              children: [
                _header(),
                Expanded(
                  child: controller.isAuthenticated.value
                      ? _buildDashboard()
                      : _buildLogin(),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kColorWhite,
                size: 16,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: SemiBoldText(
                text: 'Coin Seller Center',
                fontSize: 18,
                color: kColorWhite,
              ),
            ),
          ),
          Obx(() {
            if (!controller.isAuthenticated.value) {
              return const SizedBox(width: 36);
            }
            return GestureDetector(
              onTap: controller.logoutSeller,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  color: kColorWhite,
                  size: 18,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SemiBoldText(
              text: 'Seller Login',
              fontSize: 16,
              color: kColorWhite,
            ),
            Spacing.v8,
            const AppText(
              text:
                  'Sign in with your seller_admin credentials to manage coin inventory and transfers.',
              fontSize: 12,
              color: Colors.white60,
            ),
            Spacing.v20,
            AppTextField(
              controller: controller.emailController,
              hintText: 'Seller email',
              textInputType: TextInputType.emailAddress,
              fillColor: Colors.white10,
              borderColor: Colors.white12,
              textStyle: TextStyles.kRegularPoppins(
                colors: kColorWhite,
                fontSize: 13,
              ),
            ),
            Spacing.v12,
            AppTextField(
              controller: controller.passwordController,
              hintText: 'Password',
              obscureText: true,
              fillColor: Colors.white10,
              borderColor: Colors.white12,
              textStyle: TextStyles.kRegularPoppins(
                colors: kColorWhite,
                fontSize: 13,
              ),
            ),
            Spacing.v24,
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 48,
                child: appButton(
                  onPressed: controller.login,
                  buttonText: controller.isLoggingIn.value
                      ? 'Signing in…'
                      : 'Login',
                  isGradient: true,
                  borderRadius: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      color: kColorPrimary,
      onRefresh: () => controller.loadDashboard(isShowLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _buildStatsHeader(),
            Spacing.v20,
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildTabs(),
                  Spacing.v16,
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _buildTransferForm(),
                        _buildLedgerList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: 'Seller Balance',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  Spacing.v4,
                  Obx(
                    () => BoldText(
                      text: '${controller.availableCoins.value} Coins',
                      fontSize: 22,
                      color: Colors.amber,
                    ),
                  ),
                  Obx(() {
                    final email = controller.sellerEmail.value.trim();
                    if (email.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: AppText(
                        text: email,
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    );
                  }),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    SemiBoldText(
                      text: 'Verified Seller',
                      fontSize: 10,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v16,
          const Divider(color: Colors.white12, height: 1),
          Spacing.v16,
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _miniStat(
                    'Revenue',
                    'INR ${controller.totalRevenue.value}',
                    Colors.green,
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white12),
              Expanded(
                child: Obx(
                  () => _miniStat(
                    'Coins Sold',
                    '${controller.totalCoinsSold.value}',
                    Colors.amber,
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white12),
              Expanded(
                child: Obx(
                  () => _miniStat(
                    'Sales',
                    '${controller.totalTransactions.value}',
                    Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        AppText(text: label, fontSize: 11, color: Colors.white54),
        Spacing.v4,
        SemiBoldText(text: value, fontSize: 14, color: color),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: kColorPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: kColorWhite,
        unselectedLabelColor: Colors.white60,
        labelStyle: TextStyles.kSemiBoldPoppins(fontSize: 12),
        tabs: const [
          Tab(text: 'Transfer'),
          Tab(text: 'Sales'),
        ],
      ),
    );
  }

  Widget _buildTransferForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Sell Coins to Member',
            fontSize: 14,
            color: kColorWhite,
          ),
          Spacing.v12,
          AppTextField(
            controller: controller.userIdController,
            hintText: 'User ID / email / phone',
            fillColor: Colors.white10,
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(
              colors: kColorWhite,
              fontSize: 13,
            ),
          ),
          Spacing.v12,
          AppTextField(
            controller: controller.coinsController,
            hintText: 'Coin amount',
            textInputType: TextInputType.number,
            fillColor: Colors.white10,
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(
              colors: kColorWhite,
              fontSize: 13,
            ),
          ),
          Spacing.v12,
          AppTextField(
            controller: controller.priceController,
            hintText: 'Price (INR)',
            textInputType: const TextInputType.numberWithOptions(decimal: true),
            fillColor: Colors.white10,
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(
              colors: kColorWhite,
              fontSize: 13,
            ),
          ),
          Spacing.v16,
          const AppText(
            text:
                '* Coins are deducted from your seller stock and credited to the user wallet. Confirm payment before transferring.',
            fontSize: 10,
            color: Colors.white38,
          ),
          const Spacer(),
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 48,
              child: appButton(
                onPressed: controller.transferCoins,
                buttonText: controller.isTransferring.value
                    ? 'Transferring…'
                    : 'Transfer Now',
                isGradient: true,
                borderRadius: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerList() {
    return Obx(() {
      if (controller.salesLedger.isEmpty) {
        return _emptyState(
          Icons.receipt_long_rounded,
          'No sales yet',
          'Completed coin transfers will appear here.',
        );
      }
      return ListView.separated(
        itemCount: controller.salesLedger.length,
        separatorBuilder: (_, __) => Spacing.v10,
        itemBuilder: (_, index) {
          final log = controller.salesLedger[index];
          final currency = log['currency']?.toString() ?? 'INR';
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: '${log['buyerName']}',
                        fontSize: 12,
                        color: kColorWhite,
                      ),
                      Spacing.v2,
                      AppText(
                        text: 'ID: ${log['buyerId']}',
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                      Spacing.v4,
                      AppText(
                        text: '${log['date']}',
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SemiBoldText(
                      text: '+${log['coins']} Coins',
                      fontSize: 13,
                      color: Colors.amber,
                    ),
                    Spacing.v2,
                    AppText(
                      text: '$currency ${log['price']}',
                      fontSize: 11,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          Spacing.v12,
          SemiBoldText(text: title, fontSize: 14, color: kColorWhite),
          Spacing.v4,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AppText(
              text: subtitle,
              fontSize: 11,
              color: Colors.white38,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
