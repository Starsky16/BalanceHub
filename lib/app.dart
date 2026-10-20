import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/app_shell.dart';
import 'ui/state/accounts_controller.dart';

/// 应用根组件。
class BalanceHubApp extends StatelessWidget {
  const BalanceHubApp({super.key, required this.controller});

  final AccountsController controller;

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.teal;
    return ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        title: 'BalanceHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}
