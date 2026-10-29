import 'package:flutter/material.dart';

import '../data/iot_service.dart';
import '../data/models/iot_models.dart';

/// Layar daftar perangkat IoT dengan tata letak modern.
/// Menampilkan channel telemetri dan kontrol langsung per perangkat.
class DeviceListScreen extends StatefulWidget {
  final IotService? service;

  const DeviceListScreen({super.key, this.service});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  late final IotService _service;
  List<IotDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? IotService();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getDevices();
      if (mounted) {
        setState(() {
          _devices = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback data demo jika backend belum aktif
      if (mounted) {
        setState(() {
          _devices = const [
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendCommand(
    String deviceId,
    String channelId,
    dynamic value,
  ) async {
    setState(() {
      final idx = _devices.indexWhere((d) => d.id == deviceId);
      if (idx != -1) {
        _devices[idx] = _devices[idx].copyWithState(channelId, value);
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final dev = _devices[index];

          return Card(
            elevation: isDark ? 0 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? colors.outline.withValues(alpha: 0.2)
                    : colors.outlineVariant.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.devices_rounded,
                          size: 22,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dev.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ID: ${dev.id} • Driver: ${dev.driver}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  ...dev.channels.map((ch) {
                    final currentVal = dev.states[ch.id];

                    if (ch.type == 'boolean' &&
                        (ch.direction == 'output' ||
                            ch.direction == 'bidirectional')) {
                      final isOn =
                          currentVal == true ||
                          currentVal == 'true' ||
                          currentVal == 'on' ||
                          currentVal == 'ON';
                      return SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(ch.name),
                        subtitle: Text('Channel: ${ch.id}'),
                        value: isOn,
                        onChanged: (val) => _sendCommand(dev.id, ch.id, val),
                      );
                    }

                    if (ch.type == 'number' &&
                        (ch.direction == 'output' ||
                            ch.direction == 'bidirectional')) {
                      final double min = ch.min ?? 0;
                      final double max = ch.max ?? 100;
                      double val = min;
                      if (currentVal is num) {
                        val = (currentVal).toDouble();
                      }
                      val = val.clamp(min, max);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(ch.name),
                                Text(
                                  '${val.toInt()} ${ch.unit ?? ""}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Slider(
                            value: val,
                            min: min,
                            max: max,
                            onChanged: (newVal) =>
                                _sendCommand(dev.id, ch.id, newVal.round()),
                          ),
                        ],
                      );
                    }

                    // Telemetri / Input
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sensors_rounded, size: 20),
                      title: Text(ch.name),
                      subtitle: Text('Channel: ${ch.id}'),
                      trailing: Text(
                        '${currentVal ?? "--"} ${ch.unit ?? ""}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
