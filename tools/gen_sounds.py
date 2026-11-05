#!/usr/bin/env python3
"""Synthesizes K-Alarm's bundled alarm-tone library — no external audio
files, no licensing questions. Pure stdlib (wave + math), then ffmpeg
converts each .wav to a small .mp3 for the Flutter assets bundle.

Each sound is a short (2-4s) clip meant to be looped natively by the
`alarm` plugin (loopAudio: true), so it just needs to start and end near
zero amplitude to loop cleanly.
"""
import math
import struct
import wave
import os
import subprocess

SR = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
os.makedirs(OUT_DIR, exist_ok=True)


def envelope(i, n, attack=0.01, release=0.05):
    """Simple linear attack/release envelope, fraction of total length."""
    t = i / n
    a = attack
    r = release
    if t < a:
        return t / a
    if t > 1 - r:
        return max(0.0, (1 - t) / r)
    return 1.0


def tone(freq, dur, wave_type="sine", vol=0.7, vib=0.0, vib_rate=0.0):
    n = int(SR * dur)
    samples = []
    for i in range(n):
        t = i / SR
        f = freq + (math.sin(2 * math.pi * vib_rate * t) * vib if vib else 0)
        phase = 2 * math.pi * f * t
        if wave_type == "sine":
            s = math.sin(phase)
        elif wave_type == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        elif wave_type == "triangle":
            s = 2 / math.pi * math.asin(math.sin(phase))
        elif wave_type == "saw":
            s = 2 * (t * f - math.floor(t * f + 0.5))
        else:
            s = math.sin(phase)
        s *= vol * envelope(i, n)
        samples.append(s)
    return samples


def silence(dur):
    return [0.0] * int(SR * dur)


def sweep(f0, f1, dur, wave_type="sine", vol=0.7):
    n = int(SR * dur)
    samples = []
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (t / dur)
        phase = 2 * math.pi * f * t
        if wave_type == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        else:
            s = math.sin(phase)
        s *= vol * envelope(i, n, attack=0.02, release=0.08)
        samples.append(s)
    return samples


def mix_sequence(parts, repeat=1):
    seq = []
    for _ in range(repeat):
        for p in parts:
            seq.extend(p)
    return seq


def write_wav(path, samples):
    n = len(samples)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(bytes(frames))


SOUNDS = {}


def define(sound_id, builder):
    SOUNDS[sound_id] = builder


# --- Classic / digital beeps -------------------------------------------------
define("classic_beep", lambda: mix_sequence(
    [tone(880, 0.15, "square", 0.6), silence(0.15)], repeat=6))
define("double_beep", lambda: mix_sequence(
    [tone(1000, 0.1, "square", 0.6), silence(0.08),
     tone(1000, 0.1, "square", 0.6), silence(0.4)], repeat=3))
define("digital_chirp", lambda: mix_sequence(
    [sweep(600, 1800, 0.2, "sine", 0.6), silence(0.15)], repeat=5))
define("retro_game", lambda: mix_sequence(
    [tone(660, 0.08, "square", 0.55), tone(880, 0.08, "square", 0.55),
     tone(990, 0.08, "square", 0.55), tone(1320, 0.12, "square", 0.55),
     silence(0.25)], repeat=3))
define("fast_pulse", lambda: mix_sequence(
    [tone(1200, 0.06, "square", 0.55), silence(0.06)], repeat=18))
define("slow_pulse", lambda: mix_sequence(
    [tone(700, 0.25, "sine", 0.6), silence(0.35)], repeat=5))
define("urgent_triple", lambda: mix_sequence(
    [tone(1100, 0.08, "square", 0.6), silence(0.05),
     tone(1100, 0.08, "square", 0.6), silence(0.05),
     tone(1100, 0.08, "square", 0.6), silence(0.4)], repeat=3))
define("industrial_alarm", lambda: mix_sequence(
    [sweep(300, 900, 0.3, "square", 0.55), sweep(900, 300, 0.3, "square", 0.55)],
    repeat=4))

# --- Sirens / sweeps ----------------------------------------------------------
define("siren_sweep", lambda: mix_sequence(
    [sweep(400, 1200, 0.5, "sine", 0.6), sweep(1200, 400, 0.5, "sine", 0.6)],
    repeat=3))
define("two_tone_siren", lambda: mix_sequence(
    [tone(880, 0.3, "sine", 0.6), tone(660, 0.3, "sine", 0.6)], repeat=6))
define("police_classic", lambda: mix_sequence(
    [sweep(500, 1400, 0.4, "square", 0.5), sweep(1400, 500, 0.4, "square", 0.5)],
    repeat=4))
define("air_raid", lambda: mix_sequence(
    [sweep(250, 1000, 1.0, "sine", 0.6)], repeat=3))

# --- Gentle / wake-friendly ----------------------------------------------------
define("soft_chime", lambda: mix_sequence(
    [tone(523, 0.5, "sine", 0.5), tone(659, 0.5, "sine", 0.5),
     tone(784, 0.7, "sine", 0.5), silence(0.5)], repeat=2))
define("gentle_wake", lambda: mix_sequence(
    [tone(440, 1.2, "sine", 0.45), silence(0.3)], repeat=3))
define("calm_ascend", lambda: mix_sequence(
    [tone(392, 0.4, "sine", 0.45), tone(440, 0.4, "sine", 0.45),
     tone(494, 0.4, "sine", 0.45), tone(523, 0.6, "sine", 0.5),
     silence(0.4)], repeat=2))
define("marimba_pulse", lambda: mix_sequence(
    [tone(523, 0.18, "triangle", 0.55), tone(659, 0.18, "triangle", 0.55),
     tone(784, 0.18, "triangle", 0.55), silence(0.3)], repeat=4))
define("chirp_pattern", lambda: mix_sequence(
    [sweep(1200, 1800, 0.08, "sine", 0.5), silence(0.05),
     sweep(1800, 1200, 0.08, "sine", 0.5), silence(0.3)], repeat=5))

# --- Arpeggios / melodic -------------------------------------------------------
define("arpeggio_up", lambda: mix_sequence(
    [tone(392, 0.15, "triangle", 0.55), tone(494, 0.15, "triangle", 0.55),
     tone(587, 0.15, "triangle", 0.55), tone(784, 0.25, "triangle", 0.6),
     silence(0.3)], repeat=3))
define("arpeggio_down", lambda: mix_sequence(
    [tone(784, 0.15, "triangle", 0.55), tone(587, 0.15, "triangle", 0.55),
     tone(494, 0.15, "triangle", 0.55), tone(392, 0.25, "triangle", 0.6),
     silence(0.3)], repeat=3))
define("rising_alarm", lambda: mix_sequence(
    [tone(440, 0.2, "square", 0.5), tone(554, 0.2, "square", 0.5),
     tone(659, 0.2, "square", 0.55), tone(880, 0.3, "square", 0.6),
     silence(0.3)], repeat=3))

# --- Waveform character studies ------------------------------------------------
define("square_buzzer", lambda: mix_sequence(
    [tone(220, 0.4, "square", 0.6), silence(0.2)], repeat=5))
define("sawtooth_alert", lambda: mix_sequence(
    [tone(330, 0.25, "saw", 0.5), silence(0.15)], repeat=6))
define("triangle_soft", lambda: mix_sequence(
    [tone(330, 0.4, "triangle", 0.5), silence(0.25)], repeat=5))
define("low_rumble", lambda: mix_sequence(
    [tone(110, 0.6, "square", 0.55), silence(0.2)], repeat=4))
define("high_alert", lambda: mix_sequence(
    [tone(1760, 0.12, "sine", 0.5), silence(0.1)], repeat=8))
define("vibrato_pulse", lambda: mix_sequence(
    [tone(600, 0.6, "sine", 0.55, vib=40, vib_rate=8), silence(0.3)], repeat=4))
define("pulse_wave_sweep", lambda: mix_sequence(
    [sweep(500, 1000, 0.3, "square", 0.5), sweep(1000, 500, 0.3, "square", 0.5),
     silence(0.2)], repeat=3))

LABELS_VI = {
    "classic_beep": "Bíp Cổ Điển",
    "double_beep": "Bíp Đôi",
    "digital_chirp": "Chirp Kỹ Thuật Số",
    "retro_game": "Retro Game",
    "fast_pulse": "Xung Nhanh",
    "slow_pulse": "Xung Chậm",
    "urgent_triple": "Ba Hồi Gấp",
    "industrial_alarm": "Báo Động Công Nghiệp",
    "siren_sweep": "Còi Hú Lướt",
    "two_tone_siren": "Còi Hai Tông",
    "police_classic": "Còi Cảnh Báo",
    "air_raid": "Báo Động Trường",
    "soft_chime": "Chuông Êm",
    "gentle_wake": "Thức Dậy Dịu Nhẹ",
    "calm_ascend": "Giai Điệu Lên Nhẹ",
    "marimba_pulse": "Marimba",
    "chirp_pattern": "Chim Chíp Kỹ Thuật Số",
    "arpeggio_up": "Hợp Âm Rải Lên",
    "arpeggio_down": "Hợp Âm Rải Xuống",
    "rising_alarm": "Báo Thức Tăng Dần",
    "square_buzzer": "Chuông Vuông",
    "sawtooth_alert": "Cảnh Báo Sawtooth",
    "triangle_soft": "Sóng Tam Giác Êm",
    "low_rumble": "Rền Trầm",
    "high_alert": "Cảnh Báo Cao",
    "vibrato_pulse": "Xung Rung",
    "pulse_wave_sweep": "Xung Lướt",
}

if __name__ == "__main__":
    manifest = []
    for sid, builder in SOUNDS.items():
        samples = builder()
        wav_path = os.path.join(OUT_DIR, f"{sid}.wav")
        mp3_path = os.path.join(OUT_DIR, f"{sid}.mp3")
        write_wav(wav_path, samples)
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path,
             "-codec:a", "libmp3lame", "-qscale:a", "4", mp3_path],
            check=True,
        )
        os.remove(wav_path)
        manifest.append((sid, LABELS_VI.get(sid, sid)))
        print(f"generated {sid}.mp3  ({LABELS_VI.get(sid, sid)})")

    print(f"\nTotal: {len(manifest)} sounds")
