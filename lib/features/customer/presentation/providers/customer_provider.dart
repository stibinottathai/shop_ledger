import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:shop_ledger/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/repositories/customer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data Source Provider
final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource>((
  ref,
) {
  return CustomerRemoteDataSourceImpl(Supabase.instance.client);
});

// Repository Provider
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final remoteDataSource = ref.watch(customerRemoteDataSourceProvider);
  return CustomerRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Customer List Provider (AsyncNotifier)
final customerListProvider =
    AsyncNotifierProvider<CustomerListNotifier, List<Customer>>(() {
      return CustomerListNotifier();
    });

class CustomerListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    // Watch auth state to force refresh on user change
    ref.watch(authStateProvider);
    return _fetchCustomers();
  }

  Future<List<Customer>> _fetchCustomers({String? query}) async {
    final repository = ref.read(customerRepositoryProvider);
    return await repository
        .getCustomers(query: query)
        .timeout(const Duration(seconds: 10));
  }

  Future<void> searchCustomers(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers(query: query));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  Future<void> addCustomer(Customer customer) async {
    // Ideally we shouldn't trigger state reload here directly
    // but for simplicity in this task we'll add it.
    // Better approach: return Future and let UI handle success/loading
    final repository = ref.read(customerRepositoryProvider);
    await repository.addCustomer(customer);
    // Refresh list to include new customer
    await refresh();
  }

  Future<void> deleteCustomer(String id) async {
    final repository = ref.read(customerRepositoryProvider);
    await repository.deleteCustomer(id);
    await refresh();
  }
}
