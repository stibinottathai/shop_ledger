import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';

class DashboardPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardPage({required this.navigationShell, super.key});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: navigationShell,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12, top: 16),
      decoration: BoxDecoration(
        color: context.cardColor.withOpacity(0.9),
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildNavItem(
              context,
              Icons.grid_view,
              'Dashboard',
              navigationShell.currentIndex == 0,
              () => _goBranch(0),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              Icons.people,
              'Customers',
              navigationShell.currentIndex == 1,
              () => _goBranch(1),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              Icons.local_shipping,
              'Suppliers',
              navigationShell.currentIndex == 2,
              () => _goBranch(2),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              Icons.inventory,
              'Stock',
              navigationShell.currentIndex == 3,
              () => _goBranch(3),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              Icons.account_balance_wallet,
              'Expense',
              navigationShell.currentIndex == 4,
              () => _goBranch(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : context.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : context.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
