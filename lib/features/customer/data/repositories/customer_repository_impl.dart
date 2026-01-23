import 'package:shop_ledger/features/customer/data/datasources/customer_remote_datasource.dart';
import 'package:shop_ledger/features/customer/data/models/customer_model.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;

  CustomerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addCustomer(Customer customer) async {
    final customerModel = CustomerModel.fromEntity(customer);
    await remoteDataSource.addCustomer(customerModel);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await remoteDataSource.deleteCustomer(id);
  }

  @override
  Future<List<Customer>> getCustomers({String? query}) async {
    final customerModels = await remoteDataSource.getCustomers(query: query);
    return customerModels;
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final customerModel = await remoteDataSource.getCustomerById(id);
    return customerModel;
  }
}
