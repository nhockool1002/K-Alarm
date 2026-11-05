import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/brand.dart';

const _defaultSentences = [
  'Tôi sẽ thức dậy và bắt đầu một ngày mới thật tốt.',
  'Dậy thôi, hôm nay có nhiều việc quan trọng đang chờ.',
  'Không trì hoãn nữa, đứng lên khỏi giường ngay bây giờ.',
  'Mỗi buổi sáng là một cơ hội mới để cố gắng hơn.',
  'Tôi chịu trách nhiệm cho ngày hôm nay của chính mình.',
];

class RetypeChallengeWidget extends StatefulWidget {
  const RetypeChallengeWidget({
    super.key,
    required this.customSentence,
    required this.onSolved,
  });

  final String? customSentence;
  final VoidCallback onSolved;

  @override
  State<RetypeChallengeWidget> createState() => _RetypeChallengeWidgetState();
}

class _RetypeChallengeWidgetState extends State<RetypeChallengeWidget> {
  late final String _sentence;
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _sentence = (widget.customSentence != null && widget.customSentence!.trim().isNotEmpty)
        ? widget.customSentence!.trim()
        : _defaultSentences[Random().nextInt(_defaultSentences.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_controller.text.trim() == _sentence) {
      widget.onSolved();
    } else {
      setState(() => _error = 'Chưa đúng, gõ lại chính xác từng chữ nhé');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'MISSION: GÕ LẠI CÂU',
            style: TextStyle(
              color: KColors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gõ lại chính xác câu sau để tắt báo thức',
            style: TextStyle(color: KColors.mutedSlate, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KColors.border),
            ),
            child: Text(
              _sentence,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: KColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'Gõ lại câu ở trên...',
              hintStyle: const TextStyle(color: KColors.mutedSlate),
            ),
            onSubmitted: (_) => _check(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: KColors.coral)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _check,
            style: ElevatedButton.styleFrom(
              backgroundColor: KColors.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: const Text('KIỂM TRA', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
