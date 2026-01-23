import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/features/customer/data/models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<void> addCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<List<CustomerModel>> getCustomers({String? query});
  Future<CustomerModel?> getCustomerById(String id);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  CustomerRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    final customerData = customer.toJson();
    if (customer.id == null) {
      customerData['id'] = _uuid.v4();
    }

    // Add user_id to associate with current user
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      customerData['user_id'] = userId;
    }

    // Set timestamps
    final now = DateTime.now().toIso8601String();
    customerData['updated_at'] = now;
    // customerData['created_at'] = now; // Column might not exist as per previous error, keeping commented out just in case

    await supabaseClient.from('customers').insert(customerData);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await supabaseClient.from('customers').delete().eq('id', id);
  }

  @override
  Future<List<CustomerModel>> getCustomers({String? query}) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      print('Fetching customers for user: $userId (Query: $query)');

      if (userId == null) {
        print('Error: User not logged in, cannot fetch customers');
        return [];
      }

      var queryBuilder = supabaseClient.from('customers').select();

      // STRICTLY Filter by current user
      queryBuilder = queryBuilder.eq('user_id', userId);

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('name', '%$query%');
      }

      final response = await queryBuilder
          .order('updated_at', ascending: false)
          .withConverter(
            (data) =>
                (data as List).map((e) => CustomerModel.fromJson(e)).toList(),
          );
      print(
        'Successfully fetched ${response.length} customers for user $userId',
      );
      return response;
    } catch (e, stack) {
      print('Error fetching customers: $e');
      print(stack);
      rethrow;
    }
  }

  @override
  Future<CustomerModel?> getCustomerById(String id) async {
    final response = await supabaseClient
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return CustomerModel.fromJson(response);
  }
}
