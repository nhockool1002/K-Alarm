import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The K-Alarm mark: a stylised "K" whose branches read as a chain link and
/// an alarm-bell hammer, per the brand guidelines.
class KAlarmLogo extends StatelessWidget {
  const KAlarmLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/brand/logo.svg',
      width: size,
      height: size,
    );
  }
}

/// "K-ALARM." wordmark with the signature coral full-stop.
class KAlarmWordmark extends StatelessWidget {
  const KAlarmWordmark({super.key, this.fontSize = 20, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).textTheme.titleLarge?.color;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: -0.2,
          color: resolved,
        ),
        children: const [
          TextSpan(text: 'K-ALARM'),
          TextSpan(text: '.', style: TextStyle(color: Color(0xFFFF4A3D))),
        ],
      ),
    );
  }
}
