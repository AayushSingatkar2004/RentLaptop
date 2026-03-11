// lib/data/repositories/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final _sb = Supabase.instance.client;

  Future<void> signIn(String email, String password) async {
    final res = await _sb.auth.signInWithPassword(
      email: email, password: password,
    );
    if (res.session == null) throw Exception('Invalid credentials');
  }

  Future<void> signOut() async => _sb.auth.signOut();

  bool get isLoggedIn => _sb.auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _sb.auth.onAuthStateChange;
}