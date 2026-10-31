import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core_api/core_api.dart';
import 'package:flutter/foundation.dart';

import 'models/iot_models.dart';

/// Service untuk orkestrasi data IoT, dashboard pengguna, dan stream WebSocket real-time.
class IotService {
  final ApiClient apiClient;
  final String wsBaseUrl;

  WebSocket? _socket;
  Timer? _pingTimer;
  final _stateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stateStream => _stateController.stream;

  /// Notifikasi id layout dashboard yang sedang aktif.
  /// Dibagi (shared) antar layar (dashboard, kelola layout, explore)
  /// pada satu instance service agar perubahan langsung terlihat.
  final activeLayout = ValueNotifier<String?>(null);

  /// Notifikasi pembaruan data/daftar dashboard.
  final dashboardsChanged = ValueNotifier<int>(0);

  void notifyDashboardsChanged() {
    dashboardsChanged.value++;
  }

  IotService({ApiClient? client, String? baseUrl, String? wsUrl})
    : apiClient =
          client ??
          ApiClient(
            baseUrl: baseUrl ?? 'http://127.0.0.1:8080',
            tokenStorage: SharedPrefsTokenStorage(),
          ),
      wsBaseUrl =
          wsUrl ??
          (baseUrl != null
              ? (baseUrl.startsWith('https://')
                    ? baseUrl.replaceFirst('https://', 'wss://')
                    : baseUrl.replaceFirst('http://', 'ws://'))
              : 'ws://127.0.0.1:8080');

  /// Mengambil daftar seluruh perangkat dan status channel terkini.
  Future<List<IotDevice>> getDevices() async {
    final response = await apiClient.get('/iot/v1/devices');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => IotDevice.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat perangkat (${response.statusCode})');
  }

  /// Mengirimkan perintah ke channel perangkat.
  Future<void> sendCommand(
    String deviceId,
    String channelId,
    dynamic value,
  ) async {
    // Coba kirim via WebSocket bila terhubung untuk latensi instan
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      try {
        _socket!.add(
          jsonEncode({
            'type': 'command',
            'deviceId': deviceId,
            'channelId': channelId,
            'value': value,
          }),
        );
        return;
      } catch (_) {}
    }

    // Fallback ke HTTP REST
    final response = await apiClient.post(
      '/iot/v1/devices/$deviceId/command',
      body: {'channel': channelId, 'value': value},
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengirim perintah (${response.statusCode})');
    }
  }

  /// Mengambil daftar layout dashboard milik pengguna saat ini.
  Future<List<DashboardModel>> getDashboards() async {
    final response = await apiClient.get('/iot/v1/dashboards');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => DashboardModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat dashboard (${response.statusCode})');
  }

  /// Membuat layout dashboard baru.
  Future<DashboardModel> createDashboard({
    required String name,
    required bool isPublic,
    required List<DashboardWidgetConfig> widgets,
  }) async {
    final deviceIds = widgets.map((w) => w.deviceId).toSet().toList();
    final response = await apiClient.post(
      '/iot/v1/dashboards',
      body: {
        'name': name,
        'isPublic': isPublic,
        'layoutJson': jsonEncode(widgets.map((w) => w.toJson()).toList()),
        'deviceIds': deviceIds,
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      notifyDashboardsChanged();
      return DashboardModel.fromJson(data);
    }
    throw Exception('Gagal membuat dashboard (${response.statusCode})');
  }

  /// Memperbarui layout dashboard yang ada.
  Future<DashboardModel> updateDashboard(DashboardModel dash) async {
    final deviceIds = dash.widgets.map((w) => w.deviceId).toSet().toList();
    final response = await apiClient.put(
      '/iot/v1/dashboards/${dash.id}',
      body: {
        'name': dash.name,
        'isPublic': dash.isPublic,
        'layoutJson': jsonEncode(dash.widgets.map((w) => w.toJson()).toList()),
        'deviceIds': deviceIds,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      notifyDashboardsChanged();
      return DashboardModel.fromJson(data);
    }
    throw Exception('Gagal memperbarui dashboard (${response.statusCode})');
  }

  /// Menghapus layout dashboard.
  Future<void> deleteDashboard(String id) async {
    final response = await apiClient.delete('/iot/v1/dashboards/$id');
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus dashboard (${response.statusCode})');
    }
    notifyDashboardsChanged();
  }

  /// Mengambil layout dashboard publik pengguna lain yang kompatibel.
  Future<List<DashboardModel>> getExploreDashboards() async {
    final response = await apiClient.get('/iot/v1/dashboards/explore');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => DashboardModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat layout publik (${response.statusCode})');
  }

  /// Melakukan kloning layout dashboard milik orang lain ke akun pengguna.
  Future<DashboardModel> cloneDashboard(String id) async {
    final response = await apiClient.post('/iot/v1/dashboards/$id/clone');
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      notifyDashboardsChanged();
      return DashboardModel.fromJson(data);
    }
    throw Exception('Gagal mengkloning dashboard (${response.statusCode})');
  }

  // -------------------------------------------------------------------------
  // Operasi Aturan Otomasi (Automation Rules)
  // -------------------------------------------------------------------------

  /// Mengambil daftar aturan otomasi milik pengguna saat ini.
  Future<List<AutomationRule>> fetchRules() async {
    final response = await apiClient.get('/iot/v1/rules');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => AutomationRule.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Gagal memuat aturan otomasi (${response.statusCode})');
  }

  String _extractErrorMessage(dynamic body, int statusCode, String fallback) {
    try {
      final parsed = jsonDecode(body.toString());
      if (parsed is Map && parsed['error'] != null) {
        return parsed['error'].toString();
      }
    } catch (_) {}
    return '$fallback ($statusCode)';
  }

  /// Membuat aturan otomasi baru.
  Future<AutomationRule> createRule(AutomationRule rule) async {
    final response = await apiClient.post('/iot/v1/rules', body: rule.toJson());
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AutomationRule.fromJson(data);
    }
    throw Exception(
      _extractErrorMessage(
        response.body,
        response.statusCode,
        'Gagal membuat aturan',
      ),
    );
  }

  /// Memperbarui aturan otomasi yang sudah ada.
  Future<AutomationRule> updateRule(AutomationRule rule) async {
    final response = await apiClient.put(
      '/iot/v1/rules/${rule.id}',
      body: rule.toJson(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AutomationRule.fromJson(data);
    }
    throw Exception(
      _extractErrorMessage(
        response.body,
        response.statusCode,
        'Gagal memperbarui aturan',
      ),
    );
  }

  /// Mengubah status aktif/nonaktif aturan otomasi.
  Future<bool> toggleRule(String id, bool enabled) async {
    final response = await apiClient.patch(
      '/iot/v1/rules/$id/toggle',
      body: {'enabled': enabled},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['enabled'] as bool? ?? enabled;
    }
    throw Exception(
      _extractErrorMessage(
        response.body,
        response.statusCode,
        'Gagal mengubah status aturan',
      ),
    );
  }

  /// Menghapus aturan otomasi.
  Future<void> deleteRule(String id) async {
    final response = await apiClient.delete('/iot/v1/rules/$id');
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response.body,
          response.statusCode,
          'Gagal menghapus aturan',
        ),
      );
    }
  }

  /// Menjalankan uji coba eksekusi aksi aturan otomasi secara instan.
  Future<void> testRule(String id) async {
    final response = await apiClient.post('/iot/v1/rules/$id/test');
    if (response.statusCode != 200) {
      throw Exception('Gagal menguji aksi aturan (${response.statusCode})');
    }
  }

  /// Menghubungkan client WebSocket ke backend svc-iot.
  Future<void> connectWebSocket() async {
    try {
      final token = await apiClient.tokenStorage.readToken();
      final uri = Uri.parse('$wsBaseUrl/iot/v1/ws');

      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      _socket = await WebSocket.connect(uri.toString(), headers: headers);
      _socket!.listen(
        (data) {
          try {
            final parsed = jsonDecode(data.toString()) as Map<String, dynamic>;
            _stateController.add(parsed);
          } catch (_) {}
        },
        onError: (_) => _reconnectWebSocket(),
        onDone: () => _reconnectWebSocket(),
        cancelOnError: true,
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (_socket != null && _socket!.readyState == WebSocket.open) {
          _socket!.add(jsonEncode({'type': 'ping'}));
        }
      });
    } catch (_) {
      _reconnectWebSocket();
    }
  }

  void _reconnectWebSocket() {
    _socket = null;
    _pingTimer?.cancel();
    Future.delayed(const Duration(seconds: 4), () {
      connectWebSocket();
    });
  }

  // -------------------------------------------------------------------------
  // History API
  // -------------------------------------------------------------------------

  /// Mengambil kemampuan history yang diaktifkan server.
  /// Jika endpoint tidak tersedia (server lama), kembalikan HistoryCapabilities.none().
  Future<HistoryCapabilities> getHistoryCapabilities() async {
    try {
      final response = await apiClient.get('/iot/v1/history/capabilities');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return HistoryCapabilities.fromJson(data);
      }
    } catch (_) {}
    return HistoryCapabilities.none();
  }

  /// Mengambil log sensor untuk device tertentu.
  /// [channelId] opsional — kosong berarti semua channel.
  /// [from] dan [to] adalah unix timestamp detik; jika null, server pakai default (24 jam terakhir).
  /// [limit] maksimum jumlah entri (default server: 200, max: 1000).
  Future<List<SensorLogEntry>> getSensorHistory(
    String deviceId, {
    String? channelId,
    int? from,
    int? to,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (channelId != null && channelId.isNotEmpty) params['channel'] = channelId;
    if (from != null) params['from'] = from.toString();
    if (to != null) params['to'] = to.toString();
    if (limit != null) params['limit'] = limit.toString();

    final uri = Uri.parse(
      '/iot/v1/devices/$deviceId/history/sensor',
    ).replace(queryParameters: params.isEmpty ? null : params);

    final response = await apiClient.get(uri.toString());
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => SensorLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      _extractErrorMessage(response.body, response.statusCode, 'Gagal memuat sensor history'),
    );
  }

  /// Mengambil log aktuator untuk device tertentu.
  Future<List<ActuatorLogEntry>> getActuatorHistory(
    String deviceId, {
    String? channelId,
    int? from,
    int? to,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (channelId != null && channelId.isNotEmpty) params['channel'] = channelId;
    if (from != null) params['from'] = from.toString();
    if (to != null) params['to'] = to.toString();
    if (limit != null) params['limit'] = limit.toString();

    final uri = Uri.parse(
      '/iot/v1/devices/$deviceId/history/actuator',
    ).replace(queryParameters: params.isEmpty ? null : params);

    final response = await apiClient.get(uri.toString());
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => ActuatorLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      _extractErrorMessage(response.body, response.statusCode, 'Gagal memuat actuator history'),
    );
  }

  void dispose() {
    _pingTimer?.cancel();
    _socket?.close();
    _stateController.close();
    activeLayout.dispose();
  }
}
