import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/api_credentials.dart';
import 'balance_exception.dart';

/// 统一的余额请求封装：Bearer 鉴权、超时与错误归类。
class BalanceHttp {
  BalanceHttp(this._client, {this.timeout = const Duration(seconds: 15)});

  final http.Client _client;
  final Duration timeout;

  /// 发起 GET 请求并返回 JSON 对象，失败时统一抛 [BalanceException]。
  Future<Map<String, Object?>> getJson(
    Uri uri,
    ApiCredentials credentials,
  ) async {
    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer ${credentials.apiKey}',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const BalanceException(BalanceErrorKind.unauthorized);
      }
      if (response.statusCode == 429) {
        throw const BalanceException(BalanceErrorKind.rateLimited);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BalanceException(
          BalanceErrorKind.unknown,
          detail: 'HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, Object?>) {
        throw const BalanceException(BalanceErrorKind.invalidResponse);
      }
      return decoded;
    } on TimeoutException {
      throw const BalanceException(BalanceErrorKind.network);
    } on SocketException {
      throw const BalanceException(BalanceErrorKind.network);
    } on http.ClientException {
      throw const BalanceException(BalanceErrorKind.network);
    } on FormatException {
      throw const BalanceException(BalanceErrorKind.invalidResponse);
    }
  }
}

/// 把接口返回的金额（字符串或数字）转成 [double]。
double parseAmount(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw const BalanceException(BalanceErrorKind.invalidResponse);
}
