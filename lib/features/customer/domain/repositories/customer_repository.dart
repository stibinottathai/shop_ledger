import 'package:shop_ledger/features/customer/domain/entities/customer.dart';

abstract class CustomerRepository {
  Future<void> addCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  Future<List<Customer>> getCustomers({String? query});
}
