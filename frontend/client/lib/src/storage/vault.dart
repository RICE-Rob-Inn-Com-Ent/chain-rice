import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Шифроване сховище для токенів KING та ключів SMITH / SAGE.
class RiceVault {
  RiceVault({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const kingAccessToken = 'king_access_token';
  static const kingRefreshToken = 'king_refresh_token';
  static const sageApiKey = 'sage_api_key';
  static const smithDeviceKey = 'smith_device_key';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearAll() => _storage.deleteAll();
}
