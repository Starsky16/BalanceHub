import 'dart:convert';
import 'dart:io';

import '../core/models/account_config.dart';
import '../core/repository/account_repository.dart';

/// 以普通 JSON 文件保存账户元数据，API Key 不在此文件内。
class JsonAccountRepository implements AccountRepository {
  JsonAccountRepository(this._directory);

  static const String _fileName = 'accounts.json';

  final Directory _directory;

  File get _file =>
      File('${_directory.path}${Platform.pathSeparator}$_fileName');

  @override
  Future<List<AccountConfig>> loadAll() async {
    final file = _file;
    if (!await file.exists()) {
      return [];
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(content);
    if (decoded is! List) {
      throw const FormatException('账户数据格式不正确');
    }

    final accounts = <AccountConfig>[];
    for (final item in decoded) {
      if (item is! Map) {
        throw const FormatException('账户数据包含无效条目');
      }
      accounts.add(AccountConfig.fromJson(item.cast<String, Object?>()));
    }
    return accounts;
  }

  @override
  Future<void> saveAll(List<AccountConfig> accounts) async {
    await _directory.create(recursive: true);
    final payload = jsonEncode(
      accounts.map((account) => account.toJson()).toList(),
    );
    await _file.writeAsString(payload, flush: true);
  }
}
