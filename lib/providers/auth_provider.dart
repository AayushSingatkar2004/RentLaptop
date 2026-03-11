// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';

class AuthNotifier extends StateNotifier<bool> {
  final AuthRepository _repo;

  AuthNotifier(this._repo)
      : super(Supabase.instance.client.auth.currentSession != null);

  Future<void> login(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 10));

      if (res.session == null) {
        throw Exception('Login failed: session is null');
      }
      state = true;
    } on AuthException catch (e) {
      throw Exception('Auth error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Timed out! Check:\n'
          '- supabase_config.dart has correct URL\n'
          '- AndroidManifest.xml has INTERNET permission\n'
          '- Phone has internet access'
        );
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = false;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});