import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_ledger/features/auth/presentation/pages/change_password_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/login_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/onboarding_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/signup_page.dart';
import 'package:shop_ledger/features/auth/presentation/pages/splash_screen.dart';
import 'package:shop_ledger/features/profile/presentation/pages/profile_page.dart';
import 'package:shop_ledger/features/settings/presentation/pages/settings_page.dart';

import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/pages/add_customer_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/customer_detail_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/customer_list_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/payment_in_page.dart';
import 'package:shop_ledger/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:shop_ledger/features/dashboard/presentation/pages/home_page.dart';
import 'package:shop_ledger/features/customer/presentation/pages/transaction_detail_page.dart';

import 'package:shop_ledger/features/reports/presentation/pages/reports_page.dart';
import 'package:shop_ledger/features/sales/presentation/pages/add_sale_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/add_purchase_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/add_supplier_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/supplier_ledger_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/supplier_list_page.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/payment_out_page.dart';
import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:shop_ledger/features/suppliers/presentation/pages/supplier_transaction_details_page.dart';
import 'package:shop_ledger/features/inventory/presentation/pages/manage_stock_page.dart';
import 'package:shop_ledger/features/inventory/presentation/pages/all_stock_page.dart';
import 'package:shop_ledger/features/expenses/presentation/pages/expenses_page.dart';
import 'package:shop_ledger/features/expenses/presentation/pages/add_expense_page.dart';
import 'package:shop_ledger/features/expenses/presentation/pages/all_expenses_page.dart';
import 'package:shop_ledger/features/inventory/presentation/pages/low_stock_settings_page.dart';

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
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/low-stock-settings',
        builder: (context, state) => const LowStockSettingsPage(),
      ),
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
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfilePage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsPage(),
                    routes: [
                      GoRoute(
                        path: 'change-password',
                        builder: (context, state) => const ChangePasswordPage(),
                      ),
                      GoRoute(
                        path: 'reports',
                        builder: (context, state) => const ReportsPage(),
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
                path: '/customers',
                builder: (context, state) {
                  final filter = state.uri.queryParameters['filter'];
                  final showHighDueOnly = filter == 'highDue';
                  return CustomerListPage(showHighDueOnly: showHighDueOnly);
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) {
                      final customerToEdit = state.extra as Customer?;
                      return AddCustomerPage(customerToEdit: customerToEdit);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      if (state.extra is! Customer) {
                        return const CustomerListPage();
                      }
                      final customer = state.extra as Customer;
                      return CustomerDetailPage(customer: customer);
                    },
                    routes: [
                      GoRoute(
                        path: 'sale',
                        builder: (context, state) {
                          if (state.extra is! Customer) {
                            return const CustomerListPage();
                          }
                          final customer = state.extra as Customer;
                          return AddSalePage(customer: customer);
                        },
                      ),
                      GoRoute(
                        path: 'payment',
                        builder: (context, state) {
                          if (state.extra is! Customer) {
                            return const CustomerListPage();
                          }
                          final customer = state.extra as Customer;
                          return PaymentInPage(customer: customer);
                        },
                      ),
                      GoRoute(
                        path: 'transaction',
                        builder: (context, state) {
                          final extras = state.extra as Map<String, dynamic>?;
                          if (extras == null) return const CustomerListPage();

                          final customer = extras['customer'] as Customer;
                          final transaction =
                              extras['transaction'] as Transaction;
                          return TransactionDetailPage(
                            customer: customer,
                            transaction: transaction,
                          );
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
                    builder: (context, state) {
                      final supplierToEdit = state.extra as Supplier?;
                      return AddSupplierPage(supplierToEdit: supplierToEdit);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      if (state.extra is! Supplier) {
                        return const SupplierListPage();
                      }
                      final supplier = state.extra as Supplier;
                      return SupplierLedgerPage(supplier: supplier);
                    },
                    routes: [
                      GoRoute(
                        path: 'purchase',
                        builder: (context, state) {
                          if (state.extra is! Supplier) {
                            return const SupplierListPage();
                          }
                          final supplier = state.extra as Supplier;
                          return AddPurchasePage(supplier: supplier);
                        },
                      ),
                      GoRoute(
                        path: 'payment',
                        builder: (context, state) {
                          if (state.extra is! Supplier) {
                            return const SupplierListPage();
                          }
                          final supplier = state.extra as Supplier;
                          return PaymentOutPage(supplier: supplier);
                        },
                      ),
                      GoRoute(
                        path: 'transaction',
                        builder: (context, state) {
                          final transaction = state.extra as Transaction;
                          return SupplierTransactionDetailsPage(
                            transaction: transaction,
                          );
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
                path: '/inventory',
                builder: (context, state) => const ManageStockPage(),
                routes: [
                  GoRoute(
                    path: 'all',
                    builder: (context, state) => const AllStockPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ExpensesPage(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddExpensePage(),
                  ),
                  GoRoute(
                    path: 'all',
                    builder: (context, state) => const AllExpensesPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
