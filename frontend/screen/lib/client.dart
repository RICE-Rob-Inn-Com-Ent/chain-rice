import 'package:http/http.dart' as http;

// TODO:
// [ ] ConnectRPC dart client to apiUrl; connect_dart gen — https://connectrpc.com/docs/dart/getting-started
// [ ] PASETO interceptor; ConnectException → RiceException
//
/// Default SMITH / API base — override via `--dart-define=SMITH_URL=...` at build time.
Uri smithBaseUrl() {
  const String String fromEnv = String.fromEnvironment('SMITH_URL', defaultValue: 'http://localhost:8080');
  return Uri.parse(fromEnv);
}

/// Minimal HTTP client factory; swap for ConnectRPC Dart when generated stubs land.
http.Client createHttpClient() => http.Client();

Future<http.Response> smithGet(String path, {Map<String, String>? headers}) {
  final Uri Uri base = smithBaseUrl();
  final Uri Uri uri = base.resolve(path.startsWith('/') ? path.substring(1) : path);
  return createHttpClient().get(uri, headers: headers);
}
