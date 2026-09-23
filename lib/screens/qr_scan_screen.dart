import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/assets.dart';
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
  bool _handled = false;
  String? _hint;

  static const _lensSize = 236.0;

  Future<void> _verify(String payload) async {
    if (_handled) return;
    if (widget.store.requireGps) {
      final nearby = LocationSession.instance.isNear(widget.store.position);
      if (!nearby) {
        setState(() => _hint = 'GPS가 가게에서 너무 멉니다. 시연 경로로 가까이 가주세요.');
        return;
      }
    }
    if (payload.trim() != widget.store.qrPayload) {
      setState(() => _hint = '이 가게 QR이 아닙니다. ${widget.store.qrPayload}');
      return;
    }
    final ok = AppSession.instance.markQrVerified(widget.store);
    if (!ok) {
      setState(() => _hint = '이 식당을 먼저 예약한 뒤 QR을 인증할 수 있습니다.');
      return;
    }
    _handled = true;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('QR 인증 성공'),
        content: Text(
          '${widget.store.name} 예약 메뉴를 수령했습니다.\n먹은 음식은 이용내역 리뷰에 함께 기록됩니다.',
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(AppAssets.qrMarketCounter, fit: BoxFit.cover),
                const ColoredBox(color: Color(0x33000000)),
                Center(
                  child: const _MagnifierLens(
                    size: _lensSize,
                    child: _LensQrPhoto(),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  '렌즈 안은 계산대 QR을 비춘 시연 화면입니다. 에뮬레이터는 아래 시연 인증을 누르세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
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

/// 돋보기 렌즈가 계산대 QR을 확대해서 보여 준다.
class _LensQrPhoto extends StatelessWidget {
  const _LensQrPhoto();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        if (!side.isFinite || side <= 0) return const SizedBox.shrink();
        const focusX = 610 / 864;
        const focusY = 800 / 1152;
        final imageW = side * 3.5;
        final imageH = imageW * (1152 / 864);
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(side / 2 - focusX * imageW, side / 2 - focusY * imageH),
              child: Image.asset(
                AppAssets.qrMarketCounter,
                width: imageW,
                height: imageH,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        );
      },
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
                    ColoredBox(color: Colors.black, child: child),
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
