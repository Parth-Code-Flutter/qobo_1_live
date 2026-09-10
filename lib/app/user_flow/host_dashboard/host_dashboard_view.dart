import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

/// Self-service host dashboard; financial details use the existing wallet flow.
class HostDashboardView extends StatelessWidget {
  const HostDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Dashboard')),
      body: GetBuilder<UserSessionController>(
        builder: (session) {
          if (!session.isHost) {
            return const Center(child: Text('Host approval is required.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await session.refreshProfileFromApi();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  session.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('Approved Host'),
                if (session.agencyCode.isNotEmpty)
                  Text('Agency: ${session.agencyCode}'),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.live_tv),
                  title: const Text('Go live'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed(Routes.LIVE_ACTION),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Wallet & withdrawals'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.to(
                    () => const WalletView(),
                    binding: WalletBinding(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Gift transactions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed(Routes.GIFT_TRANSACTIONS),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
