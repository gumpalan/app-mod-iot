library;

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'src/data/iot_service.dart';
import 'src/screens/dashboard_editor_screen.dart';
import 'src/screens/device_list_screen.dart';
import 'src/screens/explore_dashboards_screen.dart';
import 'src/screens/iot_dashboard_screen.dart';
import 'src/screens/kelola_layouts.dart';

export 'src/capabilities/registry.dart';
export 'src/data/iot_service.dart';
export 'src/data/models/iot_models.dart';
export 'src/screens/dashboard_editor_screen.dart';
export 'src/screens/device_list_screen.dart';
export 'src/screens/explore_dashboards_screen.dart';
export 'src/screens/iot_dashboard_screen.dart';
export 'src/screens/kelola_layouts.dart';
export 'src/widgets/iot_widgets.dart';

/// Implementasi modul IoT untuk super app Gumpalan.
class IotModule implements AppModule {
  final IotService? service;
  late final IotService _effectiveService;

  IotModule({this.service}) {
    _effectiveService = service ?? IotService();
  }

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
          builder: (context, state) =>
              IotDashboardScreen(service: _effectiveService),
          routes: [
            GoRoute(
              path: 'edit',
              name: 'iot-edit',
              builder: (context, state) => DashboardEditorScreen(
                iotService: _effectiveService,
              ),
            ),
            GoRoute(
              path: 'explore',
              name: 'iot-explore',
              builder: (context, state) => ExploreDashboardsScreen(
                iotService: _effectiveService,
              ),
            ),
            GoRoute(
              path: 'devices',
              name: 'iot-devices',
              builder: (context, state) => Scaffold(
                appBar: AppBar(title: const Text('Daftar Perangkat Terhubung')),
                body: DeviceListScreen(service: _effectiveService),
              ),
            ),
          ],
        ),
      ];

  /// Hapus kartu ringkasan pembuka dashboard ganda pada menu/beranda
  /// karena tombol "Buka Dashboard" sudah ada di header modul.
  @override
  Widget? get homeCard => null;

  /// Daftar menu spesifik IoT pada tab "Menu":
  /// 1. Layout Saya (buka bottom sheet kelola layout, buat baru, ganti aktif, edit, hapus)
  /// 2. Jelajahi Layout Publik (salin layout pengguna lain)
  /// 3. Daftar Perangkat Terhubung (lihat channel & kontrol langsung per unit)
  @override
  List<MenuEntry> get menuEntries => [
        MenuEntry(
          id: 'iot_my_layouts',
          label: 'Layout Saya',
          icon: Icons.dashboard_customize_outlined,
          onOpen: (context) {
            showManageLayoutsSheet(
              context: context,
              service: _effectiveService,
            );
          },
        ),
        MenuEntry(
          id: 'iot_explore_layouts',
          label: 'Jelajahi Layout Publik',
          icon: Icons.explore_outlined,
          path: '/iot/explore',
        ),
        MenuEntry(
          id: 'iot_connected_devices',
          label: 'Daftar Perangkat Terhubung',
          icon: Icons.devices_outlined,
          path: '/iot/devices',
        ),
      ];

  @override
  Widget get homeScreen => IotDashboardScreen(service: _effectiveService);
}
