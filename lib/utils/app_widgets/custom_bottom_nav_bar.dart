import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:flutter/material.dart';

/// Custom Bottom Navigation Bar Widget
/// Matches the design with 5 items: Home, Payments, Money, Invest, Salary
/// Active item is highlighted with coral color
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: kColorWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.payment_outlined,
            activeIcon: Icons.payment,
            label: 'Payments',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Money',
            index: 2,
          ),
          _buildNavItem(
            icon: Icons.trending_up_outlined,
            activeIcon: Icons.trending_up,
            label: 'Invest',
            index: 3,
          ),
          _buildNavItem(
            icon: Icons.star_outline,
            activeIcon: Icons.star,
            label: 'Salary',
            index: 4,
          ),
        ],
      ),
    );
  }

  /// Build individual navigation item
  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    // Coral color for active state
    final activeColor = kColorCoral;
    final inactiveColor = kColorGrey76;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              // Label
              AppText(
                text: label,
                style: TextStyles.kRegularLato(
                  fontSize: 12,
                  colors: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

