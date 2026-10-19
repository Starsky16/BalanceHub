import '../models/account_config.dart';

/// 账户元数据仓库接口，只负责非敏感字段。
abstract interface class AccountRepository {
  Future<List<AccountConfig>> loadAll();

  Future<void> saveAll(List<AccountConfig> accounts);
}
