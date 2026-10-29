import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mod_iot/mod_iot.dart';

class MockIotServiceRules extends IotService {
  final List<AutomationRule> rules;
  final List<IotDevice> devices;

  MockIotServiceRules({this.rules = const [], this.devices = const []});

  @override
  Future<List<AutomationRule>> fetchRules() async => rules;

  @override
  Future<List<IotDevice>> getDevices() async => devices;

  @override
  Future<bool> toggleRule(String id, bool enabled) async => enabled;

  @override
  Future<void> testRule(String id) async {}

  @override
  Future<void> deleteRule(String id) async {}
}

void main() {
  group('Automation Rule Model & Widget Tests', () {
    test('AutomationRule toJson and fromJson work correctly', () {
      final rule = const AutomationRule(
        id: 'rule-1',
        name: 'Auto Matikan Lampu',
        enabled: true,
        triggerType: 'state',
        triggerDeviceId: 'sensor-1',
        triggerChannelId: 'lux',
        triggerOperator: '>',
        triggerValue: '500',
        actionDeviceId: 'lamp-1',
        actionChannelId: 'power',
        actionValue: 'false',
      );

      final json = rule.toJson();
      expect(json['id'], equals('rule-1'));
      expect(json['triggerOperator'], equals('>'));

      final decoded = AutomationRule.fromJson(json);
      expect(decoded.name, equals('Auto Matikan Lampu'));
      expect(decoded.actionValue, equals('false'));
      expect(decoded.triggerValue, equals('500'));
    });

    testWidgets('AutomationListScreen renders rules list correctly', (
      tester,
    ) async {
      final mockRule = const AutomationRule(
        id: 'rule-1',
        name: 'Nyalakan Kipas Otomatis',
        enabled: true,
        triggerType: 'state',
        triggerDeviceId: 'dht11',
        triggerChannelId: 'temp',
        triggerOperator: '>=',
        triggerValue: '32',
        actionDeviceId: 'fan1',
        actionChannelId: 'power',
        actionValue: 'true',
      );

      final service = MockIotServiceRules(rules: [mockRule]);

      await tester.pumpWidget(
        MaterialApp(home: AutomationListScreen(iotService: service)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aturan Otomasi'), findsOneWidget);
      expect(find.text('Nyalakan Kipas Otomatis'), findsOneWidget);
      expect(find.text('Uji Aksi'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('AutomationEditorScreen renders form fields correctly', (
      tester,
    ) async {
      final device = const IotDevice(
        id: 'lampu1',
        name: 'Lampu Teras',
        driver: 'custom',
        channels: [
          DeviceChannel(
            id: 'power',
            name: 'Power',
            type: 'boolean',
            direction: 'bidirectional',
          ),
        ],
      );

      final service = MockIotServiceRules(devices: [device]);

      await tester.pumpWidget(
        MaterialApp(home: AutomationEditorScreen(iotService: service)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Buat Aturan Otomasi'), findsOneWidget);
      expect(find.text('Nama Aturan'), findsOneWidget);
      expect(find.text('Sensor / State'), findsOneWidget);
      expect(find.text('Waktu / Jadwal'), findsOneWidget);
    });
  });
}
