import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:shop_ledger/core/error/failures.dart';
import 'package:shop_ledger/core/usecases/usecase.dart';
import 'package:shop_ledger/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyOtpUseCase implements UseCase<AuthResponse, VerifyOtpParams> {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(email: params.email, token: params.token);
  }
}

class VerifyOtpParams extends Equatable {
  final String email;
  final String token;

  const VerifyOtpParams({required this.email, required this.token});

  @override
  List<Object?> get props => [email, token];
}
