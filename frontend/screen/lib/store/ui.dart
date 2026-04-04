import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui.dart';

// TODO:
// [ ] ThemeMode, Locale, volume; SharedPreferences non-sensitive — https://pub.dev/packages/shared_preferences
//
class UiState {
  const UiState({
    this.themeMode = ThemeMode.system,
    this.drawerOpen = false,
    this.modalKey,
    this.snackMessage,
  });

  final ThemeMode themeMode;
  final bool drawerOpen;
  final String? modalKey;
  final String? snackMessage;

  UiState copyWith({
    ThemeMode? themeMode,
    bool? drawerOpen,
    String? modalKey,
    String? snackMessage,
  }) => UiState(
      themeMode: themeMode ?? this.themeMode,
      drawerOpen: drawerOpen ?? this.drawerOpen,
      modalKey: modalKey ?? this.modalKey,
      snackMessage: snackMessage ?? this.snackMessage,
    );
}

StateNotifierProvider<UiNotifier, UiState> StateNotifierProvider<UiNotifier, UiState> uiStoreProvider = StateNotifierProvider<UiNotifier, UiState>((StateNotifierProviderRef<UiNotifier, UiState> StateNotifierProviderRef<UiNotifier, UiState> ref) => UiNotifier());

class UiNotifier extends StateNotifier<UiState> {
  UiNotifier() : super(const UiState());

  void setTheme(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setDrawer(bool open) => state = state.copyWith(drawerOpen: open);

  void setModal(String? key) => state = state.copyWith(modalKey: key);

  void snack(String? msg) => state = state.copyWith(snackMessage: msg);
}
