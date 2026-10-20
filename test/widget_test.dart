import 'package:balancehub/app.dart';
import 'package:balancehub/core/models/provider_id.dart';
import 'package:balancehub/ui/state/accounts_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

AccountsController _controller() {
  return AccountsController(
    repository: MemoryAccountRepository(),
    credentialStore: MemoryCredentialStore(),
    settingsRepository: MemorySettingsRepository(),
    adapters: {ProviderId.deepSeek: FakeAdapter(id: ProviderId.deepSeek)},
  );
}

void main() {
  testWidgets('宽屏使用 NavigationRail 并可切换到账户管理页', (tester) async {
    await tester.pumpWidget(BalanceHubApp(controller: _controller()));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('总览'), findsWidgets);

    await tester.tap(find.byIcon(Icons.manage_accounts_outlined));
    await tester.pumpAndSettle();

    expect(find.text('账户管理'), findsOneWidget);
    expect(find.text('点击右下角按钮添加 API 账户'), findsOneWidget);
  });

  testWidgets('窄屏使用 NavigationBar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BalanceHubApp(controller: _controller()));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
