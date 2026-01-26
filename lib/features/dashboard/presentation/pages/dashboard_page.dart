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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: navigationShell,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
              Icons.receipt_long,
              'Transactions',
              navigationShell.currentIndex == 3,
              () => _goBranch(3),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              Icons.history,
              'Reports',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).unselectedWidgetColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).unselectedWidgetColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
