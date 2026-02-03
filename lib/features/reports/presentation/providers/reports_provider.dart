import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
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
  // Generic chart data
  final List<double> chartSales;
  final List<double> chartPurchases;
  final List<double> chartExpenses;
  final List<String> chartLabels; // Labels for the X-axis
  final String
  chartPeriod; // Description of the period (e.g., "Today", "This Week")

  final List<TopPerformer> topCustomers;
  final List<TopPerformer> topSuppliers;

  const ReportsState({
    required this.totalExpenses,
    required this.totalSales,
    required this.totalPurchases,
    required this.salesGrowth,
    required this.purchaseGrowth,
    required this.chartSales,
    required this.chartPurchases,
    required this.chartExpenses,
    required this.chartLabels,
    required this.chartPeriod,
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
      chartSales: [],
      chartPurchases: [],
      chartExpenses: [],
      chartLabels: [],
      chartPeriod: '',
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
    // Default to "This Month"
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
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
    // Watch auth state to force refresh when user changes (logout/login)
    ref.watch(authStateProvider);
    // Rebuild when transactions update
    ref.watch(transactionUpdateProvider);
    // Rebuild when expenses update
    ref.watch(expenseUpdateProvider);
    // Rebuild when filter updates
    ref.watch(reportsFilterProvider);
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

    DateTime start, end;
    if (filterRange == null) {
      // Fallback default if null (though notifier defaults to This Month)
      final now = DateTime.now();
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      start = filterRange.start;
      end = filterRange.end;
    }

    // Filter transactions in memory
    final transactions = allTransactions
        .where(
          (t) =>
              t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();

    // Fetch filtered expenses
    final expenses = await expenseRepo.getExpenses(
      start: start,
      end: end,
      limit: 2000,
    );

    double totalSales = 0;
    double totalPurchases = 0;
    double totalExpenses = 0;

    // Determine Filter Mode and Setup Buckets
    // Mode 0: Today (Span <= 1 day) -> 4h buckets: 0-4, 4-8, 8-12, 12-16, 16-20, 20-24
    // Mode 1: Week (Span <= 7 days) -> Daily buckets
    // Mode 2: Month/Range (Span > 7 days) -> Monthly buckets? Or if standard range, monthly.

    final duration = end.difference(start);
    List<double> chartSales;
    List<double> chartPurchases;
    List<double> chartExpenses;
    List<String> chartLabels;
    String chartPeriod;

    if (duration.inHours <= 24) {
      // TODAY / SINGLE DAY
      chartPeriod = 'Today';
      chartLabels = ['4 AM', '8 AM', '12 PM', '4 PM', '8 PM', '12 AM'];
      chartSales = List.filled(6, 0.0);
      chartPurchases = List.filled(6, 0.0);
      chartExpenses = List.filled(6, 0.0);

      // Helper to map hour to index
      // 0-4 -> 0, 4-8 -> 1, 8-12 -> 2, 12-16 -> 3, 16-20 -> 4, 20-24 -> 5
      int getIndex(DateTime dt) {
        final localDt = dt.toLocal();
        final h = localDt.hour;
        if (h < 4) return 0;
        if (h < 8) return 1;
        if (h < 12) return 2;
        if (h < 16) return 3;
        if (h < 20) return 4;
        return 5;
      }

      for (var t in transactions) {
        if (t.type == TransactionType.sale) {
          totalSales += t.amount;
          chartSales[getIndex(t.date)] += t.amount;
        } else if (t.type == TransactionType.purchase) {
          totalPurchases += t.amount;
          chartPurchases[getIndex(t.date)] += t.amount;
        }
        // Ignore paymentIn and paymentOut for sales/purchases calculation
      }
      for (var e in expenses) {
        totalExpenses += e.amount;
        chartExpenses[getIndex(e.date)] += e.amount;
      }
    } else if (duration.inDays <= 31) {
      // THIS WEEK or THIS MONTH (Up to 31 days) -> Daily buckets
      chartPeriod = duration.inDays <= 7 ? 'This Week' : 'This Month';

      // Generate labels for the days in range
      // For This Month, standard 1..30/31 labels or Day Names?
      // If > 7 days, Day number (1, 2, 3...) is better.
      // If <= 7 days, Day name (Mon, Tue...) is better.
      final useDayName = duration.inDays <= 7;

      final days = duration.inDays + 1;
      chartSales = List.filled(days, 0.0);
      chartPurchases = List.filled(days, 0.0);
      chartExpenses = List.filled(days, 0.0);

      final DateFormat dayFormat = useDayName
          ? DateFormat('E')
          : DateFormat('d');
      chartLabels = List.generate(
        days,
        (i) => dayFormat.format(start.add(Duration(days: i))),
      );

      for (var t in transactions) {
        final localDate = t.date.toLocal();
        final localDateMidnight = DateTime(
          localDate.year,
          localDate.month,
          localDate.day,
        );
        final startMidnight = DateTime(start.year, start.month, start.day);

        final dayIndex = localDateMidnight.difference(startMidnight).inDays;

        if (dayIndex >= 0 && dayIndex < days) {
          if (t.type == TransactionType.sale) {
            totalSales += t.amount;
            chartSales[dayIndex] += t.amount;
          } else if (t.type == TransactionType.purchase) {
            totalPurchases += t.amount;
            chartPurchases[dayIndex] += t.amount;
          }
        }
      }
      for (var e in expenses) {
        totalExpenses += e.amount;
        final localDate = e.date.toLocal();
        final localDateMidnight = DateTime(
          localDate.year,
          localDate.month,
          localDate.day,
        );
        final startMidnight = DateTime(start.year, start.month, start.day);

        final dayIndex = localDateMidnight.difference(startMidnight).inDays;
        if (dayIndex >= 0 && dayIndex < days) {
          chartExpenses[dayIndex] += e.amount;
        }
      }
    } else {
      // RANGE / MONTHLY
      // If range > 7 days, likely switch to Monthly or just aggregate total?
      // Let's stick to existing "Last 6 Months" logic or "Months in Range".
      // Better: Dynamic months in range.
      // But for simplicity of UI (fixed 6 bars often), let's clamp max bars?
      // Let's implement dynamic monthly buckets for the range.
      chartPeriod = 'History';

      // Count months
      int months = (end.year - start.year) * 12 + end.month - start.month + 1;
      if (months > 6) {
        months =
            6; // Cap at 6 for UI? Or let UI scroll? UI expects 6 fixed currently.
      }
      // If fixed 6, take last 6 months of the range?

      // Actually, if user selects broad range, maybe we just show last 6 months ENDING at Range End.
      final plotEnd = end;

      // Re-align start for bucket logic if we enforce 6 months
      // But if user selected a custom range, they might want to see THAT range.
      // Let's stick to "Last 6 months ending at current selection" OR "Months within selection".
      // Implementation: Fixed 6 buckets ending at 'end'.

      chartSales = List.filled(6, 0.0);
      chartPurchases = List.filled(6, 0.0);
      chartExpenses = List.filled(6, 0.0);
      chartLabels = List.generate(6, (i) {
        final d = DateTime(plotEnd.year, plotEnd.month - (5 - i), 1);
        return DateFormat('MMM').format(d).toUpperCase();
      });

      for (var t in transactions) {
        // Calculate Total for the ACTUAL filtered range (passed in start/end), not just the chart plot
        // Already done in loop above? No, the loop above sums 'totalSales' based on 'transactions' list which IS filtered by 'start'/'end'.
        // So totals are correct for the User Selected Range.

        // Chart data: Only plot if it falls within the 6-month plot window
        if (t.type == TransactionType.sale) {
          totalSales += t.amount; // Wait, this sums it again?
          // NO. 'transactions' list is ALREADY filtered.
          // So iterating it is safe for totals.

          _addToMonthly(chartSales, t.date, t.amount, plotEnd);
        } else if (t.type == TransactionType.purchase) {
          totalPurchases += t.amount;
          _addToMonthly(chartPurchases, t.date, t.amount, plotEnd);
        }
        // Ignore paymentIn and paymentOut for sales/purchases calculation
      }
      // Totals are accumulating?
      // logic error: `totalSales` is inside the loop.
      // But I am iterating `transactions` which IS the filtered list.
      // So `totalSales` will sum up all transactions in the filtered range. Correct.
      // `_addToMonthly` only adds if it falls in the bucket. Correct.

      for (var e in expenses) {
        totalExpenses += e.amount;
        _addToMonthly(chartExpenses, e.date, e.amount, plotEnd);
      }
    }

    // Grouping for top performers
    final customerSales = <String, double>{};
    final supplierPurchases = <String, double>{};

    for (var t in transactions) {
      if (t.type == TransactionType.sale) {
        if (t.customerId != null) {
          customerSales[t.customerId!] =
              (customerSales[t.customerId!] ?? 0) + t.amount;
        }
      } else if (t.type == TransactionType.purchase) {
        if (t.supplierId != null) {
          supplierPurchases[t.supplierId!] =
              (supplierPurchases[t.supplierId!] ?? 0) + t.amount;
        }
      }
    }

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

    // Growth calculation (Optional: Disable or Fix?)
    // Existing logic used hardcoded indices [5] and [4].
    // With dynamic charts, "Growth" is ambiguous (vs last hour? vs last day?).
    // For now, set to 0 to avoid index errors, or implement complex logic.
    // Let's set to 0.0 for safety as "Growth" is mainly valid for Monthly comparison.

    final salesGrowth = 0.0;
    final purchaseGrowth = 0.0;

    return ReportsState(
      totalExpenses: totalExpenses,
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      salesGrowth: salesGrowth,
      purchaseGrowth: purchaseGrowth,
      chartSales: chartSales,
      chartPurchases: chartPurchases,
      chartExpenses: chartExpenses,
      chartLabels: chartLabels,
      chartPeriod: chartPeriod,
      topCustomers: topCustomers,
      topSuppliers: topSuppliers,
    );
  }

  void _addToMonthly(
    List<double> buckets,
    DateTime date,
    double amount,
    DateTime now, // Actually plotEnd
  ) {
    // Bucket 5: Current Month (now)
    // Bucket 4: Now - 1 month
    // ...
    final localDate = date.toLocal();
    final localNow = now
        .toLocal(); // Should be local already but safe to ensure
    final monthDiff =
        (localNow.year - localDate.year) * 12 +
        localNow.month -
        localDate.month;
    if (monthDiff >= 0 && monthDiff < 6) {
      buckets[5 - monthDiff] += amount;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _calculateReports());
  }
}
