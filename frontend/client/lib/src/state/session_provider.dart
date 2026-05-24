import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

/// Стан авторизації клієнта .rice (KING / сесія).
enum AuthStatus {
  unknown,
  unauthenticated,
  authenticated,
}

@immutable
class SessionData {
  const SessionData({
    required this.status,
    this.userId,
    this.accessToken,
  });

  final AuthStatus status;
  final String? userId;
  final String? accessToken;

  SessionData copyWith({
    AuthStatus? status,
    String? userId,
    String? accessToken,
  }) {
    return SessionData(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}

@Riverpod(keepAlive: true)
class UserSession extends _$UserSession {
  @override
  SessionData build() =>
      const SessionData(status: AuthStatus.unauthenticated);

  void setAuthenticated({
    required String userId,
    String? accessToken,
  }) {
    state = SessionData(
      status: AuthStatus.authenticated,
      userId: userId,
      accessToken: accessToken,
    );
  }

  void setUnauthenticated() {
    state = const SessionData(status: AuthStatus.unauthenticated);
  }
}
