import 'package:http/http.dart' as http;

import '../models/api_credentials.dart';
import '../models/balance_snapshot.dart';
import '../models/provider_id.dart';
import 'balance_exception.dart';
import 'balance_http.dart';
import 'provider_adapter.dart';

/// DeepSeek 余额适配器。
class DeepSeekAdapter implements ProviderAdapter {
  DeepSeekAdapter({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) : _http = BalanceHttp(client ?? http.Client(), timeout: timeout);

  static final Uri _endpoint = Uri.https('api.deepseek.com', '/user/balance');

  final BalanceHttp _http;

  @override
  ProviderId get id => ProviderId.deepSeek;

  @override
  Future<BalanceSnapshot> fetchBalance(ApiCredentials credentials) async {
    final json = await _http.getJson(_endpoint, credentials);
    final infos = json['balance_infos'];
    if (infos is! List || infos.isEmpty) {
      throw const BalanceException(BalanceErrorKind.invalidResponse);
    }

    final info = _selectInfo(infos);
    final currency = info['currency'] as String? ?? 'CNY';
    final toppedUp = parseAmount(info['topped_up_balance']);
    final granted = parseAmount(info['granted_balance']);

    return BalanceSnapshot(
      totalAvailable: parseAmount(info['total_balance']),
      currency: currency,
      fetchedAt: DateTime.now(),
      items: [
        BalanceItem(label: '充值余额', amount: toppedUp),
        BalanceItem(label: '赠送余额', amount: granted),
      ],
    );
  }

  /// 优先取人民币账户，其次取第一条。
  Map<String, Object?> _selectInfo(List<Object?> infos) {
    for (final item in infos) {
      if (item is Map<String, Object?> && item['currency'] == 'CNY') {
        return item;
      }
    }
    for (final item in infos) {
      if (item is Map<String, Object?>) {
        return item;
      }
    }
    throw const BalanceException(BalanceErrorKind.invalidResponse);
  }
}
