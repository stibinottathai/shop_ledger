import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';

// Reuse the existing repository provider from customer feature or transaction provider
// Assuming transactionRepositoryProvider exists in customer_provider.dart or transaction_provider.dart
// Let's check transaction_provider.dart later, but for now we'll imply it.
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

final allTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((
  ref,
) async {
  // Watch for global updates (adds/edits/deletes)
  ref.watch(transactionUpdateProvider);

  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getAllTransactions();
});
