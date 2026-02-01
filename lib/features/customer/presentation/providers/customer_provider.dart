import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:shop_ledger/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:shop_ledger/features/reports/presentation/providers/reports_provider.dart';
import 'package:shop_ledger/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:shop_ledger/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/repositories/customer_repository.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data Source Provider
final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource>((
  ref,
) {
  return CustomerRemoteDataSourceImpl(Supabase.instance.client);
});

// Repository Provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final remoteDataSource = ref.watch(customerRemoteDataSourceProvider);
  return CustomerRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Customer List Provider (AsyncNotifier)
final customerListProvider =
    AsyncNotifierProvider<CustomerListNotifier, List<Customer>>(() {
      return CustomerListNotifier();
    });

enum CustomerSortOption { mostDue, lowestDue, latestUpdated, latestCreated }

class CustomerListNotifier extends AsyncNotifier<List<Customer>> {
  CustomerSortOption _sortOption = CustomerSortOption.latestCreated;
  CustomerSortOption get sortOption => _sortOption;

  @override
  Future<List<Customer>> build() async {
    // Watch auth state to force refresh on user change
    ref.watch(authStateProvider);
    // Watch transaction updates to re-sort if transactions change
    ref.watch(transactionUpdateProvider);

    // Load saved sort option
    final prefs = await SharedPreferences.getInstance();
    final savedSort = prefs.getString('customer_sort_option');
    if (savedSort != null) {
      _sortOption = CustomerSortOption.values.firstWhere(
        (e) => e.name == savedSort,
        orElse: () => CustomerSortOption.latestCreated,
      );
    }

    return _fetchAndSortCustomers();
  }

  Future<List<Customer>> _fetchAndSortCustomers({String? query}) async {
    final customerRepo = ref.read(customerRepositoryProvider);
    var customers = await customerRepo
        .getCustomers(query: query)
        .timeout(const Duration(seconds: 10));

    // Apply Sorting
    if (_sortOption == CustomerSortOption.latestCreated) {
      // Default sort (usually by updated_at from DB, but let's enforce client side too if needed)
      // Assuming createdAt is populated
      customers.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(0);
        final bDate = b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate); // Descending
      });
      return customers;
    }

    // For other sorts, we need transaction data
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final transactions = await transactionRepo.getAllTransactions().timeout(
      const Duration(seconds: 10),
    );

    // Group transactions by customer
    final Map<String, List<Transaction>> customerTransactions = {};
    for (var tx in transactions) {
      if (tx.customerId != null) {
        customerTransactions.putIfAbsent(tx.customerId!, () => []).add(tx);
      }
    }

    customers.sort((a, b) {
      final aTx = customerTransactions[a.id] ?? [];
      final bTx = customerTransactions[b.id] ?? [];

      switch (_sortOption) {
        case CustomerSortOption.mostDue:
        case CustomerSortOption.lowestDue:
          final aBalance = _calculateBalance(aTx);
          final bBalance = _calculateBalance(bTx);
          if (_sortOption == CustomerSortOption.mostDue) {
            return bBalance.compareTo(aBalance); // Descending
          } else {
            return aBalance.compareTo(bBalance); // Ascending
          }

        case CustomerSortOption.latestUpdated:
          final aLast = _getLastTransactionDate(aTx, a.createdAt);
          final bLast = _getLastTransactionDate(bTx, b.createdAt);
          return bLast.compareTo(aLast); // Descending

        case CustomerSortOption.latestCreated:
          return 0;
      }
    });

    return customers;
  }

  double _calculateBalance(List<Transaction> transactions) {
    double sale = 0;
    double paid = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.sale) {
        sale += t.amount;
      } else if (t.type == TransactionType.paymentIn) {
        paid += t.amount;
      }
    }
    return sale - paid;
  }

  DateTime _getLastTransactionDate(
    List<Transaction> transactions,
    DateTime? created,
  ) {
    if (transactions.isEmpty) return created ?? DateTime(0);
    // Find absolute latest date
    return transactions
        .map((e) => e.date)
        .reduce((curr, next) => curr.isAfter(next) ? curr : next);
  }

  Future<void> setSortOption(CustomerSortOption option) async {
    if (_sortOption == option) return;
    _sortOption = option;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_sort_option', option.name);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndSortCustomers());
  }

  Future<void> searchCustomers(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndSortCustomers(query: query));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndSortCustomers());
  }

  Future<void> addCustomer(Customer customer) async {
    final repository = ref.read(customerRepositoryProvider);
    await repository.addCustomer(customer);
    await refresh();
  }

  Future<void> updateCustomer(Customer customer) async {
    final repository = ref.read(customerRepositoryProvider);
    await repository.updateCustomer(customer);

    await Future.delayed(const Duration(milliseconds: 1000));
    ref.read(dashboardStatsProvider.notifier).refresh();
    ref.read(reportsProvider.notifier).refresh();
    ref.read(transactionUpdateProvider.notifier).increment();

    await refresh();
  }

  Future<void> deleteCustomer(String id) async {
    final repository = ref.read(customerRepositoryProvider);
    await repository.deleteCustomer(id);

    await Future.delayed(const Duration(milliseconds: 1000));
    ref.read(dashboardStatsProvider.notifier).refresh();
    ref.read(reportsProvider.notifier).refresh();
    ref.read(transactionUpdateProvider.notifier).increment();

    await refresh();
  }
}
