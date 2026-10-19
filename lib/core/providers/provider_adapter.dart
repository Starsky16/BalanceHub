import '../models/api_credentials.dart';
import '../models/balance_snapshot.dart';
import '../models/provider_id.dart';

/// 厂商余额适配器统一接口。
///
/// v1 为 Bearer Key 鉴权；v2 的签名类厂商实现同一接口，仅内部鉴权方式不同。
abstract interface class ProviderAdapter {
  ProviderId get id;

  /// 拉取余额并归一化为 [BalanceSnapshot]。
  Future<BalanceSnapshot> fetchBalance(ApiCredentials credentials);
}
