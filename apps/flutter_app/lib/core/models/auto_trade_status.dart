import 'broker_health.dart';

enum AutoTradeState { stopped, starting, running, degraded, emergencyStop }

class AutoTradeStatus {
  const AutoTradeStatus({
    required this.accountMode,
    required this.state,
    required this.running,
    required this.reason,
    required this.ordersEnabled,
    this.startedAt,
    this.activeTradeId,
    this.tradesToday = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.consecutiveLosses = 0,
    this.lastSignalId,
    this.dailyProfit = 0,
    this.dailyLoss = 0,
  });

  final AccountMode accountMode;
  final AutoTradeState state;
  final bool running;
  final String reason;
  final bool ordersEnabled;
  final DateTime? startedAt;
  final String? activeTradeId;
  final int tradesToday;
  final int wins;
  final int losses;
  final int draws;
  final int consecutiveLosses;
  final String? lastSignalId;
  final double dailyProfit;
  final double dailyLoss;

  factory AutoTradeStatus.fromJson(Map<String, dynamic> json) {
    final stateName = json['state']?.toString().toUpperCase();
    final state = switch (stateName) {
      'STARTING' => AutoTradeState.starting,
      'RUNNING' => AutoTradeState.running,
      'DEGRADED' => AutoTradeState.degraded,
      'EMERGENCY_STOP' => AutoTradeState.emergencyStop,
      _ => AutoTradeState.stopped,
    };
    final rawStarted = json['started_at'];
    final startedAt = rawStarted is num ? DateTime.fromMillisecondsSinceEpoch((rawStarted * 1000).round(), isUtc: true) : null;
    double number(String key) => json[key] is num ? (json[key] as num).toDouble() : 0;
    int integer(String key) => json[key] is num ? (json[key] as num).toInt() : 0;
    return AutoTradeStatus(
      accountMode: json['account_mode']?.toString().toUpperCase() == 'REAL' ? AccountMode.real : AccountMode.demo,
      state: state,
      running: json['running'] == true,
      reason: json['reason']?.toString() ?? 'No status reason',
      ordersEnabled: json['orders_enabled'] == true,
      startedAt: startedAt,
      activeTradeId: json['active_trade_id']?.toString(),
      tradesToday: integer('trades_today'),
      wins: integer('wins'),
      losses: integer('losses'),
      draws: integer('draws'),
      consecutiveLosses: integer('consecutive_losses'),
      lastSignalId: json['last_signal_id']?.toString(),
      dailyProfit: number('daily_profit'),
      dailyLoss: number('daily_loss'),
    );
  }

  String get label => switch (state) {
        AutoTradeState.running => 'RUNNING',
        AutoTradeState.starting => 'STARTING',
        AutoTradeState.degraded => 'DEGRADED',
        AutoTradeState.emergencyStop => 'EMERGENCY STOP',
        AutoTradeState.stopped => 'STOPPED',
      };
}

class AiHealth {
  const AiHealth({required this.available, required this.provider, required this.model});

  final bool available;
  final String provider;
  final String model;

  factory AiHealth.fromJson(Map<String, dynamic> json) {
    final providers = json['providers'];
    final first = providers is List && providers.isNotEmpty && providers.first is Map ? Map<String, dynamic>.from(providers.first as Map) : const <String, dynamic>{};
    return AiHealth(available: json['available'] == true, provider: first['provider']?.toString() ?? '—', model: first['model']?.toString() ?? '—');
  }
}
