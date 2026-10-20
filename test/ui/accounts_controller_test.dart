import 'package:balancehub/core/models/balance_snapshot.dart';
import 'package:balancehub/core/models/provider_id.dart';
import 'package:balancehub/core/providers/balance_exception.dart';
import 'package:balancehub/ui/state/accounts_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late MemoryAccountRepository repository;
  late MemoryCredentialStore credentialStore;
  late FakeAdapter adapter;
  late AccountsController controller;
  late BalanceSnapshot snapshot;

  setUp(() {
    repository = MemoryAccountRepository();
    credentialStore = MemoryCredentialStore();
    adapter = FakeAdapter(id: ProviderId.deepSeek);
    controller = AccountsController(
      repository: repository,
      credentialStore: credentialStore,
      adapters: {ProviderId.deepSeek: adapter},
    );
    snapshot = BalanceSnapshot(
      totalAvailable: 12.5,
      currency: 'CNY',
      fetchedAt: DateTime(2026, 10, 19, 12),
    );
  });

  Future<void> addAccount() {
    return controller.addAccount(
      providerId: ProviderId.deepSeek,
      remark: '主账户',
      apiKey: 'sk-test',
    );
  }

  test('新增账户写入 Key 与元数据', () async {
    await addAccount();

    expect(repository.accounts, hasLength(1));
    expect(repository.accounts.single.providerId, ProviderId.deepSeek);
    expect(repository.accounts.single.remark, '主账户');
    expect(credentialStore.keys.values, contains('sk-test'));
  });

  test('刷新成功后写入快照', () async {
    await addAccount();
    adapter.snapshot = snapshot;

    await controller.refreshAll();

    expect(controller.accounts.single.snapshot, same(snapshot));
    expect(controller.accounts.single.error, isNull);
  });

  test('单家失败保留上次快照并记录错误', () async {
    await addAccount();
    adapter.snapshot = snapshot;
    await controller.refreshAll();

    adapter.error = const BalanceException(BalanceErrorKind.unauthorized);
    await controller.refreshAll();

    expect(controller.accounts.single.snapshot, same(snapshot));
    expect(
      controller.accounts.single.error?.kind,
      BalanceErrorKind.unauthorized,
    );
  });

  test('缺少 Key 时归类为鉴权失败且不调用适配器', () async {
    await addAccount();
    credentialStore.keys.clear();

    await controller.refreshAll();

    expect(
      controller.accounts.single.error?.kind,
      BalanceErrorKind.unauthorized,
    );
    expect(adapter.calls, 0);
  });

  test('删除账户同时删除 Key', () async {
    await addAccount();
    final id = controller.accounts.single.account.id;

    await controller.deleteAccount(id);

    expect(controller.accounts, isEmpty);
    expect(repository.accounts, isEmpty);
    expect(credentialStore.keys.containsKey(id), isFalse);
  });

  test('编辑备注时保留原 Key', () async {
    await addAccount();
    final id = controller.accounts.single.account.id;

    await controller.updateAccount(id: id, remark: '新备注');

    expect(repository.accounts.single.remark, '新备注');
    expect(credentialStore.keys[id], 'sk-test');
  });

  test('读取失败时记录 loadError', () async {
    repository.failOnLoad = true;

    await controller.load();

    expect(controller.loadError, isNotNull);
    expect(controller.accounts, isEmpty);
  });
}
