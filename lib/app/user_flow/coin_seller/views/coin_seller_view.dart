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

class CoinSellerView extends StatefulWidget {
  const CoinSellerView({super.key});

  @override
  State<CoinSellerView> createState() => _CoinSellerViewState();
}

class _CoinSellerViewState extends State<CoinSellerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CoinSellerController controller = Get.put(CoinSellerController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      _buildStatsHeader(),
                      Spacing.v20,
                      _buildTabs(),
                      Spacing.v16,
                      SizedBox(
                        height: 480,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTransferForm(),
                            _buildRequestsList(),
                            _buildLedgerList(),
                          ],
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: kColorWhite, size: 16),
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
          const SizedBox(width: 36), // spacing balance
        ],
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
                  const AppText(text: 'Seller Balance', fontSize: 12, color: Colors.white70),
                  Spacing.v4,
                  Obx(() => BoldText(
                        text: '${controller.availableCoins.value} Coins',
                        fontSize: 22,
                        color: Colors.amber,
                      )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    SemiBoldText(text: 'Verified Seller', fontSize: 10, color: Colors.amber),
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
                    'Today\'s Sales',
                    'PKR ${controller.todaySalesPkr.value}',
                    Colors.green,
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white12),
              Expanded(
                child: Obx(
                  () => _miniStat(
                    'Total Volume',
                    'PKR ${controller.totalSalesPkr.value}',
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
        SemiBoldText(text: value, fontSize: 15, color: color),
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
        controller: _tabController,
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
          Tab(text: 'Requests'),
          Tab(text: 'Ledger'),
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
          const SemiBoldText(text: 'Transfer Coins to Member', fontSize: 14, color: kColorWhite),
          Spacing.v12,
          AppTextField(
            controller: controller.userIdController,
            hintText: 'Recipient User ID (e.g. user_8829)',
            fillColor: Colors.white10,
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(colors: kColorWhite, fontSize: 13),
          ),
          Spacing.v12,
          AppTextField(
            controller: controller.coinsController,
            hintText: 'Coin Amount',
            textInputType: TextInputType.number,
            fillColor: Colors.white10,
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(colors: kColorWhite, fontSize: 13),
          ),
          Spacing.v16,
          const AppText(
            text: '* Manual transfer instantly sends coins from your balance to the user. Make sure you have received payment before initiating transfers.',
            fontSize: 10,
            color: Colors.white38,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: appButton(
              onPressed: controller.transferCoins,
              buttonText: 'Transfer Now',
              isGradient: true,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return Obx(() {
      if (controller.buyerRequests.isEmpty) {
        return _emptyState(Icons.check_circle_outline_rounded, 'All requests cleared!', 'New purchase requests from members will show here.');
      }
      return ListView.separated(
        itemCount: controller.buyerRequests.length,
        separatorBuilder: (_, __) => Spacing.v10,
        itemBuilder: (_, index) {
          final req = controller.buyerRequests[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SemiBoldText(text: req['userName'], fontSize: 13, color: kColorWhite),
                    AppText(text: req['time'], fontSize: 10, color: Colors.white38),
                  ],
                ),
                Spacing.v4,
                AppText(text: 'User ID: ${req['userId']}', fontSize: 11, color: Colors.white54),
                Spacing.v10,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.diamond_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        SemiBoldText(text: '${req['coins']} Coins', fontSize: 14, color: Colors.amber),
                      ],
                    ),
                    SemiBoldText(text: 'PKR ${req['pricePkr']}', fontSize: 14, color: Colors.green),
                  ],
                ),
                Spacing.v12,
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => controller.rejectRequest(req['id']),
                        child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    Spacing.h12,
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: kColorWhite,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => controller.approveRequest(req),
                        child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
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

  Widget _buildLedgerList() {
    return Obx(() {
      if (controller.salesLedger.isEmpty) {
        return _emptyState(Icons.receipt_long_rounded, 'No transactions found', 'Recent manual and approved coin sales will show here.');
      }
      return ListView.separated(
        itemCount: controller.salesLedger.length,
        separatorBuilder: (_, __) => Spacing.v10,
        itemBuilder: (_, index) {
          final log = controller.salesLedger[index];
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(text: log['buyerName'], fontSize: 12, color: kColorWhite),
                    Spacing.v2,
                    AppText(text: 'ID: ${log['buyerId']}', fontSize: 10, color: Colors.white54),
                    Spacing.v4,
                    AppText(text: log['date'], fontSize: 10, color: Colors.white38),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SemiBoldText(text: '+${log['coins']} Coins', fontSize: 13, color: Colors.amber),
                    Spacing.v2,
                    AppText(text: 'PKR ${log['pricePkr']}', fontSize: 11, color: Colors.green),
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
