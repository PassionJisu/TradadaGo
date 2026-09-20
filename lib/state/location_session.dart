import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import '../data/gwangju_markets.dart';

class LocationSession extends ChangeNotifier {
  LocationSession._();
  static final LocationSession instance = LocationSession._();

  NLatLng? current;
  bool demoWalking = false;
  bool demoPaused = false;
  bool usingGps = false;
  String? status;

  StreamSubscription<Position>? _gpsSub;
  Timer? _demoTimer;
  int _pathIndex = 0;
  int _segmentStep = 0;
  List<NLatLng> _path = const [];

  static const _stepsPerSegment = 12;

  Future<void> startGps() async {
    status = '위치 권한을 확인하는 중…';
    notifyListeners();

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      current ??= GwangjuMarkets.cityCenter;
      status = '시장 핀을 눌러 들어가세요.';
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      current ??= GwangjuMarkets.cityCenter;
      status = '시장 핀을 눌러 들어가세요.';
      notifyListeners();
      return;
    }

    usingGps = true;
    status = 'GPS 수신 중';
    notifyListeners();

    _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      if (demoWalking) return;
      final next = NLatLng(pos.latitude, pos.longitude);
      if (!_looksLikeKorea(next)) {
        current ??= GwangjuMarkets.cityCenter;
        status = '시연 위치 표시 중';
        notifyListeners();
        return;
      }
      current = next;
      status = 'GPS 추적 중';
      notifyListeners();
    });
  }

  void startYangdongDemoWalk() {
    stopDemoWalk();
    demoWalking = true;
    demoPaused = false;
    usingGps = false;
    _path = GwangjuMarkets.yangdongDemoPath;
    _pathIndex = 0;
    _segmentStep = 0;
    current = _path.first;
    status = '양동시장 시연 경로 이동 중';
    notifyListeners();

    _demoTimer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      if (!demoWalking || demoPaused || _path.isEmpty) return;
      if (_pathIndex >= _path.length - 1) {
        demoWalking = false;
        demoPaused = false;
        _demoTimer?.cancel();
        status = '시연 경로 도착';
        notifyListeners();
        return;
      }

      final from = _path[_pathIndex];
      final to = _path[_pathIndex + 1];
      _segmentStep += 1;
      final t = _segmentStep / _stepsPerSegment;
      current = NLatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
      if (_segmentStep >= _stepsPerSegment) {
        _pathIndex += 1;
        _segmentStep = 0;
        current = to;
      }
      notifyListeners();
    });
  }

  void pauseDemoWalk() {
    if (!demoWalking || demoPaused) return;
    demoPaused = true;
    status = '시연 경로 일시정지';
    notifyListeners();
  }

  void resumeDemoWalk() {
    if (!demoWalking || !demoPaused) return;
    demoPaused = false;
    status = '양동시장 시연 경로 이동 중';
    notifyListeners();
  }

  void stopDemoWalk() {
    _demoTimer?.cancel();
    _demoTimer = null;
    demoPaused = false;
    if (!demoWalking) return;
    demoWalking = false;
    notifyListeners();
  }

  bool isInside(NLatLngBounds bounds) {
    final p = current;
    if (p == null) return false;
    return p.latitude >= bounds.southLatitude &&
        p.latitude <= bounds.northLatitude &&
        p.longitude >= bounds.westLongitude &&
        p.longitude <= bounds.eastLongitude;
  }

  void enterMarketPlay({
    required String marketName,
    required NLatLngBounds bounds,
    required NLatLng entrance,
  }) {
    if (isInside(bounds)) {
      status = '$marketName 탐험 중';
      notifyListeners();
      return;
    }
    jumpTo(entrance, message: '$marketName 조감도에 입장했습니다');
  }

  void leaveMarketPlay() {
    stopDemoWalk();
    status = '전통시장 핀을 선택하세요';
    notifyListeners();
  }

  void jumpTo(NLatLng point, {String? message}) {
    current = point;
    status = message ?? status;
    notifyListeners();
  }

  double? metersTo(NLatLng target) {
    final here = current;
    if (here == null) return null;
    return Geolocator.distanceBetween(
      here.latitude,
      here.longitude,
      target.latitude,
      target.longitude,
    );
  }

  bool isNear(NLatLng target, {double meters = 28}) {
    final d = metersTo(target);
    return d != null && d <= meters;
  }

  static bool _looksLikeKorea(NLatLng p) {
    return p.latitude > 33 &&
        p.latitude < 39 &&
        p.longitude > 124 &&
        p.longitude < 132;
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }
}
