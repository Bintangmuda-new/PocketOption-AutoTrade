import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/auto_trade_status.dart';
import '../models/broker_health.dart';
import '../networking/api_client.dart';

class AppController extends ChangeNotifier {
  AppController({required this.config}) : api = BrokerApiClient(baseUrl: config.apiBaseUrl) {
    connectionState = config.hasApi ? BrokerConnectionState.offline : BrokerConnectionState.notConfigured;
  }

  final AppConfig config;
  final BrokerApiClient api;

  AccountMode mode = AccountMode.demo;
  BrokerConnectionState connectionState = BrokerConnectionState.offline;
  BrokerHealth? health;
  String notice = 'DEMO aktif. Hubungkan backend untuk membaca health broker.';
  bool autoTradeRunning = false;
  AutoTradeStatus? autoTradeStatus;
  AiHealth? aiHealth;
  int _connectionEpoch = 0;

  bool get isDemoConnected =>
      mode == AccountMode.demo &&
      connectionState == BrokerConnectionState.connected &&
      health?.connected == true &&
      health?.balanceAvailable == true;

  void setNotice(String message) {
    notice = message;
    notifyListeners();
  }

  String get connectionLabel {
    switch (connectionState) {
      case BrokerConnectionState.notConfigured:
        return 'NOT CONFIGURED';
      case BrokerConnectionState.offline:
        return 'OFFLINE';
      case BrokerConnectionState.connecting:
        return 'CONNECTING';
      case BrokerConnectionState.connected:
        return 'CONNECTED';
      case BrokerConnectionState.error:
        return 'ERROR';
    }
  }

  Future<void> selectMode(AccountMode next) async {
    if (next == mode) return;
    final previousMode = mode;
    _connectionEpoch++;
    mode = next;
    autoTradeRunning = false;
    autoTradeStatus = null;
    aiHealth = null;
    health = null;
    connectionState = next == AccountMode.real
        ? BrokerConnectionState.offline
        : config.hasApi
            ? BrokerConnectionState.offline
            : BrokerConnectionState.notConfigured;
    notice = next == AccountMode.real
        ? 'REAL dipilih tetapi dikunci. Koneksi dan transaksi REAL belum diaktifkan.'
        : 'DEMO dipilih. Hubungkan backend untuk membaca data broker.';
    notifyListeners();

    // A mode switch must close the previous DEMO session. The backend also
    // enforces this boundary, but closing here makes the client fail-safe on
    // fast user interactions and application restarts.
    if (next == AccountMode.real && previousMode == AccountMode.demo && config.hasApi) {
      try {
        await api.disconnectDemo();
      } catch (_) {
        // The local REAL lock remains active even if the backend is offline.
      }
    }
  }

  Future<void> connectDemo() async {
    if (mode != AccountMode.demo) return;
    if (!config.hasApi) {
      connectionState = BrokerConnectionState.notConfigured;
      notice = 'Backend belum dikonfigurasi. Jalankan FastAPI dan isi API_BASE_URL.';
      notifyListeners();
      return;
    }
    connectionState = BrokerConnectionState.connecting;
    notice = 'Menghubungkan akun DEMO dan memeriksa saldo…';
    final epoch = ++_connectionEpoch;
    notifyListeners();
    try {
      final result = await api.connectDemo();
      if (epoch != _connectionEpoch || mode != AccountMode.demo) return;
      if (!result.connected || !result.balanceAvailable || result.accountMode != AccountMode.demo) {
        throw const BrokerApiException('Health-check broker belum lengkap. Entry tetap diblokir.');
      }
      health = result;
      connectionState = BrokerConnectionState.connected;
      notice = 'DEMO terhubung. ${result.pairCount ?? 0} pair tersedia. ${result.ordersEnabled ? 'Execution gate aktif; AI/Risk tetap wajib PASS.' : 'Execution gate masih OFF.'}';
      try {
        aiHealth = await api.getAiHealth();
      } catch (_) {
        aiHealth = null;
      }
    } on BrokerApiException catch (error) {
      if (epoch != _connectionEpoch || mode != AccountMode.demo) return;
      health = null;
      connectionState = BrokerConnectionState.error;
      notice = error.message;
    } catch (_) {
      if (epoch != _connectionEpoch || mode != AccountMode.demo) return;
      health = null;
      connectionState = BrokerConnectionState.error;
      notice = 'Koneksi DEMO gagal. Tidak ada order yang dikirim.';
    }
    notifyListeners();
  }

  Future<void> disconnectDemo() async {
    _connectionEpoch++;
    autoTradeRunning = false;
    if (config.hasApi && connectionState == BrokerConnectionState.connected) {
      try {
        await api.disconnectDemo();
      } catch (_) {
        // The safe local state is still applied if the backend is already down.
      }
    }
    health = null;
    connectionState = config.hasApi ? BrokerConnectionState.offline : BrokerConnectionState.notConfigured;
    notice = 'Koneksi DEMO diputus. Tidak ada order baru yang diizinkan.';
    notifyListeners();
  }

  Future<void> startAutoTrade() async {
    if (mode == AccountMode.real) {
      notice = 'REAL auto trade dikunci oleh safety policy.';
      notifyListeners();
      return;
    }
    if (!isDemoConnected || !config.hasApi) {
      notice = 'Hubungkan akun DEMO dan backend terlebih dahulu.';
      notifyListeners();
      return;
    }
    notice = 'Preflight Auto Trade memeriksa AI, market data, Risk, dan execution…';
    notifyListeners();
    try {
      final result = await api.startAutoTrade();
      autoTradeStatus = result;
      autoTradeRunning = result.running;
      notice = result.running ? 'Auto Trade RUNNING. Semua entry melewati Risk Engine.' : result.reason;
    } on BrokerApiException catch (error) {
      autoTradeRunning = false;
      notice = error.message;
    }
    notifyListeners();
  }

  Future<void> stopAutoTrade() async {
    if (config.hasApi && mode == AccountMode.demo && isDemoConnected) {
      try {
        autoTradeStatus = await api.stopAutoTrade();
      } catch (_) {
        // Local state remains stopped when the backend is already unavailable.
      }
    }
    autoTradeRunning = false;
    notice = 'Auto Trade dihentikan.';
    notifyListeners();
  }

  Future<void> emergencyStop() async {
    _connectionEpoch++;
    if (config.hasApi && mode == AccountMode.demo) {
      try {
        autoTradeStatus = await api.emergencyStopAutoTrade();
      } catch (_) {
        // Local state remains stopped even if the backend cannot be reached.
      }
    }
    autoTradeRunning = false;
    notice = 'EMERGENCY STOP aktif. Aktivitas AI dan entry baru diblokir.';
    notifyListeners();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
