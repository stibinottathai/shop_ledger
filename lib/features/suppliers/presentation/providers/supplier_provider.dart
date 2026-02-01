import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:shop_ledger/features/reports/presentation/providers/reports_provider.dart';
import 'package:shop_ledger/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:shop_ledger/features/suppliers/data/repositories/supplier_repository_impl.dart';
import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:shop_ledger/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data Source Provider
final supplierRemoteDataSourceProvider = Provider<SupplierRemoteDataSource>((
  ref,
) {
  return SupplierRemoteDataSourceImpl(Supabase.instance.client);
});

// Repository Provider
final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final remoteDataSource = ref.watch(supplierRemoteDataSourceProvider);
  return SupplierRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Supplier List Provider (AsyncNotifier)
final supplierListProvider =
    AsyncNotifierProvider<SupplierListNotifier, List<Supplier>>(() {
      return SupplierListNotifier();
    });

enum SupplierSortOption { mostToPay, lowestToPay, latestUpdated, latestCreated }

class SupplierListNotifier extends AsyncNotifier<List<Supplier>> {
  SupplierSortOption _sortOption = SupplierSortOption.latestCreated;
  SupplierSortOption get sortOption => _sortOption;

  @override
  Future<List<Supplier>> build() async {
    // Watch auth state to force refresh on user change
    ref.watch(authStateProvider);
    ref.watch(transactionUpdateProvider);

    // Load saved sort option
    final prefs = await SharedPreferences.getInstance();
    final savedSort = prefs.getString('supplier_sort_option');
    if (savedSort != null) {
      _sortOption = SupplierSortOption.values.firstWhere(
        (e) => e.name == savedSort,
        orElse: () => SupplierSortOption.latestCreated,
      );
    }

    return _fetchAndSortSuppliers();
  }

  Future<List<Supplier>> _fetchAndSortSuppliers({String? query}) async {
    final repository = ref.read(supplierRepositoryProvider);
    var suppliers = await repository
        .getSuppliers(query: query)
        .timeout(const Duration(seconds: 10));

    // Apply Sorting
    if (_sortOption == SupplierSortOption.latestCreated) {
      suppliers.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(0);
        final bDate = b.createdAt ?? DateTime(0);
        return bDate.compareTo(aDate); // Descending
      });
      return suppliers;
    }

    // For other sorts, we need transaction data
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final transactions = await transactionRepo.getAllTransactions();

    // Group transactions by supplier
    final Map<String, List<Transaction>> supplierTransactions = {};
    for (var tx in transactions) {
      if (tx.supplierId != null) {
        supplierTransactions.putIfAbsent(tx.supplierId!, () => []).add(tx);
      }
    }

    suppliers.sort((a, b) {
      final aTx = supplierTransactions[a.id] ?? [];
      final bTx = supplierTransactions[b.id] ?? [];

      switch (_sortOption) {
        case SupplierSortOption.mostToPay:
        case SupplierSortOption.lowestToPay:
          final aBalance = _calculateBalance(aTx);
          final bBalance = _calculateBalance(bTx);
          if (_sortOption == SupplierSortOption.mostToPay) {
            return bBalance.compareTo(aBalance); // Descending
          } else {
            return aBalance.compareTo(bBalance); // Ascending
          }

        case SupplierSortOption.latestUpdated:
          final aLast = _getLastTransactionDate(aTx, a.createdAt);
          final bLast = _getLastTransactionDate(bTx, b.createdAt);
          return bLast.compareTo(aLast); // Descending

        case SupplierSortOption.latestCreated:
          return 0;
      }
    });

    return suppliers;
  }

  double _calculateBalance(List<Transaction> transactions) {
    double purchased = 0;
    double paid = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.purchase) {
        purchased += t.amount;
      } else if (t.type == TransactionType.paymentOut) {
        paid += t.amount;
      }
    }
    return purchased - paid;
  }

  DateTime _getLastTransactionDate(
    List<Transaction> transactions,
    DateTime? created,
  ) {
    if (transactions.isEmpty) return created ?? DateTime(0);
    return transactions
        .map((e) => e.date)
        .reduce((curr, next) => curr.isAfter(next) ? curr : next);
  }

  Future<void> setSortOption(SupplierSortOption option) async {
    if (_sortOption == option) return;
    _sortOption = option;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supplier_sort_option', option.name);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndSortSuppliers());
  }

  Future<void> searchSuppliers(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndSortSuppliers(query: query));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndSortSuppliers());
  }

  Future<void> addSupplier(Supplier supplier) async {
    final repository = ref.read(supplierRepositoryProvider);
    await repository.addSupplier(supplier);

    // Trigger global update (good practice for consistency, though less critical than delete)
    // Small delay to ensure DB consistency
    await Future.delayed(const Duration(milliseconds: 1000));
    ref.read(dashboardStatsProvider.notifier).refresh();
    ref.read(reportsProvider.notifier).refresh();
    ref.read(transactionUpdateProvider.notifier).increment();

    await refresh();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final repository = ref.read(supplierRepositoryProvider);
    await repository.updateSupplier(supplier);

    // Trigger global update with forced refresh
    await Future.delayed(const Duration(milliseconds: 1000));
    ref.read(dashboardStatsProvider.notifier).refresh();
    ref.read(reportsProvider.notifier).refresh();
    ref.read(transactionUpdateProvider.notifier).increment();

    await refresh();
  }

  Future<void> deleteSupplier(String id) async {
    final repository = ref.read(supplierRepositoryProvider);
    await repository.deleteSupplier(id);

    // Trigger global update
    // Small delay to ensure DB consistency
    await Future.delayed(const Duration(milliseconds: 1000));
    ref.read(dashboardStatsProvider.notifier).refresh();
    ref.read(reportsProvider.notifier).refresh();
    ref.read(transactionUpdateProvider.notifier).increment();

    await refresh();
  }
}

// Supplier Transaction List Provider (grouped by supplierId)
final supplierTransactionListProvider =
    AsyncNotifierProvider.family<
      SupplierTransactionListNotifier,
      List<Transaction>,
      String
    >((arg) => SupplierTransactionListNotifier(arg));

class SupplierTransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  final String _supplierId;

  SupplierTransactionListNotifier(this._supplierId);

  @override
  Future<List<Transaction>> build() async {
    ref.watch(authStateProvider);
    ref.watch(transactionUpdateProvider);
    return _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final repository = ref.read(transactionRepositoryProvider);
    return await repository.getTransactions(supplierId: _supplierId);
  }
}

// Supplier Stats Provider
final supplierStatsProvider = Provider.family<SupplierStats, String>((
  ref,
  supplierId,
) {
  final transactionsAsync = ref.watch(
    supplierTransactionListProvider(supplierId),
  );

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      double totalPurchased = 0;
      double totalPaid = 0;

      for (var t in transactions) {
        if (t.type == TransactionType.purchase) {
          totalPurchased += t.amount;
        } else {
          totalPaid += t.amount;
        }
      }

      return SupplierStats(
        totalPurchased: totalPurchased,
        totalPaid: totalPaid,
        outstandingBalance: totalPurchased - totalPaid,
      );
    },
    orElse: () => const SupplierStats(
      totalPurchased: 0,
      totalPaid: 0,
      outstandingBalance: 0,
    ),
  );
});

class SupplierStats {
  final double totalPurchased;
  final double totalPaid;
  final double outstandingBalance;

  const SupplierStats({
    required this.totalPurchased,
    required this.totalPaid,
    required this.outstandingBalance,
  });
}

// Supplier Overview Stats Provider (Bulk fetch for list view)
final supplierOverviewStatsProvider =
    FutureProvider<Map<String, SupplierStats>>((ref) async {
      // Watch for updates
      ref.watch(transactionUpdateProvider);

      final transactionRepo = ref.read(transactionRepositoryProvider);
      final transactions = await transactionRepo.getAllTransactions();

      final Map<String, List<Transaction>> supplierTransactions = {};
      for (var tx in transactions) {
        if (tx.supplierId != null) {
          supplierTransactions.putIfAbsent(tx.supplierId!, () => []).add(tx);
        }
      }

      final Map<String, SupplierStats> stats = {};
      supplierTransactions.forEach((id, txs) {
        double totalPurchased = 0;
        double totalPaid = 0;

        for (var t in txs) {
          if (t.type == TransactionType.purchase) {
            totalPurchased += t.amount;
          } else if (t.type == TransactionType.paymentOut) {
            totalPaid += t.amount;
          }
        }

        stats[id] = SupplierStats(
          totalPurchased: totalPurchased,
          totalPaid: totalPaid,
          outstandingBalance: totalPurchased - totalPaid,
        );
      });

      return stats;
    });
