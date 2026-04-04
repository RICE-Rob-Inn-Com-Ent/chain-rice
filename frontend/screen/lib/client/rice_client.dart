// TODO:
// [ ] typed methods per gen service; retry max from dart-define RETRY_MAX
//
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../env.dart';
import '../rice_keys.dart';

/// Fetches remote Rice values from SMITH — mirrors [RiceProvider] in browser.
Future<Object?> fetchRemoteRice(String key) async {
  final base = RiceEnv.smithBaseUrl.trim();
  if (base.isEmpty) return null;

  if (key.startsWith(RicePrefixes.db)) {
    final path = key.substring(RicePrefixes.db.length);
    final uri = Uri.parse(
      '$base/v1/rice/db/${Uri.encodeComponent(path)}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('rice db: ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  if (key.startsWith(RicePrefixes.ai)) {
    final uri = Uri.parse('$base/v1/rice/ai');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': key}),
    );
    if (res.statusCode != 200) {
      throw Exception('rice ai: ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  return null;
}

// TODO:
// [ ] Add auth headers from secure storage when SMITH requires PASETO/session.
// [ ] Share timeout/retry policy with [frontend/browser/providers/RiceProvider.tsx] via documented env keys.
// [ ] Use connectrpc_dart + types from frontend/gen/ when buf generates Dart stubs.
