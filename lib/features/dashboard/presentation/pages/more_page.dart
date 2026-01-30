import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/auth/presentation/pages/login_page.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          context.go('/login');
        }
      });
    });

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: Text('More', style: TextStyle(color: context.textPrimary)),
        centerTitle: true,
        backgroundColor: context.appBarBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: context.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.pop();
                          ref.read(authControllerProvider.notifier).signOut();
                          // Auth state listener will handle redirection, but explicit is fine too
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
