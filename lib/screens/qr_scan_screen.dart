import 'dart:math' as math;

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

  static const _lensSize = 236.0;

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
    AppSession.instance.markQrVerified(widget.store.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('QR 인증 성공'),
        content: Text(
          '${widget.store.name} 앞에서 인증되었습니다.\n리뷰는 예약내역에서 작성할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141820),
      appBar: AppBar(
        title: Text('${widget.store.name} QR'),
        backgroundColor: const Color(0xFF141820),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF2A3344), Color(0xFF101318)],
                ),
              ),
              child: Center(
                child: _MagnifierLens(
                  size: _lensSize,
                  child: MobileScanner(
                    controller: _controller,
                    fit: BoxFit.cover,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => const ColoredBox(
                      color: Color(0xFF1A1A1A),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '렌즈 안에 카메라가 열립니다',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                const Text(
                  '돋보기 렌즈 안으로 QR을 맞추세요. GPS 근접 + QR 이중 인증.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Text(
                  '시연 QR  ${widget.store.qrPayload}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
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

class _MagnifierLens extends StatelessWidget {
  const _MagnifierLens({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = size + 36;
    return SizedBox(
      width: frame + 70,
      height: frame + 70,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 8,
            bottom: 10,
            child: Transform.rotate(
              angle: math.pi / 4.4,
              child: Container(
                width: 30,
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFE48A),
                      AppColors.goldDeep,
                      Color(0xFFB8860B),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(4, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: frame,
            height: frame,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF6C8),
                  AppColors.gold,
                  AppColors.goldDeep,
                  Color(0xFFB8860B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipOval(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: Colors.black,
                      child: OverflowBox(
                        maxWidth: size * 1.5,
                        maxHeight: size * 1.5,
                        child: SizedBox(
                          width: size * 1.5,
                          height: size * 1.5,
                          child: child,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.32),
                            ],
                            stops: const [0.12, 0.58, 1],
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Align(
                        alignment: const Alignment(-0.42, -0.52),
                        child: Container(
                          width: 96,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
