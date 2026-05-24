import 'package:flutter/foundation.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:url_launcher/url_launcher.dart';

import 'errors.dart';

/// Міст до системного кліпборду та зовнішніх протоколів.
class SystemClipboardBridge {
  /// Копіює в системний буфер комбінацію тексту / посилання та (за наявності) PNG.
  ///
  /// На деяких платформах [SystemClipboard] може бути недоступний (наприклад, web).
  static Future<void> copySmart({
    String? plainText,
    Uint8List? pngBytes,
  }) async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      if (kIsWeb) {
        throw RiceBrowserException(
          'SystemClipboard недоступний у цьому браузерному контексті.',
        );
      }
      throw RiceBrowserException('SystemClipboard недоступний на цій платформі.');
    }
    final item = DataWriterItem();
    final text = (plainText ?? '').trim();
    if (text.isNotEmpty) {
      item.add(Formats.plainText(text));
    }
    if (pngBytes != null && pngBytes.isNotEmpty) {
      item.add(Formats.png(pngBytes));
    }
    if (text.isEmpty && (pngBytes == null || pngBytes.isEmpty)) {
      throw RiceBrowserException('copySmart: немає даних для копіювання.');
    }
    try {
      await clipboard.write([item]);
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Не вдалося записати буфер обміну.', cause: e),
        st,
      );
    }
  }

  /// Елемент для drag & drop (super_drag_and_drop / нативні сесії), той самий формат, що й для кліпборду.
  static DataWriterItem buildDragItem({
    String? plainText,
    Uint8List? pngBytes,
    String? suggestedFileName,
  }) {
    final item = DataWriterItem(suggestedName: suggestedFileName);
    final text = (plainText ?? '').trim();
    if (text.isNotEmpty) {
      item.add(Formats.plainText(text));
    }
    if (pngBytes != null && pngBytes.isNotEmpty) {
      item.add(Formats.png(pngBytes));
    }
    return item;
  }

  /// Відкриває `mailto:`, `tel:`, магазини додатків тощо у зовнішньому застосунку.
  static Future<void> handleExternal(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        throw RiceBrowserException('launchUrl повернув false для $uri');
      }
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('handleExternal: не вдалося відкрити $uri', cause: e),
        st,
      );
    }
  }
}
