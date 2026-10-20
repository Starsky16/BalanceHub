import 'dart:convert';

import 'package:balancehub/core/models/api_credentials.dart';
import 'package:balancehub/core/providers/balance_exception.dart';
import 'package:balancehub/core/providers/deepseek_adapter.dart';
import 'package:balancehub/core/providers/kimi_adapter.dart';
import 'package:balancehub/core/providers/silicon_flow_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _credentials = ApiCredentials(apiKey: 'test-key');

http.Response _jsonResponse(Object payload, {int status = 200}) {
  return http.Response(
    jsonEncode(payload),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Matcher _isBalanceError(BalanceErrorKind kind) {
  return isA<BalanceException>().having((error) => error.kind, 'kind', kind);
}

void main() {
  group('DeepSeekAdapter', () {
    test('解析余额与明细', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-key');
        return _jsonResponse({
          'is_available': true,
          'balance_infos': [
            {
              'currency': 'CNY',
              'total_balance': '110.00',
              'granted_balance': '10.00',
              'topped_up_balance': '100.00',
            },
          ],
        });
      });

      final snapshot = await DeepSeekAdapter(client: client)
          .fetchBalance(_credentials);

      expect(snapshot.totalAvailable, 110);
      expect(snapshot.currency, 'CNY');
      expect(snapshot.items[0].label, '充值余额');
      expect(snapshot.items[0].amount, 100);
      expect(snapshot.items[1].label, '赠送余额');
      expect(snapshot.items[1].amount, 10);
    });

    test('401 归类为鉴权失败', () async {
      final adapter = DeepSeekAdapter(
        client: MockClient((_) async => http.Response('{}', 401)),
      );
      await expectLater(
        adapter.fetchBalance(_credentials),
        throwsA(_isBalanceError(BalanceErrorKind.unauthorized)),
      );
    });

    test('429 归类为限流', () async {
      final adapter = DeepSeekAdapter(
        client: MockClient((_) async => http.Response('{}', 429)),
      );
      await expectLater(
        adapter.fetchBalance(_credentials),
        throwsA(_isBalanceError(BalanceErrorKind.rateLimited)),
      );
    });

    test('超时归类为网络错误', () async {
      final adapter = DeepSeekAdapter(
        client: MockClient((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return _jsonResponse({});
        }),
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        adapter.fetchBalance(_credentials),
        throwsA(_isBalanceError(BalanceErrorKind.network)),
      );
    });

    test('响应无法解析时归类为接口变更', () async {
      final adapter = DeepSeekAdapter(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );
      await expectLater(
        adapter.fetchBalance(_credentials),
        throwsA(_isBalanceError(BalanceErrorKind.invalidResponse)),
      );
    });

    test('缺少余额字段时归类为接口变更', () async {
      final adapter = DeepSeekAdapter(
        client: MockClient(
          (_) async =>
              _jsonResponse({'is_available': true, 'balance_infos': []}),
        ),
      );
      await expectLater(
        adapter.fetchBalance(_credentials),
        throwsA(_isBalanceError(BalanceErrorKind.invalidResponse)),
      );
    });
  });

  group('KimiAdapter', () {
    test('解析余额与明细', () async {
      final adapter = KimiAdapter(
        client: MockClient(
          (_) async => _jsonResponse({
            'code': 0,
            'data': {
              'available_balance': 49.58894,
              'voucher_balance': 46.58893,
              'cash_balance': 3.00001,
            },
            'scode': '0x0',
            'status': true,
          }),
        ),
      );

      final snapshot = await adapter.fetchBalance(_credentials);

      expect(snapshot.currency, 'CNY');
      expect(snapshot.totalAvailable, closeTo(49.58894, 0.000001));
      expect(snapshot.items[0].label, '现金余额');
      expect(snapshot.items[1].label, '代金券余额');
    });

    test('业务码非 0 归类为接口变更', () async {
      final adapter = KimiAdapter(
        client: MockClient((_) async => _jsonResponse({'code': 1})),
      );
      await expectLater(
        adapter.fetchBalance(_credentials),
        throwsA(_isBalanceError(BalanceErrorKind.invalidResponse)),
      );
    });
  });

  group('SiliconFlowAdapter', () {
    test('解析余额与明细', () async {
      final adapter = SiliconFlowAdapter(
        client: MockClient(
          (_) async => _jsonResponse({
            'code': 20000,
            'message': 'OK',
            'status': true,
            'data': {
              'balance': '0.88',
              'chargeBalance': '88.00',
              'totalBalance': '88.88',
            },
          }),
        ),
      );

      final snapshot = await adapter.fetchBalance(_credentials);

      expect(snapshot.totalAvailable, 88.88);
      expect(snapshot.currency, 'CNY');
      expect(snapshot.items[0].label, '充值余额');
      expect(snapshot.items[0].amount, 88);
      expect(snapshot.items[1].label, '赠送余额');
      expect(snapshot.items[1].amount, 0.88);
    });

    test('业务码非 20000 归类为接口变更', () async {
      final adapter = SiliconFlowAdapter(
        client: MockClient((_) async => _jsonResponse({'code': 40000})),
      );
      await expectLater(
        adapter.fetchBalance(_credentials),
        throwsA(_isBalanceError(BalanceErrorKind.invalidResponse)),
      );
    });
  });
}
