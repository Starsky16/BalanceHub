/// 余额查询失败的归类。
enum BalanceErrorKind {
  unauthorized,
  rateLimited,
  network,
  invalidResponse,
  unknown,
}

/// 适配器统一抛出的余额查询异常。
class BalanceException implements Exception {
  const BalanceException(this.kind, {this.detail});

  final BalanceErrorKind kind;

  /// 调试用细节，不直接展示给用户。
  final String? detail;

  /// 卡片上展示的用户提示。
  String get userMessage => switch (kind) {
    BalanceErrorKind.unauthorized => 'Key 无效或已被删除',
    BalanceErrorKind.rateLimited => '请求过于频繁，稍后再试',
    BalanceErrorKind.network => '网络错误',
    BalanceErrorKind.invalidResponse => '响应异常，适配器待更新',
    BalanceErrorKind.unknown => '未知错误',
  };

  @override
  String toString() => 'BalanceException($kind, detail: $detail)';
}
