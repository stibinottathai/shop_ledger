import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shop_ledger/features/expenses/data/models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<void> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<List<ExpenseModel>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? category,
    int? limit,
  });
  Future<double> getTotalAmount();
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  ExpenseRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    final expenseData = expense.toJson();
    if (expense.id == null) {
      expenseData['id'] = _uuid.v4();
    }

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      expenseData['user_id'] = userId;
    }

    final now = DateTime.now().toIso8601String();
    expenseData['updated_at'] = now;
    // expenseData['created_at'] = now; // Avoiding based on previous errors

    await supabaseClient.from('expenses').insert(expenseData);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    final expenseData = expense.toJson();
    expenseData['updated_at'] = DateTime.now().toIso8601String();

    await supabaseClient
        .from('expenses')
        .update(expenseData)
        .eq('id', expense.id!);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await supabaseClient.from('expenses').delete().eq('id', id);
  }

  @override
  Future<List<ExpenseModel>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? category,
    int? limit,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return [];

    var query = supabaseClient.from('expenses').select();
    query = query.eq('user_id', userId);

    if (start != null) {
      query = query.gte('date', start.toIso8601String());
    }
    if (end != null) {
      query = query.lte('date', end.toIso8601String());
    }
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    var queryBuilder = query.order('date', ascending: false);

    if (limit != null) {
      // We need to verify if supabase_flutter supports .limit() directly on the chain properly
      // usually it's .limit(limit) after order.
      // But we can't chain conditionally easily with 'final response = await ...'
      // so let's use the PostgrestTransformBuilder/FilterBuilder types or just 'limit' on the end.
      // Actually, simple way:
      return await queryBuilder
          .limit(limit)
          .withConverter(
            (data) =>
                (data as List).map((e) => ExpenseModel.fromJson(e)).toList(),
          );
    }

    return await queryBuilder.withConverter(
      (data) => (data as List).map((e) => ExpenseModel.fromJson(e)).toList(),
    );
  }

  @override
  Future<double> getTotalAmount() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return 0.0;

    final response = await supabaseClient
        .from('expenses')
        .select('amount')
        .eq('user_id', userId);

    final data = response as List<dynamic>;
    if (data.isEmpty) return 0.0;

    final total = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    return total;
  }
}
