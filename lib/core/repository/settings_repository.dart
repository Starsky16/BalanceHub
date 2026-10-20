import '../models/app_settings.dart';

/// 应用设置读写接口。
abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
