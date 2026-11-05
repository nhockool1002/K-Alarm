import 'challenge.dart';

/// A single alarm "shot" — one specific time of day, with its own dismiss
/// challenge. It may stand alone, or be one entry inside an [AlarmChain].
class AlarmItem {
  /// Unique numeric id (also used as the native alarm id).
  final int id;

  /// Optional label, e.g. "Thức dậy" or "Nhắc uống nước".
  String label;

  int hour;
  int minute;

  bool enabled;

  /// Weekdays (1 = Monday .. 7 = Sunday) this alarm repeats on.
  /// Empty list = fires once (today, or tomorrow if the time already passed)
  /// and then disables itself automatically.
  List<int> repeatDays;

  ChallengeConfig challenge;

  /// Volume 0.0 - 1.0
  double volume;
  bool vibrate;

  /// If part of a chain, the chain's id; otherwise null.
  String? chainId;

  /// Order of this alarm inside its chain (0-based). Unused if standalone.
  int chainOrder;

  AlarmItem({
    required this.id,
    this.label = '',
    required this.hour,
    required this.minute,
    this.enabled = true,
    List<int>? repeatDays,
    ChallengeConfig? challenge,
    this.volume = 0.8,
    this.vibrate = true,
    this.chainId,
    this.chainOrder = 0,
  })  : repeatDays = repeatDays ?? [],
        challenge = challenge ?? ChallengeConfig();

  bool get isOneTime => repeatDays.isEmpty;
  bool get isPartOfChain => chainId != null;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
        'repeatDays': repeatDays,
        'challenge': challenge.toJson(),
        'volume': volume,
        'vibrate': vibrate,
        'chainId': chainId,
        'chainOrder': chainOrder,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> json) {
    return AlarmItem(
      id: json['id'] as int,
      label: json['label'] as String? ?? '',
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      enabled: json['enabled'] as bool? ?? true,
      repeatDays: (json['repeatDays'] as List?)?.map((e) => e as int).toList() ?? [],
      challenge: json['challenge'] != null
          ? ChallengeConfig.fromJson(json['challenge'] as Map<String, dynamic>)
          : ChallengeConfig(),
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      vibrate: json['vibrate'] as bool? ?? true,
      chainId: json['chainId'] as String?,
      chainOrder: json['chainOrder'] as int? ?? 0,
    );
  }

  AlarmItem copyWith({
    String? label,
    int? hour,
    int? minute,
    bool? enabled,
    List<int>? repeatDays,
    ChallengeConfig? challenge,
    double? volume,
    bool? vibrate,
    String? chainId,
    int? chainOrder,
  }) {
    return AlarmItem(
      id: id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      challenge: challenge ?? this.challenge,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
      chainId: chainId ?? this.chainId,
      chainOrder: chainOrder ?? this.chainOrder,
    );
  }
}

/// A named, ordered group of [AlarmItem]s, e.g. a sequence of wake attempts
/// at 01:05, 02:03 and 05:00.
class AlarmChain {
  final String id;
  String name;
  bool enabled;

  /// Ids of the [AlarmItem]s belonging to this chain, in the order the user
  /// created them (the actual firing order is determined by each item's time).
  List<int> itemIds;

  AlarmChain({
    required this.id,
    required this.name,
    this.enabled = true,
    List<int>? itemIds,
  }) : itemIds = itemIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'itemIds': itemIds,
      };

  factory AlarmChain.fromJson(Map<String, dynamic> json) {
    return AlarmChain(
      id: json['id'] as String,
      name: json['name'] as String,
      enabled: json['enabled'] as bool? ?? true,
      itemIds: (json['itemIds'] as List?)?.map((e) => e as int).toList() ?? [],
    );
  }
}
