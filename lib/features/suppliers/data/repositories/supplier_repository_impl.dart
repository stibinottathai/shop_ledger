import 'package:shop_ledger/features/suppliers/data/datasources/supplier_remote_datasource.dart';
import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:shop_ledger/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:shop_ledger/features/suppliers/data/models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierRemoteDataSource remoteDataSource;

  SupplierRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> addSupplier(Supplier supplier) async {
    return remoteDataSource.addSupplier(SupplierModel.fromEntity(supplier));
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    return remoteDataSource.updateSupplier(SupplierModel.fromEntity(supplier));
  }

  @override
  Future<void> deleteSupplier(String id) async {
    return remoteDataSource.deleteSupplier(id);
  }

  @override
  Future<List<Supplier>> getSuppliers({String? query}) async {
    return remoteDataSource.getSuppliers(query: query);
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    return remoteDataSource.getSupplierById(id);
  }
}
