import 'package:flutter/material.dart';

import 'pages/accounts_page.dart';
import 'pages/overview_page.dart';
import 'pages/settings_page.dart';

/// 应用主框架：宽屏用 NavigationRail，窄屏用 NavigationBar。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _wideBreakpoint = 720;

  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final pages = [
      OverviewPage(onGoToAccounts: () => _select(1)),
      const AccountsPage(),
      const SettingsPage(),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('总览'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.manage_accounts_outlined),
                  selectedIcon: Icon(Icons.manage_accounts),
                  label: Text('账户'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('设置'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: '总览',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts),
            label: '账户',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
