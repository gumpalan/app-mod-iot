import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../data/models/iot_models.dart';

typedef CommandCallback = void Function(
  String deviceId,
  String channelId,
  dynamic value,
);

/// Widget kartu saklar toggle blynk-style.
class IotToggleWidget extends StatelessWidget {
  final DashboardWidgetConfig config;
  final dynamic currentState;
  final CommandCallback onCommand;

  const IotToggleWidget({
    super.key,
    required this.config,
    required this.currentState,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool isOn =
        currentState == true ||
        currentState == 'true' ||
        currentState == 'on' ||
        currentState == 1 ||
        currentState == 'ON';

    return Card(
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isOn
              ? colors.primary.withValues(alpha: 0.5)
              : (isDark
                    ? colors.outline.withValues(alpha: 0.2)
                    : colors.outlineVariant.withValues(alpha: 0.6)),
          width: isOn ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onCommand(config.deviceId, config.channelId, !isOn),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOn
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.onSurface.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      isOn ? Icons.power_rounded : Icons.power_off_rounded,
                      color: isOn
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.4),
                      size: 24,
                    ),
                  ),
                  Switch.adaptive(
                    value: isOn,
                    onChanged: (val) =>
                        onCommand(config.deviceId, config.channelId, val),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${config.deviceId} • ${isOn ? "MENYALA" : "MATI"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOn
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget kartu slider kecerahan / kecepatan / dimmer.
class IotSliderWidget extends StatefulWidget {
  final DashboardWidgetConfig config;
  final dynamic currentState;
  final CommandCallback onCommand;

  const IotSliderWidget({
    super.key,
    required this.config,
    required this.currentState,
    required this.onCommand,
  });

  @override
  State<IotSliderWidget> createState() => _IotSliderWidgetState();
}

class _IotSliderWidgetState extends State<IotSliderWidget> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double min = widget.config.min ?? 0;
    final double max = widget.config.max ?? 100;

    double currentVal = min;
    if (_dragValue != null) {
      currentVal = _dragValue!;
    } else if (widget.currentState is num) {
      currentVal = (widget.currentState as num).toDouble();
    } else if (widget.currentState is String) {
      currentVal = double.tryParse(widget.currentState as String) ?? min;
    }
    currentVal = currentVal.clamp(min, max);

    final unit = widget.config.unit ?? '%';

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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.config.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${currentVal.toInt()} $unit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.config.deviceId} • ${widget.config.channelId}',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: currentVal,
                min: min,
                max: max,
                onChanged: (val) {
                  setState(() => _dragValue = val);
                },
                onChangeEnd: (val) {
                  _dragValue = null;
                  widget.onCommand(
                    widget.config.deviceId,
                    widget.config.channelId,
                    val.round(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget gauge melingkar modern untuk sensor telemetri (suhu, kelembaban, dll).
class IotGaugeWidget extends StatelessWidget {
  final DashboardWidgetConfig config;
  final dynamic currentState;

  const IotGaugeWidget({
    super.key,
    required this.config,
    required this.currentState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double min = config.min ?? 0;
    final double max = config.max ?? 100;

    double numVal = min;
    if (currentState is num) {
      numVal = (currentState as num).toDouble();
    } else if (currentState is String) {
      numVal = double.tryParse(currentState as String) ?? min;
    }

    final fraction = ((numVal - min) / (max - min)).clamp(0.0, 1.0);
    final unit = config.unit ?? '';

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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              config.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${config.deviceId} • ${config.channelId}',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 8,
                    backgroundColor: colors.surfaceContainerHighest,
                    color: colors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          numVal.toStringAsFixed(1),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (unit.isNotEmpty)
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Widget kartu metrik nilai teks / angka besar.
class IotValueCardWidget extends StatelessWidget {
  final DashboardWidgetConfig config;
  final dynamic currentState;

  const IotValueCardWidget({
    super.key,
    required this.config,
    required this.currentState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final displayVal = currentState != null ? '$currentState' : '--';
    final unit = config.unit ?? '';

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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    config.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.show_chart_rounded, size: 20, color: colors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayVal,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${config.deviceId} • ${config.channelId}',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget tombol aksi (push button).
class IotButtonWidget extends StatelessWidget {
  final DashboardWidgetConfig config;
  final CommandCallback onCommand;

  const IotButtonWidget({
    super.key,
    required this.config,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${config.deviceId} • ${config.channelId}',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.tonal(
                onPressed: () =>
                    onCommand(config.deviceId, config.channelId, 'press'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Jalankan Perintah'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget tombol menahan / latching push button (gabungan switch dan push button).
class IotHoldButtonWidget extends StatelessWidget {
  final DashboardWidgetConfig config;
  final dynamic currentState;
  final CommandCallback onCommand;

  const IotHoldButtonWidget({
    super.key,
    required this.config,
    required this.currentState,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool isOn =
        currentState == true ||
        currentState == 'true' ||
        currentState == 'on' ||
        currentState == 1 ||
        currentState == 'ON';

    return Card(
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isOn
              ? colors.primary.withValues(alpha: 0.6)
              : (isDark
                    ? colors.outline.withValues(alpha: 0.2)
                    : colors.outlineVariant.withValues(alpha: 0.6)),
          width: isOn ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${config.deviceId} • ${isOn ? "AKTIF" : "NONAKTIF"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOn
                              ? colors.primary
                              : colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 20,
                    color: isOn
                        ? colors.primary
                        : colors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () =>
                    onCommand(config.deviceId, config.channelId, !isOn),
                style: FilledButton.styleFrom(
                  backgroundColor: isOn
                      ? colors.primary
                      : colors.primary.withValues(alpha: 0.12),
                  foregroundColor: isOn ? colors.onPrimary : colors.primary,
                  elevation: isOn ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  isOn
                      ? Icons.power_settings_new_rounded
                      : Icons.touch_app_rounded,
                  size: 20,
                ),
                label: Text(
                  isOn ? 'Matikan Perangkat' : 'Nyalakan Perangkat',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SensorChartWidget — Line chart time-series untuk data sensor numerik
// ---------------------------------------------------------------------------

/// Widget chart sensor historis berbasis fl_chart.
/// Hanya ditampilkan di dashboard jika server mengaktifkan HISTORY_MODE sensor/all.
class SensorChartWidget extends StatelessWidget {
  final String title;
  final String? unit;
  final List<SensorLogEntry> entries;
  final bool isLoading;
  final String? error;

  const SensorChartWidget({
    super.key,
    required this.title,
    this.unit,
    required this.entries,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit != null)
                  Text(
                    unit!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _buildChartBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBody(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }

    final numericEntries = entries
        .where((e) => e.numericValue != null)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (numericEntries.isEmpty) {
      return const Center(child: Text('Tidak ada data numerik'));
    }

    final spots = numericEntries
        .map((e) => FlSpot(e.recordedAt.toDouble(), e.numericValue!))
        .toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.15;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return LineChart(
      LineChartData(
        minY: minY - yPad,
        maxY: maxY + yPad,
        lineTouchData: const LineTouchData(enabled: true),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: spots.length > 1
                  ? (spots.last.x - spots.first.x) / 4
                  : 1,
              getTitlesWidget: (value, meta) {
                final dt = DateTime.fromMillisecondsSinceEpoch(
                  value.toInt() * 1000,
                );
                final h = dt.hour.toString().padLeft(2, '0');
                final m = dt.minute.toString().padLeft(2, '0');
                return Text('$h:$m', style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 2,
            dotData: FlDotData(
              show: spots.length <= 50,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 2.5,
                color: bar.color ?? Colors.blue,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ActuatorLogWidget — Daftar log eksekusi aktuator dengan badge sumber
// ---------------------------------------------------------------------------

class ActuatorLogWidget extends StatelessWidget {
  final String title;
  final List<ActuatorLogEntry> entries;
  final bool isLoading;
  final String? error;

  const ActuatorLogWidget({
    super.key,
    required this.title,
    required this.entries,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(heightFactor: 3, child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        heightFactor: 3,
        child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    if (entries.isEmpty) {
      return const Center(heightFactor: 3, child: Text('Belum ada aktivitas'));
    }

    final shown = entries.length > 30 ? entries.sublist(0, 30) : entries;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shown.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _LogTile(entry: shown[i]),
    );
  }
}

class _LogTile extends StatelessWidget {
  final ActuatorLogEntry entry;
  const _LogTile({required this.entry});

  Color _badgeColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (entry.source) {
      case 'app':
        return cs.primary;
      case 'automation':
        return Colors.orange;
      case 'schedule':
        return Colors.teal;
      case 'device':
        return Colors.grey;
      default:
        return cs.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = entry.dateTime.toLocal();
    final timeStr =
        '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    final actorDisplay = entry.actorName ?? entry.actorId ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _badgeColor(context).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _badgeColor(context), width: 0.8),
            ),
            child: Text(
              entry.sourceLabel,
              style: TextStyle(
                fontSize: 10,
                color: _badgeColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.channelId} = ${entry.value}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$actorDisplay  •  $timeStr',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
