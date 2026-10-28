import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/iot_service.dart';
import '../data/models/iot_models.dart';
import 'dashboard_editor_screen.dart';
import 'iot_dashboard_screen.dart';

/// Membuka bottom sheet "Layout Saya" untuk mengelola layout dashboard:
/// membuat, mengedit, menyetel layout aktif, mempublikasikan, dan menghapus.
void showManageLayoutsSheet({
  required BuildContext context,
  required IotService service,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => ManageLayoutsSheet(
      iotService: service,
      onChanged: () {
        // Notifikasi dashboard (via ValueNotifier) agar reload.
      },
    ),
  );
}

/// Bottom sheet daftar layout milik pengguna beserta aksi pengelolaannya.
class ManageLayoutsSheet extends StatefulWidget {
  final IotService iotService;
  final VoidCallback? onChanged;

  const ManageLayoutsSheet({
    super.key,
    required this.iotService,
    this.onChanged,
  });

  @override
  State<ManageLayoutsSheet> createState() => _ManageLayoutsSheetState();
}

class _ManageLayoutsSheetState extends State<ManageLayoutsSheet> {
  List<DashboardModel> _layouts = [];
  String? _activeId;
  bool _isLoading = true;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getString(kIotActiveDashboardPref);
      List<DashboardModel> list;
      try {
        list = await widget.iotService.getDashboards();
      } catch (_) {
        list = [];
      }
      if (!mounted) return;
      setState(() {
        _layouts = list;
        _activeId = active != null &&
                list.any((d) => d.id == active)
            ? active
            : (list.isNotEmpty ? list.first.id : null);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setActive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kIotActiveDashboardPref, id);
    widget.iotService.activeLayout.value = id;
    if (mounted) {
      setState(() => _activeId = id);
      widget.onChanged?.call();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layout aktif diperbarui.')),
      );
    }
  }

  Future<void> _openEditor(DashboardModel? dash) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => DashboardEditorScreen(
          iotService: widget.iotService,
          initialDashboard: dash,
        ),
      ),
    );
    if (result == true && mounted) {
      await _load();
      widget.onChanged?.call();
      // Layout baru langsung jadi aktif bila belum ada yang aktif.
      if (_activeId == null && _layouts.isNotEmpty) {
        await _setActive(_layouts.first.id);
      }
    }
  }

  Future<void> _delete(DashboardModel dash) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Layout?'),
        content: Text(
          'Layout "${dash.name}" akan dihapus permanen. Widget di dalamnya ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingId = dash.id);
    try {
      await widget.iotService.deleteDashboard(dash.id);
      final wasActive = _activeId == dash.id;
      if (mounted) {
        await _load();
        widget.onChanged?.call();
        // Jika layout aktif terhapus, aktifkan sisa layout pertama.
        if (wasActive && _layouts.isNotEmpty) {
          await _setActive(_layouts.first.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deletingId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus layout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      Icons.dashboard_customize_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Layout Saya',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _openEditor(null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Buat Baru'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _layouts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.dashboard_customize_outlined,
                                  size: 40,
                                  color: colors.primary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Belum ada layout',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tekan "Buat Baru" untuk menyusun layout pertama Anda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _layouts.length,
                          itemBuilder: (context, index) {
                            final dash = _layouts[index];
                            final isActive = dash.id == _activeId;
                            final isDeleting = _deletingId == dash.id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: isDark ? 0 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isActive
                                      ? colors.primary
                                      : colors.outline.withValues(
                                            alpha: 0.15,
                                          ),
                                  width: isActive ? 1.5 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    // Pilihan radio & info layout aktif
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: isActive
                                            ? null
                                            : () => _setActive(dash.id),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    isActive
                                                        ? Icons.radio_button_checked
                                                        : Icons.radio_button_off,
                                                    size: 20,
                                                    color: isActive
                                                        ? colors.primary
                                                        : colors.onSurface
                                                            .withValues(
                                                                alpha: 0.4),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      dash.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: theme
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isActive) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: colors.primary
                                                            .withValues(
                                                                alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8),
                                                      ),
                                                      child: Text(
                                                        'AKTIF',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: colors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${dash.widgets.length} widget • ${dash.isPublic ? "Publik" : "Pribadi"}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colors.onSurface
                                                      .withValues(alpha: 0.55),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isDeleting)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    else ...[
                                      FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => _openEditor(dash),
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 16),
                                        label: const Text('Edit',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                      IconButton(
                                        tooltip: dash.isPublic
                                            ? 'Jadikan Pribadi'
                                            : 'Publikasikan Layout',
                                        icon: Icon(
                                          dash.isPublic
                                              ? Icons.public_rounded
                                              : Icons.public_outlined,
                                          size: 19,
                                        ),
                                        color: dash.isPublic
                                            ? colors.primary
                                            : null,
                                        onPressed: () async {
                                          final toggled = DashboardModel(
                                            id: dash.id,
                                            userId: dash.userId,
                                            name: dash.name,
                                            isPublic: !dash.isPublic,
                                            widgets: dash.widgets,
                                            deviceIds: dash.deviceIds,
                                          );
                                          try {
                                            await widget.iotService
                                                .updateDashboard(toggled);
                                            await _load();
                                            widget.onChanged?.call();
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Gagal memperbarui: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus Layout',
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 19),
                                        color: colors.error,
                                        onPressed: () => _delete(dash),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
