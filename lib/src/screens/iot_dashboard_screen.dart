import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/iot_service.dart';
import '../data/models/iot_models.dart';
import '../widgets/iot_widgets.dart';
import 'dashboard_editor_screen.dart';
import 'device_list_screen.dart';
import 'explore_dashboards_screen.dart';

/// Pref key layout dashboard IoT yang sedang aktif.
const kIotActiveDashboardPref = 'iot_active_dashboard_id';

/// Layar dashboard IoT: kanvas bersih berisi widget saja.
/// Nama layout, aksi pengaturan, dan navigasi dipindah ke tab Menu.
class IotDashboardScreen extends StatefulWidget {
  final IotService? service;

  const IotDashboardScreen({super.key, this.service});

  @override
  State<IotDashboardScreen> createState() => _IotDashboardScreenState();
}

class _IotDashboardScreenState extends State<IotDashboardScreen> {
  late final IotService _service;
  StreamSubscription? _wsSubscription;

  List<DashboardModel> _dashboards = [];
  String? _activeDashboardId;
  List<IotDevice> _devices = [];
  final Map<String, Map<String, dynamic>> _deviceStates =
      {}; // devID -> chID -> val

  // History
  HistoryCapabilities _historyCaps = HistoryCapabilities.none();
  // cache: key = "deviceId/channelId" -> data
  final Map<String, List<SensorLogEntry>> _sensorCache = {};
  final Map<String, List<ActuatorLogEntry>> _actuatorCache = {};
  final Map<String, bool> _historyLoading = {};
  final Map<String, String?> _historyError = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? IotService();
    _service.activeLayout.addListener(_onActiveLayoutChanged);
    _service.dashboardsChanged.addListener(_onDashboardsChanged);
    _initDataAndSocket();
  }

  void _onActiveLayoutChanged() {
    final newId = _service.activeLayout.value;
    if (newId != _activeDashboardId) {
      setState(() => _activeDashboardId = newId);
    }
  }

  void _onDashboardsChanged() {
    _loadDashboardsAndDevices();
  }

  @override
  void dispose() {
    _service.activeLayout.removeListener(_onActiveLayoutChanged);
    _service.dashboardsChanged.removeListener(_onDashboardsChanged);
    _wsSubscription?.cancel();
    if (widget.service == null) {
      _service.dispose();
    }
    super.dispose();
  }

  Future<void> _initDataAndSocket() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _activeDashboardId =
        _service.activeLayout.value ?? prefs.getString(kIotActiveDashboardPref);
    _service.activeLayout.value = _activeDashboardId;
    // Muat capabilities history di background — tidak memblokir UI
    _service.getHistoryCapabilities().then((caps) {
      if (mounted) setState(() => _historyCaps = caps);
    });
    await _loadDashboardsAndDevices();
    _connectWebSocket();
  }

  String _historyKey(String deviceId, String channelId) => '$deviceId/$channelId';

  Future<void> _fetchSensorHistory(String deviceId, String channelId) async {
    final key = _historyKey(deviceId, channelId);
    if (_historyLoading[key] == true) return;
    setState(() {
      _historyLoading[key] = true;
      _historyError[key] = null;
    });
    try {
      final data = await _service.getSensorHistory(deviceId, channelId: channelId);
      if (mounted) {
        setState(() {
          _sensorCache[key] = data;
          _historyLoading[key] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError[key] = e.toString();
          _historyLoading[key] = false;
        });
      }
    }
  }

  Future<void> _fetchActuatorHistory(String deviceId, String channelId) async {
    final key = _historyKey(deviceId, channelId);
    if (_historyLoading[key] == true) return;
    setState(() {
      _historyLoading[key] = true;
      _historyError[key] = null;
    });
    try {
      final data = await _service.getActuatorHistory(deviceId, channelId: channelId);
      if (mounted) {
        setState(() {
          _actuatorCache[key] = data;
          _historyLoading[key] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError[key] = e.toString();
          _historyLoading[key] = false;
        });
      }
    }
  }

  Future<void> _loadDashboardsAndDevices() async {
    List<DashboardModel> dashboards = [];
    List<IotDevice> devices = [];

    try {
      dashboards = await _service.getDashboards();
    } catch (_) {}

    try {
      devices = await _service.getDevices();
    } catch (_) {
      // Fallback demo jika belum terkoneksi
      if (_devices.isEmpty) {
        devices = const [
          IotDevice(
            id: 'living-room-sensor',
            name: 'Sensor Ruang Tamu',
            driver: 'custom',
            channels: [
              DeviceChannel(
                id: 'temperature',
                name: 'Suhu',
                direction: 'input',
                type: 'number',
                unit: '°C',
                uiHint: 'gauge',
              ),
              DeviceChannel(
                id: 'humidity',
                name: 'Kelembaban',
                direction: 'input',
                type: 'number',
                unit: '%',
                uiHint: 'value_display',
              ),
              DeviceChannel(
                id: 'fan_power',
                name: 'Power Kipas',
                direction: 'bidirectional',
                type: 'boolean',
                uiHint: 'toggle',
              ),
            ],
            states: {'temperature': 27.5, 'fan_power': true},
          ),
          IotDevice(
            id: 'lampu-kamar',
            name: 'Lampu Kamar Tidur',
            driver: 'tasmota',
            channels: [
              DeviceChannel(
                id: 'power',
                name: 'Power Lampu',
                direction: 'bidirectional',
                type: 'boolean',
                uiHint: 'toggle',
              ),
            ],
            states: {'power': false},
          ),
        ];
      } else {
        devices = _devices;
      }
    }

    for (final dev in devices) {
      _deviceStates[dev.id] = Map<String, dynamic>.from(dev.states);
    }

    // Jaga: id aktif yang tersimpan harus masih ada di daftar layout.
    if (_activeDashboardId != null &&
        dashboards.every((d) => d.id != _activeDashboardId)) {
      _activeDashboardId = null;
    }

    // Jika belum ada layout aktif tapi daftar layout tidak kosong, pakai layout pertama.
    if (_activeDashboardId == null && dashboards.isNotEmpty) {
      _activeDashboardId = dashboards.first.id;
      _service.activeLayout.value = _activeDashboardId;
      SharedPreferences.getInstance().then((p) {
        p.setString(kIotActiveDashboardPref, _activeDashboardId!);
      });
    }

    if (mounted) {
      setState(() {
        _dashboards = dashboards;
        _devices = devices;
        _isLoading = false;
      });
    }
  }

  DashboardModel? get _activeDashboard => _activeDashboardId == null
      ? null
      : _dashboards
            .where((d) => d.id == _activeDashboardId)
            .cast<DashboardModel?>()
            .firstWhere((_) => true, orElse: () => null);

  Future<void> _setActiveDashboard(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(kIotActiveDashboardPref);
    } else {
      await prefs.setString(kIotActiveDashboardPref, id);
    }
    _service.activeLayout.value = id;
    if (mounted) {
      setState(() => _activeDashboardId = id);
    }
  }

  void _connectWebSocket() {
    _service.connectWebSocket();
    _wsSubscription = _service.stateStream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'state_change') {
        final devId = event['deviceId'] as String?;
        final chId = event['channelId'] as String?;
        final val = event['value'];
        if (devId != null && chId != null) {
          setState(() {
            _deviceStates.putIfAbsent(devId, () => {})[chId] = val;
          });
        }
      } else if (type == 'init') {
        final data = event['data'] as Map<String, dynamic>?;
        final states = data?['states'] as Map<String, dynamic>?;
        if (states != null) {
          setState(() {
            states.forEach((devId, chMap) {
              if (chMap is Map<String, dynamic>) {
                _deviceStates[devId] = Map<String, dynamic>.from(chMap);
              }
            });
          });
        }
      }
    });
  }

  Future<void> _handleCommand(
    String deviceId,
    String channelId,
    dynamic value,
  ) async {
    // Update optimistik lokal untuk latensi instan
    setState(() {
      _deviceStates.putIfAbsent(deviceId, () => {})[channelId] = value;
    });

    try {
      await _service.sendCommand(deviceId, channelId, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim perintah: $e')));
      }
    }
  }

  Future<void> _openEditor([DashboardModel? dash]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => DashboardEditorScreen(
          iotService: _service,
          initialDashboard: dash,
          initialDevices: _devices,
        ),
      ),
    );

    if (result == true) {
      await _loadDashboardsAndDevices();
      // Layout baru langsung jadi aktif; layout lama dipertahankan jika id-nya ada.
      if (_activeDashboardId == null && _dashboards.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kIotActiveDashboardPref, _dashboards.first.id);
        if (mounted) {
          setState(() => _activeDashboardId = _dashboards.first.id);
        }
      }
    }
  }

  void _openExplore() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => ExploreDashboardsScreen(iotService: _service),
      ),
    );

    if (result == true) {
      await _loadDashboardsAndDevices();
      // Klon baru selalu jadi layout aktif (bisa diubah lagi lewat Layout Saya).
      if (_dashboards.isNotEmpty) {
        await _setActiveDashboard(_dashboards.last.id);
      }
    }
  }

  void _openDeviceList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Daftar Perangkat Terhubung')),
          body: DeviceListScreen(service: _service),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. TAMPILAN JIKA BELUM ADA DASHBOARD AKTIF
    final active = _activeDashboard;
    if (active == null) {
      final colors = Theme.of(context).colorScheme;
      final theme = Theme.of(context);
      return RefreshIndicator(
        onRefresh: _loadDashboardsAndDevices,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.dashboard_customize_outlined,
                  size: 64,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _dashboards.isEmpty
                  ? 'Belum Ada Layout Dashboard'
                  : 'Pilih Layout Aktif',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _dashboards.isEmpty
                  ? 'Buat layout pertama Anda atau gunakan tata letak siap pakai dari pengguna lain. Kelola semuanya lewat tab Menu.'
                  : 'Anda punya ${_dashboards.length} layout. Buka tab Menu lalu pilih "Layout Saya" untuk menentukan layout yang aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            if (_dashboards.isEmpty)
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Atur Layout Baru'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // 2. KANVAS BERSIH: HANYA WIDGET, TANPA NAMA LAYOUT & AKSI
    final widgets = active.widgets;

    return RefreshIndicator(
      onRefresh: _loadDashboardsAndDevices,
      child: widgets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Layout ini belum punya widget.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                for (final w in widgets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildWidget(w),
                  ),
              ],
            ),
    );
  }

  Widget _buildWidget(DashboardWidgetConfig w) {
    final devStates = _deviceStates[w.deviceId] ?? {};
    final currentVal = devStates[w.channelId];

    switch (w.widgetType) {
      case 'slider':
        return IotSliderWidget(
          config: w,
          currentState: currentVal,
          onCommand: _handleCommand,
        );
      case 'gauge':
        return IotGaugeWidget(config: w, currentState: currentVal);
      case 'value_card':
        return IotValueCardWidget(config: w, currentState: currentVal);
      case 'button':
        return IotButtonWidget(config: w, onCommand: _handleCommand);
      case 'hold_button':
        return IotHoldButtonWidget(
          config: w,
          currentState: currentVal,
          onCommand: _handleCommand,
        );

      // Widget history — hanya dirender jika server mendukung
      case 'chart':
        if (!_historyCaps.sensor) {
          return const SizedBox.shrink(); // server tidak aktifkan sensor history
        }
        final key = _historyKey(w.deviceId, w.channelId);
        // Trigger fetch saat pertama kali widget muncul (jika belum ada cache)
        if (!_sensorCache.containsKey(key) && _historyLoading[key] != true) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fetchSensorHistory(w.deviceId, w.channelId),
          );
        }
        return SensorChartWidget(
          title: w.title,
          unit: w.unit,
          entries: _sensorCache[key] ?? [],
          isLoading: _historyLoading[key] ?? false,
          error: _historyError[key],
        );

      case 'actuator_log':
        if (!_historyCaps.actuator) {
          return const SizedBox.shrink();
        }
        final key = _historyKey(w.deviceId, w.channelId);
        if (!_actuatorCache.containsKey(key) && _historyLoading[key] != true) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fetchActuatorHistory(w.deviceId, w.channelId),
          );
        }
        return ActuatorLogWidget(
          title: w.title,
          entries: _actuatorCache[key] ?? [],
          isLoading: _historyLoading[key] ?? false,
          error: _historyError[key],
        );

      case 'toggle':
      default:
        return IotToggleWidget(
          config: w,
          currentState: currentVal,
          onCommand: _handleCommand,
        );
    }
  }
}
