import 'package:flutter/material.dart';

typedef CapabilityWidgetBuilder = Widget Function(
  BuildContext context,
  String deviceId,
  Map<String, dynamic> capability,
  ValueChanged<dynamic> onCommand,
);

/// Registry kapabilitas UI: memetakan tipe kapabilitas (switch, dimmer, sensor)
/// ke builder widget. Jika tipe belum dikenal, fallback ke kartu generik.
class CapabilityRegistry {
  CapabilityRegistry._();

  static final Map<String, CapabilityWidgetBuilder> _registry = {
    'switch': _buildSwitch,
    'dimmer': _buildDimmer,
    'sensor': _buildSensor,
  };

  static void register(String type, CapabilityWidgetBuilder builder) {
    _registry[type] = builder;
  }

  static Widget build(
    BuildContext context,
    String deviceId,
    Map<String, dynamic> capability,
    ValueChanged<dynamic> onCommand,
  ) {
    final type = capability['type'] as String? ?? 'unknown';
    final builder = _registry[type] ?? _buildGeneric;
    return builder(context, deviceId, capability, onCommand);
  }

  static Widget _buildSwitch(
    BuildContext context,
    String deviceId,
    Map<String, dynamic> capability,
    ValueChanged<dynamic> onCommand,
  ) {
    final state = capability['state'] == 'on' || capability['state'] == true;
    return SwitchListTile(
      title: const Text('Saklar'),
      value: state,
      onChanged: (val) => onCommand(val ? 'on' : 'off'),
    );
  }

  static Widget _buildDimmer(
    BuildContext context,
    String deviceId,
    Map<String, dynamic> capability,
    ValueChanged<dynamic> onCommand,
  ) {
    final rawVal = capability['value'];
    final double value = (rawVal is num) ? rawVal.toDouble() : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Tingkat Kecerahan: ${value.toInt()}%'),
        ),
        Slider(
          value: value.clamp(0.0, 100.0),
          min: 0,
          max: 100,
          divisions: 20,
          onChanged: (newVal) => onCommand(newVal.round()),
        ),
      ],
    );
  }

  static Widget _buildSensor(
    BuildContext context,
    String deviceId,
    Map<String, dynamic> capability,
    ValueChanged<dynamic> onCommand,
  ) {
    final val = capability['value'] ?? capability['state'] ?? '-';
    return ListTile(
      leading: const Icon(Icons.sensors),
      title: const Text('Sensor'),
      trailing: Text(
        '$val',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  static Widget _buildGeneric(
    BuildContext context,
    String deviceId,
    Map<String, dynamic> capability,
    ValueChanged<dynamic> onCommand,
  ) {
    final type = capability['type'] ?? 'unknown';
    final val = capability['value'] ?? capability['state'] ?? '-';
    return ListTile(
      leading: const Icon(Icons.device_unknown),
      title: Text('Kemampuan: $type'),
      subtitle: Text('Nilai: $val'),
    );
  }
}
