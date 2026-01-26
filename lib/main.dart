import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/core/router/app_router.dart';
import 'package:shop_ledger/core/theme/app_theme.dart';
import 'package:shop_ledger/features/settings/presentation/providers/settings_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // TODO: Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://sdcibdhdkbwdzmuzqtwu.supabase.co',
    anonKey: 'sb_publishable_0BoS3JOgkmBr-SQcV6cxQw_0sBKe4VY',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final settingsState = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Shop Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsState.themeMode,
      routerConfig: router,
    );
  }
}
