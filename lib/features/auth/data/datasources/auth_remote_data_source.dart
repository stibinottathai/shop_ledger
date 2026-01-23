import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<void> signOut();

  User? getCurrentUser();

  Stream<AuthState> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    return await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  @override
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  @override
  User? getCurrentUser() {
    return supabaseClient.auth.currentUser;
  }

  @override
  Stream<AuthState> get authStateChanges =>
      supabaseClient.auth.onAuthStateChange;
}
