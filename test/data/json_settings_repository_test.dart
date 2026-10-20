import 'dart:io';

import 'package:balancehub/core/models/app_settings.dart';
import 'package:balancehub/data/json_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late JsonSettingsRepository repository;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('balancehub_settings_');
    repository = JsonSettingsRepository(directory);
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('文件不存在时返回默认设置', () async {
    final settings = await repository.load();

    expect(settings.autoRefreshMinutes, 10);
  });

  test('保存后可读回', () async {
    await repository.save(const AppSettings(autoRefreshMinutes: 5));

    final settings = await repository.load();

    expect(settings.autoRefreshMinutes, 5);
  });

  test('文件损坏时回落默认设置', () async {
    await File('${directory.path}${Platform.pathSeparator}settings.json')
        .writeAsString('{');

    final settings = await repository.load();

    expect(settings.autoRefreshMinutes, 10);
  });
}
