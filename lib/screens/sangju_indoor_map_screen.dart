import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/assets.dart';
import '../data/sangju_indoor_map.dart';
import '../map/alley_route.dart';
import '../map/indoor_camera.dart';
import '../map/market_blueprint.dart';
import '../map/sangju_indoor_painter.dart';
import '../map/store_pin_images.dart';
import '../models/indoor_stall.dart';
import 'qr_scan_screen.dart';
import 'store_detail_screen.dart';
import '../state/app_session.dart';
import '../state/indoor_qr_cue.dart';
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
  IndoorPathWalker? _walker;
  int _floor = 1;
  StallUse? _filterUse;
  late final AnimationController _pulse;
  late final Ticker _walk;
  final _backdrop = IndoorMapBackdrop();
  IndoorStall? _routeStall;
  bool _browsing = false;
  Duration? _lastWalkFrame;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _askAvatarOnce());
  }

  Future<void> _askAvatarOnce() async {
    if (!mounted || AppSession.instance.demoAvatarGender != null) return;
    final choice = await showDialog<DemoAvatarGender>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AvatarChoiceDialog(),
    );
    if (!mounted || choice == null) return;
    AppSession.instance.chooseDemoAvatar(choice);
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
      _walker = IndoorPathWalker(data.demoWalkPath);
    });
    _syncNearby();
    await StorePinImages.ensureLoaded();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    IndoorQrCue.instance.clear();
    _backdrop.dispose();
    _pulse.dispose();
    _walk.dispose();
    super.dispose();
  }

  void _onWalk(Duration elapsed) {
    final camera = _camera;
    final walker = _walker;
    if (camera == null || walker == null || !walker.walking) return;
    final last = _lastWalkFrame;
    if (last != null && elapsed - last < const Duration(milliseconds: 33)) {
      return;
    }
    _lastWalkFrame = elapsed;
    final next = walker.tick();
    if (next != null) {
      camera.focus = next;
      camera.clampFocus();
    }
    _syncNearby();
    setState(() {});
  }

  void _startDemoWalk() {
    final data = _data;
    final camera = _camera;
    final walker = _walker;
    if (data == null || camera == null || walker == null) return;
    _browsing = false;
    camera.follow();
    walker.start();
    camera.focus = walker.position;
    camera.clampFocus();
    _resumeAvatarPulse();
    setState(() {
      _floor = 1;
      _filterUse = null;
      _syncNearby();
    });
  }

  void _pauseDemoWalk() {
    _walker?.pause();
    _pauseAvatarPulse();
    if (mounted) setState(() {});
  }

  void _resumeDemoWalk() {
    _walker?.resume();
    _resumeAvatarPulse();
    if (mounted) setState(() {});
  }

  void _stopDemoWalk() {
    _walker?.stop();
    _resumeAvatarPulse();
    if (mounted) setState(() {});
  }

  void _pauseAvatarPulse() {
    if (_pulse.isAnimating) _pulse.stop();
  }

  void _resumeAvatarPulse() {
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
  }

  Widget _demoWalkBar() {
    final inSession = _walker?.running == true;
    final paused = _walker?.paused == true;
    return Row(
      children: [
        if (inSession) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _stopDemoWalk,
              icon: const Icon(Icons.stop_rounded),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('시연 경로 정지'),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: !inSession
                ? _startDemoWalk
                : paused
                    ? _resumeDemoWalk
                    : _pauseDemoWalk,
            icon: Icon(
              !inSession
                  ? Icons.directions_walk_rounded
                  : paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                !inSession
                    ? '골목 시연 걷기'
                    : paused
                        ? '이어서 걷기'
                        : '일시정지',
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _syncNearby() {
    final camera = _camera;
    final data = _data;
    if (camera == null || data == null) return;
    final menus = [
      for (final stall in data.stallsOnFloor(_floor))
        if (stall.hasMenu && (_filterUse == null || stall.use == _filterUse))
          stall,
    ];
    _nearby = camera.nearest(camera.focus, menus);
    IndoorQrCue.instance.setReady(
      ready: _nearby != null,
      storeName: _nearby?.name,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    final camera = _camera;
    if (camera == null) return;
    _startScale = camera.scale;
    _startRotation = camera.rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size viewport) {
    final camera = _camera;
    if (camera == null) return;
    if (details.pointerCount >= 2) {
      camera.scale = _startScale * details.scale;
      camera.rotation = _startRotation + details.rotation;
      camera.clampScale(viewport);
    } else if (details.pointerCount == 1) {
      _browsing = true;
      camera.panByScreen(details.focalPointDelta);
    }
    _syncNearby();
    setState(() {});
  }

  void _onTap(TapUpDetails details, Size viewport) {
    final camera = _camera;
    final data = _data;
    if (camera == null || data == null) return;
    final world = camera.screenToWorld(details.localPosition, viewport);
    final stall = camera.hit(world, data.stallsOnFloor(_floor));
    if (stall == null || !stall.hasMenu) return;
    if (_filterUse != null && stall.use != _filterUse) return;
    _showStall(stall);
  }

  void openNearbyStamp() {
    final stall = _nearby;
    if (stall == null || !stall.hasMenu) {
      showAppNotice(context, '핀이 켜진 식당 앞으로 이동한 뒤 다시 눌러주세요.');
      return;
    }
    _openQr(stall);
  }

  void _openQr(IndoorStall stall) {
    if (!stall.hasMenu || _nearby?.id != stall.id) {
      showAppNotice(context, '가게 앞에서만 QR 인증이 됩니다.');
      return;
    }
    if (AppSession.instance.activeReservation(stall.id) == null) {
      showAppNotice(context, '이 식당을 먼저 예약한 뒤 QR을 인증할 수 있습니다.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(store: stall.asStore(qrUnlocked: true)),
      ),
    );
  }

  void _showStall(IndoorStall stall) {
    final verified = AppSession.instance.hasQrVerified(stall.id);
    final qrEnabled = stall.hasMenu && _nearby?.id == stall.id;
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
          qrEnabled: qrEnabled,
          onScanQr: qrEnabled
              ? () {
                  Navigator.pop(ctx);
                  _openQr(stall);
                }
              : null,
          onFind: stall.hasMenu
              ? () {
                  Navigator.pop(ctx);
                  _startFind(stall);
                }
              : null,
          onOpenStore: stall.hasMenu
              ? () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoreDetailScreen(
                        store: stall.asStore(qrUnlocked: qrEnabled),
                      ),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }

  void _startFind(IndoorStall stall) {
    final camera = _camera;
    if (camera == null || !stall.hasMenu) return;
    final mid = Offset.lerp(camera.focus, stall.bounds.center, 0.45)!;
    setState(() {
      _routeStall = stall;
      _browsing = true;
      camera.lookAt(mid);
    });
  }

  void _cancelFind() {
    setState(() {
      _routeStall = null;
      _browsing = false;
      _camera?.follow();
    });
  }

  Future<void> _selectFloor(String id) async {
    final next = int.parse(id);
    if (next != _floor) {
      final goingUp = next > _floor;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$next층으로 이동하시겠습니까?'),
          content: Text(
            goingUp
                ? '2층은 둘러보기용입니다. 대부분 가게 정보는 이 데모에서 아직 열리지 않았습니다.'
                : '1층 시장 지도로 돌아갑니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('이동'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    _walker?.stop();
    _resumeAvatarPulse();
    setState(() {
      _floor = next;
      _filterUse = null;
      _routeStall = null;
      _syncNearby();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final camera = _camera;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    const navClearance = 72.0;
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
                camera.clampScale(viewport);
                camera.clampFocus();
                final origin = camera.worldToScreen(camera.focus, viewport);
                final paintedIds = AppSession.instance.paintedStoreIds;
                final restaurants = data.restaurants;
                final painted = restaurants
                    .where((stall) => paintedIds.contains(stall.id))
                    .length;
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
                              routeId: _routeStall?.id,
                              activePinId: _nearby?.id,
                              guide: _routeStall == null
                                  ? const []
                                  : alleyRoute(
                                      path: data.demoWalkPath,
                                      from: camera.focus,
                                      to: _routeStall!.bounds.center,
                                    ),
                              backdrop: _backdrop,
                              floorFilter: _floor,
                              useFilter: _filterUse,
                              visitedIds: Set<String>.of(paintedIds),
                              pinIdle: StorePinImages.idle,
                              pinActive: StorePinImages.active,
                              rotation: camera.rotation,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _avatar(origin, camera),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SafeArea(
                        bottom: false,
                        child: _hud(data),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: safeBottom + navClearance + 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_browsing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FilledButton.tonalIcon(
                                onPressed: () {
                                  setState(() {
                                    _browsing = false;
                                    _camera?.follow();
                                  });
                                },
                                icon: const Icon(Icons.my_location_rounded, size: 18),
                                label: const Text('내 캐릭터'),
                              ),
                            ),
                          _demoWalkBar(),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: safeBottom + 64,
                      child: PaintProgressBanner(
                        painted: painted,
                        total: restaurants.length,
                        compact: true,
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

  void _openIndex(SangjuIndoorMap data) {
    final listed = data.uniqueNamed([
      for (final stall in data.stallsOnFloor(_floor, use: _filterUse))
        if (stall.hasMenu) stall,
    ]);
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
                  '수산·청과·다과·먹거리처럼 정보가 있는 식품 가게는, 안내에서 위치 찾기를 누르면 복도를 따라 선이 이어집니다.',
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
                    subtitle: Text(
                      stall.hasMenu
                          ? '${stall.floor}층 · ${stall.use.labelKo}'
                          : '${stall.floor}층 · 정보 준비 중',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showStall(stall);
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _avatar(Offset origin, IndoorCamera camera) {
    final size = camera.avatarScreenSize();
    final shadow = camera.avatarShadowScreenSize();
    final bounce = 3 * camera.scale / IndoorCamera.referenceScale;
    const rim = 3.2;
    return Positioned(
      left: origin.dx - (size.width + rim) / 2,
      top: origin.dy - size.height - rim / 2 + shadow.height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -bounce * _pulse.value),
              child: Column(
                children: [
                  child!,
                  Container(
                    width: size.width * 0.7,
                    height: shadow.height * 1.7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6D0).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.7),
                          blurRadius: 7,
                          spreadRadius: 0.4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          child: _outlinedAvatar(
            AppSession.instance.playAvatarAsset,
            size,
          ),
        ),
      ),
    );
  }

  Widget _outlinedAvatar(String asset, Size size) {
    Widget silhouette(Offset offset) {
      return Transform.translate(
        offset: offset,
        child: Image.asset(
          asset,
          width: size.width,
          height: size.height,
          fit: BoxFit.contain,
          color: const Color(0xFFFFF8E1),
          colorBlendMode: BlendMode.srcIn,
        ),
      );
    }

    return SizedBox(
      width: size.width + 4,
      height: size.height + 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final offset in const [
            Offset(-1.7, 0),
            Offset(1.7, 0),
            Offset(0, -1.7),
            Offset(0, 1.7),
            Offset(-1.2, -1.2),
            Offset(1.2, -1.2),
            Offset(-1.2, 1.2),
            Offset(1.2, 1.2),
          ])
            silhouette(offset),
          Image.asset(
            asset,
            key: const Key('indoor-avatar'),
            width: size.width,
            height: size.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }

  Widget _hud(SangjuIndoorMap data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                          _walker?.paused == true
                              ? '내부 지도 · 골목 시연 일시정지'
                              : _walker?.running == true
                                  ? '내부 지도 · 골목 시연 경로 이동 중'
                                  : '내부 지도 · 식품 ${data.restaurants.length}곳 · 캐릭터 고정',
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
                onSelected: (use) => setState(() {
                  _filterUse = use;
                  _syncNearby();
                }),
              ),
              onFloor: () => showFloorPicker(
                context: context,
                floors: data.floors,
                selectedId: '$_floor',
                onSelected: _selectFloor,
              ),
              onStores: () => _openIndex(data),
            ),
          ),
          if (_routeStall != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_routeStall!.name} 찾는 중',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _cancelFind,
                        child: const Text('식당 찾기 취소'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_nearby != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showStall(_nearby!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      '${_nearby!.name} QR 인증이 활성화되었습니다. 가운데 버튼을 눌러 인증을 시도하세요!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
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
    this.qrEnabled = false,
    this.onScanQr,
    this.onOpenStore,
    this.onFind,
  });

  final IndoorStall stall;
  final bool verified;
  final bool qrEnabled;
  final VoidCallback? onScanQr;
  final VoidCallback? onOpenStore;
  final VoidCallback? onFind;

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
          if (!stall.hasMenu) ...[
            const SizedBox(height: 12),
            const Text(
              '아직 가게 정보가 구현되지 않았습니다.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '데모 버전에서는 사진이 맞는 일부 음식 가게만 열려 있습니다.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ] else ...[
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
                  ? '이전에 수령한 식당입니다. 다시 먹으려면 메뉴를 새로 예약하세요.'
                  : qrEnabled
                      ? '식당 앞입니다. 메뉴를 예약한 뒤에만 QR 인증과 리뷰가 됩니다.'
                      : '가게 앞에서만 QR 인증이 됩니다. 예약은 미리 할 수 있습니다.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            if (onFind != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onFind,
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('이 시장 위치 찾기'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (onOpenStore != null) ...[
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
                onPressed: qrEnabled ? onScanQr : null,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(
                  qrEnabled
                      ? (verified ? 'QR 다시 인증하기' : 'QR 인증하기')
                      : '가게 앞에서만 QR 인증이 됩니다',
                ),
              ),
            ),
          ],
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

class _AvatarChoiceDialog extends StatelessWidget {
  const _AvatarChoiceDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '남성인가요, 여성인가요?',
              textAlign: TextAlign.center,
              style: GoogleFonts.jua(fontSize: 24, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            const Text(
              '시장 데모에 처음 들어올 때 한 번 고릅니다.\n가입할 때는 성별에 맞춰 아바타가 정해집니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.deepBlue),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AvatarChoice(
                    asset: AppAssets.playAvatar,
                    label: '남성',
                    onTap: () => Navigator.pop(context, DemoAvatarGender.male),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AvatarChoice(
                    asset: AppAssets.playAvatarFemale,
                    label: '여성',
                    onTap: () => Navigator.pop(context, DemoAvatarGender.female),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          child: Column(
            children: [
              Image.asset(asset, height: 120, fit: BoxFit.contain),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

