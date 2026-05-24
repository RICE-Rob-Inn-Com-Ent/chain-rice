import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screenshot/screenshot.dart';

import 'controller.dart';
import 'errors.dart';

/// «Зір» BARD: знімки поверхні та (за можливості) нативного WebView.
///
/// Пакет [screenshot] не захоплює Android/iOS PlatformView у [RepaintBoundary]
/// (обмеження Flutter). Для пікселів самої сторінки використовуйте
/// [RiceWebController.captureNativeViewportPng] або [captureFullPage].
class WebVision {
  WebVision({ScreenshotController? screenshotController})
      : screenshot = screenshotController ?? ScreenshotController();

  final ScreenshotController screenshot;

  /// Знімок Flutter-шару всередині [Screenshot] (адресний рядок, прогрес тощо).
  ///
  /// Вміст нативного WebView може бути порожнім — див. документацію пакета screenshot.
  Future<Uint8List> captureVisibleArea({
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 32),
  }) async {
    try {
      final bytes = await screenshot.capture(pixelRatio: pixelRatio, delay: delay);
      if (bytes == null || bytes.isEmpty) {
        throw RiceBrowserException('captureVisibleArea: порожній буфер PNG.');
      }
      return bytes;
    } catch (e, st) {
      if (e is RiceBrowserException) rethrow;
      Error.throwWithStackTrace(
        RiceBrowserException('captureVisibleArea не вдался.', cause: e),
        st,
      );
    }
  }

  /// Найкращий доступний знімок сторінки: спочатку нативний WebView, інакше [captureVisibleArea].
  Future<Uint8List> captureFullPage(
    RiceWebController controller, {
    double? pixelRatio,
  }) async {
    final engine = controller.engine;
    if (engine != null) {
      try {
        final native = await engine.takeScreenshot(
          screenshotConfiguration: ScreenshotConfiguration(
            compressFormat: CompressFormat.PNG,
            afterScreenUpdates: true,
          ),
        );
        if (native != null && native.isNotEmpty) {
          return native;
        }
      } catch (_) {
        /* ігноруємо — часто обмеження ОС / sandbox; нижче Flutter-шар */
      }
    }
    return captureVisibleArea(pixelRatio: pixelRatio);
  }
}
