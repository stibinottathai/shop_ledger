import 'package:dartz/dartz.dart';
import 'package:shop_ledger/core/error/failures.dart';
import 'package:shop_ledger/core/usecases/usecase.dart';
import 'package:shop_ledger/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}
