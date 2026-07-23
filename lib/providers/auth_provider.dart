import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'chat_provider.dart';
import 'dart:io';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._authService, this._ref) : super(const AsyncValue.loading()) {
    _checkExistingSession();
  }

  final AuthService _authService;
  final Ref _ref;

  Future<void> _checkExistingSession() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signUp(email: email, password: password, username: username);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile({String? username, String? bio, File? avatarFile}) async {
    final updated = await _authService.updateProfile(username: username, bio: bio, avatarFile: avatarFile);
    state = AsyncValue.data(updated);
  }

  Future<void> signOut() async {
    _ref.read(chatServiceProvider).disconnect();
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
  return AuthController(ref.watch(authServiceProvider), ref);
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).value;
});