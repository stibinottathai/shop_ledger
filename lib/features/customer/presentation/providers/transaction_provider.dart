import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:shop_ledger/features/reports/presentation/providers/reports_provider.dart';
import 'package:shop_ledger/features/customer/data/datasources/transaction_remote_datasource.dart';
import 'package:shop_ledger/features/customer/data/repositories/transaction_repository_impl.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/domain/repositories/transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data Source Provider
final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
      return TransactionRemoteDataSourceImpl(Supabase.instance.client);
    });

// Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final remoteDataSource = ref.watch(transactionRemoteDataSourceProvider);
  return TransactionRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Global update signal
final transactionUpdateProvider =
    NotifierProvider<TransactionUpdateNotifier, int>(
      TransactionUpdateNotifier.new,
    );

class TransactionUpdateNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

// Transaction List Provider Family (grouped by customerId)
final transactionListProvider =
    AsyncNotifierProvider.family<
      TransactionListNotifier,
      List<Transaction>,
      String
    >((arg) => TransactionListNotifier(arg));

class TransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  final String _customerId;

  TransactionListNotifier(this._customerId);

  @override
  Future<List<Transaction>> build() async {
    ref.watch(authStateProvider);
    return _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final repository = ref.read(transactionRepositoryProvider);
    return await repository
        .getTransactions(customerId: _customerId)
        .timeout(const Duration(seconds: 10));
  }

  Future<void> addTransaction(Transaction transaction) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);

      // Small delay to ensure DB consistency before reading back for dashboard
      await Future.delayed(const Duration(milliseconds: 1000));

      // Trigger global update - FORCE REFRESH
      ref.read(dashboardStatsProvider.notifier).refresh();
      ref.read(reportsProvider.notifier).refresh();
      ref.read(transactionUpdateProvider.notifier).increment();

      state = await AsyncValue.guard(() => _fetchTransactions());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.deleteTransaction(transactionId);

      // Small delay for DB
      await Future.delayed(const Duration(milliseconds: 500));

      // Force refresh
      ref.read(dashboardStatsProvider.notifier).refresh();
      ref.read(reportsProvider.notifier).refresh();
      ref.read(transactionUpdateProvider.notifier).increment();

      state = await AsyncValue.guard(() => _fetchTransactions());
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

// All Transactions Provider (Bulk fetch for optimizations)
final allTransactionsProvider =
    AsyncNotifierProvider<AllTransactionsNotifier, List<Transaction>>(
      AllTransactionsNotifier.new,
    );

class AllTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    // Watch auth state to force refresh when user changes (logout/login)
    ref.watch(authStateProvider);

    // Watch transaction update signals for refresh
    ref.watch(transactionUpdateProvider);

    return _fetchAllTransactions();
  }

  Future<List<Transaction>> _fetchAllTransactions() async {
    final repository = ref.read(transactionRepositoryProvider);
    // Assuming repository has a getAllTransactions method.
    // If not, we fall back to getTransactions without args which usually returns all.
    // Based on previous file reads, repository.getAllTransactions() exists.
    return await repository.getAllTransactions().timeout(
      const Duration(seconds: 15),
    );
  }
}

// Stats Provider (Dependent on AllTransactions Provider - In Memory Filtering)
// This solves the N+1 query problem and timeouts for individual customers
final customerStatsProvider = Provider.family<CustomerStats, String>((
  ref,
  customerId,
) {
  final allTransactionsAsync = ref.watch(allTransactionsProvider);

  return allTransactionsAsync.maybeWhen(
    data: (allTransactions) {
      double totalSales = 0;
      double totalPaid = 0;

      // Filter in memory - much faster than N DB calls
      final customerTransactions = allTransactions.where(
        (t) => t.customerId == customerId,
      );

      for (var t in customerTransactions) {
        if (t.type == TransactionType.sale) {
          totalSales += t.amount;
        } else {
          totalPaid += t.amount;
        }
      }

      return CustomerStats(
        totalSales: totalSales,
        totalPaid: totalPaid,
        outstandingBalance: totalSales - totalPaid,
      );
    },
    orElse: () =>
        const CustomerStats(totalSales: 0, totalPaid: 0, outstandingBalance: 0),
  );
});

class CustomerStats {
  final double totalSales;
  final double totalPaid;
  final double outstandingBalance;

  const CustomerStats({
    required this.totalSales,
    required this.totalPaid,
    required this.outstandingBalance,
  });
}
