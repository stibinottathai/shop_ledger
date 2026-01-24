import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/features/customer/data/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

abstract class TransactionRemoteDataSource {
  Future<void> addTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getTransactions({
    String? customerId,
    String? supplierId,
  });
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  TransactionRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final data = transaction.toJson();
    if (transaction.id == null) {
      data['id'] = _uuid.v4();
    }

    // Add timestamps
    final now = DateTime.now().toIso8601String();
    data['updated_at'] = now;

    // Add user_id
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      data['user_id'] = user.id;
    }

    // Ensure we don't send nulls if not needed, or let Supabase handle it.
    // However, we need to ensure either customer_id or supplier_id is present.
    if (transaction.customerId == null && transaction.supplierId == null) {
      throw Exception('Transaction must have either customerId or supplierId');
    }

    await supabaseClient.from('transactions').insert(data);
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    String? customerId,
    String? supplierId,
  }) async {
    var query = supabaseClient
        .from('transactions')
        .select('*, customers(name), suppliers(name)');

    // Filter by current user
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      query = query.eq('user_id', user.id);
    }

    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    } else if (supplierId != null) {
      query = query.eq('supplier_id', supplierId);
    }

    final response = await query
        .order('date', ascending: false)
        .withConverter(
          (data) =>
              (data as List).map((e) => TransactionModel.fromJson(e)).toList(),
        );
    return response;
  }
}
