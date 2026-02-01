import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/domain/repositories/transaction_repository.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

// Generate mocks
@GenerateNiceMocks([MockSpec<TransactionRepository>()])
import 'transaction_provider_test.mocks.dart';

void main() {
  late MockTransactionRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'customerStatsProvider calculates balance correctly from allTransactionsProvider',
    () async {
      final customerId = 'cust123';
      final transactions = [
        Transaction(
          id: '1',
          customerId: customerId,
          amount: 1000,
          type: TransactionType.sale,
          date: DateTime.now(),
        ),
        Transaction(
          id: '2',
          customerId: customerId,
          amount: 500,
          type: TransactionType.paymentIn,
          date: DateTime.now(),
        ),
        Transaction(
          id: '3',
          customerId: 'other_cust',
          amount: 2000,
          type: TransactionType.sale,
          date: DateTime.now(),
        ),
      ];

      // Mock getAllTransactions
      when(
        mockRepository.getAllTransactions(),
      ).thenAnswer((_) async => transactions);

      // Wait for the provider to load
      final allTransactions = await container.read(
        allTransactionsProvider.future,
      );
      expect(allTransactions.length, 3);

      // Check stats for specific customer
      final stats = container.read(customerStatsProvider(customerId));

      expect(stats.totalSales, 1000);
      expect(stats.totalPaid, 500);
      expect(stats.outstandingBalance, 500); // 1000 - 500
    },
  );

  test('customerStatsProvider handles empty transactions gracefully', () async {
    when(mockRepository.getAllTransactions()).thenAnswer((_) async => []);

    final stats = container.read(customerStatsProvider('any_id'));

    expect(stats.totalSales, 0);
    expect(stats.totalPaid, 0);
    expect(stats.outstandingBalance, 0);
  });
}
