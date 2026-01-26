import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:shop_ledger/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';
import 'package:shop_ledger/features/expenses/domain/repositories/expense_repository.dart';

// --- Data Layer Providers ---

final expenseRemoteDataSourceProvider = Provider<ExpenseRemoteDataSource>((
  ref,
) {
  return ExpenseRemoteDataSourceImpl(Supabase.instance.client);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final remoteDataSource = ref.watch(expenseRemoteDataSourceProvider);
  return ExpenseRepositoryImpl(remoteDataSource: remoteDataSource);
});

// --- Filter State ---

class ExpenseFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;

  const ExpenseFilter({this.startDate, this.endDate, this.category});

  ExpenseFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) {
    return ExpenseFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
    );
  }
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilter>(
      () => ExpenseFilterNotifier(),
    );

class ExpenseFilterNotifier extends Notifier<ExpenseFilter> {
  @override
  ExpenseFilter build() {
    // Default to show all expenses since we removed the filter UI
    return const ExpenseFilter();
  }

  void setFilter(ExpenseFilter filter) {
    state = filter;
  }
}

// --- Expense List Provider ---

// --- Expense List Provider (Filtered) ---
final expenseListProvider =
    AsyncNotifierProvider<ExpenseListNotifier, List<Expense>>(
      () => ExpenseListNotifier(),
    );

class ExpenseListNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final filter = ref.watch(expenseFilterProvider);
    return _fetchExpenses(filter);
  }

  Future<List<Expense>> _fetchExpenses(ExpenseFilter filter) async {
    final repository = ref.read(expenseRepositoryProvider);
    return await repository.getExpenses(
      start: filter.startDate,
      end: filter.endDate,
      category: filter.category,
    );
  }

  Future<void> addExpense(Expense expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.addExpense(expense);
    ref.invalidateSelf(); // Refresh filtered list
    ref.invalidate(recentExpensesProvider); // Refresh recent list
    ref.invalidate(totalExpenseProvider); // Refresh total
  }

  Future<void> updateExpense(Expense expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.updateExpense(expense);
    ref.invalidateSelf();
    ref.invalidate(recentExpensesProvider);
    ref.invalidate(totalExpenseProvider);
  }

  Future<void> deleteExpense(String id) async {
    final repository = ref.read(expenseRepositoryProvider);
    await repository.deleteExpense(id);
    ref.invalidateSelf();
    ref.invalidate(recentExpensesProvider);
    ref.invalidate(totalExpenseProvider);
  }

  void updateFilter(ExpenseFilter filter) {
    ref.read(expenseFilterProvider.notifier).setFilter(filter);
  }
}

// --- Recent Expenses Provider (Top 5) ---
final recentExpensesProvider = FutureProvider.autoDispose<List<Expense>>((
  ref,
) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getExpenses(limit: 5);
});

// --- Total Expense Provider ---
final totalExpenseProvider = FutureProvider.autoDispose<double>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getTotalAmount();
});
