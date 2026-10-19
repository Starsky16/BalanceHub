import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/repository/credential_store.dart';

/// 基于系统安全存储的 API Key 存取实现。
///
/// Windows 走 DPAPI、Android 走 Keystore、Linux 走 libsecret/Keyring。
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// 存储键前缀，避免与其他数据冲突。
  static const String _keyPrefix = 'api_key.';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String accountId) =>
      _storage.read(key: _keyFor(accountId));

  @override
  Future<void> write(String accountId, String apiKey) =>
      _storage.write(key: _keyFor(accountId), value: apiKey);

  @override
  Future<void> delete(String accountId) =>
      _storage.delete(key: _keyFor(accountId));

  String _keyFor(String accountId) => '$_keyPrefix$accountId';
}
