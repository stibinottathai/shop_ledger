import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/inventory/presentation/widgets/manage_items_sheet.dart';
import 'package:shop_ledger/features/settings/presentation/widgets/business_card_sheet.dart';
import 'package:shop_ledger/features/settings/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Manage Items
          _buildSettingsTile(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Manage Items',
            subtitle: 'Add or edit items in your inventory',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => const ManageItemsSheet(),
              );
            },
          ),
          const SizedBox(height: 12),

          // Privacy Mode Toggle
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                'Hide sensitive amounts on dashboard',
                style: GoogleFonts.inter(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ),
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

          // App Theme
          _buildSettingsTile(
            context,
            icon: Icons.brightness_6_outlined,
            title: 'App Theme',
            subtitle: _getThemeModeName(settingsState.themeMode),
            onTap: () =>
                _showThemeSelector(context, notifier, settingsState.themeMode),
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

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  void _showThemeSelector(
    BuildContext context,
    SettingsNotifier notifier,
    ThemeMode currentMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Choose Theme',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                title: 'System Default',
                mode: ThemeMode.system,
                currentMode: currentMode,
                onTap: (mode) {
                  notifier.setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              _buildThemeOption(
                context,
                title: 'Light Mode',
                mode: ThemeMode.light,
                currentMode: currentMode,
                onTap: (mode) {
                  notifier.setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              _buildThemeOption(
                context,
                title: 'Dark Mode',
                mode: ThemeMode.dark,
                currentMode: currentMode,
                onTap: (mode) {
                  notifier.setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required Function(ThemeMode) onTap,
  }) {
    final isSelected = mode == currentMode;
    return ListTile(
      onTap: () => onTap(mode),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
