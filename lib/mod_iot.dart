library;

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'src/screens/device_list_screen.dart';

export 'src/capabilities/registry.dart';
export 'src/screens/device_list_screen.dart';

/// Implementasi modul IoT untuk super app Gumpalan.
class IotModule implements AppModule {
  @override
  String get id => 'iot';

  @override
  String get name => 'IoT';

  @override
  IconData get icon => Icons.devices_other;

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: '/iot',
      name: 'iot',
      builder: (context, state) => const DeviceListScreen(),
    ),
  ];

  @override
  Widget? get homeCard => Builder(
    builder: (context) => Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: const Text('Perangkat IoT'),
        subtitle: const Text('Kontrol dan pantau perangkat rumah pintar'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.push('/iot'),
      ),
    ),
  );

  @override
  Widget get homeScreen => const DeviceListScreen();
}
