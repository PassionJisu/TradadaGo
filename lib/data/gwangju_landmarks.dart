import '../config/assets.dart';
import '../models/landmark.dart';

abstract final class GwangjuLandmarks {
  static const all = [
    Landmark(
      id: 'mudeung',
      name: '무등산',
      photoAsset: AppAssets.landmarkMudeung,
      blurb: '광주 사람들의 산. 계절마다 다른 능선이 스탬프에 담깁니다.',
    ),
    Landmark(
      id: 'acc',
      name: '국립아시아문화전당',
      photoAsset: AppAssets.landmarkAcc,
      blurb: '옛 전남도청 자리에 들어선 문화 허브입니다.',
    ),
    Landmark(
      id: 'square518',
      name: '5·18민주광장',
      photoAsset: AppAssets.landmark518,
      blurb: '광주의 민주주의 기억을 잇는 광장입니다.',
    ),
    Landmark(
      id: 'yangnim',
      name: '양림동',
      photoAsset: AppAssets.landmarkYangnim,
      blurb: '호랑가시나무와 근대 선교 역사가 공존하는 마을입니다.',
    ),
    Landmark(
      id: 'chungjang',
      name: '충장로',
      photoAsset: AppAssets.landmarkChungjang,
      blurb: '광주의 대표 번화가. 시장 나들이의 연장선입니다.',
    ),
  ];

  static Landmark byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => all.first);

  static Landmark atIndex(int index) => all[index % all.length];
}
