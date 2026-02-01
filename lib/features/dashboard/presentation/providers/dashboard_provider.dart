import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:shop_ledger/features/settings/presentation/providers/settings_provider.dart';

class DashboardStats {
  final double todaysSale;
  final double todaysCollection;
  final double todaysPurchase;
  final double todaysPaymentOut;
  final double totalSales;
  final double totalPurchases;
  final double toGet;
  final double toGive;
  final int highDueCustomerCount;
  final double creditLimit;

  const DashboardStats({
    required this.todaysSale,
    required this.todaysCollection,
    required this.todaysPurchase,
    required this.todaysPaymentOut,
    required this.totalSales,
    required this.totalPurchases,
    required this.toGet,
    required this.toGive,
    required this.highDueCustomerCount,
    this.creditLimit = 5000.0,
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
    print('DashboardStatsNotifier: _calculateStats started');
    try {
      print(
        'DashboardStatsNotifier: Fetching transactions from allTransactionsProvider...',
      );

      // Use the cached allTransactionsProvider instead of making a new API call
      final transactions = await ref.read(allTransactionsProvider.future);

      print(
        'DashboardStatsNotifier: Fetched ${transactions.length} transactions',
      );

      double todaysSale = 0;
      double todaysCollection = 0;
      double todaysPurchase = 0;
      double todaysPaymentOut = 0;
      double totalSales = 0;
      double totalPurchases = 0;
      double totalPaymentIn = 0;
      double totalPaymentOut = 0;

      final now = DateTime.now();

      final settings = ref.read(settingsProvider);
      final creditLimit = settings.maxCreditLimit;

      // Calculate customer balances
      final customerBalances = <String, double>{};

      print('DashboardStatsNotifier: Processing transactions...');
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
          } else if (t.type == TransactionType.purchase) {
            todaysPurchase += t.amount;
          } else if (t.type == TransactionType.paymentOut) {
            todaysPaymentOut += t.amount;
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
          .where((balance) => balance > creditLimit)
          .length;

      print('DashboardStatsNotifier: Stats calculation complete');
      return DashboardStats(
        todaysSale: todaysSale,
        todaysCollection: todaysCollection,
        todaysPurchase: todaysPurchase,
        todaysPaymentOut: todaysPaymentOut,
        totalSales: totalSales,
        totalPurchases: totalPurchases,
        toGet: totalSales - totalPaymentIn,
        toGive: totalPurchases - totalPaymentOut,
        highDueCustomerCount: highDueCustomerCount,
        creditLimit: creditLimit,
      );
    } catch (e, stack) {
      print('DashboardStatsNotifier: Error calculating stats: $e');
      print(stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _calculateStats());
  }
}
