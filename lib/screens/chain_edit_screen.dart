import 'package:flutter/material.dart';

import '../models/alarm_item.dart';
import '../models/challenge.dart';
import '../services/alarm_repository.dart';
import '../theme/brand.dart';
import '../theme/sounds.dart';
import '../widgets/challenge_config_editor.dart';
import '../widgets/sound_picker.dart';

/// One editable row inside the chain editor's in-memory draft.
class _EntryDraft {
  TimeOfDay time;
  String label;
  ChallengeConfig challenge;
  String? soundAsset;
  final int? existingId;

  _EntryDraft({
    required this.time,
    this.label = '',
    ChallengeConfig? challenge,
    this.soundAsset,
    this.existingId,
  }) : challenge = challenge ?? ChallengeConfig();
}

/// Create or edit a chain of alarms — e.g. 01:05, 02:03, 05:00 — each with
/// its own, independently configurable dismiss challenge.
class ChainEditScreen extends StatefulWidget {
  const ChainEditScreen({super.key, this.existing});

  final AlarmChain? existing;

  @override
  State<ChainEditScreen> createState() => _ChainEditScreenState();
}

class _ChainEditScreenState extends State<ChainEditScreen> {
  late TextEditingController _nameController;
  final List<_EntryDraft> _entries = [];
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    if (widget.existing != null) {
      final items = AlarmRepository.instance.itemsOfChain(widget.existing!.id);
      for (final item in items) {
        _entries.add(_EntryDraft(
          time: TimeOfDay(hour: item.hour, minute: item.minute),
          label: item.label,
          challenge: item.challenge,
          soundAsset: item.soundAsset,
          existingId: item.id,
        ));
      }
    }
    if (_entries.isEmpty) {
      _entries.add(_EntryDraft(time: TimeOfDay.now(), soundAsset: kDefaultSoundId));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addEntry() {
    final last = _entries.last.time;
    final nextMinutes = (last.hour * 60 + last.minute + 60) % (24 * 60);
    setState(() {
      _entries.add(_EntryDraft(
        time: TimeOfDay(hour: nextMinutes ~/ 60, minute: nextMinutes % 60),
        soundAsset: kDefaultSoundId,
      ));
    });
  }

  Future<void> _pickSoundFor(int index) async {
    final draft = _entries[index];
    final picked = await showSoundPicker(context, current: draft.soundAsset);
    if (!mounted) return;
    setState(() => draft.soundAsset = picked);
  }

  void _removeEntry(int index) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(index));
  }

  Future<void> _pickTimeFor(int index) async {
    final res = await showTimePicker(context: context, initialTime: _entries[index].time);
    if (res != null) setState(() => _entries[index].time = res);
  }

  List<_EntryDraft> get _sortedEntries {
    final list = List<_EntryDraft>.from(_entries);
    list.sort((a, b) => (a.time.hour * 60 + a.time.minute)
        .compareTo(b.time.hour * 60 + b.time.minute));
    return list;
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy đặt tên cho chuỗi báo thức')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final drafts = _sortedEntries
          .map((e) => ChainEntryDraft(
                hour: e.time.hour,
                minute: e.time.minute,
                label: e.label,
                challenge: e.challenge,
                soundAsset: e.soundAsset,
                existingId: e.existingId,
              ))
          .toList();

      final repo = AlarmRepository.instance;
      if (_isNew) {
        await repo.createChain(name: _nameController.text.trim(), entries: drafts);
      } else {
        widget.existing!.name = _nameController.text.trim();
        await repo.updateChain(widget.existing!, entries: drafts);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object e) {
    if (e is AlarmSchedulingException) return e.message;
    return 'Không thể lưu chuỗi báo thức. Vui lòng thử lại. ($e)';
  }

  Future<void> _delete() async {
    await AlarmRepository.instance.deleteChain(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Chuỗi báo thức mới' : 'Sửa chuỗi báo thức'),
        actions: [
          if (!_isNew)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên chuỗi (ví dụ: Chuỗi thức khuya ôn thi)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mỗi mốc giờ reo độc lập và có thể dùng nhiệm vụ tắt khác nhau.',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._entries.asMap().entries.map((entry) {
            final index = entry.key;
            final draft = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'MẮT XÍCH ${(index + 1).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontFamily: KFonts.mono,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                            color: kStageColor(index),
                          ),
                        ),
                        const Spacer(),
                        if (_entries.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => _removeEntry(index),
                          ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => _pickTimeFor(index),
                      child: Text(
                        draft.time.format(context),
                        style: kMonoTime(fontSize: 24, color: kStageColor(index)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: draft.label,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (không bắt buộc)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => draft.label = v,
                    ),
                    const SizedBox(height: 12),
                    ChallengeConfigEditor(
                      config: draft.challenge,
                      onChanged: (c) => setState(() => draft.challenge = c),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.music_note_outlined, size: 20),
                      title: const Text('Âm báo thức', style: TextStyle(fontSize: 14)),
                      subtitle: Text(kSoundLabel(draft.soundAsset)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickSoundFor(index),
                    ),
                  ],
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.add),
            label: const Text('Thêm mốc giờ'),
          ),
          const SizedBox(height: 16),
        ],
      ),
      // Docked outside the scroll view so it's always on-screen and
      // tappable — never hidden behind the system gesture bar / nav
      // buttons, however many chain entries are in the list above.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu chuỗi báo thức'),
        ),
      ),
    );
  }
}
