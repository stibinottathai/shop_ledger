import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<List<Expense>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? category,
    int? limit,
  });
  Future<double> getTotalAmount();
}
