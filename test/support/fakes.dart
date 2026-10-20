import 'package:balancehub/core/models/account_config.dart';
import 'package:balancehub/core/models/api_credentials.dart';
import 'package:balancehub/core/models/balance_snapshot.dart';
import 'package:balancehub/core/models/provider_id.dart';
import 'package:balancehub/core/providers/balance_exception.dart';
import 'package:balancehub/core/providers/provider_adapter.dart';
import 'package:balancehub/core/repository/account_repository.dart';
import 'package:balancehub/core/repository/credential_store.dart';

/// 测试用内存账户仓库。
class MemoryAccountRepository implements AccountRepository {
  MemoryAccountRepository([List<AccountConfig>? initial])
    : accounts = List.of(initial ?? const []);

  List<AccountConfig> accounts;
  bool failOnLoad = false;

  @override
  Future<List<AccountConfig>> loadAll() async {
    if (failOnLoad) {
      throw const FormatException('测试读取失败');
    }
    return List.of(accounts);
  }

  @override
  Future<void> saveAll(List<AccountConfig> value) async {
    accounts = List.of(value);
  }
}

/// 测试用内存 Key 存储。
class MemoryCredentialStore implements CredentialStore {
  final Map<String, String> keys = {};

  @override
  Future<String?> read(String accountId) async => keys[accountId];

  @override
  Future<void> write(String accountId, String apiKey) async {
    keys[accountId] = apiKey;
  }

  @override
  Future<void> delete(String accountId) async {
    keys.remove(accountId);
  }
}

/// 测试用适配器。
class FakeAdapter implements ProviderAdapter {
  FakeAdapter({required this.id, this.snapshot, this.error});

  @override
  final ProviderId id;

  BalanceSnapshot? snapshot;
  BalanceException? error;
  int calls = 0;

  @override
  Future<BalanceSnapshot> fetchBalance(ApiCredentials credentials) async {
    calls++;
    if (error != null) {
      throw error!;
    }
    return snapshot!;
  }
}
