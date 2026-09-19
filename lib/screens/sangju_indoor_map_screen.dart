import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/assets.dart';
import '../data/sangju_indoor_map.dart';
import '../map/indoor_camera.dart';
import '../map/sangju_indoor_painter.dart';
import '../models/indoor_stall.dart';
import '../theme/app_colors.dart';

class SangjuIndoorMapScreen extends StatefulWidget {
  const SangjuIndoorMapScreen({super.key});

  @override
  State<SangjuIndoorMapScreen> createState() => _SangjuIndoorMapScreenState();
}

class _SangjuIndoorMapScreenState extends State<SangjuIndoorMapScreen>
    with TickerProviderStateMixin {
  SangjuIndoorMap? _data;
  IndoorCamera? _camera;
  IndoorStall? _nearby;
  Offset _stick = Offset.zero;
  late final AnimationController _pulse;
  late final Ticker _walk;

  double _startScale = 1;
  double _startRotation = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _walk = createTicker(_onWalk)..start();
    _load();
  }

  Future<void> _load() async {
    final data = await SangjuIndoorMap.load();
    if (!mounted) return;
    setState(() {
      _data = data;
      _camera = IndoorCamera(
        mapSize: data.mapSize,
        pad: data.pad,
        focus: data.startFocus,
      );
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _walk.dispose();
    super.dispose();
  }

  void _onWalk(Duration _) {
    final camera = _camera;
    if (camera == null || _stick.distance < 0.12) return;
    camera.walkInView(_stick, 9);
    _syncNearby();
    setState(() {});
  }

  void _syncNearby() {
    final camera = _camera;
    final data = _data;
    if (camera == null || data == null) return;
    _nearby = camera.hit(camera.focus, data.stalls);
  }

  void _onScaleStart(ScaleStartDetails details) {
    final camera = _camera;
    if (camera == null) return;
    _startScale = camera.scale;
    _startRotation = camera.rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size viewport) {
    final camera = _camera;
    if (camera == null || details.pointerCount < 2) return;
    camera.scale = _startScale * details.scale;
    camera.rotation = _startRotation + details.rotation;
    camera.clampScale(viewport);
    _syncNearby();
    setState(() {});
  }

  void _onTap(TapUpDetails details, Size viewport) {
    final camera = _camera;
    final data = _data;
    if (camera == null || data == null) return;
    final world = camera.screenToWorld(details.localPosition, viewport);
    final stall = camera.hit(world, data.stalls);
    if (stall != null) _showStall(stall);
  }

  void _showStall(IndoorStall stall) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stall.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text('${stall.floor}층 · 상주종합시장 공식 점포안내도'),
              const SizedBox(height: 10),
              const Text(
                '점포 위치는 공식 배치도의 영역 좌표를 그대로 옮겼습니다.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final camera = _camera;
    return Scaffold(
      body: data == null || camera == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : LayoutBuilder(
              builder: (context, constraints) {
                final viewport = Size(constraints.maxWidth, constraints.maxHeight);
                camera.clampScale(viewport);
                camera.clampFocus();
                final origin = camera.characterScreen(viewport);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF9ED6FF),
                            Color(0xFFBFE9FF),
                            Color(0xFF8FCB5A),
                          ],
                          stops: [0, 0.34, 0.34],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: (d) => _onScaleUpdate(d, viewport),
                        onTapUp: (d) => _onTap(d, viewport),
                        child: Transform(
                          alignment: Alignment(
                            0,
                            (origin.dy / viewport.height) * 2 - 1,
                          ),
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.00085)
                            ..rotateX(-0.28),
                          child: CustomPaint(
                            size: viewport,
                            painter: SangjuIndoorPainter(
                              stalls: data.stalls,
                              mapSize: data.mapSize,
                              pad: data.pad,
                              scale: camera.scale,
                              matrix: camera.mapMatrix(viewport),
                              highlightId: _nearby?.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _avatar(origin, camera),
                    SafeArea(child: _hud(data, camera, viewport)),
                    Positioned(
                      left: 16,
                      bottom: 28,
                      child: _Joystick(
                        value: _stick,
                        onChanged: (v) => setState(() => _stick = v),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _avatar(Offset origin, IndoorCamera camera) {
    final size = camera.avatarScreenSize();
    final shadow = camera.avatarShadowScreenSize();
    final bounce = 3 * camera.scale / IndoorCamera.referenceScale;
    return Positioned(
      left: origin.dx - size.width / 2,
      top: origin.dy - size.height + shadow.height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -bounce * _pulse.value),
              child: child,
            );
          },
          child: Column(
            children: [
              Image.asset(
                AppAssets.playAvatar,
                key: const Key('indoor-avatar'),
                width: size.width,
                height: size.height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              Container(
                width: shadow.width,
                height: shadow.height,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hud(SangjuIndoorMap data, IndoorCamera camera, Size viewport) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Material(
            color: const Color(0xE6FFF8E8),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.navy,
                  ),
                  Image.asset(AppAssets.logo, width: 44, height: 44),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '상주종합시장',
                          style: GoogleFonts.jua(
                            fontSize: 20,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          '내부 지도 · 점포 ${data.stalls.length}곳 · 캐릭터 고정',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_nearby != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showStall(_nearby!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      '${_nearby!.name} · 탭해서 보기',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              children: [
                _RoundCtrl(
                  icon: Icons.add,
                  onTap: () {
                    camera.scale = math.min(
                      IndoorCamera.maxScale,
                      camera.scale * 1.18,
                    );
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _RoundCtrl(
                  icon: Icons.remove,
                  onTap: () {
                    camera.scale = math.max(
                      camera.minScale(viewport),
                      camera.scale / 1.18,
                    );
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _RoundCtrl(
                  icon: Icons.explore_outlined,
                  onTap: () {
                    camera.rotation = 0;
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundCtrl extends StatelessWidget {
  const _RoundCtrl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.navy),
      ),
    );
  }
}

class _Joystick extends StatelessWidget {
  const _Joystick({required this.value, required this.onChanged});

  final Offset value;
  final ValueChanged<Offset> onChanged;

  static const size = 118.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanStart: (d) => _update(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => onChanged(Offset.zero),
        onPanCancel: () => onChanged(Offset.zero),
        child: CustomPaint(painter: _JoystickPainter(value)),
      ),
    );
  }

  void _update(Offset local) {
    final center = const Offset(size / 2, size / 2);
    final delta = local - center;
    final max = size / 2 - 18;
    final clamped = delta.distance <= max ? delta : delta / delta.distance * max;
    onChanged(clamped / max);
  }
}

class _JoystickPainter extends CustomPainter {
  const _JoystickPainter(this.value);

  final Offset value;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, size.width / 2, Paint()..color = const Color(0xCCFFFFFF));
    canvas.drawCircle(
      c,
      size.width / 2,
      Paint()
        ..color = const Color(0x330B3A6A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c + value * (size.width / 2 - 18),
      22,
      Paint()..color = AppColors.navy,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.value != value;
}
