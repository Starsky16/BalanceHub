import 'package:balancehub/core/models/account_config.dart';
import 'package:balancehub/core/models/app_settings.dart';
import 'package:balancehub/core/models/balance_snapshot.dart';
import 'package:balancehub/core/models/manual_balance.dart';
import 'package:balancehub/core/models/provider_id.dart';
import 'package:balancehub/core/providers/balance_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountConfig', () {
    test('JSON 往返保留字段', () {
      const account = AccountConfig(
        id: 'acc-1',
        providerId: ProviderId.deepSeek,
        remark: '主账户',
      );

      final restored = AccountConfig.fromJson(account.toJson());

      expect(restored.id, 'acc-1');
      expect(restored.providerId, ProviderId.deepSeek);
      expect(restored.remark, '主账户');
    });

    test('缺少必要字段时抛出 FormatException', () {
      expect(
        () => AccountConfig.fromJson(const {'providerId': 'deepseek'}),
        throwsFormatException,
      );
    });

    test('手动余额账户 JSON 往返', () {
      final account = AccountConfig(
        id: 'acc-manual',
        providerId: ProviderId.manual,
        remark: '智谱',
        manualBalance: ManualBalance(
          amount: 12.5,
          currency: 'CNY',
          updatedAt: DateTime.utc(2026, 10, 21, 12),
        ),
      );

      final restored = AccountConfig.fromJson(account.toJson());

      expect(restored.providerId, ProviderId.manual);
      expect(restored.isManual, isTrue);
      expect(restored.manualBalance?.amount, 12.5);
      expect(restored.manualBalance?.currency, 'CNY');
      expect(restored.manualBalance?.updatedAt, DateTime.utc(2026, 10, 21, 12));
    });
  });

  group('ProviderId', () {
    test('按稳定标识还原厂商', () {
      expect(ProviderId.fromWireName('kimi'), ProviderId.kimi);
      expect(ProviderId.fromWireName('siliconflow'), ProviderId.siliconFlow);
      expect(ProviderId.fromWireName('manual'), ProviderId.manual);
    });

    test('未知标识抛出 ArgumentError', () {
      expect(() => ProviderId.fromWireName('unknown'), throwsArgumentError);
    });
  });

  test('BalanceSnapshot 默认无明细', () {
    final snapshot = BalanceSnapshot(
      totalAvailable: 12.5,
      currency: 'CNY',
      fetchedAt: DateTime.utc(2026, 10, 19),
    );

    expect(snapshot.items, isEmpty);
    expect(snapshot.currency, 'CNY');
  });

  test('错误类型映射为用户提示', () {
    expect(
      const BalanceException(BalanceErrorKind.unauthorized).userMessage,
      'Key 无效或已被删除',
    );
    expect(
      const BalanceException(BalanceErrorKind.rateLimited).userMessage,
      '请求过于频繁，稍后再试',
    );
    expect(
      const BalanceException(BalanceErrorKind.invalidResponse).userMessage,
      '响应异常，适配器待更新',
    );
  });

  group('ManualBalance', () {
    test('缺少字段时抛出 FormatException', () {
      expect(() => ManualBalance.fromJson(const {}), throwsFormatException);
    });

    test('时间格式非法时抛出 FormatException', () {
      expect(
        () => ManualBalance.fromJson(const {
          'amount': 1,
          'currency': 'CNY',
          'updatedAt': 'bad',
        }),
        throwsFormatException,
      );
    });
  });

  group('AppSettings', () {
    test('默认 10 分钟', () {
      expect(const AppSettings().autoRefreshMinutes, 10);
    });

    test('合法值原样保留', () {
      expect(
        AppSettings.fromJson(const {'autoRefreshMinutes': 0})
            .autoRefreshMinutes,
        0,
      );
      expect(
        AppSettings.fromJson(const {'autoRefreshMinutes': 30})
            .autoRefreshMinutes,
        30,
      );
    });

    test('非法值回落默认', () {
      expect(
        AppSettings.fromJson(const {'autoRefreshMinutes': 7})
            .autoRefreshMinutes,
        10,
      );
      expect(
        AppSettings.fromJson(const {'autoRefreshMinutes': '5'})
            .autoRefreshMinutes,
        10,
      );
    });
  });
}
