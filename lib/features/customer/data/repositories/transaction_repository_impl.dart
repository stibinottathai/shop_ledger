import 'package:shop_ledger/features/customer/data/datasources/transaction_remote_datasource.dart';
import 'package:shop_ledger/features/customer/data/models/transaction_model.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await remoteDataSource.addTransaction(
      TransactionModel.fromEntity(transaction),
    );
  }

  @override
  Future<List<Transaction>> getTransactions({
    String? customerId,
    String? supplierId,
  }) async {
    return await remoteDataSource.getTransactions(
      customerId: customerId,
      supplierId: supplierId,
    );
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    return await remoteDataSource.getTransactions();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await remoteDataSource.deleteTransaction(id);
  }
}
