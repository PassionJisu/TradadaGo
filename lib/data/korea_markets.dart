import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../models/market.dart';
import 'gwangju_markets.dart';

/// 홈 화면 전국 지도에 찍는 전통시장 핀.
/// 내부 조감도는 [GwangjuMarkets.yangdong]만 열려 있고, 나머지는 위치 핀만 제공한다.
abstract final class KoreaMarkets {
  /// 제주까지 한 화면에 들어오도록 한반도 남쪽으로 살짝 치우친 중심.
  static const countryCenter = NLatLng(36.20, 127.70);

  /// flutter_naver_map 문서의 한반도 이동 제한 영역.
  static const countryBounds = NLatLngBounds(
    southWest: NLatLng(31.43, 122.37),
    northEast: NLatLng(44.35, 132.0),
  );

  static const initialZoom = 6.6;
  static const minZoom = 5.8;
  static const maxZoom = 16.5;

  static List<Market> get all => [
    ...GwangjuMarkets.all,
    namdaemun,
    mangwon,
    gwangjang,
    suyumarket,
    bupyeong,
    gwangmyeong,
    sangju,
    gyeongju,
    yeongcheon,
    gangneung,
    yukgeori,
    gongju,
    jeonjuNambu,
    yeosuSusan,
    jinju,
    jejuDongmun,
  ];

  static Market byId(String id) => all.firstWhere((m) => m.id == id);

  /// 서울 중구 · 남대문시장4길 21
  static final namdaemun = _pin(
    id: 'namdaemun',
    name: '남대문시장',
    subtitle: '서울 중구',
    lat: 37.55944444,
    lng: 126.97741667,
  );

  /// 서울 마포구 · 망원로8길 7
  static final mangwon = _pin(
    id: 'mangwon',
    name: '망원시장',
    subtitle: '서울 마포구',
    lat: 37.55715742,
    lng: 126.9059507,
  );

  /// 서울 종로구 · 창경궁로 88
  static final gwangjang = _pin(
    id: 'gwangjang',
    name: '광장시장',
    subtitle: '서울 종로구',
    lat: 37.570,
    lng: 126.999,
  );

  /// 서울 강북구 · 도봉로67길 18
  static final suyumarket = _pin(
    id: 'suyu',
    name: '수유시장',
    subtitle: '서울 강북구',
    lat: 37.6307392541,
    lng: 127.0232678952,
  );

  /// 인천 부평구 · 부흥로316번길 38-3
  static final bupyeong = _pin(
    id: 'bupyeong',
    name: '부평종합시장',
    subtitle: '인천 부평구',
    lat: 37.49649796,
    lng: 126.7266075,
  );

  /// 경기 광명시 · 광이로13번길 17-5
  static final gwangmyeong = _pin(
    id: 'gwangmyeong',
    name: '광명전통시장',
    subtitle: '경기 광명시',
    lat: 37.47994501,
    lng: 126.8561659,
  );

  /// 경북 상주시 · 중앙시장길 1-7 (sjsijang.co.kr)
  static final sangju = _pin(
    id: 'sangju',
    name: '상주종합시장',
    subtitle: '경북 상주시',
    lat: 36.41035,
    lng: 128.15925,
  );

  /// 경북 경주시 · 금성로 295
  static final gyeongju = _pin(
    id: 'gyeongju',
    name: '경주중앙시장',
    subtitle: '경북 경주시',
    lat: 35.8439605,
    lng: 129.2067453,
  );

  /// 경북 영천시 · 시장로 67
  static final yeongcheon = _pin(
    id: 'yeongcheon',
    name: '영천공설시장',
    subtitle: '경북 영천시',
    lat: 35.9638446,
    lng: 128.9380606,
  );

  /// 강원 강릉시 · 금성로 21
  static final gangneung = _pin(
    id: 'gangneung',
    name: '강릉중앙시장',
    subtitle: '강원 강릉시',
    lat: 37.75418,
    lng: 128.89647,
  );

  /// 충북 청주시 · 청남로2197번길 42
  static final yukgeori = _pin(
    id: 'yukgeori',
    name: '육거리종합시장',
    subtitle: '충북 청주시',
    lat: 36.62794095,
    lng: 127.4881836,
  );

  /// 충남 공주시 · 용당길 22
  static final gongju = _pin(
    id: 'gongju',
    name: '공주산성시장',
    subtitle: '충남 공주시',
    lat: 36.45881276,
    lng: 127.1226147,
  );

  /// 전북 전주시 · 풍남문1길 19-3
  static final jeonjuNambu = _pin(
    id: 'jeonju-nambu',
    name: '전주남부시장',
    subtitle: '전북 전주시',
    lat: 35.81278651,
    lng: 127.1475386,
  );

  /// 전남 여수시 · 여객선터미널길 24
  static final yeosuSusan = _pin(
    id: 'yeosu-susan',
    name: '여수수산시장',
    subtitle: '전남 여수시',
    lat: 34.73813576,
    lng: 127.7317623,
  );

  /// 경남 진주시 · 진양호로547번길 8-1
  static final jinju = _pin(
    id: 'jinju',
    name: '진주중앙시장',
    subtitle: '경남 진주시',
    lat: 35.19285,
    lng: 128.08493,
  );

  /// 제주 제주시 · 관덕로14길 20
  static final jejuDongmun = _pin(
    id: 'jeju-dongmun',
    name: '동문재래시장',
    subtitle: '제주 제주시',
    lat: 33.5115942,
    lng: 126.5260281,
  );

  static Market _pin({
    required String id,
    required String name,
    required String subtitle,
    required double lat,
    required double lng,
  }) {
    const delta = 0.0012;
    return Market(
      id: id,
      name: name,
      subtitle: subtitle,
      center: NLatLng(lat, lng),
      bounds: NLatLngBounds(
        southWest: NLatLng(lat - delta, lng - delta),
        northEast: NLatLng(lat + delta, lng + delta),
      ),
      stores: const [],
    );
  }
}
