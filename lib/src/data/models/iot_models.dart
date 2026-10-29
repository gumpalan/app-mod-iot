import 'dart:convert';

/// Konfigurasi channel pada perangkat IoT.
class DeviceChannel {
  final String id;
  final String name;
  final String direction; // input, output, bidirectional
  final String? topic;
  final String? commandTopic;
  final String? stateTopic;
  final String type; // boolean, number, string, enum
  final String? unit;
  final double? min;
  final double? max;
  final List<String>? options;
  final String? uiHint;

  const DeviceChannel({
    required this.id,
    required this.name,
    required this.direction,
    this.topic,
    this.commandTopic,
    this.stateTopic,
    required this.type,
    this.unit,
    this.min,
    this.max,
    this.options,
    this.uiHint,
  });

  factory DeviceChannel.fromJson(Map<String, dynamic> json) {
    return DeviceChannel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      direction: json['direction'] as String? ?? 'input',
      topic: json['topic'] as String?,
      commandTopic: json['command_topic'] as String?,
      stateTopic: json['state_topic'] as String?,
      type: json['type'] as String? ?? 'string',
      unit: json['unit'] as String?,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      uiHint: json['ui_hint'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'direction': direction,
    if (topic != null) 'topic': topic,
    if (commandTopic != null) 'command_topic': commandTopic,
    if (stateTopic != null) 'state_topic': stateTopic,
    'type': type,
    if (unit != null) 'unit': unit,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (options != null) 'options': options,
    if (uiHint != null) 'ui_hint': uiHint,
  };
}

/// Model perangkat IoT yang didaftarkan melalui backend svc-iot.
class IotDevice {
  final String id;
  final String name;
  final String driver;
  final List<DeviceChannel> channels;
  final Map<String, dynamic> states;

  const IotDevice({
    required this.id,
    required this.name,
    required this.driver,
    required this.channels,
    this.states = const {},
  });

  factory IotDevice.fromJson(Map<String, dynamic> json) {
    final chList =
        (json['channels'] as List<dynamic>?)
            ?.map((e) => DeviceChannel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final stMap = (json['states'] as Map<String, dynamic>?) ?? {};
    return IotDevice(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      driver: json['driver'] as String? ?? 'custom',
      channels: chList,
      states: stMap,
    );
  }

  IotDevice copyWithState(String channelId, dynamic value) {
    final updatedStates = Map<String, dynamic>.from(states);
    updatedStates[channelId] = value;
    return IotDevice(
      id: id,
      name: name,
      driver: driver,
      channels: channels,
      states: updatedStates,
    );
  }
}

/// Definisi widget individu pada kanvas dashboard ala Blynk.
class DashboardWidgetConfig {
  final String id;
  final String widgetType; // toggle, slider, gauge, value_card, button
  final String title;
  final String deviceId;
  final String channelId;
  final double? min;
  final double? max;
  final String? unit;

  const DashboardWidgetConfig({
    required this.id,
    required this.widgetType,
    required this.title,
    required this.deviceId,
    required this.channelId,
    this.min,
    this.max,
    this.unit,
  });

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      id: json['id'] as String? ?? '',
      widgetType: json['widgetType'] as String? ?? 'toggle',
      title: json['title'] as String? ?? 'Widget',
      deviceId: json['deviceId'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'widgetType': widgetType,
    'title': title,
    'deviceId': deviceId,
    'channelId': channelId,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (unit != null) 'unit': unit,
  };
}

/// Tata letak dashboard pengguna yang tersimpan di backend.
class DashboardModel {
  final String id;
  final String userId;
  final String name;
  final bool isPublic;
  final List<DashboardWidgetConfig> widgets;
  final List<String> deviceIds;
  final int createdAt;
  final int updatedAt;

  const DashboardModel({
    required this.id,
    required this.userId,
    required this.name,
    this.isPublic = false,
    required this.widgets,
    required this.deviceIds,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    List<DashboardWidgetConfig> parsedWidgets = [];
    final layoutRaw = json['layoutJson'];
    if (layoutRaw is String && layoutRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(layoutRaw);
        if (decoded is List) {
          parsedWidgets = decoded
              .map(
                (w) =>
                    DashboardWidgetConfig.fromJson(w as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (_) {}
    } else if (layoutRaw is List) {
      parsedWidgets = layoutRaw
          .map((w) => DashboardWidgetConfig.fromJson(w as Map<String, dynamic>))
          .toList();
    }

    final devIds =
        (json['deviceIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return DashboardModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Dashboard',
      isPublic: json['isPublic'] as bool? ?? false,
      widgets: parsedWidgets,
      deviceIds: devIds,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'isPublic': isPublic,
    'layoutJson': jsonEncode(widgets.map((w) => w.toJson()).toList()),
    'deviceIds': deviceIds,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

/// Model Aturan Otomasi IoT (Trigger -> Action)
class AutomationRule {
  final String id;
  final String userId;
  final String name;
  final bool enabled;
  final String triggerType; // 'state' | 'schedule'
  final String? triggerDeviceId;
  final String? triggerChannelId;
  final String? triggerOperator;
  final String? triggerValue;
  final String? triggerCron;
  final String actionDeviceId;
  final String actionChannelId;
  final String actionValue;
  final int createdAt;
  final int updatedAt;
  final bool isOwner;

  const AutomationRule({
    required this.id,
    this.userId = '',
    required this.name,
    this.enabled = true,
    required this.triggerType,
    this.triggerDeviceId,
    this.triggerChannelId,
    this.triggerOperator,
    this.triggerValue,
    this.triggerCron,
    required this.actionDeviceId,
    required this.actionChannelId,
    required this.actionValue,
    this.createdAt = 0,
    this.updatedAt = 0,
    this.isOwner = true,
  });

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    return AutomationRule(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      triggerType: json['triggerType'] as String? ?? 'state',
      triggerDeviceId: json['triggerDeviceId'] as String?,
      triggerChannelId: json['triggerChannelId'] as String?,
      triggerOperator: json['triggerOperator'] as String?,
      triggerValue: json['triggerValue'] as String?,
      triggerCron: json['triggerCron'] as String?,
      actionDeviceId: json['actionDeviceId'] as String? ?? '',
      actionChannelId: json['actionChannelId'] as String? ?? '',
      actionValue: json['actionValue']?.toString() ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      isOwner: json['isOwner'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'enabled': enabled,
    'triggerType': triggerType,
    if (triggerDeviceId != null) 'triggerDeviceId': triggerDeviceId,
    if (triggerChannelId != null) 'triggerChannelId': triggerChannelId,
    if (triggerOperator != null) 'triggerOperator': triggerOperator,
    if (triggerValue != null) 'triggerValue': triggerValue,
    if (triggerCron != null) 'triggerCron': triggerCron,
    'actionDeviceId': actionDeviceId,
    'actionChannelId': actionChannelId,
    'actionValue': actionValue,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isOwner': isOwner,
  };

  AutomationRule copyWith({
    String? id,
    String? userId,
    String? name,
    bool? enabled,
    String? triggerType,
    String? triggerDeviceId,
    String? triggerChannelId,
    String? triggerOperator,
    String? triggerValue,
    String? triggerCron,
    String? actionDeviceId,
    String? actionChannelId,
    String? actionValue,
    int? createdAt,
    int? updatedAt,
    bool? isOwner,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      triggerType: triggerType ?? this.triggerType,
      triggerDeviceId: triggerDeviceId ?? this.triggerDeviceId,
      triggerChannelId: triggerChannelId ?? this.triggerChannelId,
      triggerOperator: triggerOperator ?? this.triggerOperator,
      triggerValue: triggerValue ?? this.triggerValue,
      triggerCron: triggerCron ?? this.triggerCron,
      actionDeviceId: actionDeviceId ?? this.actionDeviceId,
      actionChannelId: actionChannelId ?? this.actionChannelId,
      actionValue: actionValue ?? this.actionValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}
