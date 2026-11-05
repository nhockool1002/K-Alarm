import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../theme/brand.dart';

class ShakeChallengeWidget extends StatefulWidget {
  const ShakeChallengeWidget({
    super.key,
    required this.requiredShakes,
    required this.onSolved,
  });

  final int requiredShakes;
  final VoidCallback onSolved;

  @override
  State<ShakeChallengeWidget> createState() => _ShakeChallengeWidgetState();
}

class _ShakeChallengeWidgetState extends State<ShakeChallengeWidget> {
  static const _threshold = 18.0; // m/s^2 of combined acceleration delta
  static const _cooldown = Duration(milliseconds: 300);

  StreamSubscription<UserAccelerometerEvent>? _sub;
  int _count = 0;
  DateTime? _lastShake;

  @override
  void initState() {
    super.initState();
    _sub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(UserAccelerometerEvent e) {
    final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (magnitude < _threshold) return;

    final now = DateTime.now();
    if (_lastShake != null && now.difference(_lastShake!) < _cooldown) return;
    _lastShake = now;

    setState(() => _count++);
    if (_count >= widget.requiredShakes) {
      _sub?.cancel();
      widget.onSolved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_count / widget.requiredShakes).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MISSION: LẮC & BƯỚC',
          style: TextStyle(
            color: KColors.emerald,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Lắc điện thoại mạnh để tắt báo thức',
          style: TextStyle(color: KColors.mutedSlate, fontSize: 15),
        ),
        const SizedBox(height: 24),
        const Icon(Icons.vibration, color: Colors.white, size: 56),
        const SizedBox(height: 20),
        SizedBox(
          width: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: KColors.surface,
              valueColor: const AlwaysStoppedAnimation(KColors.emerald),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_count / ${widget.requiredShakes} LẦN',
          style: kMonoTime(fontSize: 20, color: Colors.white),
        ),
      ],
    );
  }
}
