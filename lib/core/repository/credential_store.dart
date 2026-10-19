/// API Key 安全存取接口。
///
/// 实现必须使用系统安全存储，明文不得写入普通存储。
abstract interface class CredentialStore {
  Future<String?> read(String accountId);

  Future<void> write(String accountId, String apiKey);

  Future<void> delete(String accountId);
}
