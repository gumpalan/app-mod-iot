import 'package:flutter_test/flutter_test.dart';
import 'package:mod_iot/mod_iot.dart';

void main() {
  test('IotModule properties are valid', () {
    final module = IotModule();
    expect(module.id, equals('iot'));
    expect(module.name, equals('IoT'));
    expect(module.routes, isNotEmpty);
    expect(module.homeCard, isNotNull);
  });
}
