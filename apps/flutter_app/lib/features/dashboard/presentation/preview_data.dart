class PreviewSignal {
  const PreviewSignal({
    required this.pair,
    required this.direction,
    required this.confidence,
    required this.payout,
    required this.trend,
    required this.expiration,
    required this.consensus,
    required this.score,
  });

  final String pair;
  final String direction;
  final int confidence;
  final int payout;
  final String trend;
  final String expiration;
  final String consensus;
  final double score;
}

// These values are presentation fixtures only. They are never sent to the
// backend, never used by Risk/Execution, and are always labelled PREVIEW.
const previewSignals = <PreviewSignal>[
  PreviewSignal(pair: 'EUR/USD', direction: 'CALL', confidence: 82, payout: 92, trend: 'Bullish', expiration: '5m', consensus: '2 / 2', score: 86.2),
  PreviewSignal(pair: 'GBP/USD', direction: 'CALL', confidence: 79, payout: 91, trend: 'Bullish', expiration: '5m', consensus: '2 / 2', score: 83.4),
  PreviewSignal(pair: 'USD/JPY', direction: 'PUT', confidence: 78, payout: 90, trend: 'Bearish', expiration: '5m', consensus: '2 / 2', score: 81.1),
  PreviewSignal(pair: 'AUD/USD', direction: 'CALL', confidence: 76, payout: 89, trend: 'Bullish', expiration: '5m', consensus: '2 / 2', score: 79.8),
  PreviewSignal(pair: 'USD/CAD', direction: 'PUT', confidence: 74, payout: 88, trend: 'Bearish', expiration: '5m', consensus: '2 / 2', score: 77.3),
  PreviewSignal(pair: 'EUR/GBP', direction: 'CALL', confidence: 72, payout: 87, trend: 'Bullish', expiration: '5m', consensus: '1 / 2', score: 74.2),
];
