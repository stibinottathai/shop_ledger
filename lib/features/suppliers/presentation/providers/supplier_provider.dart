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

class SupplierListNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    // Watch auth state to force refresh on user change
    ref.watch(authStateProvider);
    return _fetchSuppliers();
  }

  Future<List<Supplier>> _fetchSuppliers({String? query}) async {
    final repository = ref.read(supplierRepositoryProvider);
    return await repository
        .getSuppliers(query: query)
        .timeout(const Duration(seconds: 10));
  }

  Future<void> searchSuppliers(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSuppliers(query: query));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSuppliers());
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
