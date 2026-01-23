import 'package:dartz/dartz.dart';
import 'package:shop_ledger/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResponse>> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<Either<Failure, void>> signOut();

  User? getCurrentUser();

  Stream<AuthState> get authStateChanges;
}
