import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_ledger/features/auth/presentation/pages/login_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/onboarding_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/signup_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/splash_screen.dart';

import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/presentation/pages/add_customer_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/customer_detail_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/customer_list_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/payment_in_page.dart';
import 'package:shop_ledger/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:shop_ledger/features/dashboard/presentation/pages/home_page.dart';
import 'package:shop_ledger/features/dashboard/presentation/pages/more_page.dart';
import 'package:shop_ledger/features/reports/presentation/pages/reports_page.dart';
import 'package:shop_ledger/features/sales/presentation/pages/add_sale_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/add_purchase_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/add_supplier_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/supplier_ledger_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/supplier_list_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // We do NOT watch authStateProvider here to prevent GoRouter from rebuilding
  // matching navigation stack reset on every auth change.
  // Instead, manual redirection is handled in Pages (Login, More, Splash).

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // Simple redirect logic based on current requirement
      // Detailed Auth Guard can be implemented here if needed
      // Currently generic auth flow is handled in Splash
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomerListPage(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddCustomerPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final customer = state.extra as Customer;
                      return CustomerDetailPage(customer: customer);
                    },
                    routes: [
                      GoRoute(
                        path: 'sale',
                        builder: (context, state) {
                          final customer = state.extra as Customer;
                          return AddSalePage(customer: customer);
                        },
                      ),
                      GoRoute(
                        path: 'payment',
                        builder: (context, state) {
                          final customer = state.extra as Customer;
                          return PaymentInPage(customer: customer);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/suppliers',
                builder: (context, state) => const SupplierListPage(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddSupplierPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => const SupplierLedgerPage(),
                    routes: [
                      GoRoute(
                        path: 'purchase',
                        builder: (context, state) => const AddPurchasePage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
