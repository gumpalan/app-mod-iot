import 'package:flutter/material.dart';

import '../capabilities/registry.dart';

/// Layar daftar perangkat IoT dengan tata letak modern.
/// Rilis tampilan sebagai konten utama (tanpa AppBar) untuk diintegrasikan
/// ke dalam app-shell superapp.
class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data contoh kapabilitas untuk demonstrasi rendering dinamis
    final sampleDevices = [
      {
        'id': 'kipas1',
        'name': 'Kipas Kamar (Tasmota)',
        'icon': Icons.air_rounded,
        'status': 'nonaktif',
        'capabilities': [
          {'type': 'switch', 'state': 'off'},
        ],
      },
      {
        'id': 'lampu-tidur',
        'name': 'Lampu Tidur (Generic MQTT)',
        'icon': Icons.lightbulb_outline_rounded,
        'status': 'aktif',
        'capabilities': [
          {'type': 'switch', 'state': 'on'},
          {'type': 'dimmer', 'value': 75},
        ],
      },
    ];

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(milliseconds: 600)),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: sampleDevices.length,
        itemBuilder: (context, index) {
          final dev = sampleDevices[index];
          final caps = dev['capabilities'] as List<Map<String, dynamic>>;
          final isActive = dev['status'] == 'aktif';

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.primary.withValues(alpha: 0.12)
                              : colors.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          dev['icon'] as IconData,
                          size: 22,
                          color: isActive
                              ? colors.primary
                              : colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dev['name'] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              (isActive ? 'Sedang Aktif' : 'Sedang Nonaktif')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: isActive
                                    ? colors.primary
                                    : colors.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...caps.map(
                    (cap) => CapabilityRegistry.build(
                      context,
                      dev['id'] as String,
                      cap,
                      (cmd) {},
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
