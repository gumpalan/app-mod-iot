import 'package:flutter/material.dart';

import '../data/iot_service.dart';
import '../data/models/iot_models.dart';

class AutomationEditorScreen extends StatefulWidget {
  final IotService iotService;
  final AutomationRule? initialRule;

  const AutomationEditorScreen({
    super.key,
    required this.iotService,
    this.initialRule,
  });

  @override
  State<AutomationEditorScreen> createState() => _AutomationEditorScreenState();
}

class _AutomationEditorScreenState extends State<AutomationEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _cronController;
  late TextEditingController _triggerValController;
  late TextEditingController _actionValController;

  String _triggerType = 'state'; // 'state' | 'schedule'
  String? _selectedTriggerDevice;
  String? _selectedTriggerChannel;
  String _selectedOperator = '==';

  String? _selectedActionDevice;
  String? _selectedActionChannel;

  List<IotDevice> _devices = [];
  bool _isLoadingDevices = true;
  bool _isSaving = false;

  final List<String> _operators = ['==', '!=', '>', '>=', '<', '<='];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRule;
    _nameController = TextEditingController(text: r?.name ?? '');
    _cronController = TextEditingController(text: r?.triggerCron ?? '23:00');
    _triggerValController = TextEditingController(
      text: r?.triggerValue ?? 'true',
    );
    _actionValController = TextEditingController(
      text: r?.actionValue ?? 'false',
    );

    if (r != null) {
      _triggerType = r.triggerType;
      _selectedTriggerDevice = r.triggerDeviceId;
      _selectedTriggerChannel = r.triggerChannelId;
      _selectedOperator = r.triggerOperator ?? '==';
      _selectedActionDevice = r.actionDeviceId;
      _selectedActionChannel = r.actionChannelId;
    }

    _loadDevices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cronController.dispose();
    _triggerValController.dispose();
    _actionValController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      final list = await widget.iotService.getDevices();
      if (!mounted) return;
      setState(() {
        _devices = list;
        _isLoadingDevices = false;

        if (_selectedTriggerDevice == null && list.isNotEmpty) {
          _selectedTriggerDevice = list.first.id;
          if (list.first.channels.isNotEmpty) {
            _selectedTriggerChannel = list.first.channels.first.id;
          }
        }
        if (_selectedActionDevice == null && list.isNotEmpty) {
          _selectedActionDevice = list.first.id;
          if (list.first.channels.isNotEmpty) {
            _selectedActionChannel = list.first.channels.first.id;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _cronController.text = '$hh:$mm';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_triggerType == 'state') {
      if (_selectedTriggerDevice == null || _selectedTriggerChannel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih perangkat dan channel pemicu')),
        );
        return;
      }
    }

    if (_selectedActionDevice == null || _selectedActionChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih perangkat dan channel aksi')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isEdit = widget.initialRule != null;
      final rule = AutomationRule(
        id: widget.initialRule?.id ?? '',
        name: _nameController.text.trim(),
        enabled: widget.initialRule?.enabled ?? true,
        triggerType: _triggerType,
        triggerDeviceId: _triggerType == 'state'
            ? _selectedTriggerDevice
            : null,
        triggerChannelId: _triggerType == 'state'
            ? _selectedTriggerChannel
            : null,
        triggerOperator: _triggerType == 'state' ? _selectedOperator : null,
        triggerValue: _triggerType == 'state'
            ? _triggerValController.text.trim()
            : null,
        triggerCron: _triggerType == 'schedule'
            ? _cronController.text.trim()
            : null,
        actionDeviceId: _selectedActionDevice!,
        actionChannelId: _selectedActionChannel!,
        actionValue: _actionValController.text.trim(),
      );

      if (isEdit) {
        await widget.iotService.updateRule(rule);
      } else {
        await widget.iotService.createRule(rule);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Aturan berhasil diperbarui' : 'Aturan berhasil dibuat',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialRule != null ? 'Edit Aturan' : 'Buat Aturan Otomasi',
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Simpan'),
          ),
        ],
      ),
      body: _isLoadingDevices
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Nama Aturan
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Aturan',
                      hintText: 'Misal: Matikan Lampu Tengah Malam',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bolt_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama aturan tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Bagian JIKA (TRIGGER)
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'JIKA (IF)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Kondisi Pemicu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'state',
                                icon: Icon(Icons.sensors_rounded, size: 18),
                                label: Text('Sensor / State'),
                              ),
                              ButtonSegment(
                                value: 'schedule',
                                icon: Icon(Icons.schedule_rounded, size: 18),
                                label: Text('Waktu / Jadwal'),
                              ),
                            ],
                            selected: {_triggerType},
                            onSelectionChanged: (set) {
                              setState(() {
                                _triggerType = set.first;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_triggerType == 'state') ...[
                            _buildDeviceDropdown(
                              label: 'Pilih Perangkat Pemicu',
                              selectedId: _selectedTriggerDevice,
                              onChanged: (devId) {
                                setState(() {
                                  _selectedTriggerDevice = devId;
                                  final dev = _devices.firstWhere(
                                    (d) => d.id == devId,
                                    orElse: () => _devices.first,
                                  );
                                  _selectedTriggerChannel =
                                      dev.channels.isNotEmpty
                                      ? dev.channels.first.id
                                      : null;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildChannelDropdown(
                              deviceId: _selectedTriggerDevice,
                              selectedId: _selectedTriggerChannel,
                              onChanged: (chId) {
                                setState(() => _selectedTriggerChannel = chId);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedOperator,
                                    decoration: const InputDecoration(
                                      labelText: 'Operator',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _operators.map((op) {
                                      return DropdownMenuItem(
                                        value: op,
                                        child: Text(op),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _selectedOperator = v);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _triggerValController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nilai Banding',
                                      hintText: 'true / 30 / on',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Wajib diisi'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cronController,
                                    decoration: const InputDecoration(
                                      labelText: 'Waktu (HH:MM atau Cron)',
                                      hintText: '23:00 atau 0 23 * * *',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Jadwal wajib diisi'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: _pickTime,
                                  icon: const Icon(Icons.access_time_rounded),
                                  tooltip: 'Pilih Jam & Menit',
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bagian MAKA (ACTION)
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'MAKA (THEN)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onTertiary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Aksi yang Dijalankan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDeviceDropdown(
                            label: 'Pilih Perangkat Target',
                            selectedId: _selectedActionDevice,
                            onChanged: (devId) {
                              setState(() {
                                _selectedActionDevice = devId;
                                final dev = _devices.firstWhere(
                                  (d) => d.id == devId,
                                  orElse: () => _devices.first,
                                );
                                _selectedActionChannel = dev.channels.isNotEmpty
                                    ? dev.channels.first.id
                                    : null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildChannelDropdown(
                            deviceId: _selectedActionDevice,
                            selectedId: _selectedActionChannel,
                            onChanged: (chId) {
                              setState(() => _selectedActionChannel = chId);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _actionValController,
                            decoration: const InputDecoration(
                              labelText: 'Nilai Aksi (Command Value)',
                              hintText: 'true / false / on / off / 100',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nilai aksi wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      widget.initialRule != null
                          ? 'Perbarui Aturan'
                          : 'Simpan Aturan',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceDropdown({
    required String label,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    if (_devices.isEmpty) {
      return Text(
        'Belum ada perangkat terdaftar.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _devices.any((d) => d.id == selectedId) ? selectedId : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _devices.map((d) {
        return DropdownMenuItem(
          value: d.id,
          child: Text('${d.name} (${d.id})', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildChannelDropdown({
    required String? deviceId,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    final dev = _devices.where((d) => d.id == deviceId).firstOrNull;
    final channels = dev?.channels ?? [];

    if (channels.isEmpty) {
      return const Text('Perangkat tidak memiliki channel.');
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: channels.any((c) => c.id == selectedId) ? selectedId : null,
      decoration: const InputDecoration(
        labelText: 'Pilih Channel',
        border: OutlineInputBorder(),
      ),
      items: channels.map((c) {
        return DropdownMenuItem(
          value: c.id,
          child: Text(
            '${c.name} [${c.id}] (${c.type})',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
