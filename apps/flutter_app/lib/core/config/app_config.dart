import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  bool get hasApi => apiBaseUrl.trim().isNotEmpty;

  factory AppConfig.fromEnvironment() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.trim().isNotEmpty) {
      return AppConfig(apiBaseUrl: _normalize(configured));
    }

    // The emulator maps the host computer to 10.0.2.2. Physical devices
    // should be launched with --dart-define=API_BASE_URL=http://<PC-IP>:8000.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const AppConfig(apiBaseUrl: 'http://10.0.2.2:8000');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return const AppConfig(apiBaseUrl: 'http://127.0.0.1:8000');
    }
    return const AppConfig(apiBaseUrl: '');
  }

  static String _normalize(String value) => value.trim().replaceFirst(RegExp(r'/+$'), '');
}
