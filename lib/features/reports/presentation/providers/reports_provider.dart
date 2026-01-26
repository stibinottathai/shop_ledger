import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:shop_ledger/features/customer/presentation/providers/customer_provider.dart';
import 'package:shop_ledger/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:shop_ledger/features/expenses/presentation/providers/expense_provider.dart';

class ReportsState {
  final double totalExpenses;
  final double totalSales;
  final double totalPurchases;
  final double salesGrowth;
  final double purchaseGrowth;
  final List<double> monthlySales; // Last 6 months
  final List<double> monthlyPurchases; // Last 6 months
  final List<double> monthlyExpenses; // Last 6 months
  final List<TopPerformer> topCustomers;
  final List<TopPerformer> topSuppliers;

  const ReportsState({
    required this.totalExpenses,
    required this.totalSales,
    required this.totalPurchases,
    required this.salesGrowth,
    required this.purchaseGrowth,
    required this.monthlySales,
    required this.monthlyPurchases,
    required this.monthlyExpenses,
    required this.topCustomers,
    required this.topSuppliers,
  });

  factory ReportsState.initial() {
    return const ReportsState(
      totalExpenses: 0,
      totalSales: 0,
      totalPurchases: 0,
      salesGrowth: 0,
      purchaseGrowth: 0,
      monthlySales: [0, 0, 0, 0, 0, 0],
      monthlyPurchases: [0, 0, 0, 0, 0, 0],
      monthlyExpenses: [0, 0, 0, 0, 0, 0],
      topCustomers: [],
      topSuppliers: [],
    );
  }
}

class TopPerformer {
  final String name;
  final double amount;
  final String subtitle;

  const TopPerformer({
    required this.name,
    required this.amount,
    required this.subtitle,
  });
}

final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, DateTimeRange?>(
      () => ReportsFilterNotifier(),
    );

class ReportsFilterNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() {
    // Default to "Today" or "This Month"?
    // User interface defaults to "Today" (index 0).
    // Let's match typical default.
    // Actually the UI defaults to index 0 which is Today.
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  void setRange(DateTimeRange? range) {
    state = range;
  }
}

final reportsProvider = AsyncNotifierProvider<ReportsNotifier, ReportsState>(
  () {
    return ReportsNotifier();
  },
);

class ReportsNotifier extends AsyncNotifier<ReportsState> {
  @override
  Future<ReportsState> build() async {
    // Rebuild when transactions update
    ref.watch(transactionUpdateProvider);
    // Rebuild when filter updates
    // ref.watch(reportsFilterProvider); // Access inside _calculateReports to use values
    return _calculateReports();
  }

  Future<ReportsState> _calculateReports() async {
    final filterRange = ref.watch(reportsFilterProvider);

    final transactionRepo = ref.read(transactionRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);
    final supplierRepo = ref.read(supplierRepositoryProvider);
    final expenseRepo = ref.read(expenseRepositoryProvider);

    final allTransactions = await transactionRepo.getAllTransactions().timeout(
      const Duration(seconds: 10),
    );

    // Filter transactions in memory
    final transactions = filterRange == null
        ? allTransactions
        : allTransactions
              .where(
                (t) =>
                    t.date.isAfter(
                      filterRange.start.subtract(const Duration(seconds: 1)),
                    ) &&
                    t.date.isBefore(
                      filterRange.end.add(const Duration(seconds: 1)),
                    ),
              )
              .toList();

    // Fetch filtered expenses
    final expenses = await expenseRepo.getExpenses(
      start: filterRange?.start,
      end: filterRange?.end,
      limit: 2000,
    );

    double totalSales = 0;
    double totalPurchases = 0;
    double totalExpenses = 0;

    // Monthly aggregation (Always uses global context or filtered context?)
    // If user filters "Today", "Monthly Sales" chart showing only today's bar is correct for "Performance during selected period".
    // Or do we want the chart to ALWAYS show 6 month history regardless of filter?
    // User asked "filters... make it work". Usually implies the view data should match filter.
    // However, calculating "Growth" (vs previous month) requires data outside the filter if filter is "Today".
    // If filter is "Today", salesGrowth = (Today - LastMonth) / LastMonth? No, usually (Today - Yesterday) or similar for daily.
    // Given the complexity, let's stick to: ReportsState reflects the FILTERED data.
    // Charts will just show what's passed.
    // Growth might be weird if we don't handle it, but let's implement basic filtering first.

    final now = DateTime.now();
    final monthlySales = List<double>.filled(6, 0);
    final monthlyPurchases = List<double>.filled(6, 0);
    final monthlyExpenses = List<double>.filled(6, 0);

    // Grouping for top performers
    final customerSales = <String, double>{};
    final supplierPurchases = <String, double>{};

    for (var t in transactions) {
      if (t.type == TransactionType.sale) {
        totalSales += t.amount;
        _addToMonthly(monthlySales, t.date, t.amount, now);
        if (t.customerId != null) {
          customerSales[t.customerId!] =
              (customerSales[t.customerId!] ?? 0) + t.amount;
        }
      } else if (t.type == TransactionType.purchase) {
        totalPurchases += t.amount;
        _addToMonthly(monthlyPurchases, t.date, t.amount, now);
        if (t.supplierId != null) {
          supplierPurchases[t.supplierId!] =
              (supplierPurchases[t.supplierId!] ?? 0) + t.amount;
        }
      }
    }

    for (var e in expenses) {
      totalExpenses += e.amount;
      _addToMonthly(monthlyExpenses, e.date, e.amount, now);
    }

    // --- Process Expenses ---
    // Fetch expenses
    // I need to import this provider.
    // Assuming imported:
    // final expenseRepo = ref.read(expenseRepositoryProvider);
    // final expenses = await expenseRepo.getExpenses();
    //
    // But wait, ReportsNotifier needs to read expenseRepositoryProvider.
    // I'll modify the loop to sum expenses.

    // START TEMPORARY PLACEHOLDER LOGIC TO BE REPLACED WITH REAL FETCH ONCE IMPORTS ARE IN
    // Actually I can use Ref to get it dynamically? No.
    // I will replace this whole block after adding imports.
    // But I can't split logic easily.
    // I will just return the state with 0 expenses for now to match the signature,
    // then adding imports and logic in next steps.

    // Wait, I changed the constructor already! So I MUST return totalExpenses now or it breaks.
    // So I will return 0 for now and then immediately fix it.

    // Fetch Top Customer
    List<TopPerformer> topCustomers = [];
    if (customerSales.isNotEmpty) {
      final sortedCustomers = customerSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topEntry = sortedCustomers.first;
      final customer = await customerRepo.getCustomerById(topEntry.key);
      topCustomers.add(
        TopPerformer(
          name: customer?.name ?? 'Unknown Customer',
          amount: topEntry.value,
          subtitle: 'Top Customer',
        ),
      );
    }

    // Fetch Top Supplier
    List<TopPerformer> topSuppliers = [];
    if (supplierPurchases.isNotEmpty) {
      final sortedSuppliers = supplierPurchases.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topEntry = sortedSuppliers.first;
      final supplier = await supplierRepo.getSupplierById(topEntry.key);
      topSuppliers.add(
        TopPerformer(
          name: supplier?.name ?? 'Unknown Supplier',
          amount: topEntry.value,
          subtitle: 'Top Supplier',
        ),
      );
    }

    // Growth calculation
    final currentMonthSales = monthlySales.last;
    final prevMonthSales = monthlySales[4];
    final salesGrowth = prevMonthSales > 0
        ? ((currentMonthSales - prevMonthSales) / prevMonthSales) * 100
        : 0.0;

    final currentMonthPurchases = monthlyPurchases.last;
    final prevMonthPurchases = monthlyPurchases[4];
    final purchaseGrowth = prevMonthPurchases > 0
        ? ((currentMonthPurchases - prevMonthPurchases) / prevMonthPurchases) *
              100
        : 0.0;

    return ReportsState(
      totalExpenses: totalExpenses,
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      salesGrowth: salesGrowth,
      purchaseGrowth: purchaseGrowth,
      monthlySales: monthlySales,
      monthlyPurchases: monthlyPurchases,
      monthlyExpenses: monthlyExpenses,
      topCustomers: topCustomers,
      topSuppliers: topSuppliers,
    );
  }

  void _addToMonthly(
    List<double> buckets,
    DateTime date,
    double amount,
    DateTime now,
  ) {
    final monthDiff = (now.year - date.year) * 12 + now.month - date.month;
    if (monthDiff >= 0 && monthDiff < 6) {
      buckets[5 - monthDiff] += amount;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _calculateReports());
  }
}
