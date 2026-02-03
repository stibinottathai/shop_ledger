import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';

import 'package:shop_ledger/features/settings/presentation/widgets/business_card_sheet.dart';
import 'package:shop_ledger/features/settings/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Mode Toggle
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: SwitchListTile(
              value: settingsState.hideSensitiveData,
              onChanged: (value) {
                notifier.toggleHideSensitiveData(value);
              },
              activeColor: AppColors.primary,
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  settingsState.hideSensitiveData
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'Privacy Mode',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.textPrimary,
                ),
              ),
              subtitle: Text(
                'Hide sensitive amounts on dashboard',
                style: GoogleFonts.inter(
                  color: context.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Theme Selector
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.subtleBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildThemeOption(
                        context,
                        label: 'System',
                        icon: Icons.brightness_auto,
                        isSelected: settingsState.themeMode == ThemeMode.system,
                        onTap: () => notifier.updateThemeMode(ThemeMode.system),
                      ),
                      _buildThemeOption(
                        context,
                        label: 'Light',
                        icon: Icons.light_mode,
                        isSelected: settingsState.themeMode == ThemeMode.light,
                        onTap: () => notifier.updateThemeMode(ThemeMode.light),
                      ),
                      _buildThemeOption(
                        context,
                        label: 'Dark',
                        icon: Icons.dark_mode,
                        isSelected: settingsState.themeMode == ThemeMode.dark,
                        onTap: () => notifier.updateThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Maximum Credit Limit
          _buildSettingsTile(
            context,
            icon: Icons.credit_score,
            title: 'Maximum Credit Limit',
            subtitle: '₹${settingsState.maxCreditLimit.toStringAsFixed(0)}',
            onTap: () {
              final controller = TextEditingController(
                text: settingsState.maxCreditLimit.toStringAsFixed(0),
              );
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: dialogContext.cardColor,
                  title: Text(
                    'Set Credit Limit',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: dialogContext.textPrimary,
                    ),
                  ),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: dialogContext.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      labelStyle: TextStyle(color: dialogContext.textMuted),
                      filled: true,
                      fillColor: dialogContext.subtleBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: dialogContext.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: dialogContext.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      counterText: "",
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => dialogContext.pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: dialogContext.textMuted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text);
                        if (value != null) {
                          notifier.updateMaxCreditLimit(value);
                          dialogContext.pop();
                        }
                      },
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Low Stock Threshold
          _buildSettingsTile(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Low Stock Thresholds',
            subtitle: 'Manage individual item thresholds',
            onTap: () {
              context.push('/low-stock-settings');
            },
          ),

          const SizedBox(height: 12),

          // Test Notification Button
          _buildSettingsTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Test Notification',
            subtitle: 'Check if notifications are working',
            onTap: () async {
              // Test notification by showing a simple notification
              try {
                await notifier.testNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Test notification sent! Check your notification panel.',
                      ),
                      backgroundColor: AppColors.primary,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 12),

          // Business Card
          _buildSettingsTile(
            context,
            icon: Icons.badge_outlined,
            title: 'Share Business Card',
            subtitle: 'Share your business details',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor:
                    Colors.transparent, // Important for rounded corners
                builder: (context) => const BusinessCardSheet(),
              );
            },
          ),

          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: Icons.analytics_outlined,
            title: 'Reports & Analytics',
            subtitle: 'View sales and purchase reports',
            onTap: () => context.push('/home/settings/reports'),
          ),

          const SizedBox(height: 12),

          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Manage your account details',
            onTap: () => context.push('/home/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: context.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: context.textMuted),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? context.textPrimary : context.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? context.textPrimary : context.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
