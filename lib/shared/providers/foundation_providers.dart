import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_enums.dart';

class AuthState {
  const AuthState({
    required this.currentUserId,
    required this.isAuthenticated,
  });

  const AuthState.unauthenticated()
      : currentUserId = null,
        isAuthenticated = false;

  const AuthState.demoAuthenticated()
      : currentUserId = 'u1',
        isAuthenticated = true;

  final String? currentUserId;
  final bool isAuthenticated;

  AuthState copyWith({
    String? currentUserId,
    bool? isAuthenticated,
  }) {
    return AuthState(
      currentUserId: currentUserId ?? this.currentUserId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

final authStateProvider = StateProvider<AuthState>((ref) {
  return const AuthState.unauthenticated();
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).currentUserId;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.online);
