import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/features/customer/data/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

abstract class TransactionRemoteDataSource {
  Future<void> addTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getTransactions(String customerId);
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

    await supabaseClient.from('transactions').insert(data);
  }

  @override
  Future<List<TransactionModel>> getTransactions(String customerId) async {
    final response = await supabaseClient
        .from('transactions')
        .select()
        .eq('customer_id', customerId)
        .order('date', ascending: false) // Most recent first
        .withConverter(
          (data) =>
              (data as List).map((e) => TransactionModel.fromJson(e)).toList(),
        );
    return response;
  }
}
