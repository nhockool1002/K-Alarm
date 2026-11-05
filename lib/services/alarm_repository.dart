import 'package:flutter/foundation.dart';

import '../models/alarm_item.dart';
import '../models/challenge.dart';
import 'alarm_scheduler.dart';
import 'storage_service.dart';

/// Single source of truth for alarms & chains: owns the in-memory list,
/// persists every change, and keeps the native alarms in sync.
class AlarmRepository extends ChangeNotifier {
  AlarmRepository._();
  static final AlarmRepository instance = AlarmRepository._();

  final List<AlarmItem> _alarms = [];
  final List<AlarmChain> _chains = [];

  List<AlarmItem> get alarms => List.unmodifiable(_alarms);
  List<AlarmChain> get chains => List.unmodifiable(_chains);

  /// Standalone alarms (not part of any chain), sorted by time.
  List<AlarmItem> get standaloneAlarms {
    final list = _alarms.where((a) => !a.isPartOfChain).toList();
    list.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return list;
  }

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    _alarms
      ..clear()
      ..addAll(await StorageService.instance.loadAlarms());
    _chains
      ..clear()
      ..addAll(await StorageService.instance.loadChains());
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.instance.saveAlarms(_alarms);
    await StorageService.instance.saveChains(_chains);
  }

  AlarmItem? alarmById(int id) {
    for (final a in _alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  AlarmChain? chainById(String id) {
    for (final c in _chains) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<AlarmItem> itemsOfChain(String chainId) {
    final chain = chainById(chainId);
    if (chain == null) return [];
    final items = chain.itemIds.map(alarmById).whereType<AlarmItem>().toList();
    items.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return items;
  }

  // ---------------------------------------------------------------------
  // Single (standalone) alarms
  // ---------------------------------------------------------------------

  Future<AlarmItem> createAlarm({
    required int hour,
    required int minute,
    String label = '',
    List<int> repeatDays = const [],
    ChallengeConfig? challenge,
    double volume = 0.8,
    bool vibrate = true,
  }) async {
    final item = AlarmItem(
      id: StorageService.instance.newAlarmId(),
      hour: hour,
      minute: minute,
      label: label,
      repeatDays: List.of(repeatDays),
      challenge: challenge,
      volume: volume,
      vibrate: vibrate,
    );
    _alarms.add(item);
    await AlarmScheduler.schedule(item);
    await _persist();
    notifyListeners();
    return item;
  }

  Future<void> updateAlarm(AlarmItem updated) async {
    final idx = _alarms.indexWhere((a) => a.id == updated.id);
    if (idx == -1) return;
    _alarms[idx] = updated;
    await AlarmScheduler.schedule(updated);
    await _persist();
    notifyListeners();
  }

  Future<void> setAlarmEnabled(int id, bool enabled) async {
    final item = alarmById(id);
    if (item == null) return;
    item.enabled = enabled;
    await AlarmScheduler.schedule(item);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteAlarm(int id) async {
    await AlarmScheduler.cancel(id);
    _alarms.removeWhere((a) => a.id == id);
    for (final chain in _chains) {
      chain.itemIds.remove(id);
    }
    await _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Chains
  // ---------------------------------------------------------------------

  Future<AlarmChain> createChain({
    required String name,
    required List<ChainEntryDraft> entries,
  }) async {
    final chain = AlarmChain(id: _newChainId(), name: name);
    for (final e in entries) {
      final item = AlarmItem(
        id: StorageService.instance.newAlarmId(),
        hour: e.hour,
        minute: e.minute,
        label: e.label,
        challenge: e.challenge,
        repeatDays: const [],
        chainId: chain.id,
        chainOrder: chain.itemIds.length,
      );
      _alarms.add(item);
      chain.itemIds.add(item.id);
      await AlarmScheduler.schedule(item);
    }
    _chains.add(chain);
    await _persist();
    notifyListeners();
    return chain;
  }

  Future<void> updateChain(
    AlarmChain chain, {
    required List<ChainEntryDraft> entries,
  }) async {
    // Cancel & remove the old items belonging to this chain, then rebuild.
    final old = List<int>.from(chain.itemIds);
    for (final id in old) {
      await AlarmScheduler.cancel(id);
    }
    _alarms.removeWhere((a) => old.contains(a.id));
    chain.itemIds.clear();

    for (final e in entries) {
      final item = AlarmItem(
        id: e.existingId ?? StorageService.instance.newAlarmId(),
        hour: e.hour,
        minute: e.minute,
        label: e.label,
        challenge: e.challenge,
        repeatDays: const [],
        chainId: chain.id,
        chainOrder: chain.itemIds.length,
        enabled: chain.enabled,
      );
      _alarms.add(item);
      chain.itemIds.add(item.id);
      await AlarmScheduler.schedule(item);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setChainEnabled(String chainId, bool enabled) async {
    final chain = chainById(chainId);
    if (chain == null) return;
    chain.enabled = enabled;
    for (final item in itemsOfChain(chainId)) {
      item.enabled = enabled;
      await AlarmScheduler.schedule(item);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteChain(String chainId) async {
    final chain = chainById(chainId);
    if (chain == null) return;
    for (final id in chain.itemIds) {
      await AlarmScheduler.cancel(id);
    }
    _alarms.removeWhere((a) => chain.itemIds.contains(a.id));
    _chains.removeWhere((c) => c.id == chainId);
    await _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Called once the dismiss challenge has been completed successfully.
  // ---------------------------------------------------------------------

  Future<void> onAlarmDismissed(int id) async {
    final item = alarmById(id);
    if (item == null) return;
    if (item.repeatDays.isEmpty) {
      // One-time alarm: it has done its job.
      item.enabled = false;
      await AlarmScheduler.cancel(item.id);
    } else {
      // Repeating alarm: re-arm for its next occurrence.
      await AlarmScheduler.schedule(item);
    }
    await _persist();
    notifyListeners();
  }

  String _newChainId() =>
      'chain_${DateTime.now().microsecondsSinceEpoch}_${_alarms.length}';
}

/// Lightweight draft used when building/editing the items of a chain.
class ChainEntryDraft {
  final int hour;
  final int minute;
  final String label;
  final ChallengeConfig challenge;
  final int? existingId;

  ChainEntryDraft({
    required this.hour,
    required this.minute,
    this.label = '',
    ChallengeConfig? challenge,
    this.existingId,
  }) : challenge = challenge ?? ChallengeConfig();
}
