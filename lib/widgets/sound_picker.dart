import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../theme/brand.dart';
import '../theme/sounds.dart';

/// Opens a bottom sheet letting the user pick one of K-Alarm's bundled
/// alarm tones (or the device's default sound), with a preview-play button
/// per row. Returns the selected sound id, or null for "device default".
/// Returns nothing (dismissed) if the user backs out without choosing.
Future<String?> showSoundPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: KColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SoundPickerSheet(current: current),
  );
}

class _SoundPickerSheet extends StatefulWidget {
  const _SoundPickerSheet({this.current});
  final String? current;

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  final AudioPlayer _player = AudioPlayer();
  String? _selected;
  String? _previewing;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _preview(KSound sound) async {
    try {
      if (_previewing == sound.id) {
        await _player.stop();
        setState(() => _previewing = null);
        return;
      }
      await _player.stop();
      setState(() => _previewing = sound.id);
      await _player.play(AssetSource(sound.assetPath.replaceFirst('assets/', '')));
      _player.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _previewing = null);
      });
    } catch (_) {
      if (mounted) setState(() => _previewing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_selected);
      },
      child: SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'CHỌN ÂM BÁO THỨC',
                    style: TextStyle(
                      fontFamily: KFonts.mono,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: KColors.mutedSlate,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text('Xong'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _SoundTile(
                    label: 'Âm mặc định máy',
                    selected: _selected == null,
                    playing: false,
                    onTap: () => setState(() => _selected = null),
                    onPlay: null,
                  ),
                  const Divider(height: 8, color: Colors.transparent),
                  ...kSoundCatalog.map((sound) => _SoundTile(
                        label: sound.label,
                        selected: _selected == sound.id,
                        playing: _previewing == sound.id,
                        onTap: () => setState(() => _selected = sound.id),
                        onPlay: () => _preview(sound),
                      )),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.label,
    required this.selected,
    required this.playing,
    required this.onTap,
    required this.onPlay,
  });

  final String label;
  final bool selected;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? KColors.indigo.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? KColors.indigo : KColors.mutedSlate,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onPlay != null)
                IconButton(
                  icon: Icon(
                    playing ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                    color: playing ? KColors.coral : KColors.mutedSlate,
                  ),
                  onPressed: onPlay,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
