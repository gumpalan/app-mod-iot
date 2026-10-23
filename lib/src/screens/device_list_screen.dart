import 'package:flutter/material.dart';
import '../capabilities/registry.dart';

/// Layar placeholder daftar perangkat IoT.
class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data contoh kapabilitas untuk demonstrasi rendering dinamis
    final sampleDevices = [
      {
        'id': 'kipas1',
        'name': 'Kipas Kamar (Tasmota)',
        'capabilities': [
          {'type': 'switch', 'state': 'off'}
        ],
      },
      {
        'id': 'lampu-tidur',
        'name': 'Lampu Tidur (Generic MQTT)',
        'capabilities': [
          {'type': 'switch', 'state': 'on'},
          {'type': 'dimmer', 'value': 75},
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perangkat IoT'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleDevices.length,
        itemBuilder: (context, index) {
          final dev = sampleDevices[index];
          final caps = dev['capabilities'] as List<Map<String, dynamic>>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      dev['name'] as String,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Divider(),
                  ...caps.map((cap) => CapabilityRegistry.build(
                        context,
                        dev['id'] as String,
                        cap,
                        (cmd) {
                          // TODO: Kirim perintah ke API backend lewat core_api
                        },
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
