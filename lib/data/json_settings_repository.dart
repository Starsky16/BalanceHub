import 'dart:convert';
import 'dart:io';

import '../core/models/app_settings.dart';
import '../core/repository/settings_repository.dart';

/// 以 JSON 文件保存应用设置。
class JsonSettingsRepository implements SettingsRepository {
  JsonSettingsRepository(this._directory);

  static const String _fileName = 'settings.json';

  final Directory _directory;

  File get _file =>
      File('${_directory.path}${Platform.pathSeparator}$_fileName');

  @override
  Future<AppSettings> load() async {
    final file = _file;
    if (!await file.exists()) {
      return const AppSettings();
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        return AppSettings.fromJson(decoded.cast<String, Object?>());
      }
    } on FormatException {
      // 设置损坏时回到默认值，不阻塞启动。
    } on FileSystemException {
      // 读取失败同样回落默认值。
    }
    return const AppSettings();
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _directory.create(recursive: true);
    await _file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }
}
