import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/ring_screen.dart';
import 'services/alarm_repository.dart';
import 'services/alarm_scheduler.dart';
import 'services/permission_service.dart';
import 'theme/brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await AlarmScheduler.init();
  await AlarmRepository.instance.load();
  unawaited(PermissionService.requestAll());

  runApp(const KAlarmApp());
}

class KAlarmApp extends StatefulWidget {
  const KAlarmApp({super.key});

  @override
  State<KAlarmApp> createState() => _KAlarmAppState();
}

class _KAlarmAppState extends State<KAlarmApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AlarmSet>? _ringingSub;
  final Set<int> _openRingScreens = {};

  @override
  void initState() {
    super.initState();
    _ringingSub = Alarm.ringing.listen(_onRingingChanged);
  }

  @override
  void dispose() {
    _ringingSub?.cancel();
    super.dispose();
  }

  void _onRingingChanged(AlarmSet alarmSet) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    for (final settings in alarmSet.alarms) {
      if (_openRingScreens.contains(settings.id)) continue;
      _openRingScreens.add(settings.id);
      navigator
          .push(MaterialPageRoute(builder: (_) => RingScreen(alarmSettings: settings)))
          .then((_) => _openRingScreens.remove(settings.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'K-Alarm',
      // The brand is designed around the dark "Obsidian Night" surface
      // system — K-Alarm always runs in it, day or night.
      theme: buildKAlarmTheme(brightness: Brightness.dark),
      darkTheme: buildKAlarmTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
