import 'package:flutter/material.dart';
import '../data/iot_service.dart';
import '../data/models/iot_models.dart';
import 'automation_editor_screen.dart';

class AutomationListScreen extends StatefulWidget {
  final IotService iotService;

  const AutomationListScreen({
    super.key,
    required this.iotService,
  });

  @override
  State<AutomationListScreen> createState() => _AutomationListScreenState();
}

class _AutomationListScreenState extends State<AutomationListScreen> {
  List<AutomationRule> _rules = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _testingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await widget.iotService.fetchRules();
      if (!mounted) return;
      setState(() {
        _rules = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRule(AutomationRule rule, bool newVal) async {
    try {
      final success = await widget.iotService.toggleRule(rule.id, newVal);
      if (!mounted) return;
      setState(() {
        final idx = _rules.indexWhere((r) => r.id == rule.id);
        if (idx != -1) {
          _rules[idx] = _rules[idx].copyWith(enabled: success);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status aturan: $e')),
      );
    }
  }

  Future<void> _testRule(AutomationRule rule) async {
    setState(() => _testingIds.add(rule.id));
    try {
      await widget.iotService.testRule(rule.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aksi aturan "${rule.name}" berhasil dieksekusi!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengeksekusi aksi: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _testingIds.remove(rule.id));
      }
    }
  }

  Future<void> _deleteRule(AutomationRule rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Aturan Otomasi'),
        content: Text('Apakah Anda yakin ingin menghapus "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.iotService.deleteRule(rule.id);
      if (!mounted) return;
      setState(() {
        _rules.removeWhere((r) => r.id == rule.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aturan berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus aturan: $e')),
      );
    }
  }

  Future<void> _openEditor([AutomationRule? rule]) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AutomationEditorScreen(
          iotService: widget.iotService,
          initialRule: rule,
        ),
      ),
    );

    if (updated == true) {
      _loadRules();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aturan Otomasi'),
        actions: [
          IconButton(
            onPressed: _loadRules,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Aturan'),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Terjadi Kesalahan',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadRules,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Aturan Otomasi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Buat aturan logika otomasi untuk menghubungkan sensor dan kontrol perangkat secara otomatis.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Buat Aturan Pertama'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: _rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final rule = _rules[index];
        final isTesting = _testingIds.contains(rule.id);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: rule.enabled
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (rule.enabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        rule.triggerType == 'schedule'
                            ? Icons.schedule_rounded
                            : Icons.sensors_rounded,
                        color: rule.enabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rule.enabled ? 'Aktif' : 'Dinonaktifkan',
                            style: TextStyle(
                              fontSize: 12,
                              color: rule.enabled
                                  ? Colors.green.shade700
                                  : theme.colorScheme.outline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: rule.enabled,
                      onChanged: (val) => _toggleRule(rule, val),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Penjelasan Kondisi & Aksi
                _buildConditionBadge(theme, rule),
                const SizedBox(height: 8),
                _buildActionBadge(theme, rule),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isTesting ? null : () => _testRule(rule),
                      icon: isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Uji Aksi'),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _openEditor(rule),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Aturan',
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      onPressed: () => _deleteRule(rule),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Hapus Aturan',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConditionBadge(ThemeData theme, AutomationRule rule) {
    String triggerDesc = '';
    if (rule.triggerType == 'schedule') {
      triggerDesc = 'Pukul / Jadwal: ${rule.triggerCron ?? '-'}';
    } else {
      triggerDesc =
          'Jika ${rule.triggerDeviceId ?? 'perangkat'}.${rule.triggerChannelId ?? 'channel'} ${rule.triggerOperator ?? '=='} ${rule.triggerValue ?? '-'}';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'IF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            triggerDesc,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBadge(ThemeData theme, AutomationRule rule) {
    final actionDesc =
        'Set ${rule.actionDeviceId}.${rule.actionChannelId} = ${rule.actionValue}';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'THEN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            actionDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
