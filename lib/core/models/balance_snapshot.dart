/// 余额明细项，例如现金、赠送、代金券。
class BalanceItem {
  const BalanceItem({required this.label, required this.amount});

  /// 明细名称。
  final String label;

  /// 明细金额。
  final double amount;
}

/// 归一化后的余额快照，各厂商适配器统一产出该结构。
class BalanceSnapshot {
  const BalanceSnapshot({
    required this.totalAvailable,
    required this.currency,
    required this.fetchedAt,
    this.items = const [],
  });

  /// 主显示的可用余额。
  final double totalAvailable;

  /// 币种，v1 三家厂商均为 CNY。
  final String currency;

  /// 余额明细拆分，厂商未提供时为空。
  final List<BalanceItem> items;

  /// 拉取时间。
  final DateTime fetchedAt;
}
