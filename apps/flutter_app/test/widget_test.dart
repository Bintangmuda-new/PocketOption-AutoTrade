import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';

import 'package:bmfuture_po_autotrade/app.dart';
import 'package:bmfuture_po_autotrade/core/config/app_config.dart';

void main() {
  testWidgets('starts in safe DEMO mode with execution gate visible', (tester) async {
    await tester.pumpWidget(const BMFutureApp(config: AppConfig(apiBaseUrl: '')));

    expect(find.text('DEMO'), findsWidgets);
    expect(find.byKey(const ValueKey('real-mode-button')), findsOneWidget);
    expect(find.text('NO LIVE CANDLE DATA'), findsOneWidget);
    expect(find.text('CONNECT DEMO'), findsOneWidget);
  });

  testWidgets('REAL mode is visibly locked', (tester) async {
    await tester.pumpWidget(const BMFutureApp(config: AppConfig(apiBaseUrl: '')));

    await tester.tap(find.byKey(const ValueKey('real-mode-button')));
    await tester.pump();

    expect(find.textContaining('REAL LOCKED', skipOffstage: false), findsWidgets);
    expect(find.textContaining('REAL dipilih', skipOffstage: false), findsOneWidget);
  });
}
