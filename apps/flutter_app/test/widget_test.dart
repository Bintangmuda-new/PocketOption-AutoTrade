import 'package:flutter_test/flutter_test.dart';

import 'package:bmfuture_po_autotrade/app.dart';
import 'package:bmfuture_po_autotrade/core/config/app_config.dart';

void main() {
  testWidgets('starts in safe DEMO mode with execution locked', (tester) async {
    await tester.pumpWidget(const BMFutureApp(config: AppConfig(apiBaseUrl: '')));

    expect(find.text('DEMO'), findsWidgets);
    expect(find.text('REAL TRADING\nNOT ACTIVATED'), findsOneWidget);
    expect(find.text('EXECUTION LOCKED'), findsWidgets);
    expect(find.text('NO LIVE CANDLE DATA'), findsOneWidget);
  });

  testWidgets('REAL mode is visibly locked', (tester) async {
    await tester.pumpWidget(const BMFutureApp(config: AppConfig(apiBaseUrl: '')));

    await tester.tap(find.text('REAL').first);
    await tester.pump();

    expect(find.text('REAL LOCKED', skipOffstage: false), findsWidgets);
    expect(find.text('REAL dipilih tetapi dikunci. Koneksi dan transaksi REAL belum diaktifkan.'), findsOneWidget);
  });
}
