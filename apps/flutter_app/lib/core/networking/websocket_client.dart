import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeMarketClient {
  RealtimeMarketClient({required String baseUrl, String mode = 'DEMO', String pair = 'EURUSD_otc'})
      : _baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
        _mode = mode.trim().toUpperCase(),
        _pair = pair.trim();

  final String _baseUrl;
  final String _mode;
  final String _pair;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _closedByUser = false;
  bool _disposed = false;

  final _events = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  void connect() {
    if (_disposed || _baseUrl.isEmpty || _channel != null || !_validScope) return;
    _closedByUser = false;
    final baseUri = Uri.tryParse(_baseUrl);
    if (baseUri == null || (baseUri.scheme != 'http' && baseUri.scheme != 'https')) return;
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final basePath = baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    final uri = baseUri.replace(
      scheme: scheme,
      path: '$basePath/ws/market/${Uri.encodeComponent(_mode)}/${Uri.encodeComponent(_pair)}',
      query: '',
      fragment: '',
    );
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      channel.stream.listen(
        (event) {
          if (event is! String) return;
          try {
            final decoded = jsonDecode(event);
            if (decoded is Map<String, dynamic>) {
              _attempt = 0;
              if (!_disposed) _events.add(decoded);
            }
          } catch (_) {
            // Invalid market events are ignored; consumers remain fail-closed.
          }
        },
        onDone: _scheduleReconnect,
        onError: (_, __) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _channel = null;
    if (_disposed || _closedByUser || _baseUrl.isEmpty || _reconnectTimer != null) return;
    final cappedAttempt = _attempt.clamp(0, 5).toInt();
    final seconds = 1 << cappedAttempt;
    _attempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      connect();
    });
  }

  Future<void> close() async {
    if (_disposed) return;
    _disposed = true;
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _channel = null;
    await _events.close();
  }

  bool get _validScope => (_mode == 'DEMO' || _mode == 'REAL') && _pair.isNotEmpty && _pair.length <= 80;
}
