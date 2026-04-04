import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth.dart';

// TODO:
// [ ] AuthNotifier token/user/claims; flutter_secure_storage — https://pub.dev/packages/flutter_secure_storage
//
class User {
  const User({required this.id, this.email, this.name});

  final String id;
  final String? email;
  final String? name;
}

class Session {
  const Session({required this.token, this.expiresAt});

  final String token;
  final String? expiresAt;
}

class AuthState {
  const AuthState({
    this.user,
    this.session,
    this.permissions = const <String>[],
  });

  final User? user;
  final Session? session;
  final List<String> permissions;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    Session? session,
    List<String>? permissions,
  }) => AuthState(
      user: user ?? this.user,
      session: session ?? this.session,
      permissions: permissions ?? this.permissions,
    );
}

StateNotifierProvider<AuthNotifier, AuthState> StateNotifierProvider<AuthNotifier, AuthState> authStoreProvider = StateNotifierProvider<AuthNotifier, AuthState>((StateNotifierProviderRef<AuthNotifier, AuthState> StateNotifierProviderRef<AuthNotifier, AuthState> ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void setUser(User? user) => state = state.copyWith(user: user);

  void setSession(Session? session) => state = state.copyWith(session: session);

  void setPermissions(List<String> p) => state = state.copyWith(permissions: p);

  void clear() => state = const AuthState();

  bool hasPermission(String p) => state.permissions.contains(p);
}
