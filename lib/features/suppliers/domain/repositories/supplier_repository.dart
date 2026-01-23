import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<void> addSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
  Future<List<Supplier>> getSuppliers({String? query});
  Future<Supplier?> getSupplierById(String id);
}
