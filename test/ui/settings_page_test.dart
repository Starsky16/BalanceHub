import 'package:balancehub/app.dart';
import 'package:balancehub/core/models/provider_id.dart';
import 'package:balancehub/ui/state/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/fakes.dart';

void main() {
  late MemorySettingsRepository settingsRepository;
  late AccountsController controller;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'BalanceHub',
      packageName: 'com.starsky16.balancehub',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    settingsRepository = MemorySettingsRepository();
    controller = AccountsController(
      repository: MemoryAccountRepository(),
      credentialStore: MemoryCredentialStore(),
      settingsRepository: settingsRepository,
      adapters: {ProviderId.deepSeek: FakeAdapter(id: ProviderId.deepSeek)},
    );
  });

  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(BalanceHubApp(controller: controller));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('显示版本号与自动刷新间隔', (tester) async {
    await openSettings(tester);

    expect(find.text('设置'), findsWidgets);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    expect(find.text('10 分钟'), findsOneWidget);
  });

  testWidgets('可修改自动刷新间隔并持久化', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('自动刷新'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 分钟'));
    await tester.pumpAndSettle();

    expect(controller.autoRefreshMinutes, 5);
    expect(settingsRepository.settings.autoRefreshMinutes, 5);
    expect(find.text('5 分钟'), findsOneWidget);
  });
}
