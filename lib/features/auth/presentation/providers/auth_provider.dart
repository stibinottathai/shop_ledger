import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shop_ledger/core/usecases/usecase.dart';
import 'package:shop_ledger/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:shop_ledger/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shop_ledger/features/auth/domain/repositories/auth_repository.dart';
import 'package:shop_ledger/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:shop_ledger/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:shop_ledger/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:shop_ledger/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data Sources
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(Supabase.instance.client);
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

// Use Cases
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.read(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.read(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.read(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

// Auth State (User Session)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return repository.authStateChanges;
});

// Auth Controller
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(
        signInUseCase: ref.read(signInUseCaseProvider),
        signUpUseCase: ref.read(signUpUseCaseProvider),
        signOutUseCase: ref.read(signOutUseCaseProvider),
      );
    });

class AuthController extends StateNotifier<AsyncValue<void>> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;

  AuthController({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await _signInUseCase(
      SignInParams(email: email, password: password),
    );
    result.fold(
      (failure) => state = AsyncValue.error(
        failure,
        StackTrace.current,
      ), // Assuming Failure has a message
      (response) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String shopName,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    final result = await _signUpUseCase(
      SignUpParams(
        email: email,
        password: password,
        username: username,
        shopName: shopName,
        phone: phone,
      ),
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (response) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final result = await _signOutUseCase(NoParams()); // NoParams is standard
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}
