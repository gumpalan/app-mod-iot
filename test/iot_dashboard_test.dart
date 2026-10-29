import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mod_iot/mod_iot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockIotService extends IotService {
  final List<DashboardModel> mockDashboards;
  final List<IotDevice> mockDevices;

  MockIotService({this.mockDashboards = const [], this.mockDevices = const []});

  @override
  Future<List<DashboardModel>> getDashboards() async => mockDashboards;

  @override
  Future<List<IotDevice>> getDevices() async => mockDevices;

  @override
  Future<List<DashboardModel>> getExploreDashboards() async => mockDashboards;

  @override
  Future<void> connectWebSocket() async {}

  @override
  Future<void> sendCommand(
    String deviceId,
    String channelId,
    dynamic value,
  ) async {}
}

void main() {
  group('IoT Model Tests', () {
    test('DashboardModel json encoding and decoding works', () {
      final widgetCfg = const DashboardWidgetConfig(
        id: 'w1',
        widgetType: 'toggle',
        title: 'Saklar Lampu',
        deviceId: 'lampu1',
        channelId: 'power',
      );

      final dash = DashboardModel(
        id: 'dash-1',
        userId: 'user-1',
        name: 'Dashboard Kamar',
        isPublic: true,
        widgets: [widgetCfg],
        deviceIds: const ['lampu1'],
      );

      final json = dash.toJson();
      expect(json['id'], equals('dash-1'));
      expect(json['isPublic'], isTrue);

      final decoded = DashboardModel.fromJson(json);
      expect(decoded.name, equals('Dashboard Kamar'));
      expect(decoded.widgets.length, equals(1));
      expect(decoded.widgets.first.title, equals('Saklar Lampu'));
    });
  });

  group('ManageLayoutsSheet Widget Tests', () {
    testWidgets('ManageLayoutsSheet renders layout list properly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({kIotActiveDashboardPref: 'd1'});

      final mock = MockIotService(
        mockDashboards: [
          const DashboardModel(
            id: 'd1',
            userId: 'u1',
            name: 'Dashboard Saya',
            widgets: [],
            deviceIds: [],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ManageLayoutsSheet(iotService: mock)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Layout Saya'), findsOneWidget);
      expect(find.text('Dashboard Saya'), findsOneWidget);
    });
  });

  group('IotDashboardScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    testWidgets('Tampil state kosong jika belum ada dashboard', (tester) async {
      final mock = MockIotService(mockDashboards: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IotDashboardScreen(service: mock)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Layout Dashboard'), findsOneWidget);
      expect(find.text('Atur Layout Baru'), findsOneWidget);
    });

    testWidgets('Tampil kanvas widget jika dashboard sudah diatur', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({kIotActiveDashboardPref: 'd1'});

      final mock = MockIotService(
        mockDashboards: [
          const DashboardModel(
            id: 'd1',
            userId: 'u1',
            name: 'Kamar Tidur',
            widgets: [
              DashboardWidgetConfig(
                id: 'w1',
                widgetType: 'toggle',
                title: 'Power Lampu',
                deviceId: 'lampu1',
                channelId: 'power',
              ),
              DashboardWidgetConfig(
                id: 'w2',
                widgetType: 'gauge',
                title: 'Suhu Ruangan',
                deviceId: 'sensor1',
                channelId: 'temp',
                unit: '°C',
              ),
            ],
            deviceIds: ['lampu1', 'sensor1'],
          ),
        ],
        mockDevices: [
          const IotDevice(
            id: 'lampu1',
            name: 'Lampu Kamar',
            driver: 'custom',
            channels: [
              DeviceChannel(
                id: 'power',
                name: 'Power',
                direction: 'bidirectional',
                type: 'boolean',
              ),
            ],
            states: {'power': true},
          ),
          const IotDevice(
            id: 'sensor1',
            name: 'Sensor Suhu',
            driver: 'custom',
            channels: [
              DeviceChannel(
                id: 'temp',
                name: 'Suhu',
                direction: 'input',
                type: 'number',
                unit: '°C',
              ),
            ],
            states: {'temp': 28.5},
          ),
        ],
      );
      mock.activeLayout.value = 'd1';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IotDashboardScreen(service: mock)),
        ),
      );

      await tester.pumpAndSettle();

      // Kanvas bersih: nama dashboard tidak tampil lagi, hanya widget
      expect(find.text('Power Lampu'), findsOneWidget);
      expect(find.text('Suhu Ruangan'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
