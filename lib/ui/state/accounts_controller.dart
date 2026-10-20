import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/models/account_config.dart';
import '../../core/models/api_credentials.dart';
import '../../core/models/balance_snapshot.dart';
import '../../core/models/provider_id.dart';
import '../../core/providers/balance_exception.dart';
import '../../core/providers/provider_adapter.dart';
import '../../core/repository/account_repository.dart';
import '../../core/repository/credential_store.dart';

/// 单个账户的余额展示状态。
class AccountBalanceState {
  AccountBalanceState({required this.account});

  AccountConfig account;

  /// 最近一次成功拉取的余额，失败时保留用于灰显。
  BalanceSnapshot? snapshot;

  /// 最近一次刷新错误。
  BalanceException? error;

  bool isLoading = false;
}

/// 账户与余额状态控制器。
class AccountsController extends ChangeNotifier {
  AccountsController({
    required AccountRepository repository,
    required CredentialStore credentialStore,
    required Map<ProviderId, ProviderAdapter> adapters,
  }) : this._(repository, credentialStore, adapters);

  AccountsController._(this._repository, this._credentialStore, this._adapters);

  final AccountRepository _repository;
  final CredentialStore _credentialStore;
  final Map<ProviderId, ProviderAdapter> _adapters;
  final Random _random = Random();

  List<AccountBalanceState> _accounts = [];
  bool _loadingAccounts = false;
  bool _refreshing = false;
  String? _loadError;

  List<AccountBalanceState> get accounts => List.unmodifiable(_accounts);

  bool get loadingAccounts => _loadingAccounts;

  bool get refreshing => _refreshing;

  String? get loadError => _loadError;

  /// 读取账户元数据。
  Future<void> load() async {
    _loadingAccounts = true;
    _loadError = null;
    notifyListeners();
    try {
      final configs = await _repository.loadAll();
      _accounts = configs
          .map((config) => AccountBalanceState(account: config))
          .toList();
    } catch (error) {
      _loadError = '账户数据读取失败：$error';
    } finally {
      _loadingAccounts = false;
      notifyListeners();
    }
  }

  /// 新增账户：先写安全存储，再落账户元数据。
  Future<void> addAccount({
    required ProviderId providerId,
    required String remark,
    required String apiKey,
  }) async {
    final id =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final config = AccountConfig(
      id: id,
      providerId: providerId,
      remark: remark.trim(),
    );

    await _credentialStore.write(id, apiKey.trim());
    _accounts = [..._accounts, AccountBalanceState(account: config)];
    await _persist();
    notifyListeners();
  }

  /// 编辑账户；[apiKey] 为空表示保留原 Key。
  Future<void> updateAccount({
    required String id,
    required String remark,
    String? apiKey,
  }) async {
    final index = _accounts.indexWhere((state) => state.account.id == id);
    if (index < 0) {
      return;
    }

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      await _credentialStore.write(id, apiKey.trim());
    }

    final current = _accounts[index].account;
    _accounts[index].account = AccountConfig(
      id: current.id,
      providerId: current.providerId,
      remark: remark.trim(),
    );
    await _persist();
    notifyListeners();
  }

  /// 删除账户及其 API Key。
  Future<void> deleteAccount(String id) async {
    final remaining = _accounts
        .where((state) => state.account.id != id)
        .toList();
    await _repository.saveAll(remaining.map((state) => state.account).toList());
    _accounts = remaining;
    await _credentialStore.delete(id);
    notifyListeners();
  }

  /// 并行刷新全部账户，单家失败不影响其他账户。
  Future<void> refreshAll() async {
    if (_refreshing || _accounts.isEmpty) {
      return;
    }

    _refreshing = true;
    for (final state in _accounts) {
      state.isLoading = true;
      state.error = null;
    }
    notifyListeners();

    await Future.wait(_accounts.map(_refreshOne));

    _refreshing = false;
    notifyListeners();
  }

  Future<void> _refreshOne(AccountBalanceState state) async {
    try {
      final apiKey = await _credentialStore.read(state.account.id);
      if (apiKey == null || apiKey.isEmpty) {
        throw const BalanceException(
          BalanceErrorKind.unauthorized,
          detail: '本地没有保存 API Key',
        );
      }

      final adapter = _adapters[state.account.providerId];
      if (adapter == null) {
        throw const BalanceException(
          BalanceErrorKind.unknown,
          detail: '没有对应的厂商适配器',
        );
      }

      state.snapshot = await adapter.fetchBalance(
        ApiCredentials(apiKey: apiKey),
      );
      state.error = null;
    } on BalanceException catch (error) {
      state.error = error;
    } catch (error) {
      state.error = BalanceException(
        BalanceErrorKind.unknown,
        detail: error.toString(),
      );
    } finally {
      state.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() {
    return _repository.saveAll(
      _accounts.map((state) => state.account).toList(),
    );
  }
}
