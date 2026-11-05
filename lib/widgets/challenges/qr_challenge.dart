import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/permission_service.dart';
import '../../theme/brand.dart';

/// Requires scanning a QR code. If [expectedContent] is non-empty, the
/// scanned code must match it exactly; otherwise any decodable QR code is
/// accepted.
class QrChallengeWidget extends StatefulWidget {
  const QrChallengeWidget({
    super.key,
    required this.expectedContent,
    required this.onSolved,
  });

  final String expectedContent;
  final VoidCallback onSolved;

  @override
  State<QrChallengeWidget> createState() => _QrChallengeWidgetState();
}

class _QrChallengeWidgetState extends State<QrChallengeWidget> {
  MobileScannerController? _controller;
  bool _checkingPermission = true;
  bool _hasPermission = false;
  bool _handled = false;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final granted = await PermissionService.requestCamera();
    if (!mounted) return;
    setState(() {
      _hasPermission = granted;
      _checkingPermission = false;
      if (granted) {
        _controller = MobileScannerController();
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;
      _lastScanned = value;
      final matches = widget.expectedContent.isEmpty ||
          value.trim() == widget.expectedContent.trim();
      if (matches) {
        _handled = true;
        widget.onSolved();
        return;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (!_hasPermission) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Cần quyền camera để quét mã QR.\nHãy cấp quyền trong Cài đặt.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _setup,
            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MISSION: QR ANCHOR',
          style: TextStyle(
            color: KColors.coral,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.expectedContent.isEmpty
              ? 'Quét bất kỳ mã QR nào để tắt báo thức'
              : 'Rời khỏi giường — quét đúng mã QR đã đặt trước',
          textAlign: TextAlign.center,
          style: const TextStyle(color: KColors.mutedSlate, fontSize: 15),
        ),
        const SizedBox(height: 16),
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KColors.coral, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
        ),
        if (_lastScanned != null) ...[
          const SizedBox(height: 12),
          const Text(
            'Mã không khớp, thử mã đúng nhé',
            style: TextStyle(color: KColors.coral),
          ),
        ],
      ],
    );
  }
}
