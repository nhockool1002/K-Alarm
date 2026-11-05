import 'package:flutter/material.dart';

import '../models/challenge.dart';

/// Inline editor for a single [ChallengeConfig]: picks the challenge type
/// and exposes whichever extra fields that type needs.
class ChallengeConfigEditor extends StatelessWidget {
  const ChallengeConfigEditor({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final ChallengeConfig config;
  final ValueChanged<ChallengeConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nhiệm vụ để tắt báo thức', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ChallengeType.values.map((type) {
            final selected = config.type == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (_) => onChanged(config.copyWith(type: type)),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          config.type.description,
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _buildExtra(context),
      ],
    );
  }

  Widget _buildExtra(BuildContext context) {
    switch (config.type) {
      case ChallengeType.none:
        return const SizedBox.shrink();

      case ChallengeType.math:
        return SegmentedButton<MathDifficulty>(
          segments: MathDifficulty.values
              .map((d) => ButtonSegment(value: d, label: Text(d.label)))
              .toList(),
          selected: {config.mathDifficulty},
          onSelectionChanged: (s) =>
              onChanged(config.copyWith(mathDifficulty: s.first)),
        );

      case ChallengeType.qrScan:
        return TextFormField(
          initialValue: config.qrExpectedContent,
          decoration: const InputDecoration(
            labelText: 'Nội dung mã QR cần quét (để trống = quét mã bất kỳ)',
            hintText: 'ví dụ: KALARM-BATHROOM-001',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => onChanged(config.copyWith(qrExpectedContent: v)),
        );

      case ChallengeType.shake:
        return Row(
          children: [
            const Text('Số lần lắc:'),
            Expanded(
              child: Slider(
                value: config.shakeCount.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                label: '${config.shakeCount}',
                onChanged: (v) =>
                    onChanged(config.copyWith(shakeCount: v.round())),
              ),
            ),
            Text('${config.shakeCount}'),
          ],
        );

      case ChallengeType.retypeSentence:
        return TextFormField(
          initialValue: config.customSentence ?? '',
          decoration: const InputDecoration(
            labelText: 'Câu cần gõ lại (để trống = câu ngẫu nhiên)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (v) => onChanged(config.copyWith(customSentence: v)),
        );
    }
  }
}
