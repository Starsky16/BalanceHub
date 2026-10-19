import 'package:flutter/material.dart';

import 'ui/app_shell.dart';

/// 应用根组件。
class BalanceHubApp extends StatelessWidget {
  const BalanceHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.teal;
    return MaterialApp(
      title: 'BalanceHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seedColor)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const AppShell(),
    );
  }
}
