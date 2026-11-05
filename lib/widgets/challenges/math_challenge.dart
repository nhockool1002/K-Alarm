import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/challenge.dart';
import '../../theme/brand.dart';

class MathChallengeWidget extends StatefulWidget {
  const MathChallengeWidget({
    super.key,
    required this.difficulty,
    required this.onSolved,
  });

  final MathDifficulty difficulty;
  final VoidCallback onSolved;

  @override
  State<MathChallengeWidget> createState() => _MathChallengeWidgetState();
}

class _MathChallengeWidgetState extends State<MathChallengeWidget> {
  final _rnd = Random();
  final _controller = TextEditingController();
  late String _question;
  late int _answer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate() {
    switch (widget.difficulty) {
      case MathDifficulty.easy:
        _easy();
      case MathDifficulty.medium:
        _medium();
      case MathDifficulty.hard:
        _hard();
    }
    _controller.clear();
  }

  void _easy() {
    final a = 1 + _rnd.nextInt(20);
    final b = 1 + _rnd.nextInt(20);
    if (_rnd.nextBool()) {
      _question = '$a + $b';
      _answer = a + b;
    } else {
      final hi = max(a, b);
      final lo = min(a, b);
      _question = '$hi - $lo';
      _answer = hi - lo;
    }
  }

  void _medium() {
    final op = _rnd.nextInt(3);
    final a = 10 + _rnd.nextInt(40);
    final b = 10 + _rnd.nextInt(40);
    if (op == 0) {
      _question = '$a + $b';
      _answer = a + b;
    } else if (op == 1) {
      final hi = max(a, b);
      final lo = min(a, b);
      _question = '$hi - $lo';
      _answer = hi - lo;
    } else {
      final c = 2 + _rnd.nextInt(11);
      final d = 2 + _rnd.nextInt(11);
      _question = '$c × $d';
      _answer = c * d;
    }
  }

  void _hard() {
    final style = _rnd.nextInt(2);
    if (style == 0) {
      final a = 2 + _rnd.nextInt(11);
      final b = 2 + _rnd.nextInt(11);
      final c = 1 + _rnd.nextInt(20);
      _question = '($a × $b) + $c';
      _answer = a * b + c;
    } else {
      final b = 2 + _rnd.nextInt(9);
      final q = 2 + _rnd.nextInt(12);
      final a = b * q; // guarantees exact division
      _question = '$a ÷ $b';
      _answer = q;
    }
  }

  void _check() {
    final value = int.tryParse(_controller.text.trim());
    if (value == _answer) {
      widget.onSolved();
    } else {
      setState(() {
        _error = 'Sai rồi, thử câu khác nhé';
        _generate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MISSION: GIẢI TOÁN',
          style: TextStyle(
            color: KColors.indigo,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$_question = ?',
          style: kMonoTime(fontSize: 38, color: Colors.white),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 160,
          child: TextField(
            controller: _controller,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: kMonoTime(fontSize: 24, color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: KColors.surface,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _check(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: KColors.coral)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _check,
          style: ElevatedButton.styleFrom(
            backgroundColor: KColors.emerald,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          ),
          child: const Text('KIỂM TRA', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
