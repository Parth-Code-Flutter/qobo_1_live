import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/coin_seller/models/seller_sale.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                Spacing.h12,
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: 'Seller portal',
                        fontSize: 16,
                        color: kColorWhite,
                      ),
                      SizedBox(height: 4),
                      AppText(
                        text: 'Secure entry for coin merchants',
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacing.v16,
            const AppText(
              text:
                  'Sign in with your seller_admin credentials. This session is '
                  'isolated from your personal account and only manages coin stock.',
              fontSize: 12,
              color: Colors.white60,
            ),
            Spacing.v20,
            AppTextField(
              controller: controller.emailController,
              hintText: 'Seller email',
              textInputType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              fillColor: Colors.white10,
              borderColor: Colors.white12,
              textStyle: TextStyles.kRegularPoppins(
                colors: kColorWhite,
                fontSize: 13,
              ),
            ),
            Spacing.v12,
            Obx(
              () => AppTextField(
                controller: controller.passwordController,
                hintText: 'Password',
                obscureText: controller.obscurePassword.value,
                autofillHints: const [AutofillHints.password],
                fillColor: Colors.white10,
                borderColor: Colors.white12,
                textStyle: TextStyles.kRegularPoppins(
                  colors: kColorWhite,
                  fontSize: 13,
                ),
                suffix: IconButton(
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
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
                      : 'Sign in',
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
            _buildStockCard(),
            Spacing.v12,
            _buildMetricsRow(),
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

  Widget _buildStockCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.22),
            Colors.black38,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppText(
                text: 'Coin stock',
                fontSize: 13,
                color: Colors.white70,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
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
                      text: 'seller_admin',
                      fontSize: 10,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v12,
          Obx(
            () => BoldText(
              text: '${controller.availableCoins.value}',
              fontSize: 36,
              color: Colors.amber,
            ),
          ),
          const AppText(
            text: 'coins available to sell',
            fontSize: 12,
            color: Colors.white60,
          ),
          Obx(() {
            final email = controller.sellerEmail.value.trim();
            if (email.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppText(
                text: email,
                fontSize: 11,
                color: Colors.white38,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => _miniStat(
                'Revenue',
                'INR ${_formatNumber(controller.totalRevenue.value)}',
                Colors.green,
              ),
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white12),
          Expanded(
            child: Obx(
              () => _miniStat(
                'Coins sold',
                _formatNumber(controller.totalCoinsSold.value.toDouble()),
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
    );
  }

  String _formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
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
          Tab(text: 'Sell / Transfer'),
          Tab(text: 'Recent sales'),
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
            text: 'Sell coins to member',
            fontSize: 14,
            color: kColorWhite,
          ),
          Spacing.v8,
          const AppText(
            text:
                'Enter the buyer’s user ID, email, or phone. Coins leave your '
                'stock and credit their wallet instantly.',
            fontSize: 11,
            color: Colors.white54,
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
                '* Confirm payment received before transferring. A confirmation '
                'prompt will appear before the request is sent.',
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
                    : 'Transfer now',
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
          final sale = controller.salesLedger[index];
          return _saleTile(sale);
        },
      );
    });
  }

  Widget _saleTile(SellerSale sale) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          AppUserAvatar(
            name: sale.displayName,
            imageUrl: sale.avatarUrl,
            size: 42,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: sale.displayName,
                  fontSize: 13,
                  color: kColorWhite,
                ),
                Spacing.v2,
                AppText(
                  text: sale.displayUserId.isNotEmpty
                      ? sale.displayUserId
                      : '—',
                  fontSize: 10,
                  color: Colors.white54,
                ),
                Spacing.v4,
                AppText(
                  text: sale.formattedDate,
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
                text: '+${sale.amount} coins',
                fontSize: 13,
                color: Colors.amber,
              ),
              Spacing.v2,
              AppText(
                text: '${sale.currency} ${_formatNumber(sale.price)}',
                fontSize: 11,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
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
