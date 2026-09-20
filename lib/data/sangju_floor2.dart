/// 시장 데모 2층. 1층과 같은 2800×1400 공간을 쓰되 배치는 창작 평면도다.
abstract final class SangjuFloor2 {
  static const width = 2800.0;
  static const height = 1400.0;

  static List<({String name, double l, double t, double r, double b})> cells() {
    final cells = <({String name, double l, double t, double r, double b})>[];

    void band(double l, double t, double r, double b, List<String> names) {
      final slot = (r - l) / names.length;
      const gap = 8.0;
      for (var i = 0; i < names.length; i++) {
        cells.add((
          name: names[i],
          l: l + i * slot + gap / 2,
          t: t,
          r: l + (i + 1) * slot - gap / 2,
          b: b,
        ));
      }
    }

    // 3개 동 · 가로 복도 4줄. 양동시장 2층(의류·침구·그릇·먹거리) 구성을 참고.
    const leftL = 80.0, leftR = 880.0;
    const midL = 980.0, midR = 1760.0;
    const rightL = 1920.0, rightR = 2720.0;
    const r1t = 80.0, r1b = 270.0;
    const r2t = 350.0, r2b = 600.0;
    const r3t = 680.0, r3b = 930.0;
    const r4t = 1010.0, r4b = 1260.0;

    band(leftL, r1t, leftR, r1b, [
      '상인회 사무실',
      '상인교육장',
      '노을한복',
      '솔향포목',
      '달빛수선',
      '구름침구',
    ]);
    band(midL, r1t, midR, r1b, [
      '고운한복공방',
      '비단길포목',
      '청솔이불',
      '골목이불',
      '햇살침구',
      '꽃분한복',
    ]);
    band(rightL, r1t, rightR, r1b, [
      '마루그릇',
      '놋그릇공방',
      '예쁜보자기',
      '부엌살림',
      '나무수저집',
      '청자그릇',
    ]);

    band(leftL, r2t, leftR, r2b, [
      '미소한복',
      '단정포목',
      '보름이불',
      '바느질공방',
      '실바람수선',
      '하얀침구',
    ]);
    band(midL, r2t, midR, r2b, [
      '은빛그릇',
      '옹기종기',
      '주방살림',
      '꽃받침그릇',
      '나무도마집',
      '반짝수저',
    ]);
    band(rightL, r2t, rightR, r2b, [
      '라일락헤어',
      '고운미용실',
      '바늘수선',
      '실콘수선',
      '단아한복',
      '여름포목',
    ]);

    band(leftL, r3t, leftR, r3b, [
      '2층분식',
      '옥상카페',
      '따뜻한국수',
      '콩국수분식',
      '시장김밥',
      '호떡굽는집',
    ]);
    band(midL, r3t, midR, r3b, [
      '골목잡화',
      '알뜰문구',
      '작은선물집',
      '비누공방',
      '향초가게',
      '손수건집',
    ]);
    band(rightL, r3t, rightR, r3b, [
      '바람한복',
      '푸른포목',
      '이불마을',
      '베개솜집',
      '치마저고리',
      '명절한복',
    ]);

    band(leftL, r4t, leftR, r4b, [
      '2층 계단',
      '2층 화장실',
      '교육장 창고',
      '상인회 창고',
      '잔잔카페',
      '오후떡집',
    ]);
    band(midL, r4t, midR, r4b, [
      '모둠전집',
      '빈대떡집',
      '어묵꼬치',
      '찐빵가게',
      '식혜카페',
      '2층 중앙계단',
    ]);
    band(rightL, r4t, rightR, r4b, [
      '동쪽 화장실',
      '동쪽 계단',
      '그릇창고',
      '이불창고',
      '포목창고',
      '야시장포차',
    ]);

    return cells;
  }
}
