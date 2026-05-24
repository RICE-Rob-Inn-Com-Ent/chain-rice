import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/strings.g.dart';

const _kLocalePref = 'rice.lang.locale';

/// Persists the chosen [AppLocale] and applies it via [LocaleSettings] (use with [TranslationProvider]).
final class AppLocaleService {
  AppLocaleService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppLocaleService> open() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLocaleService._(prefs);
  }

  /// Applies stored locale, or no-op if none / invalid.
  Future<void> restoreSavedLocale() async {
    final raw = _prefs.getString(_kLocalePref);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      AppLocaleUtils.parse(raw);
    } catch (_) {
      await _prefs.remove(_kLocalePref);
      return;
    }
    setLocale(raw);
  }

  /// Switches active translations and persists [code] (e.g. `en`, `uk`, `de-DE`).
  void setLocale(String code) {
    LocaleSettings.setLocaleRaw(code);
    unawaited(_prefs.setString(_kLocalePref, code));
  }

  /// Same as [setLocale] but accepts the generated enum (e.g. `AppLocale.uk`).
  void setAppLocale(AppLocale locale) {
    LocaleSettings.setLocale(locale);
    unawaited(_prefs.setString(_kLocalePref, locale.languageCode));
  }

  AppLocale get currentLocale => LocaleSettings.currentLocale;

  Stream<AppLocale> get localeStream => LocaleSettings.getLocaleStream();
}
