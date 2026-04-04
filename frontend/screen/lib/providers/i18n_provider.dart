import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO:
// [ ] slang strings; locale from ui; PlatformDispatcher — https://pub.dev/packages/slang
//
/// Matches keys in `lib/i18n/strings.i18n.yaml` until slang codegen is wired.
StateProvider<Locale> StateProvider<Locale> localeProvider = StateProvider<Locale>((StateProviderRef<Locale> StateProviderRef<Locale> ref) => const Locale('en'));
