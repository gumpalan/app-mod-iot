library;

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'src/data/iot_service.dart';
import 'src/screens/dashboard_editor_screen.dart';
import 'src/screens/device_list_screen.dart';
import 'src/screens/explore_dashboards_screen.dart';
import 'src/screens/iot_dashboard_screen.dart';

export 'src/capabilities/registry.dart';
export 'src/data/iot_service.dart';
export 'src/data/models/iot_models.dart';
export 'src/screens/dashboard_editor_screen.dart';
export 'src/screens/device_list_screen.dart';
export 'src/screens/explore_dashboards_screen.dart';
export 'src/screens/iot_dashboard_screen.dart';
export 'src/widgets/iot_widgets.dart';

/// Implementasi modul IoT untuk super app Gumpalan.
class IotModule implements AppModule {
  final IotService? service;

  IotModule({this.service});

  @override
  String get id => 'iot';

  @override
  String get name => 'IoT';

  @override
  IconData get icon => Icons.devices_other_rounded;

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/iot',
          name: 'iot',
          builder: (context, state) => IotDashboardScreen(service: service),
          routes: [
            GoRoute(
              path: 'edit',
              name: 'iot-edit',
              builder: (context, state) => DashboardEditorScreen(
                iotService: service ?? IotService(),
              ),
            ),
            GoRoute(
              path: 'explore',
              name: 'iot-explore',
              builder: (context, state) => ExploreDashboardsScreen(
                iotService: service ?? IotService(),
              ),
            ),
            GoRoute(
              path: 'devices',
              name: 'iot-devices',
              builder: (context, state) => Scaffold(
                appBar: AppBar(title: const Text('Daftar Perangkat')),
                body: DeviceListScreen(service: service),
              ),
            ),
          ],
        ),
      ];

  @override
  Widget? get homeCard => Builder(
        builder: (context) => Card(
          child: ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: const Text('Dashboard IoT'),
            subtitle: const Text('Kontrol dan pantau kanvas perangkat pintar'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/iot'),
          ),
        ),
      );

  @override
  Widget get homeScreen => IotDashboardScreen(service: service);
}
