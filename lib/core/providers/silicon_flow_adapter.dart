import 'package:http/http.dart' as http;

import '../models/api_credentials.dart';
import '../models/balance_snapshot.dart';
import '../models/provider_id.dart';
import 'balance_exception.dart';
import 'balance_http.dart';
import 'provider_adapter.dart';

/// 硅基流动余额适配器。
class SiliconFlowAdapter implements ProviderAdapter {
  SiliconFlowAdapter({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) : _http = BalanceHttp(client ?? http.Client(), timeout: timeout);

  static final Uri _endpoint = Uri.https('api.siliconflow.cn', '/v1/user/info');

  final BalanceHttp _http;

  @override
  ProviderId get id => ProviderId.siliconFlow;

  @override
  Future<BalanceSnapshot> fetchBalance(ApiCredentials credentials) async {
    final json = await _http.getJson(_endpoint, credentials);
    if (json['code'] != 20000) {
      throw const BalanceException(BalanceErrorKind.invalidResponse);
    }

    final data = json['data'];
    if (data is! Map<String, Object?>) {
      throw const BalanceException(BalanceErrorKind.invalidResponse);
    }

    return BalanceSnapshot(
      totalAvailable: parseAmount(data['totalBalance']),
      currency: 'CNY',
      fetchedAt: DateTime.now(),
      items: [
        BalanceItem(label: '充值余额', amount: parseAmount(data['chargeBalance'])),
        BalanceItem(label: '赠送余额', amount: parseAmount(data['balance'])),
      ],
    );
  }
}
