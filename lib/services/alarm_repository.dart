import 'package:flutter/foundation.dart';

import '../models/alarm_item.dart';
import '../models/challenge.dart';
import 'alarm_scheduler.dart';
import 'storage_service.dart';

/// Thrown when an alarm/chain was saved to local storage successfully but
/// the native OS-level scheduling call failed (e.g. timed out, or the
/// device's alarm manager rejected it). The data is safe — only the native
/// alarm may not actually be armed — so callers should surface this as a
/// warning rather than losing the user's edits.
class AlarmSchedulingException implements Exception {
  AlarmSchedulingException(this.message);
  final String message;

  @override
  String toString() => message;
}

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

  /// Arms the native alarm for [item], swallowing any exception (timeout,
  /// platform error, …) so a native scheduling failure can never leave the
  /// caller's Future unresolved or block the data from being persisted.
  /// Returns true on success.
  Future<bool> _scheduleQuiet(AlarmItem item) async {
    try {
      await AlarmScheduler.schedule(item);
      return true;
    } catch (e) {
      debugPrint('K-Alarm: failed to schedule native alarm ${item.id}: $e');
      return false;
    }
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
    String? soundAsset,
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
      soundAsset: soundAsset,
    );
    _alarms.add(item);
    final ok = await _scheduleQuiet(item);
    await _persist();
    notifyListeners();
    if (!ok) {
      throw AlarmSchedulingException(
          'Đã lưu báo thức nhưng không thể đặt lịch trên hệ điều hành. Hãy mở lại báo thức để thử lại.');
    }
    return item;
  }

  Future<void> updateAlarm(AlarmItem updated) async {
    final idx = _alarms.indexWhere((a) => a.id == updated.id);
    if (idx == -1) return;
    _alarms[idx] = updated;
    final ok = await _scheduleQuiet(updated);
    await _persist();
    notifyListeners();
    if (!ok) {
      throw AlarmSchedulingException(
          'Đã lưu thay đổi nhưng không thể đặt lại lịch trên hệ điều hành. Hãy thử lại.');
    }
  }

  Future<void> setAlarmEnabled(int id, bool enabled) async {
    final item = alarmById(id);
    if (item == null) return;
    item.enabled = enabled;
    final ok = await _scheduleQuiet(item);
    await _persist();
    notifyListeners();
    if (!ok) {
      throw AlarmSchedulingException('Không thể cập nhật lịch báo thức trên hệ điều hành.');
    }
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
    var allOk = true;
    for (final e in entries) {
      final item = AlarmItem(
        id: StorageService.instance.newAlarmId(),
        hour: e.hour,
        minute: e.minute,
        label: e.label,
        challenge: e.challenge,
        soundAsset: e.soundAsset,
        repeatDays: const [],
        chainId: chain.id,
        chainOrder: chain.itemIds.length,
      );
      _alarms.add(item);
      chain.itemIds.add(item.id);
      if (!await _scheduleQuiet(item)) allOk = false;
    }
    _chains.add(chain);
    await _persist();
    notifyListeners();
    if (!allOk) {
      throw AlarmSchedulingException(
          'Đã lưu chuỗi báo thức nhưng một số mốc giờ không đặt được lịch trên hệ điều hành. Hãy mở lại để kiểm tra.');
    }
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

    var allOk = true;
    for (final e in entries) {
      final item = AlarmItem(
        id: e.existingId ?? StorageService.instance.newAlarmId(),
        hour: e.hour,
        minute: e.minute,
        label: e.label,
        challenge: e.challenge,
        soundAsset: e.soundAsset,
        repeatDays: const [],
        chainId: chain.id,
        chainOrder: chain.itemIds.length,
        enabled: chain.enabled,
      );
      _alarms.add(item);
      chain.itemIds.add(item.id);
      if (!await _scheduleQuiet(item)) allOk = false;
    }
    await _persist();
    notifyListeners();
    if (!allOk) {
      throw AlarmSchedulingException(
          'Đã lưu chuỗi báo thức nhưng một số mốc giờ không đặt được lịch trên hệ điều hành. Hãy mở lại để kiểm tra.');
    }
  }

  Future<void> setChainEnabled(String chainId, bool enabled) async {
    final chain = chainById(chainId);
    if (chain == null) return;
    chain.enabled = enabled;
    var allOk = true;
    for (final item in itemsOfChain(chainId)) {
      item.enabled = enabled;
      if (!await _scheduleQuiet(item)) allOk = false;
    }
    await _persist();
    notifyListeners();
    if (!allOk) {
      throw AlarmSchedulingException('Không thể cập nhật lịch của chuỗi báo thức trên hệ điều hành.');
    }
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
      await _scheduleQuiet(item);
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
  final String? soundAsset;
  final int? existingId;

  ChainEntryDraft({
    required this.hour,
    required this.minute,
    this.label = '',
    ChallengeConfig? challenge,
    this.soundAsset,
    this.existingId,
  }) : challenge = challenge ?? ChallengeConfig();
}
