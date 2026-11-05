import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';

import '../models/alarm_item.dart';
import '../models/challenge.dart';
import '../services/alarm_repository.dart';
import '../services/alarm_scheduler.dart';
import '../theme/brand.dart';
import '../widgets/challenges/math_challenge.dart';
import '../widgets/challenges/qr_challenge.dart';
import '../widgets/challenges/retype_challenge.dart';
import '../widgets/challenges/shake_challenge.dart';
import '../widgets/k_alarm_logo.dart';

/// Full-screen ringing UI. Shown over the lock screen when a native alarm
/// fires. The only way out is completing the configured challenge — there is
/// deliberately no quick "stop" button when a challenge is set.
class RingScreen extends StatefulWidget {
  const RingScreen({super.key, required this.alarmSettings});

  final AlarmSettings alarmSettings;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  StreamSubscription<AlarmSet>? _ringingSub;
  bool _solved = false;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  AlarmItem? get _item => AlarmRepository.instance.alarmById(widget.alarmSettings.id);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // If the alarm is stopped from elsewhere (e.g. Alarm.stopAll, or it was
    // already solved and this screen is on its way out), close this screen.
    _ringingSub = Alarm.ringing.listen((alarms) {
      if (!_solved && !alarms.containsId(widget.alarmSettings.id)) {
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _ringingSub?.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _onSolved() async {
    if (_solved) return;
    _solved = true;
    await AlarmScheduler.stopRinging(widget.alarmSettings.id);
    await AlarmRepository.instance.onAlarmDismissed(widget.alarmSettings.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final challenge = item?.challenge ?? ChallengeConfig(type: ChallengeType.none);
    final headline = item?.isPartOfChain == true
        ? 'MẮT XÍCH ĐÃ NỔ CHUÔNG'
        : 'ĐẾN GIỜ THỨC GIẤC';
    final label = item?.label.isNotEmpty == true ? item!.label : null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: KColors.night,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const KAlarmLogo(size: 36),
                const SizedBox(height: 14),
                Text(
                  TimeOfDay.fromDateTime(_now).format(context),
                  style: kMonoTime(fontSize: 56, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  headline,
                  style: const TextStyle(
                    color: KColors.coral,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(color: KColors.mutedSlate, fontSize: 15)),
                ],
                const SizedBox(height: 20),
                const Divider(color: KColors.border, indent: 32, endIndent: 32),
                Expanded(
                  child: Center(
                    child: _buildChallenge(challenge),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallenge(ChallengeConfig challenge) {
    switch (challenge.type) {
      case ChallengeType.none:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Không nhiệm vụ. Một chạm để bắt đầu ngày mới.',
              style: TextStyle(color: KColors.mutedSlate, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onSolved,
              style: ElevatedButton.styleFrom(
                backgroundColor: KColors.emerald,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'TẮT BÁO THỨC',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ],
        );
      case ChallengeType.math:
        return MathChallengeWidget(
          difficulty: challenge.mathDifficulty,
          onSolved: _onSolved,
        );
      case ChallengeType.qrScan:
        return QrChallengeWidget(
          expectedContent: challenge.qrExpectedContent,
          onSolved: _onSolved,
        );
      case ChallengeType.shake:
        return ShakeChallengeWidget(
          requiredShakes: challenge.shakeCount,
          onSolved: _onSolved,
        );
      case ChallengeType.retypeSentence:
        return RetypeChallengeWidget(
          customSentence: challenge.customSentence,
          onSolved: _onSolved,
        );
    }
  }
}
