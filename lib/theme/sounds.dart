/// Catalog of K-Alarm's bundled alarm tones (see tools/gen_sounds.py — these
/// mirror its `LABELS_VI` 1:1). Every sound ships inside the app as an mp3
/// under `assets/sounds/`, so picking one never needs network access.
class KSound {
  final String id;
  final String label;

  const KSound(this.id, this.label);

  /// Asset path to hand to `AlarmSettings.assetAudioPath`.
  String get assetPath => 'assets/sounds/$id.mp3';
}

/// Null/unset means "use the device's default alarm sound".
const List<KSound> kSoundCatalog = [
  KSound('classic_beep', 'Bíp Cổ Điển'),
  KSound('double_beep', 'Bíp Đôi'),
  KSound('digital_chirp', 'Chirp Kỹ Thuật Số'),
  KSound('retro_game', 'Retro Game'),
  KSound('fast_pulse', 'Xung Nhanh'),
  KSound('slow_pulse', 'Xung Chậm'),
  KSound('urgent_triple', 'Ba Hồi Gấp'),
  KSound('industrial_alarm', 'Báo Động Công Nghiệp'),
  KSound('siren_sweep', 'Còi Hú Lướt'),
  KSound('two_tone_siren', 'Còi Hai Tông'),
  KSound('police_classic', 'Còi Cảnh Báo'),
  KSound('air_raid', 'Báo Động Trường'),
  KSound('soft_chime', 'Chuông Êm'),
  KSound('gentle_wake', 'Thức Dậy Dịu Nhẹ'),
  KSound('calm_ascend', 'Giai Điệu Lên Nhẹ'),
  KSound('marimba_pulse', 'Marimba'),
  KSound('chirp_pattern', 'Chim Chíp Kỹ Thuật Số'),
  KSound('arpeggio_up', 'Hợp Âm Rải Lên'),
  KSound('arpeggio_down', 'Hợp Âm Rải Xuống'),
  KSound('rising_alarm', 'Báo Thức Tăng Dần'),
  KSound('square_buzzer', 'Chuông Vuông'),
  KSound('sawtooth_alert', 'Cảnh Báo Sawtooth'),
  KSound('triangle_soft', 'Sóng Tam Giác Êm'),
  KSound('low_rumble', 'Rền Trầm'),
  KSound('high_alert', 'Cảnh Báo Cao'),
  KSound('vibrato_pulse', 'Xung Rung'),
  KSound('pulse_wave_sweep', 'Xung Lướt'),
];

/// Default sound for new alarms.
const String kDefaultSoundId = 'classic_beep';

KSound? kSoundById(String? id) {
  if (id == null) return null;
  for (final s in kSoundCatalog) {
    if (s.id == id) return s;
  }
  return null;
}

String kSoundLabel(String? id) => kSoundById(id)?.label ?? 'Âm mặc định máy';
