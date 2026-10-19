import 'package:balancehub/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('宽屏使用 NavigationRail 并可切换到账户管理页', (tester) async {
    await tester.pumpWidget(const BalanceHubApp());

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('总览'), findsWidgets);

    await tester.tap(find.byIcon(Icons.manage_accounts_outlined));
    await tester.pumpAndSettle();

    expect(find.text('账户管理'), findsOneWidget);
    expect(find.text('账户添加功能开发中'), findsOneWidget);
  });

  testWidgets('窄屏使用 NavigationBar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BalanceHubApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
