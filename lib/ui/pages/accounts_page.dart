import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/account_config.dart';
import '../../core/models/provider_id.dart';
import '../state/accounts_controller.dart';

/// 账户管理页。
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('账户管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addAccount(context),
        tooltip: '添加账户',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, AccountsController controller) {
    if (controller.loadingAccounts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.loadError!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: controller.load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (controller.accounts.isEmpty) {
      return const _EmptyAccounts();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: controller.accounts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final account = controller.accounts[index].account;
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          title: Text(account.providerId.displayName),
          subtitle: Text(account.remark.isEmpty ? '无备注' : account.remark),
          trailing: PopupMenuButton<_AccountAction>(
            onSelected: (action) {
              switch (action) {
                case _AccountAction.edit:
                  _editAccount(context, account);
                case _AccountAction.delete:
                  _deleteAccount(context, account);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _AccountAction.edit, child: Text('编辑')),
              PopupMenuItem(value: _AccountAction.delete, child: Text('删除')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addAccount(BuildContext context) async {
    final controller = context.read<AccountsController>();
    final result = await showDialog<_AccountFormResult>(
      context: context,
      builder: (context) => const _AccountFormDialog(),
    );
    if (result == null) {
      return;
    }

    try {
      await controller.addAccount(
        providerId: result.providerId,
        remark: result.remark,
        apiKey: result.apiKey,
      );
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, '保存失败：$error');
      }
    }
  }

  Future<void> _editAccount(BuildContext context, AccountConfig account) async {
    final controller = context.read<AccountsController>();
    final result = await showDialog<_AccountFormResult>(
      context: context,
      builder: (context) => _AccountFormDialog(account: account),
    );
    if (result == null) {
      return;
    }

    try {
      await controller.updateAccount(
        id: account.id,
        remark: result.remark,
        apiKey: result.apiKey,
      );
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, '保存失败：$error');
      }
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    AccountConfig account,
  ) async {
    final controller = context.read<AccountsController>();
    final name = account.remark.isEmpty
        ? account.providerId.displayName
        : account.remark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账户'),
        content: Text('确定删除「$name」吗？该账户的 API Key 也会一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await controller.deleteAccount(account.id);
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, '删除失败：$error');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _AccountAction { edit, delete }

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

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
              Icons.manage_accounts_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('还没有账户', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮添加 API 账户',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountFormResult {
  const _AccountFormResult({
    required this.providerId,
    required this.remark,
    required this.apiKey,
  });

  final ProviderId providerId;
  final String remark;
  final String apiKey;
}

class _AccountFormDialog extends StatefulWidget {
  const _AccountFormDialog({this.account});

  final AccountConfig? account;

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  final _keyController = TextEditingController();

  late ProviderId _providerId;
  bool _showKey = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _providerId = widget.account?.providerId ?? ProviderId.deepSeek;
    _remarkController.text = widget.account?.remark ?? '';
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _AccountFormResult(
        providerId: _providerId,
        remark: _remarkController.text,
        apiKey: _keyController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑账户' : '添加账户'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ProviderId>(
                  initialValue: _providerId,
                  decoration: const InputDecoration(labelText: '厂商'),
                  items: ProviderId.values
                      .map(
                        (provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: _isEditing
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _providerId = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarkController,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '例如：主账户',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _keyController,
                  obscureText: !_showKey,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    helperText: _isEditing ? '留空则保留原 Key' : null,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showKey = !_showKey),
                      icon: Icon(
                        _showKey ? Icons.visibility_off : Icons.visibility,
                      ),
                      tooltip: _showKey ? '隐藏 Key' : '显示 Key',
                    ),
                  ),
                  validator: (value) {
                    if (!_isEditing &&
                        (value == null || value.trim().isEmpty)) {
                      return '请粘贴 API Key';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
