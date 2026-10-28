import 'package:flutter_test/flutter_test.dart';
import 'package:mod_iot/mod_iot.dart';

void main() {
  test('IotModule properties are valid', () {
    final module = IotModule();
    expect(module.id, equals('iot'));
    expect(module.name, equals('IoT'));
    expect(module.routes, isNotEmpty);
    expect(module.homeCard, isNull);
    expect(module.menuEntries.length, equals(4));
    expect(module.menuEntries[0].label, equals('Layout Saya'));
    expect(module.menuEntries[1].label, equals('Jelajahi Layout Publik'));
    expect(module.menuEntries[2].label, equals('Aturan Otomasi'));
    expect(module.menuEntries[3].label, equals('Daftar Perangkat Terhubung'));
  });
}
