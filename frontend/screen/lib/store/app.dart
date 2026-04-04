import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

// TODO:
// [ ] StateNotifierProvider AppState initialized/error/version — https://riverpod.dev/docs/providers/state_notifier_provider
// [ ] boot: config, auth, websocket
//
class AppSettings {
  const AppSettings([this.data = const <String, Object?>{}]);

  final Map<String, Object?> data;
}

class AppShellState {
  const AppShellState({
    this.locale = 'en',
    this.isLoading = false,
    this.error,
    this.settings = const AppSettings(),
  });

  final String locale;
  final bool isLoading;
  final Object? error;
  final AppSettings settings;

  AppShellState copyWith({
    String? locale,
    bool? isLoading,
    Object? error,
    AppSettings? settings,
  }) => AppShellState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      settings: settings ?? this.settings,
    );
}

StateNotifierProvider<AppShellNotifier, AppShellState> StateNotifierProvider<AppShellNotifier, AppShellState> appStoreProvider = StateNotifierProvider<AppShellNotifier, AppShellState>((StateNotifierProviderRef<AppShellNotifier, AppShellState> StateNotifierProviderRef<AppShellNotifier, AppShellState> ref) => AppShellNotifier());

class AppShellNotifier extends StateNotifier<AppShellState> {
  AppShellNotifier() : super(const AppShellState());

  void setLocale(String l) => state = state.copyWith(locale: l);

  void setLoading(bool v) => state = state.copyWith(isLoading: v);

  void setError(Object? e) => state = state.copyWith(error: e);

  void patchSettings(AppSettings s) => state = state.copyWith(settings: s);
}
