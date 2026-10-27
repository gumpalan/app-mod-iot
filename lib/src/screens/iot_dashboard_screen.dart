import 'dart:async';
import 'package:flutter/material.dart';
import '../data/iot_service.dart';
import '../data/models/iot_models.dart';
import '../widgets/iot_widgets.dart';
import 'dashboard_editor_screen.dart';
import 'device_list_screen.dart';
import 'explore_dashboards_screen.dart';

/// Layar utama dashboard IoT bergaya Blynk dengan kustomisasi kanvas penuh.
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
  DashboardModel? _activeDashboard;
  final Map<String, Map<String, dynamic>> _deviceStates = {}; // devID -> chID -> val

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? IotService();
    _initDataAndSocket();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    if (widget.service == null) {
      _service.dispose();
    }
    super.dispose();
  }

  Future<void> _initDataAndSocket() async {
    setState(() => _isLoading = true);
    await _loadDashboardsAndDevices();
    _connectWebSocket();
  }

  Future<void> _loadDashboardsAndDevices() async {
    try {
      final futures = await Future.wait([
        _service.getDashboards(),
        _service.getDevices(),
      ]);

      final dashboards = futures[0] as List<DashboardModel>;
      final devices = futures[1] as List<IotDevice>;

      for (final dev in devices) {
        _deviceStates[dev.id] = Map<String, dynamic>.from(dev.states);
      }

      if (mounted) {
        setState(() {
          _dashboards = dashboards;
          if (_dashboards.isNotEmpty) {
            // Pilih dashboard pertama atau pertahankan yang sedang aktif
            _activeDashboard = _dashboards.firstWhere(
              (d) => d.id == _activeDashboard?.id,
              orElse: () => _dashboards.first,
            );
          } else {
            _activeDashboard = null;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
      String deviceId, String channelId, dynamic value) async {
    // Update optimistik lokal untuk latensi instan
    setState(() {
      _deviceStates.putIfAbsent(deviceId, () => {})[channelId] = value;
    });

    try {
      await _service.sendCommand(deviceId, channelId, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim perintah: $e')),
        );
      }
    }
  }

  void _openEditor([DashboardModel? dash]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => DashboardEditorScreen(
          iotService: _service,
          initialDashboard: dash,
        ),
      ),
    );

    if (result == true) {
      _loadDashboardsAndDevices();
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
      _loadDashboardsAndDevices();
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. TAMPILAN JIKA BELUM ADA DASHBOARD DIATUR
    if (_dashboards.isEmpty || _activeDashboard == null) {
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
              'Dashboard IoT Belum Diatur',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kustomisasi tampilan kanvas saklar, slider dimmer, dan meteran sensor Anda atau gunakan tata letak siap pakai dari pengguna lain.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Buat Dashboard Baru
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Atur Dashboard Baru'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Jelajahi Layout Pengguna Lain
            SizedBox(
              height: 50,
              child: FilledButton.tonalIcon(
                onPressed: _openExplore,
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Jelajahi Layout Pengguna Lain'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Langsung Lihat Semua Perangkat
            Center(
              child: TextButton.icon(
                onPressed: _openDeviceList,
                icon: const Icon(Icons.devices_other_rounded, size: 18),
                label: const Text('Lihat Daftar Seluruh Perangkat'),
              ),
            ),
          ],
        ),
      );
    }

    // 2. TAMPILAN DASHBOARD AKTIF DENGAN KANVAS WIDGET
    final active = _activeDashboard!;
    final widgets = active.widgets;

    return RefreshIndicator(
      onRefresh: _loadDashboardsAndDevices,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header Bar Dashboard
          Row(
            children: [
              Expanded(
                child: _dashboards.length > 1
                    ? DropdownButtonHideUnderline(
                        child: DropdownButton<DashboardModel>(
                          value: active,
                          isDense: true,
                          items: _dashboards.map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(
                                d.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newDash) {
                            if (newDash != null) {
                              setState(() => _activeDashboard = newDash);
                            }
                          },
                        ),
                      )
                    : Text(
                        active.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              IconButton(
                tooltip: 'Edit Dashboard',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openEditor(active),
              ),
              IconButton(
                tooltip: 'Jelajahi Layout Lain',
                icon: const Icon(Icons.explore_outlined),
                onPressed: _openExplore,
              ),
              IconButton(
                tooltip: 'Daftar Perangkat',
                icon: const Icon(Icons.devices_outlined),
                onPressed: _openDeviceList,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widgets.isEmpty)
            Card(
              elevation: isDark ? 0 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      size: 44,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kanvas Belum Ada Widget',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dashboard "${active.name}" masih kosong. Tekan tombol edit di atas untuk memasang widget.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => _openEditor(active),
                      child: const Text('Tambah Widget Sekarang'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...widgets.map((w) {
              final devStates = _deviceStates[w.deviceId] ?? {};
              final currentVal = devStates[w.channelId];

              Widget builtWidget;
              switch (w.widgetType) {
                case 'slider':
                  builtWidget = IotSliderWidget(
                    config: w,
                    currentState: currentVal,
                    onCommand: _handleCommand,
                  );
                case 'gauge':
                  builtWidget = IotGaugeWidget(
                    config: w,
                    currentState: currentVal,
                  );
                case 'value_card':
                  builtWidget = IotValueCardWidget(
                    config: w,
                    currentState: currentVal,
                  );
                case 'button':
                  builtWidget = IotButtonWidget(
                    config: w,
                    onCommand: _handleCommand,
                  );
                case 'toggle':
                default:
                  builtWidget = IotToggleWidget(
                    config: w,
                    currentState: currentVal,
                    onCommand: _handleCommand,
                  );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: builtWidget,
              );
            }),
        ],
      ),
    );
  }
}
