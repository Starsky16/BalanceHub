import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_settings.dart';
import '../state/accounts_controller.dart';

/// 设置页。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader('通用'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('自动刷新'),
            subtitle: Text(_intervalLabel(controller.autoRefreshMinutes)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickInterval(context, controller),
          ),
          const Divider(height: 1),
          const _SectionHeader('关于'),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              final subtitle = info != null
                  ? '${info.version} (${info.buildNumber})'
                  : snapshot.hasError
                  ? '版本信息不可用'
                  : '读取中…';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                subtitle: Text(subtitle),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.apps),
            title: Text('应用'),
            subtitle: Text('BalanceHub · 多厂商官方 API 余额聚合工具'),
          ),
          const ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('字体'),
            subtitle: Text(
              'HarmonyOS Sans（© 2021 Huawei Device Co., Ltd.，'
              '依据 HarmonyOS Sans Fonts License Agreement）',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickInterval(
    BuildContext context,
    AccountsController controller,
  ) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('自动刷新间隔'),
        children: [
          for (final minutes in kAutoRefreshOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(minutes),
              child: Row(
                children: [
                  Expanded(child: Text(_intervalLabel(minutes))),
                  if (minutes == controller.autoRefreshMinutes)
                    const Icon(Icons.check, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null) {
      return;
    }

    try {
      await controller.setAutoRefreshMinutes(selected);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存自动刷新设置失败：$error')));
      }
    }
  }

  static String _intervalLabel(int minutes) {
    return minutes == 0 ? '关闭自动刷新' : '$minutes 分钟';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
