import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/accounts_controller.dart';

/// 余额总览页。
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, this.onGoToAccounts});

  /// 空态时跳转到账户管理页。
  final VoidCallback? onGoToAccounts;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountsController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('总览'),
        actions: [
          IconButton(
            onPressed: controller.refreshing || controller.accounts.isEmpty
                ? null
                : controller.refreshAll,
            icon: controller.refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: '刷新余额',
          ),
        ],
      ),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, AccountsController controller) {
    if (controller.loadingAccounts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loadError != null) {
      return _LoadErrorState(
        message: controller.loadError!,
        onRetry: controller.load,
      );
    }
    if (controller.accounts.isEmpty) {
      return _EmptyState(onGoToAccounts: onGoToAccounts);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 600 ? 12.0 : 20.0;
        final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 1;
        return GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 240,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.accounts.length,
          itemBuilder: (context, index) {
            return _AccountCard(state: controller.accounts[index]);
          },
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.state});

  final AccountBalanceState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = state.snapshot;
    final hasError = state.error != null;
    final isManual = state.account.isManual;
    final amountColor = hasError && snapshot != null
        ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
        : theme.colorScheme.onSurface;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.account.providerId.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (isManual) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '手动',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
                if (state.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasError)
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
            if (state.account.remark.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                state.account.remark,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const Spacer(),
            Text(
              snapshot == null
                  ? '—'
                  : '${_currencySymbol(snapshot.currency)} '
                        '${snapshot.totalAvailable.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              snapshot == null
                  ? '尚未刷新'
                  : isManual
                  ? '手动录入的余额'
                  : snapshot.items
                        .map(
                          (item) =>
                              '${item.label} ${item.amount.toStringAsFixed(2)}',
                        )
                        .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const Spacer(),
            if (hasError)
              Text(
                state.error!.userMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else if (snapshot != null)
              Text(
                isManual
                    ? '手动维护 · 更新于 ${_formatTime(snapshot.fetchedAt)}'
                    : '更新于 ${_formatTime(snapshot.fetchedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  static String _currencySymbol(String currency) {
    switch (currency) {
      case 'CNY':
        return '¥';
      case 'USD':
        return r'$';
      default:
        return currency;
    }
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onGoToAccounts});

  final VoidCallback? onGoToAccounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
            if (onGoToAccounts != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onGoToAccounts,
                icon: const Icon(Icons.add),
                label: const Text('去添加账户'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
