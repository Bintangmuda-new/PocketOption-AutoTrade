import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/broker_health.dart';
import '../models/auto_trade_status.dart';

class BrokerApiException implements Exception {
  const BrokerApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BrokerApiClient {
  BrokerApiClient({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<BrokerHealth> connectDemo() async {
    final json = await _post('/api/v1/connection/DEMO/connect', timeout: const Duration(seconds: 70));
    return BrokerHealth.fromJson(json);
  }

  Future<BrokerHealth> disconnectDemo() async {
    final json = await _post('/api/v1/connection/DEMO/disconnect');
    return BrokerHealth.fromJson(json);
  }

  Future<BrokerHealth> getDemoStatus() async {
    final json = await _get('/api/v1/connection/DEMO/status');
    return BrokerHealth.fromJson(json);
  }

  Future<AutoTradeStatus> getAutoTradeStatus() async {
    final json = await _get('/api/v1/auto-trade/DEMO/status');
    return AutoTradeStatus.fromJson(json);
  }

  Future<AutoTradeStatus> startAutoTrade({double entryAmount = 1}) async {
    final json = await _post('/api/v1/auto-trade/DEMO/start', body: {'entry_amount': entryAmount});
    return AutoTradeStatus.fromJson(json);
  }

  Future<AutoTradeStatus> stopAutoTrade() async {
    final json = await _post('/api/v1/auto-trade/DEMO/stop');
    return AutoTradeStatus.fromJson(json);
  }

  Future<AutoTradeStatus> emergencyStopAutoTrade() async {
    final json = await _post('/api/v1/auto-trade/DEMO/emergency-stop');
    return AutoTradeStatus.fromJson(json);
  }

  Future<AiHealth> getAiHealth() async {
    final json = await _get('/api/v1/ai/health');
    return AiHealth.fromJson(json);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    if (!isConfigured) {
      throw const BrokerApiException('Backend belum dikonfigurasi.');
    }
    try {
      final response = await _client.get(_uri(path)).timeout(const Duration(seconds: 12));
      return _decode(response);
    } on TimeoutException {
      throw const BrokerApiException('Backend tidak merespons tepat waktu.');
    } on BrokerApiException {
      rethrow;
    } catch (_) {
      throw const BrokerApiException('Backend tidak dapat dijangkau.');
    }
  }

  Future<Map<String, dynamic>> _post(String path, {Duration timeout = const Duration(seconds: 20), Map<String, dynamic>? body}) async {
    if (!isConfigured) {
      throw const BrokerApiException('Backend belum dikonfigurasi.');
    }
    try {
      final response = await _client
          .post(_uri(path), headers: const {'Content-Type': 'application/json'}, body: body == null ? null : jsonEncode(body))
          .timeout(timeout);
      return _decode(response);
    } on TimeoutException {
      throw const BrokerApiException('Koneksi broker timeout. Tidak ada order yang dikirim.');
    } on BrokerApiException {
      rethrow;
    } catch (_) {
      throw const BrokerApiException('Backend tidak dapat dijangkau. Tidak ada order yang dikirim.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body = const {};
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        throw const BrokerApiException('Respons backend tidak valid.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 403) {
        throw const BrokerApiException('Akun REAL dikunci oleh kebijakan keamanan.', statusCode: 403);
      }
      final detail = body['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        throw BrokerApiException(detail, statusCode: response.statusCode);
      }
      if (response.statusCode == 409) {
        throw const BrokerApiException('Permintaan ditolak karena state backend belum siap.', statusCode: 409);
      }
      if (response.statusCode == 503) {
        throw const BrokerApiException('Health-check broker belum lulus.', statusCode: 503);
      }
      throw BrokerApiException('Permintaan backend ditolak.', statusCode: response.statusCode);
    }
    return body;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  void dispose() => _client.close();
}
