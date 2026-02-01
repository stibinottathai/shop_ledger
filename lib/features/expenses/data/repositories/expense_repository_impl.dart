import 'package:shop_ledger/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:shop_ledger/features/expenses/data/models/expense_model.dart';
import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';
import 'package:shop_ledger/features/expenses/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addExpense(Expense expense) async {
    final expenseModel = ExpenseModel.fromEntity(expense);
    await remoteDataSource.addExpense(expenseModel);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final expenseModel = ExpenseModel.fromEntity(expense);
    await remoteDataSource.updateExpense(expenseModel);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await remoteDataSource.deleteExpense(id);
  }

  @override
  Future<List<Expense>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? category,
    int? limit,
  }) async {
    final models = await remoteDataSource.getExpenses(
      start: start,
      end: end,
      category: category,
      limit: limit,
    );
    return models;
  }

  @override
  Future<double> getTotalAmount() async {
    return await remoteDataSource.getTotalAmount();
  }
}
