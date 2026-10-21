import 'manual_balance.dart';
import 'provider_id.dart';

/// 账户元数据。
///
/// API Key 不在此模型中，单独存放于系统安全存储，二者以 [id] 关联。
class AccountConfig {
  const AccountConfig({
    required this.id,
    required this.providerId,
    this.remark = '',
    this.manualBalance,
  });

  final String id;
  final ProviderId providerId;

  /// 用户备注，用于区分同厂商的多个账户。
  final String remark;

  /// 手动账户的余额；API 账户为 null。
  final ManualBalance? manualBalance;

  bool get isManual => providerId == ProviderId.manual;

  Map<String, Object?> toJson() => {
    'id': id,
    'providerId': providerId.wireName,
    'remark': remark,
    if (manualBalance != null) 'manualBalance': manualBalance!.toJson(),
  };

  factory AccountConfig.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final providerId = json['providerId'];
    if (id is! String || providerId is! String) {
      throw const FormatException('账户数据缺少必要字段');
    }

    final manual = json['manualBalance'];
    ManualBalance? manualBalance;
    if (manual != null) {
      if (manual is! Map) {
        throw const FormatException('手动余额数据格式不正确');
      }
      manualBalance = ManualBalance.fromJson(manual.cast<String, Object?>());
    }

    return AccountConfig(
      id: id,
      providerId: ProviderId.fromWireName(providerId),
      remark: json['remark'] as String? ?? '',
      manualBalance: manualBalance,
    );
  }
}
