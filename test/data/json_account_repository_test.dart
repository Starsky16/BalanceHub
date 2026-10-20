import 'dart:io';

import 'package:balancehub/core/models/account_config.dart';
import 'package:balancehub/core/models/provider_id.dart';
import 'package:balancehub/data/json_account_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late JsonAccountRepository repository;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('balancehub_repo_');
    repository = JsonAccountRepository(directory);
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('文件不存在时返回空列表', () async {
    expect(await repository.loadAll(), isEmpty);
  });

  test('保存后可读回', () async {
    const accounts = [
      AccountConfig(
        id: 'acc-1',
        providerId: ProviderId.deepSeek,
        remark: '主账户',
      ),
      AccountConfig(id: 'acc-2', providerId: ProviderId.kimi),
    ];

    await repository.saveAll(accounts);
    final restored = await repository.loadAll();

    expect(restored, hasLength(2));
    expect(restored[0].id, 'acc-1');
    expect(restored[0].providerId, ProviderId.deepSeek);
    expect(restored[0].remark, '主账户');
    expect(restored[1].providerId, ProviderId.kimi);
  });

  test('非法 JSON 抛出 FormatException', () async {
    await File('${directory.path}${Platform.pathSeparator}accounts.json')
        .writeAsString('{');

    await expectLater(repository.loadAll(), throwsFormatException);
  });
}
