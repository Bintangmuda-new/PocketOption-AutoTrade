import 'package:flutter_test/flutter_test.dart';

import 'package:bmfuture_po_autotrade/core/models/broker_health.dart';

void main() {
  test('parses normalized DEMO broker health without credentials', () {
    final health = BrokerHealth.fromJson({
      'account_mode': 'DEMO',
      'connected': true,
      'balance_available': true,
      'pair_count': 3,
      'balance': 100.25,
      'orders_enabled': false,
      'checked_at': '2026-09-01T00:00:00Z',
    });

    expect(health.accountMode, AccountMode.demo);
    expect(health.connected, isTrue);
    expect(health.balanceAvailable, isTrue);
    expect(health.pairCount, 3);
    expect(health.balance, 100.25);
    expect(health.ordersEnabled, isFalse);
  });

  test('unknown or missing values fail closed', () {
    final health = BrokerHealth.fromJson(const <String, dynamic>{});

    expect(health.accountMode, AccountMode.demo);
    expect(health.connected, isFalse);
    expect(health.balanceAvailable, isFalse);
    expect(health.balance, isNull);
    expect(health.pairCount, isNull);
  });
}
