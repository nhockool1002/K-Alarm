import 'package:flutter/material.dart';

import '../models/alarm_item.dart';
import '../models/challenge.dart';
import '../services/alarm_repository.dart';
import '../theme/brand.dart';
import '../widgets/k_alarm_logo.dart';
import 'alarm_edit_screen.dart';
import 'chain_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = AlarmRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onChange);
  }

  @override
  void dispose() {
    _repo.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _addMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: KColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TẠO MỚI',
                  style: TextStyle(
                    fontFamily: KFonts.mono,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: KColors.mutedSlate,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A6366F1),
                foregroundColor: KColors.indigo,
                child: Icon(Icons.alarm_add),
              ),
              title: const Text('Báo thức đơn', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('K-Snap — một báo thức ở một giờ cố định'),
              onTap: () => Navigator.pop(context, 'single'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1AFF4A3D),
                foregroundColor: KColors.coral,
                child: Icon(Icons.playlist_add),
              ),
              title: const Text('Chuỗi báo thức', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('K-Chain — nhiều mốc giờ nối tiếp, mỗi mốc một nhiệm vụ riêng'),
              onTap: () => Navigator.pop(context, 'chain'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'single') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmEditScreen()));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ChainEditScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final standalone = _repo.standaloneAlarms;
    final chains = _repo.chains;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            KAlarmLogo(size: 28),
            SizedBox(width: 10),
            KAlarmWordmark(fontSize: 19),
          ],
        ),
      ),
      body: (standalone.isEmpty && chains.isEmpty)
          ? _EmptyState(onAdd: _addMenu)
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (standalone.isNotEmpty) ...[
                  const _SectionHeader('BÁO THỨC ĐƠN'),
                  ...standalone.map((a) => _AlarmTile(item: a)),
                  const SizedBox(height: 16),
                ],
                if (chains.isNotEmpty) ...[
                  const _SectionHeader('CHUỖI BÁO THỨC · K-CHAIN'),
                  ...chains.map((c) => _ChainTile(chain: c)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMenu,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KAlarmLogo(size: 72),
            const SizedBox(height: 20),
            const Text(
              'CHƯA CÓ CHUỖI THỨC GIẤC NÀO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: KFonts.mono,
                fontSize: 13,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: KColors.mutedSlate,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Own your rhythm. Break the slumber.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KColors.mutedSlate, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thiết lập báo thức'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: KFonts.mono,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.2,
          color: KColors.mutedSlate,
        ),
      ),
    );
  }
}

String _weekdaysLabel(List<int> days) {
  const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  if (days.isEmpty) return 'Một lần';
  if (days.length == 7) return 'Hàng ngày';
  return days.map((d) => names[d - 1]).join(', ');
}

IconData _challengeIcon(ChallengeType type) {
  switch (type) {
    case ChallengeType.none:
      return Icons.touch_app;
    case ChallengeType.math:
      return Icons.calculate_outlined;
    case ChallengeType.qrScan:
      return Icons.qr_code_scanner;
    case ChallengeType.shake:
      return Icons.vibration;
    case ChallengeType.retypeSentence:
      return Icons.keyboard_alt_outlined;
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({required this.item});
  final AlarmItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AlarmEditScreen(existing: item)),
        ),
        leading: CircleAvatar(
          backgroundColor: KColors.indigo.withValues(alpha: 0.15),
          foregroundColor: KColors.indigo,
          child: Icon(_challengeIcon(item.challenge.type)),
        ),
        title: Text(item.timeLabel, style: kMonoTime(fontSize: 24)),
        subtitle: Text(
          [
            if (item.label.isNotEmpty) item.label,
            _weekdaysLabel(item.repeatDays),
            item.challenge.type.label,
          ].join(' · '),
        ),
        trailing: Switch(
          value: item.enabled,
          onChanged: (v) => AlarmRepository.instance.setAlarmEnabled(item.id, v),
        ),
      ),
    );
  }
}

class _ChainTile extends StatefulWidget {
  const _ChainTile({required this.chain});
  final AlarmChain chain;

  @override
  State<_ChainTile> createState() => _ChainTileState();
}

class _ChainTileState extends State<_ChainTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = AlarmRepository.instance.itemsOfChain(widget.chain.id);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: KColors.coral.withValues(alpha: 0.15),
              foregroundColor: KColors.coral,
              child: const Icon(Icons.playlist_play),
            ),
            title: Text(
              widget.chain.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${items.length} mắt xích · ${items.map((e) => e.timeLabel).join(' → ')}',
              style: const TextStyle(fontFamily: KFonts.mono, fontSize: 12.5),
            ),
            trailing: Switch(
              value: widget.chain.enabled,
              onChanged: (v) =>
                  AlarmRepository.instance.setChainEnabled(widget.chain.id, v),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final color = kStageColor(i);
                  final isLast = i == items.length - 1;
                  return _ChainNode(
                    index: i,
                    color: color,
                    item: item,
                    isLast: isLast,
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChainEditScreen(existing: widget.chain),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa chuỗi'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One node in the K-Chain timeline: a numbered dot connected to the next by
/// a dashed "chain" line, echoing the brand guideline's chain visual.
class _ChainNode extends StatelessWidget {
  const _ChainNode({
    required this.index,
    required this.color,
    required this.item,
    required this.isLast,
  });

  final int index;
  final Color color;
  final AlarmItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!isLast)
            Positioned(
              left: 13,
              top: 28,
              child: Container(
                width: 2,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, kStageColor(index + 1)],
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: TextStyle(
                    fontFamily: KFonts.mono,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KColors.night,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.timeLabel, style: kMonoTime(fontSize: 22, color: color)),
                            if (item.label.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: KColors.mutedSlate,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_challengeIcon(item.challenge.type), size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(
                              item.challenge.type.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
