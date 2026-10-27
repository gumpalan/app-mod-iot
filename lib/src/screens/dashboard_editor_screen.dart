import 'package:flutter/material.dart';
import '../data/iot_service.dart';
import '../data/models/iot_models.dart';

/// Layar editor tata letak dashboard dinamis.
class DashboardEditorScreen extends StatefulWidget {
  final IotService iotService;
  final DashboardModel? initialDashboard;

  const DashboardEditorScreen({
    super.key,
    required this.iotService,
    this.initialDashboard,
  });

  @override
  State<DashboardEditorScreen> createState() => _DashboardEditorScreenState();
}

class _DashboardEditorScreenState extends State<DashboardEditorScreen> {
  late final TextEditingController _nameController;
  late bool _isPublic;
  late List<DashboardWidgetConfig> _widgets;

  List<IotDevice> _devices = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialDashboard?.name ?? 'Dashboard Saya',
    );
    _isPublic = widget.initialDashboard?.isPublic ?? false;
    _widgets = List.from(widget.initialDashboard?.widgets ?? []);
    _loadDevices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      final list = await widget.iotService.getDevices();
      if (mounted) {
        setState(() {
          _devices = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDashboard() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dashboard tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.initialDashboard != null) {
        final updated = DashboardModel(
          id: widget.initialDashboard!.id,
          userId: widget.initialDashboard!.userId,
          name: name,
          isPublic: _isPublic,
          widgets: _widgets,
          deviceIds: _widgets.map((w) => w.deviceId).toSet().toList(),
        );
        await widget.iotService.updateDashboard(updated);
      } else {
        await widget.iotService.createDashboard(
          name: name,
          isPublic: _isPublic,
          widgets: _widgets,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    }
  }

  void _showAddWidgetSheet() {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada perangkat yang tersedia')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddWidgetModal(
        devices: _devices,
        onAdd: (newWidget) {
          setState(() => _widgets.add(newWidget));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialDashboard != null
            ? 'Edit Dashboard'
            : 'Atur Dashboard Baru'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonal(
              onPressed: _isSaving ? null : _saveDashboard,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Info Pengaturan Dashboard
                Card(
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
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Dashboard',
                            hintText: 'Misal: Ruang Tamu & Sensor',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            prefixIcon: const Icon(Icons.label_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Publikasikan Layout',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Izinkan pengguna lain dengan perangkat yang sama melihat dan memakai layout ini.',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isPublic,
                          onChanged: (val) => setState(() => _isPublic = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header Bagian Widget
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAFTAR WIDGET (${_widgets.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddWidgetSheet,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Widget'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_widgets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceContainerHighest.withValues(alpha: 0.2)
                          : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.dashboard_customize_outlined,
                          size: 40,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada widget pada kanvas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekan tombol "Tambah Widget" di atas untuk menghubungkan saklar, slider, atau gauge ke perangkat Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _widgets.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final item = _widgets.removeAt(oldIndex);
                        _widgets.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _widgets[index];
                      return Card(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: isDark ? 0 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colors.outline.withValues(alpha: 0.15),
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              _getWidgetIcon(item.widgetType),
                              color: colors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Tipe: ${item.widgetType.toUpperCase()} • ${item.deviceId} / ${item.channelId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: colors.error,
                                tooltip: 'Hapus Widget',
                                onPressed: () {
                                  setState(() => _widgets.removeAt(index));
                                },
                              ),
                              const Icon(Icons.drag_indicator_rounded),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  IconData _getWidgetIcon(String type) {
    switch (type) {
      case 'toggle':
        return Icons.toggle_on_rounded;
      case 'slider':
        return Icons.tune_rounded;
      case 'gauge':
        return Icons.speed_rounded;
      case 'button':
        return Icons.touch_app_rounded;
      default:
        return Icons.analytics_outlined;
    }
  }
}

class _AddWidgetModal extends StatefulWidget {
  final List<IotDevice> devices;
  final ValueChanged<DashboardWidgetConfig> onAdd;

  const _AddWidgetModal({required this.devices, required this.onAdd});

  @override
  State<_AddWidgetModal> createState() => _AddWidgetModalState();
}

class _AddWidgetModalState extends State<_AddWidgetModal> {
  late IotDevice _selectedDevice;
  late DeviceChannel _selectedChannel;
  String _selectedWidgetType = 'toggle';
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.devices.first;
    _selectedChannel = _selectedDevice.channels.isNotEmpty
        ? _selectedDevice.channels.first
        : const DeviceChannel(
            id: 'default',
            name: 'Default',
            direction: 'input',
            type: 'boolean');
    _autoConfigure();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _autoConfigure() {
    _titleController.text = _selectedChannel.name;
    if (_selectedChannel.type == 'boolean') {
      _selectedWidgetType = 'toggle';
    } else if (_selectedChannel.type == 'number') {
      if (_selectedChannel.direction == 'output' ||
          _selectedChannel.direction == 'bidirectional') {
        _selectedWidgetType = 'slider';
      } else {
        _selectedWidgetType = 'gauge';
      }
    } else {
      _selectedWidgetType = 'value_card';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.add_to_photos_rounded,
                    color: colors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Tambah Widget ke Kanvas',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Pilih Perangkat
          DropdownButtonFormField<IotDevice>(
            value: _selectedDevice,
            decoration: InputDecoration(
              labelText: 'Pilih Perangkat',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: widget.devices.map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text('${d.name} (${d.id})'),
              );
            }).toList(),
            onChanged: (dev) {
              if (dev != null) {
                setState(() {
                  _selectedDevice = dev;
                  _selectedChannel = dev.channels.isNotEmpty
                      ? dev.channels.first
                      : const DeviceChannel(
                          id: 'default',
                          name: 'Default',
                          direction: 'input',
                          type: 'boolean');
                  _autoConfigure();
                });
              }
            },
          ),
          const SizedBox(height: 14),

          // 2. Pilih Channel
          DropdownButtonFormField<DeviceChannel>(
            value: _selectedChannel,
            decoration: InputDecoration(
              labelText: 'Pilih Channel / Topik',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: _selectedDevice.channels.map((ch) {
              return DropdownMenuItem(
                value: ch,
                child: Text(
                    '${ch.name} [${ch.type} • ${ch.direction.toUpperCase()}]'),
              );
            }).toList(),
            onChanged: (ch) {
              if (ch != null) {
                setState(() {
                  _selectedChannel = ch;
                  _autoConfigure();
                });
              }
            },
          ),
          const SizedBox(height: 14),

          // 3. Tipe Widget
          DropdownButtonFormField<String>(
            value: _selectedWidgetType,
            decoration: InputDecoration(
              labelText: 'Tipe Tampilan Widget',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: const [
              DropdownMenuItem(value: 'toggle', child: Text('Saklar (Toggle)')),
              DropdownMenuItem(value: 'slider', child: Text('Pengatur Nilai (Slider)')),
              DropdownMenuItem(value: 'gauge', child: Text('Meteran Melingkar (Gauge)')),
              DropdownMenuItem(value: 'value_card', child: Text('Kartu Angka (Value Card)')),
              DropdownMenuItem(value: 'button', child: Text('Tombol Pulsa (Push Button)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedWidgetType = val);
            },
          ),
          const SizedBox(height: 14),

          // 4. Judul Widget
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Label Judul Widget',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                final w = DashboardWidgetConfig(
                  id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                  widgetType: _selectedWidgetType,
                  title: _titleController.text.trim().isNotEmpty
                      ? _titleController.text.trim()
                      : _selectedChannel.name,
                  deviceId: _selectedDevice.id,
                  channelId: _selectedChannel.id,
                  min: _selectedChannel.min,
                  max: _selectedChannel.max,
                  unit: _selectedChannel.unit,
                );
                widget.onAdd(w);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Tambahkan Widget'),
            ),
          ),
        ],
      ),
    );
  }
}
