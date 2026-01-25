import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shop_ledger/core/error/failures.dart';
import 'package:shop_ledger/core/usecases/usecase.dart';
import 'package:shop_ledger/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpUseCase implements UseCase<AuthResponse, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(SignUpParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
      username: params.username,
      shopName: params.shopName,
      phone: params.phone,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String username;
  final String shopName;
  final String phone;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.username,
    required this.shopName,
    required this.phone,
  });

  @override
  List<Object> get props => [email, password, username, shopName];
}
