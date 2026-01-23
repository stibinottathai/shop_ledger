import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop_ledger/features/suppliers/data/models/supplier_model.dart';
import 'package:flutter/foundation.dart';

abstract class SupplierRemoteDataSource {
  Future<void> addSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);
  Future<List<SupplierModel>> getSuppliers({String? query});
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  SupplierRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> addSupplier(SupplierModel supplier) async {
    final supplierData = supplier.toJson();
    if (supplier.id == null) {
      supplierData['id'] = _uuid.v4();
    }

    final userId = supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      supplierData['user_id'] = userId;
    }

    final now = DateTime.now().toIso8601String();
    supplierData['updated_at'] = now;

    await supabaseClient.from('suppliers').insert(supplierData);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await supabaseClient.from('suppliers').delete().eq('id', id);
  }

  @override
  Future<List<SupplierModel>> getSuppliers({String? query}) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (kDebugMode) {
        print('Fetching suppliers for user: $userId (Query: $query)');
      }

      if (userId == null) {
        if (kDebugMode) {
          print('Error: User not logged in, cannot fetch suppliers');
        }
        return [];
      }

      var queryBuilder = supabaseClient.from('suppliers').select();

      queryBuilder = queryBuilder.eq('user_id', userId);

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('name', '%$query%');
      }

      final response = await queryBuilder
          .order('updated_at', ascending: false)
          .withConverter(
            (data) =>
                (data as List).map((e) => SupplierModel.fromJson(e)).toList(),
          );
      if (kDebugMode) {
        print(
          'Successfully fetched ${response.length} suppliers for user $userId',
        );
      }
      return response;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error fetching suppliers: $e');
        print(stack);
      }
      rethrow;
    }
  }
}
