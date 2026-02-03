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

// --- Update Counter Provider ---
final expenseUpdateProvider = NotifierProvider<ExpenseUpdateNotifier, int>(
  () => ExpenseUpdateNotifier(),
);

class ExpenseUpdateNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

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
    // Watch for expense updates
    ref.watch(expenseUpdateProvider);
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
    // 1. Optimistic Update: Remove from filtered list locally
    final previousState = state.asData?.value;
    if (previousState != null) {
      state = AsyncData(previousState.where((e) => e.id != id).toList());
    }

    // 2. Optimistic Update: Remove from recent list locally
    ref.read(recentExpensesProvider.notifier).optimisticDelete(id);

    // 3. Perform actual network request
    final repository = ref.read(expenseRepositoryProvider);
    try {
      await repository.deleteExpense(id);

      // 4. Update the totals and other data that relies on aggregation
      ref.invalidate(totalExpenseProvider);

      // Optional: Invalidate recent to fetch the 5th item if one was deleted
      // We delay slightly or just invalidate now. Invalidating might cause loading state.
      // Better to just let it be 4 items until next natural refresh or force silent refresh?
      // ref.invalidate(recentExpensesProvider);
    } catch (e) {
      // Revert if failed (simple restart)
      ref.invalidateSelf();
      ref.invalidate(recentExpensesProvider);
      rethrow;
    }
  }

  void updateFilter(ExpenseFilter filter) {
    ref.read(expenseFilterProvider.notifier).setFilter(filter);
  }
}

// --- Recent Expenses Provider (Top 5) ---
final recentExpensesProvider =
    AsyncNotifierProvider<RecentExpensesNotifier, List<Expense>>(
      () => RecentExpensesNotifier(),
    );

class RecentExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    // Watch for expense updates
    ref.watch(expenseUpdateProvider);
    final repository = ref.watch(expenseRepositoryProvider);
    return await repository.getExpenses(limit: 5);
  }

  void optimisticDelete(String id) {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.where((e) => e.id != id).toList());
    }
  }
}

// --- Total Expense Provider ---
final totalExpenseProvider = FutureProvider.autoDispose<double>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getTotalAmount();
});
