import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/store.dart';
import '../state/app_session.dart';
import '../state/location_session.dart';
import '../theme/app_colors.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, required this.store});

  final Store store;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(autoStart: false);
  bool _handled = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _prepareCamera();
  }

  Future<void> _prepareCamera() async {
    try {
      await _controller.start();
    } catch (e) {
      if (!mounted) return;
      setState(() => _hint = '카메라를 열 수 없습니다. 에뮬레이터는 아래 시연 인증을 사용하세요.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    String? value;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        value = raw;
        break;
      }
    }
    if (value != null) _verify(value);
  }

  Future<void> _verify(String payload) async {
    if (_handled) return;
    final nearby = LocationSession.instance.isNear(widget.store.position);
    if (!nearby) {
      setState(() => _hint = 'GPS가 가게에서 너무 멉니다. 시연 경로로 가까이 가주세요.');
      return;
    }
    if (payload.trim() != widget.store.qrPayload) {
      setState(() => _hint = '이 가게 QR이 아닙니다. ${widget.store.qrPayload}');
      return;
    }
    _handled = true;
    final added = AppSession.instance.addStamp(widget.store.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(added ? '스탬프 획득!' : '이미 받은 스탬프'),
        content: Text(
          added
              ? '${widget.store.name} 스탬프가 체크판에 찍혔습니다.'
              : '이 가게는 이미 스탬프를 받았습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.store.name} QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => const Center(
                    child: Text(
                      '카메라를 열 수 없습니다.\n에뮬레이터는 시연 인증을 사용하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gold, width: 4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              children: [
                if (_hint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _hint!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.pinRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  '가게 카운터 QR 또는 ${widget.store.qrPayload}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _verify(widget.store.qrPayload),
                  child: const Text('에뮬레이터 시연 인증'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
