import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/models/provider_id.dart';
import 'core/providers/deepseek_adapter.dart';
import 'core/providers/kimi_adapter.dart';
import 'core/providers/silicon_flow_adapter.dart';
import 'data/json_account_repository.dart';
import 'data/secure_credential_store.dart';
import 'ui/state/accounts_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationSupportDirectory();
  final client = http.Client();
  final controller = AccountsController(
    repository: JsonAccountRepository(directory),
    credentialStore: SecureCredentialStore(),
    adapters: {
      ProviderId.deepSeek: DeepSeekAdapter(client: client),
      ProviderId.kimi: KimiAdapter(client: client),
      ProviderId.siliconFlow: SiliconFlowAdapter(client: client),
    },
  );
  await controller.load();

  runApp(BalanceHubApp(controller: controller));

  // 启动后自动刷新一次；界面先渲染，卡片进入加载态。
  if (controller.accounts.isNotEmpty) {
    await controller.refreshAll();
  }
}
