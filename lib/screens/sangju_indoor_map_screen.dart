import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/assets.dart';
import '../data/sangju_indoor_map.dart';
import '../map/indoor_camera.dart';
import '../map/market_blueprint.dart';
import '../map/sangju_indoor_painter.dart';
import '../map/store_pin_images.dart';
import '../models/indoor_stall.dart';
import 'qr_scan_screen.dart';
import 'store_detail_screen.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../widgets/market_map_controls.dart';

class SangjuIndoorMapScreen extends StatefulWidget {
  const SangjuIndoorMapScreen({
    super.key,
    this.title = '시장 데모',
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  SangjuIndoorMapScreenState createState() => SangjuIndoorMapScreenState();
}

class SangjuIndoorMapScreenState extends State<SangjuIndoorMapScreen>
    with TickerProviderStateMixin {
  SangjuIndoorMap? _data;
  IndoorCamera? _camera;
  IndoorStall? _nearby;
  Offset _stick = Offset.zero;
  int _floor = 1;
  StallUse? _filterUse;
  late final AnimationController _pulse;
  late final Ticker _walk;
  Timer? _locateTimer;
  IndoorStall? _locateStall;
  Offset? _homeFocus;
  double? _homeScale;
  double? _homeRotation;

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
    await StorePinImages.ensureLoaded();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locateTimer?.cancel();
    _pulse.dispose();
    _walk.dispose();
    super.dispose();
  }

  void _onWalk(Duration _) {
    final camera = _camera;
    if (camera == null || _stick.distance < 0.12 || _locateStall != null) {
      return;
    }
    camera.walkInView(_stick, 9);
    _syncNearby();
    setState(() {});
  }

  void _syncNearby() {
    final camera = _camera;
    final data = _data;
    if (camera == null || data == null) return;
    final hit = camera.hit(camera.focus, data.stallsOnFloor(_floor));
    if (hit != null && _filterUse != null && hit.use != _filterUse) {
      _nearby = null;
      return;
    }
    _nearby = hit;
  }

  void _onScaleStart(ScaleStartDetails details) {
    final camera = _camera;
    if (camera == null) return;
    _startScale = camera.scale;
    _startRotation = camera.rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size viewport) {
    final camera = _camera;
    if (camera == null || details.pointerCount < 2 || _locateStall != null) {
      return;
    }
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
    final stall = camera.hit(world, data.stallsOnFloor(_floor));
    if (stall == null) return;
    if (_filterUse != null && stall.use != _filterUse) return;
    _showStall(stall);
  }

  void openNearbyStamp() {
    final stall = _nearby;
    if (stall == null) {
      showAppNotice(context, '가게 칸이 켜질 때까지 걸어주세요.');
      return;
    }
    _openQr(stall);
  }

  void _openQr(IndoorStall stall) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(store: stall.asStore()),
      ),
    );
  }

  void _showStall(IndoorStall stall) {
    final verified = AppSession.instance.hasQrVerified(stall.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return IndoorStallSheet(
          stall: stall,
          verified: verified,
          onScanQr: () {
            Navigator.pop(ctx);
            _openQr(stall);
          },
          onOpenStore: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoreDetailScreen(store: stall.asStore()),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final camera = _camera;
    final bottomClearance = MediaQuery.paddingOf(context).bottom + 72;
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        return Scaffold(
      backgroundColor: Colors.transparent,
      body: data == null || camera == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : LayoutBuilder(
              builder: (context, constraints) {
                final viewport = Size(constraints.maxWidth, constraints.maxHeight);
                if (_locateStall == null) {
                  camera.clampScale(viewport);
                  camera.clampFocus();
                }
                final origin = _locateStall != null && _homeFocus != null
                    ? camera.worldToScreen(_homeFocus!, viewport)
                    : camera.characterScreen(viewport);
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
                              highlightId: _locateStall?.id ?? _nearby?.id,
                              floorFilter: _floor,
                              useFilter: _filterUse,
                              visitedIds: Set<String>.of(
                                AppSession.instance.paintedStoreIds,
                              ),
                              pinIdle: StorePinImages.idle,
                              pinActive: StorePinImages.active,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _avatar(origin, camera),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomClearance),
                        child: _hud(data, camera, viewport),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: bottomClearance,
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
      },
    );
  }

  void _openIndex(SangjuIndoorMap data, IndoorCamera camera, Size viewport) {
    final listed = data.uniqueNamed(
      data.stallsOnFloor(_floor, use: _filterUse),
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                Text(
                  '점포 목록',
                  style: GoogleFonts.jua(fontSize: 22, color: AppColors.navy),
                ),
                const SizedBox(height: 2),
                const Text(
                  '이름을 누르면 지도에서 위치를 잠시 보여줍니다.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                for (final stall in listed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: stall.use.color.withValues(alpha: 0.18),
                      child: Text(stall.use.emoji),
                    ),
                    title: Text(
                      stall.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('${stall.floor}층 · ${stall.use.labelKo}'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _peekStall(stall, camera, viewport);
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _peekStall(IndoorStall stall, IndoorCamera camera, Size viewport) {
    _locateTimer?.cancel();
    _homeFocus ??= camera.focus;
    _homeScale ??= camera.scale;
    _homeRotation ??= camera.rotation;

    final origin = _homeFocus!;
    final target = stall.bounds.center;
    final span = (target - origin).distance;
    final fit = math.min(
      viewport.width / camera.mapSize.width,
      viewport.height / camera.mapSize.height,
    );
    final desired =
        math.min(viewport.width, viewport.height) / (span * 1.7 + 240);
    camera.focus = Offset.lerp(origin, target, 0.5)!;
    camera.scale = desired.clamp(fit, _homeScale!);
    camera.rotation = 0;
    _locateStall = stall;
    setState(() {});

    _locateTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final cam = _camera;
      if (cam != null) {
        cam.focus = _homeFocus ?? cam.focus;
        cam.scale = _homeScale ?? cam.scale;
        cam.rotation = _homeRotation ?? cam.rotation;
      }
      _homeFocus = null;
      _homeScale = null;
      _homeRotation = null;
      _locateStall = null;
      _syncNearby();
      setState(() {});
    });
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
                    onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.navy,
                  ),
                  Image.asset(AppAssets.emblem, width: 44, height: 44),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: MarketMapToolbar(
              categoryLabel: _filterUse == null
                  ? '카테고리 선택'
                  : '${_filterUse!.emoji} ${_filterUse!.labelKo}',
              floorLabel: '$_floor층 선택',
              categoryActive: _filterUse != null,
              onCategory: () => showCategoryPicker(
                context: context,
                uses: data.usesOnFloor(_floor),
                selected: _filterUse,
                onSelected: (use) => setState(() => _filterUse = use),
              ),
              onFloor: () => showFloorPicker(
                context: context,
                floors: data.floors,
                selectedId: '$_floor',
                onSelected: (id) => setState(() {
                  _floor = int.parse(id);
                  _filterUse = null;
                  _syncNearby();
                }),
              ),
              onStores: () => _openIndex(data, camera, viewport),
            ),
          ),
          if (_locateStall != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    '${_locateStall!.name} · 여기',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
            )
          else if (_nearby != null)
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

class IndoorStallSheet extends StatelessWidget {
  const IndoorStallSheet({
    super.key,
    required this.stall,
    required this.verified,
    required this.onScanQr,
    this.onOpenStore,
  });

  final IndoorStall stall;
  final bool verified;
  final VoidCallback onScanQr;
  final VoidCallback? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final store = stall.asStore();
    final product = store.products.isEmpty ? null : store.products.first;
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
          Text('${stall.floor}층 · ${stall.use.labelKo}'),
          if (product != null) ...[
            const SizedBox(height: 10),
            Text(
              '마감할인  ${product.name}  ·  ${_won(product.discountPrice)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.pinRed,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            verified
                ? '이미 QR 인증한 점포입니다. 다시 찍으면 이용내역에 방문이 추가되고, 방문당 리뷰는 1회입니다.'
                : '지도 핀이 없는 내부 점포도 QR 인증과 마감할인 예약이 됩니다.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          if (onOpenStore != null && store.products.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpenStore,
                child: const Text('가게·상품 자세히 보기'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScanQr,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(verified ? 'QR 다시 인증하기' : 'QR 인증하기'),
            ),
          ),
        ],
      ),
    );
  }

  static String _won(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final left = s.length - i;
      buf.write(s[i]);
      if (left > 1 && left % 3 == 1) buf.write(',');
    }
    return '$buf' '원';
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
