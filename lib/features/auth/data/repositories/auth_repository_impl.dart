import 'package:dartz/dartz.dart';
import 'package:shop_ledger/core/error/failures.dart';
import 'package:shop_ledger/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shop_ledger/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Right(response);
    } on AuthException catch (e) {
      if (e.message.contains('SocketException') ||
          e.message.contains('ClientException') ||
          e.message.contains('host lookup') ||
          e.message.contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.message));
    } on SocketException {
      return const Left(
        ServerFailure('No Internet connection. Please check your network.'),
      );
    } catch (e) {
      // Handle generic network errors if they don't match SocketException
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('host lookup') ||
          e.toString().contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> signUp({
    required String email,
    required String password,
    required String username,
    required String shopName,
    required String phone,
  }) async {
    try {
      final response = await remoteDataSource.signUp(
        email: email,
        password: password,
        username: username,
        shopName: shopName,
        phone: phone,
      );
      return Right(response);
    } on AuthException catch (e) {
      if (e.message.contains('SocketException') ||
          e.message.contains('ClientException') ||
          e.message.contains('host lookup') ||
          e.message.contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.message));
    } on SocketException {
      return const Left(
        ServerFailure('No Internet connection. Please check your network.'),
      );
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('host lookup') ||
          e.toString().contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on SocketException {
      return const Left(
        ServerFailure('No Internet connection. Please check your network.'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  User? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Stream<AuthState> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, AuthResponse>> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await remoteDataSource.verifyOtp(
        email: email,
        token: token,
      );
      return Right(response);
    } on AuthException catch (e) {
      if (e.message.contains('SocketException') ||
          e.message.contains('ClientException') ||
          e.message.contains('host lookup') ||
          e.message.contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.message));
    } on SocketException {
      return const Left(
        ServerFailure('No Internet connection. Please check your network.'),
      );
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('host lookup') ||
          e.toString().contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPasswordForEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.resetPasswordForEmail(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      if (e.message.contains('SocketException') ||
          e.message.contains('ClientException') ||
          e.message.contains('host lookup') ||
          e.message.contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.message));
    } on SocketException {
      return const Left(
        ServerFailure('No Internet connection. Please check your network.'),
      );
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('host lookup') ||
          e.toString().contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.updatePassword(newPassword: newPassword);
      return const Right(null);
    } on AuthException catch (e) {
      if (e.message.contains('SocketException') ||
          e.message.contains('ClientException') ||
          e.message.contains('host lookup') ||
          e.message.contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.message));
    } on SocketException {
      return const Left(
        ServerFailure('No Internet connection. Please check your network.'),
      );
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('host lookup') ||
          e.toString().contains('Network is unreachable')) {
        return const Left(
          ServerFailure('No Internet connection. Please check your network.'),
        );
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
