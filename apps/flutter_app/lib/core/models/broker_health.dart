enum AccountMode { demo, real }

extension AccountModeX on AccountMode {
  String get wireName => this == AccountMode.demo ? 'DEMO' : 'REAL';

  String get label => wireName;
}

enum BrokerConnectionState { notConfigured, offline, connecting, connected, error }

class BrokerHealth {
  const BrokerHealth({
    required this.accountMode,
    required this.connected,
    required this.balanceAvailable,
    this.pairCount,
    this.balance,
    this.reason,
    this.checkedAt,
    this.ordersEnabled = false,
  });

  final AccountMode accountMode;
  final bool connected;
  final bool balanceAvailable;
  final int? pairCount;
  final double? balance;
  final String? reason;
  final DateTime? checkedAt;
  final bool ordersEnabled;

  factory BrokerHealth.fromJson(Map<String, dynamic> json) {
    final mode = json['account_mode']?.toString().toUpperCase() == 'REAL'
        ? AccountMode.real
        : AccountMode.demo;
    final rawBalance = json['balance'];
    final balance = rawBalance is num ? rawBalance.toDouble() : null;
    final rawPairs = json['pair_count'];
    final pairCount = rawPairs is num ? rawPairs.toInt() : null;
    final rawCheckedAt = json['checked_at'];
    final checkedAt = rawCheckedAt is num
        ? DateTime.fromMillisecondsSinceEpoch((rawCheckedAt * 1000).round(), isUtc: true)
        : rawCheckedAt is String
            ? DateTime.tryParse(rawCheckedAt)
            : null;

    return BrokerHealth(
      accountMode: mode,
      connected: json['connected'] == true,
      balanceAvailable: json['balance_available'] == true,
      pairCount: pairCount,
      balance: balance,
      reason: json['reason']?.toString(),
      checkedAt: checkedAt,
      ordersEnabled: json['orders_enabled'] == true,
    );
  }
}
