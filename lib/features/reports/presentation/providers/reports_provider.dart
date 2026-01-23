import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:shop_ledger/features/customer/presentation/providers/customer_provider.dart';
import 'package:shop_ledger/features/suppliers/presentation/providers/supplier_provider.dart';

class ReportsState {
  final double totalSales;
  final double totalPurchases;
  final double salesGrowth;
  final double purchaseGrowth;
  final List<double> monthlySales; // Last 6 months
  final List<double> monthlyPurchases; // Last 6 months
  final List<TopPerformer> topCustomers;
  final List<TopPerformer> topSuppliers;

  const ReportsState({
    required this.totalSales,
    required this.totalPurchases,
    required this.salesGrowth,
    required this.purchaseGrowth,
    required this.monthlySales,
    required this.monthlyPurchases,
    required this.topCustomers,
    required this.topSuppliers,
  });

  factory ReportsState.initial() {
    return const ReportsState(
      totalSales: 0,
      totalPurchases: 0,
      salesGrowth: 0,
      purchaseGrowth: 0,
      monthlySales: [0, 0, 0, 0, 0, 0],
      monthlyPurchases: [0, 0, 0, 0, 0, 0],
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
    return _calculateReports();
  }

  Future<ReportsState> _calculateReports() async {
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);
    final supplierRepo = ref.read(supplierRepositoryProvider);

    final transactions = await transactionRepo.getAllTransactions();

    double totalSales = 0;
    double totalPurchases = 0;

    // Monthly aggregation
    final now = DateTime.now();
    final monthlySales = List<double>.filled(6, 0);
    final monthlyPurchases = List<double>.filled(6, 0);

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
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      salesGrowth: salesGrowth,
      purchaseGrowth: purchaseGrowth,
      monthlySales: monthlySales,
      monthlyPurchases: monthlyPurchases,
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
}
