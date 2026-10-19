import 'provider_id.dart';

/// 账户元数据。
///
/// API Key 不在此模型中，单独存放于系统安全存储，二者以 [id] 关联。
class AccountConfig {
  const AccountConfig({
    required this.id,
    required this.providerId,
    this.remark = '',
  });

  final String id;
  final ProviderId providerId;

  /// 用户备注，用于区分同厂商的多个账户。
  final String remark;

  Map<String, Object?> toJson() => {
    'id': id,
    'providerId': providerId.wireName,
    'remark': remark,
  };

  factory AccountConfig.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final providerId = json['providerId'];
    if (id is! String || providerId is! String) {
      throw const FormatException('账户数据缺少必要字段');
    }
    return AccountConfig(
      id: id,
      providerId: ProviderId.fromWireName(providerId),
      remark: json['remark'] as String? ?? '',
    );
  }
}
