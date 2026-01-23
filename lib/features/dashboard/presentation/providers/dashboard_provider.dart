import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

class DashboardStats {
  final double todaysSale;
  final double todaysCollection;
  final double totalSales;
  final double totalPurchases;
  final double toGet;
  final double toGive;
  final int highDueCustomerCount;

  const DashboardStats({
    required this.todaysSale,
    required this.todaysCollection,
    required this.totalSales,
    required this.totalPurchases,
    required this.toGet,
    required this.toGive,
    required this.highDueCustomerCount,
  });
}

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStats>(() {
      return DashboardStatsNotifier();
    });

class DashboardStatsNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    // Watch for updates
    final updateCount = ref.watch(transactionUpdateProvider);
    print('DashboardStatsNotifier: build triggered. UpdateCount: $updateCount');
    return _calculateStats();
  }

  Future<DashboardStats> _calculateStats() async {
    final repository = ref.read(transactionRepositoryProvider);
    final transactions = await repository.getTransactions();

    double todaysSale = 0;
    double todaysCollection = 0;
    double totalSales = 0;
    double totalPurchases = 0;
    double totalPaymentIn = 0;
    double totalPaymentOut = 0;

    final now = DateTime.now();

    // Calculate customer balances
    final customerBalances = <String, double>{};

    for (var t in transactions) {
      final isToday =
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day;

      if (isToday) {
        if (t.type == TransactionType.sale) {
          todaysSale += t.amount;
        } else if (t.type == TransactionType.paymentIn) {
          todaysCollection += t.amount;
        }
      }

      // Aggregates
      switch (t.type) {
        case TransactionType.sale:
          totalSales += t.amount;
          if (t.customerId != null) {
            customerBalances.update(
              t.customerId!,
              (value) => value + t.amount,
              ifAbsent: () => t.amount,
            );
          }
          break;
        case TransactionType.purchase:
          totalPurchases += t.amount;
          break;
        case TransactionType.paymentIn:
          totalPaymentIn += t.amount;
          if (t.customerId != null) {
            customerBalances.update(
              t.customerId!,
              (value) => value - t.amount,
              ifAbsent: () => -t.amount,
            );
          }
          break;
        case TransactionType.paymentOut:
          totalPaymentOut += t.amount;
          break;
      }
    }

    final highDueCustomerCount = customerBalances.values
        .where((balance) => balance > 5000)
        .length;

    return DashboardStats(
      todaysSale: todaysSale,
      todaysCollection: todaysCollection,
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      toGet: totalSales - totalPaymentIn,
      toGive: totalPurchases - totalPaymentOut,
      highDueCustomerCount: highDueCustomerCount,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _calculateStats());
  }
}
