import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Dominant media colors packaged for `ThemeData` / `ColorScheme` harmonization.
final class ContentThemeFragment {
  const ContentThemeFragment({
    required this.seedColor,
    required this.colorScheme,
    this.palette,
  });

  final Color seedColor;
  final ColorScheme colorScheme;

  /// Present when extracted on the root isolate via [ImageProvider]; omitted for RGBA isolate path.
  final PaletteGenerator? palette;

  /// Minimal [ThemeData] fragment (typically merged with the client shell theme).
  ThemeData toThemeFragment({TextTheme? textTheme}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
    );
  }
}

Color _seedFromPalette(PaletteGenerator palette) {
  final vibrant = palette.vibrantColor?.color;
  final dominant = palette.dominantColor?.color;
  return vibrant ?? dominant ?? const Color(0xFF1565C0);
}

Future<int> _seedArgbFromEncoded(EncodedImage encoded) async {
  final palette = await PaletteGenerator.fromByteData(encoded);
  return _seedFromPalette(palette).toARGB32();
}

/// Loads [provider] on the UI isolate, then quantizes the bitmap (palette work may be heavy).
Future<ContentThemeFragment> contentThemeFromImageProvider(
  ImageProvider provider, {
  Brightness brightness = Brightness.dark,
}) async {
  final palette = await PaletteGenerator.fromImageProvider(provider);
  final seed = _seedFromPalette(palette);
  return ContentThemeFragment(
    seedColor: seed,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    palette: palette,
  );
}

/// RGBA8 bytes (`width * height * 4`); runs quantization off the UI thread via [Isolate.run].
Future<ContentThemeFragment> contentThemeFromRgbaBytes(
  Uint8List rgba,
  int width,
  int height, {
  Brightness brightness = Brightness.dark,
}) async {
  if (rgba.lengthInBytes != width * height * 4) {
    throw ArgumentError('rgba length must be width*height*4');
  }
  final bd = ByteData.sublistView(rgba);
  final encoded = EncodedImage(bd, width: width, height: height);
  final seedArgb = await Isolate.run(() => _seedArgbFromEncoded(encoded));
  final seed = Color(seedArgb);
  return ContentThemeFragment(
    seedColor: seed,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    palette: null,
  );
}
