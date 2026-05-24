/// Помилки рівня BARD browser (мережа, WebView, кліпборд).
class RiceBrowserException implements Exception {
  RiceBrowserException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (cause == null) {
      return 'RiceBrowserException: $message';
    }
    return 'RiceBrowserException: $message (cause: $cause)';
  }
}
