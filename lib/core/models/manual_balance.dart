/// 手动录入的余额快照。
class ManualBalance {
  const ManualBalance({
    required this.amount,
    this.currency = 'CNY',
    required this.updatedAt,
  });

  final double amount;
  final String currency;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'amount': amount,
    'currency': currency,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ManualBalance.fromJson(Map<String, Object?> json) {
    final amount = json['amount'];
    final currency = json['currency'];
    final updatedAt = json['updatedAt'];
    if (amount is! num || currency is! String || updatedAt is! String) {
      throw const FormatException('手动余额数据不完整');
    }
    final time = DateTime.tryParse(updatedAt);
    if (time == null) {
      throw const FormatException('手动余额时间格式不正确');
    }
    return ManualBalance(
      amount: amount.toDouble(),
      currency: currency,
      updatedAt: time,
    );
  }
}
