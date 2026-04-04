import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO:
// [ ] ThemeData light/dark; tokens; MaterialYou when RICE_MATERIAL_YOU — https://api.flutter.dev/flutter/material/ThemeData-class.html
//
StateProvider<ThemeMode> StateProvider<ThemeMode> themeModeProvider = StateProvider<ThemeMode>((StateProviderRef<ThemeMode> StateProviderRef<ThemeMode> ref) => ThemeMode.system);
