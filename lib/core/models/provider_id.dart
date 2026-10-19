/// 支持余额查询的厂商标识。
enum ProviderId {
  deepSeek('DeepSeek', 'deepseek'),
  kimi('Kimi / Moonshot', 'kimi'),
  siliconFlow('硅基流动', 'siliconflow');

  const ProviderId(this.displayName, this.wireName);

  /// 界面展示名称。
  final String displayName;

  /// 持久化用的稳定标识，不随展示名称变化。
  final String wireName;

  /// 按持久化标识还原厂商。
  static ProviderId fromWireName(String value) {
    return ProviderId.values.firstWhere(
      (provider) => provider.wireName == value,
      orElse: () => throw ArgumentError.value(value, 'value', '未知厂商标识'),
    );
  }
}
