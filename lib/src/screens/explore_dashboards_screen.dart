import 'package:flutter/material.dart';
import '../data/iot_service.dart';
import '../data/models/iot_models.dart';

/// Layar untuk menjelajahi dan mengkloning tata letak dashboard yang dibagikan pengguna lain.
class ExploreDashboardsScreen extends StatefulWidget {
  final IotService iotService;

  const ExploreDashboardsScreen({super.key, required this.iotService});

  @override
  State<ExploreDashboardsScreen> createState() =>
      _ExploreDashboardsScreenState();
}

class _ExploreDashboardsScreenState extends State<ExploreDashboardsScreen> {
  List<DashboardModel> _exploreList = [];
  bool _isLoading = true;
  String? _cloningId;

  @override
  void initState() {
    super.initState();
    _loadExplore();
  }

  Future<void> _loadExplore() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.iotService.getExploreDashboards();
      if (mounted) {
        setState(() {
          _exploreList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clone(DashboardModel d) async {
    setState(() => _cloningId = d.id);
    try {
      final cloned = await widget.iotService.cloneDashboard(d.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Layout "${cloned.name}" berhasil diterapkan!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cloningId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengkloning layout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajahi Layout Publik'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExplore,
              child: _exploreList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.public_off_rounded,
                                size: 48,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum Ada Layout Publik',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Saat ini belum ada pengguna lain yang membagikan layout yang kompatibel dengan perangkat Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      itemCount: _exploreList.length,
                      itemBuilder: (context, index) {
                        final item = _exploreList[index];
                        final isCloningThis = _cloningId == item.id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: isDark ? 0 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isDark
                                  ? colors.outline.withValues(alpha: 0.2)
                                  : colors.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.primary
                                            .withValues(alpha: 0.12),
                                      ),
                                      child: Icon(
                                        Icons.dashboard_customize_rounded,
                                        color: colors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Oleh: ${item.userId} • ${item.widgets.length} widget',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colors.onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Daftar perangkat yang dipakai
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: item.deviceIds.map((dev) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: colors.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dev,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: FilledButton.tonal(
                                    onPressed: isCloningThis
                                        ? null
                                        : () => _clone(item),
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: isCloningThis
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.copy_rounded,
                                                  size: 18),
                                              SizedBox(width: 8),
                                              Text('Terapkan ke Dashboard Saya'),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
