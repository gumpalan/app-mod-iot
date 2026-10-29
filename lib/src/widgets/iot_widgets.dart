import 'package:flutter/material.dart';

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
