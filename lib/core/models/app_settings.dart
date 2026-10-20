/// 允许的自动刷新间隔（分钟），0 表示关闭。
const List<int> kAutoRefreshOptions = [0, 5, 10, 15, 30];

/// 应用设置。
class AppSettings {
  const AppSettings({this.autoRefreshMinutes = 10});

  /// 自动刷新间隔，0 表示关闭。
  final int autoRefreshMinutes;

  AppSettings copyWith({int? autoRefreshMinutes}) {
    return AppSettings(
      autoRefreshMinutes: autoRefreshMinutes ?? this.autoRefreshMinutes,
    );
  }

  Map<String, Object?> toJson() => {'autoRefreshMinutes': autoRefreshMinutes};

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final value = json['autoRefreshMinutes'];
    if (value is int && kAutoRefreshOptions.contains(value)) {
      return AppSettings(autoRefreshMinutes: value);
    }
    return const AppSettings();
  }
}
