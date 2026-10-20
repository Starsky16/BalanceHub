import 'package:http/http.dart' as http;

import '../models/api_credentials.dart';
import '../models/balance_snapshot.dart';
import '../models/provider_id.dart';
import 'balance_exception.dart';
import 'balance_http.dart';
import 'provider_adapter.dart';

/// Kimi / Moonshot 余额适配器。
class KimiAdapter implements ProviderAdapter {
  KimiAdapter({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) : _http = BalanceHttp(client ?? http.Client(), timeout: timeout);

  static final Uri _endpoint = Uri.https(
    'api.moonshot.cn',
    '/v1/users/me/balance',
  );

  final BalanceHttp _http;

  @override
  ProviderId get id => ProviderId.kimi;

  @override
  Future<BalanceSnapshot> fetchBalance(ApiCredentials credentials) async {
    final json = await _http.getJson(_endpoint, credentials);
    if (json['code'] != 0) {
      throw const BalanceException(BalanceErrorKind.invalidResponse);
    }

    final data = json['data'];
    if (data is! Map<String, Object?>) {
      throw const BalanceException(BalanceErrorKind.invalidResponse);
    }

    return BalanceSnapshot(
      totalAvailable: parseAmount(data['available_balance']),
      currency: 'CNY',
      fetchedAt: DateTime.now(),
      items: [
        BalanceItem(label: '现金余额', amount: parseAmount(data['cash_balance'])),
        BalanceItem(
          label: '代金券余额',
          amount: parseAmount(data['voucher_balance']),
        ),
      ],
    );
  }
}
