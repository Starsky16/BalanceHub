import 'package:balancehub/app.dart';
import 'package:balancehub/core/models/balance_snapshot.dart';
import 'package:balancehub/core/models/manual_balance.dart';
import 'package:balancehub/core/models/provider_id.dart';
import 'package:balancehub/core/providers/balance_exception.dart';
import 'package:balancehub/ui/state/accounts_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late MemoryAccountRepository repository;
  late MemoryCredentialStore credentialStore;
  late MemorySettingsRepository settingsRepository;
  late FakeAdapter adapter;
  late AccountsController controller;

  setUp(() {
    repository = MemoryAccountRepository();
    credentialStore = MemoryCredentialStore();
    settingsRepository = MemorySettingsRepository();
    adapter = FakeAdapter(id: ProviderId.deepSeek);
    controller = AccountsController(
      repository: repository,
      credentialStore: credentialStore,
      settingsRepository: settingsRepository,
      adapters: {ProviderId.deepSeek: adapter},
    );
  });

  Future<void> addAccount() {
    return controller.addAccount(
      providerId: ProviderId.deepSeek,
      remark: '主账户',
      apiKey: 'sk-test',
    );
  }

  testWidgets('未刷新时显示占位状态', (tester) async {
    await addAccount();

    await tester.pumpWidget(BalanceHubApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('尚未刷新'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('正常态显示余额与明细', (tester) async {
    adapter.snapshot = BalanceSnapshot(
      totalAvailable: 100,
      currency: 'CNY',
      fetchedAt: DateTime(2026, 10, 19, 10, 30),
      items: const [
        BalanceItem(label: '充值余额', amount: 80),
        BalanceItem(label: '赠送余额', amount: 20),
      ],
    );
    await addAccount();
    await controller.refreshAll();

    await tester.pumpWidget(BalanceHubApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('¥ 100.00'), findsOneWidget);
    expect(find.text('充值余额 80.00 · 赠送余额 20.00'), findsOneWidget);
    expect(find.text('主账户'), findsOneWidget);
  });

  testWidgets('错误态显示提示并保留上次余额', (tester) async {
    adapter.snapshot = BalanceSnapshot(
      totalAvailable: 100,
      currency: 'CNY',
      fetchedAt: DateTime(2026, 10, 19, 10, 30),
    );
    await addAccount();
    await controller.refreshAll();

    adapter.error = const BalanceException(BalanceErrorKind.unauthorized);
    await controller.refreshAll();

    await tester.pumpWidget(BalanceHubApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Key 无效或已被删除'), findsOneWidget);
    expect(find.text('¥ 100.00'), findsOneWidget);
  });

  testWidgets('手动账户显示录入余额与手动标记', (tester) async {
    await controller.addAccount(
      providerId: ProviderId.manual,
      remark: '智谱',
      apiKey: '',
      manualBalance: ManualBalance(
        amount: 12.5,
        currency: 'CNY',
        updatedAt: DateTime(2026, 10, 21, 12, 30),
      ),
    );

    await tester.pumpWidget(BalanceHubApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('¥ 12.50'), findsOneWidget);
    expect(find.text('手动'), findsOneWidget);
    expect(find.text('手动录入的余额'), findsOneWidget);
    expect(find.textContaining('手动维护 · 更新于'), findsOneWidget);
  });
}
