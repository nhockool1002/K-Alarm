import 'package:flutter/material.dart';

import '../models/alarm_item.dart';
import '../models/challenge.dart';
import '../services/alarm_repository.dart';
import '../theme/brand.dart';
import '../theme/sounds.dart';
import '../widgets/challenge_config_editor.dart';
import '../widgets/sound_picker.dart';

const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Create or edit a single, standalone alarm.
class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, this.existing});

  final AlarmItem? existing;

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TimeOfDay _time;
  late TextEditingController _labelController;
  late Set<int> _repeatDays;
  late ChallengeConfig _challenge;
  late double _volume;
  late bool _vibrate;
  String? _soundAsset;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _time = TimeOfDay(hour: e?.hour ?? 7, minute: e?.minute ?? 0);
    _labelController = TextEditingController(text: e?.label ?? '');
    _repeatDays = (e?.repeatDays ?? const []).toSet();
    _challenge = ChallengeConfig(
      type: e?.challenge.type ?? ChallengeType.math,
      mathDifficulty: e?.challenge.mathDifficulty ?? MathDifficulty.easy,
      qrExpectedContent: e?.challenge.qrExpectedContent ?? '',
      shakeCount: e?.challenge.shakeCount ?? 15,
      customSentence: e?.challenge.customSentence,
    );
    _volume = e?.volume ?? 0.8;
    _vibrate = e?.vibrate ?? true;
    _soundAsset = e?.soundAsset ?? (e == null ? kDefaultSoundId : null);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final res = await showTimePicker(context: context, initialTime: _time);
    if (res != null) setState(() => _time = res);
  }

  Future<void> _pickSound() async {
    final picked = await showSoundPicker(context, current: _soundAsset);
    if (!mounted) return;
    setState(() => _soundAsset = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = AlarmRepository.instance;
      if (_isNew) {
        await repo.createAlarm(
          hour: _time.hour,
          minute: _time.minute,
          label: _labelController.text.trim(),
          repeatDays: _repeatDays.toList()..sort(),
          challenge: _challenge,
          volume: _volume,
          vibrate: _vibrate,
          soundAsset: _soundAsset,
        );
      } else {
        final updated = widget.existing!.copyWith(
          hour: _time.hour,
          minute: _time.minute,
          label: _labelController.text.trim(),
          repeatDays: _repeatDays.toList()..sort(),
          challenge: _challenge,
          volume: _volume,
          vibrate: _vibrate,
          soundAsset: _soundAsset,
        );
        await repo.updateAlarm(updated);
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
    return 'Không thể lưu báo thức. Vui lòng thử lại. ($e)';
  }

  Future<void> _delete() async {
    await AlarmRepository.instance.deleteAlarm(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Báo thức mới' : 'Sửa báo thức'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: OutlinedButton(
              onPressed: _pickTime,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              ),
              child: Text(
                _time.format(context),
                style: kMonoTime(fontSize: 36, color: KColors.indigo),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Tên báo thức (không bắt buộc)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Lặp lại', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final day = i + 1; // 1 = Monday ... 7 = Sunday
              final selected = _repeatDays.contains(day);
              return FilterChip(
                label: Text(_weekdayLabels[i]),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _repeatDays.add(day);
                  } else {
                    _repeatDays.remove(day);
                  }
                }),
              );
            }),
          ),
          Text(
            _repeatDays.isEmpty
                ? 'Báo thức một lần (tự tắt sau khi reo và xử lý xong)'
                : 'Lặp lại hàng tuần vào các ngày đã chọn',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ChallengeConfigEditor(
            config: _challenge,
            onChanged: (c) => setState(() => _challenge = c),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Rung'),
              const Spacer(),
              Switch(
                value: _vibrate,
                onChanged: (v) => setState(() => _vibrate = v),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.volume_down),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (v) => setState(() => _volume = v),
                ),
              ),
              const Icon(Icons.volume_up),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('Âm báo thức'),
            subtitle: Text(kSoundLabel(_soundAsset)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickSound,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu báo thức'),
          ),
        ],
      ),
    );
  }
}
