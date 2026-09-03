import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/state/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_page.dart';

class BMFutureApp extends StatefulWidget {
  const BMFutureApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<BMFutureApp> createState() => _BMFutureAppState();
}

class _BMFutureAppState extends State<BMFutureApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController(config: widget.config);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        title: 'BM Future PO AutoTrade AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: DashboardPage(controller: controller),
      ),
    );
  }
}
