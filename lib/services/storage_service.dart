import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_item.dart';

/// Persists alarms and chains to local device storage (SharedPreferences).
class StorageService {
  static const _alarmsKey = 'kalarm.alarms';
  static const _chainsKey = 'kalarm.chains';

  static final StorageService instance = StorageService._();
  StorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Generates a fresh, collision-free numeric id for a new [AlarmItem].
  /// The `alarm` package requires an int id per scheduled alarm.
  int newAlarmId() {
    final rnd = Random();
    // Keep ids within a safe 31-bit range for native alarm managers.
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000 +
        rnd.nextInt(999);
  }

  Future<List<AlarmItem>> loadAlarms() async {
    final prefs = await _p;
    final raw = prefs.getString(_alarmsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AlarmItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarms(List<AlarmItem> alarms) async {
    final prefs = await _p;
    final raw = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_alarmsKey, raw);
  }

  Future<List<AlarmChain>> loadChains() async {
    final prefs = await _p;
    final raw = prefs.getString(_chainsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AlarmChain.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveChains(List<AlarmChain> chains) async {
    final prefs = await _p;
    final raw = jsonEncode(chains.map((c) => c.toJson()).toList());
    await prefs.setString(_chainsKey, raw);
  }
}
