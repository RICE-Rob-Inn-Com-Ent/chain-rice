import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Локальні UI-налаштування (тема, мова для інтеграції з `lang` / slang).
class RiceSettingsStore {
  RiceSettingsStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'rice_theme_mode';
  static const _localeTagKey = 'rice_locale_tag';

  static Future<RiceSettingsStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return RiceSettingsStore._(prefs);
  }

  ThemeMode get themeMode {
    final raw = _prefs.getString(_themeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeKey, v);
  }

  /// BCP 47 тег (`uk`, `en`) — підставляється в `Locale` та майбутній slang.
  String? get localeTag => _prefs.getString(_localeTagKey);

  Future<void> setLocaleTag(String? tag) async {
    if (tag == null || tag.isEmpty) {
      await _prefs.remove(_localeTagKey);
    } else {
      await _prefs.setString(_localeTagKey, tag);
    }
  }

  Locale? get locale {
    final tag = localeTag;
    if (tag == null || tag.isEmpty) return null;
    return Locale(tag);
  }
}
