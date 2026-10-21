import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/models/account_config.dart';
import '../../core/models/api_credentials.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/balance_snapshot.dart';
import '../../core/models/manual_balance.dart';
import '../../core/models/provider_id.dart';
import '../../core/providers/balance_exception.dart';
import '../../core/providers/provider_adapter.dart';
import '../../core/repository/account_repository.dart';
import '../../core/repository/credential_store.dart';
import '../../core/repository/settings_repository.dart';

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
    required SettingsRepository settingsRepository,
    int autoRefreshMinutes = 10,
  }) : this._(
         repository,
         credentialStore,
         adapters,
         settingsRepository,
         autoRefreshMinutes,
       );

  AccountsController._(
    this._repository,
    this._credentialStore,
    this._adapters,
    this._settingsRepository,
    this._autoRefreshMinutes,
  );

  final AccountRepository _repository;
  final CredentialStore _credentialStore;
  final Map<ProviderId, ProviderAdapter> _adapters;
  final SettingsRepository _settingsRepository;
  final Random _random = Random();

  List<AccountBalanceState> _accounts = [];
  bool _loadingAccounts = false;
  bool _refreshing = false;
  String? _loadError;
  int _autoRefreshMinutes;
  bool _autoRefreshStarted = false;
  Timer? _autoRefreshTimer;

  List<AccountBalanceState> get accounts => List.unmodifiable(_accounts);

  bool get loadingAccounts => _loadingAccounts;

  bool get refreshing => _refreshing;

  String? get loadError => _loadError;

  /// 自动刷新间隔（分钟），0 表示关闭。
  int get autoRefreshMinutes => _autoRefreshMinutes;

  /// 启动定时轮询。
  void startAutoRefresh() {
    if (_autoRefreshStarted) {
      return;
    }
    _autoRefreshStarted = true;
    _restartAutoRefreshTimer();
  }

  /// 修改自动刷新间隔并持久化。
  Future<void> setAutoRefreshMinutes(int minutes) async {
    if (!kAutoRefreshOptions.contains(minutes) ||
        minutes == _autoRefreshMinutes) {
      return;
    }

    final previous = _autoRefreshMinutes;
    _autoRefreshMinutes = minutes;
    try {
      await _settingsRepository.save(AppSettings(autoRefreshMinutes: minutes));
    } catch (error) {
      _autoRefreshMinutes = previous;
      rethrow;
    }

    if (_autoRefreshStarted) {
      _restartAutoRefreshTimer();
    }
    notifyListeners();
  }

  void _restartAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (_autoRefreshMinutes <= 0) {
      return;
    }

    _autoRefreshTimer = Timer.periodic(
      Duration(minutes: _autoRefreshMinutes),
      (_) => unawaited(refreshAll()),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// 读取账户元数据。
  Future<void> load() async {
    _loadingAccounts = true;
    _loadError = null;
    notifyListeners();
    try {
      final configs = await _repository.loadAll();
      _accounts = configs.map((config) {
        final state = AccountBalanceState(account: config);
        if (config.isManual && config.manualBalance != null) {
          state.snapshot = _snapshotFromManual(config.manualBalance!);
        }
        return state;
      }).toList();
    } catch (error) {
      _loadError = '账户数据读取失败：$error';
    } finally {
      _loadingAccounts = false;
      notifyListeners();
    }
  }

  /// 新增账户：API 账户先写安全存储，手动账户直接记录余额。
  Future<void> addAccount({
    required ProviderId providerId,
    required String remark,
    required String apiKey,
    ManualBalance? manualBalance,
  }) async {
    final isManual = providerId == ProviderId.manual;
    if (isManual && manualBalance == null) {
      throw ArgumentError('手动账户需要填写余额');
    }

    final id =
        '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    final config = AccountConfig(
      id: id,
      providerId: providerId,
      remark: remark.trim(),
      manualBalance: isManual ? manualBalance : null,
    );

    if (!isManual) {
      await _credentialStore.write(id, apiKey.trim());
    }

    final state = AccountBalanceState(account: config);
    if (isManual) {
      state.snapshot = _snapshotFromManual(manualBalance!);
    }
    _accounts = [..._accounts, state];
    await _persist();
    notifyListeners();
  }

  /// 编辑账户；API 账户的 [apiKey] 为空表示保留原 Key。
  Future<void> updateAccount({
    required String id,
    required String remark,
    String? apiKey,
    ManualBalance? manualBalance,
  }) async {
    final index = _accounts.indexWhere((state) => state.account.id == id);
    if (index < 0) {
      return;
    }

    final current = _accounts[index].account;
    final isManual = current.isManual;

    if (!isManual && apiKey != null && apiKey.trim().isNotEmpty) {
      await _credentialStore.write(id, apiKey.trim());
    }

    _accounts[index].account = AccountConfig(
      id: current.id,
      providerId: current.providerId,
      remark: remark.trim(),
      manualBalance: isManual ? (manualBalance ?? current.manualBalance) : null,
    );
    if (isManual) {
      final value = _accounts[index].account.manualBalance;
      if (value != null) {
        _accounts[index].snapshot = _snapshotFromManual(value);
      }
    }
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
      if (state.account.isManual) {
        final manual = state.account.manualBalance;
        if (manual == null) {
          throw const BalanceException(
            BalanceErrorKind.unknown,
            detail: '手动账户缺少余额',
          );
        }
        state.snapshot = _snapshotFromManual(manual);
        state.error = null;
        return;
      }

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

  BalanceSnapshot _snapshotFromManual(ManualBalance manual) {
    return BalanceSnapshot(
      totalAvailable: manual.amount,
      currency: manual.currency,
      fetchedAt: manual.updatedAt,
    );
  }

  Future<void> _persist() {
    return _repository.saveAll(
      _accounts.map((state) => state.account).toList(),
    );
  }
}
