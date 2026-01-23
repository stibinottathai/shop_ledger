import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<void> addTransaction(Transaction transaction);
  Future<List<Transaction>> getTransactions({
    String? customerId,
    String? supplierId,
  });
  Future<List<Transaction>> getAllTransactions();
}
