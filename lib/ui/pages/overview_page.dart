import 'package:flutter/material.dart';

/// 余额总览页。
///
/// 骨架阶段仅提供空态；卡片列表与刷新在 v1 功能阶段接入。
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('总览'),
        actions: [
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新余额',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text('还没有账户', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '先在账户管理中添加 API 账户',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
