import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/assets.dart';
import '../config/env.dart';
import '../data/gwangju_landmarks.dart';
import '../data/gwangju_markets.dart';
import '../models/collected_stamp.dart';
import '../models/reservation.dart';
import '../models/review.dart';
import '../models/store.dart';
import '../models/title_tier.dart';

class StampGrant {
  const StampGrant({
    required this.added,
    this.message = '',
    this.unlockedTitle,
  });

  final bool added;
  final String message;
  final TitleTier? unlockedTitle;
}

enum DemoAvatarGender { male, female }

class AppSession extends ChangeNotifier {
  AppSession._() {
    reviews.addAll(_seedReviews());
  }
  static final AppSession instance = AppSession._();

  static const boardSize = 30;
  static const columns = 5;
  static const recommendsForBonus = 10;
  static const dailyRecommendLimit = 2;
  static const repeatingStampGoal = 30;

  bool loggedIn = false;
  String displayName = '관리자';

  /// 시장 데모 입장 때 한 번 고른다. 가입 흐름에서는 성별에 맞춰 정해질 값이다.
  DemoAvatarGender? demoAvatarGender;

  String get playAvatarAsset => demoAvatarGender == DemoAvatarGender.female
      ? AppAssets.playAvatarFemale
      : AppAssets.playAvatar;

  void chooseDemoAvatar(DemoAvatarGender gender) {
    demoAvatarGender = gender;
    notifyListeners();
  }

  final Set<String> uniqueVisitStoreIds = {};
  final Set<String> qrVerifiedStoreIds = {};
  final Map<String, DateTime> lastVisitStampAt = {};
  final List<CollectedStamp> stamps = [];
  final List<Reservation> reservations = [];
  final List<Review> reviews = [];
  final Set<String> earnedTitleIds = {};
  final List<String> voucherLog = [];
  final Set<String> likedReviewIds = {};

  int recommendCountTowardBonus = 0;
  int recommendsToday = 0;
  DateTime? recommendDay;
  int repeatingPacksClaimed = 0;

  int get stampCount => stamps.length;
  int get uniqueVisitCount => uniqueVisitStoreIds.length;
  /// 지금 채우는 보드. 30칸이 차면 다음 빈 보드로 넘어간다.
  int get boardIndex => stampCount ~/ boardSize;
  int get boardCount => boardIndex + 1;
  int get boardFillCount => stampCount % boardSize;

  int fillOnBoard(int board) {
    final remain = stampCount - board * boardSize;
    if (remain <= 0) return 0;
    if (remain >= boardSize) return boardSize;
    return remain;
  }

  /// 실제로 지급된 지역사랑상품권 합계. 화면의 P는 이 금액이다.
  int get stampPoints {
    var total = repeatingPacksClaimed * 10000;
    for (final tier in TitleCatalog.all) {
      if (earnedTitleIds.contains(tier.id)) total += tier.voucherWon;
    }
    return total;
  }

  int get repeatingProgress => stampCount % repeatingStampGoal;

  bool login(String id, String password) {
    if (id.trim() == Env.adminId && password == Env.adminPassword) {
      loggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    loggedIn = false;
    notifyListeners();
  }

  bool hasVisitStampToday(String storeId) {
    final last = lastVisitStampAt[storeId];
    if (last == null) return false;
    return _sameDay(last, DateTime.now());
  }

  bool hasEverVisited(String storeId) => uniqueVisitStoreIds.contains(storeId);

  Set<String> get paintedStoreIds => {
    for (final review in reviews)
      if (review.isMine) review.storeId,
  };

  bool hasPainted(String storeId) => paintedStoreIds.contains(storeId);

  bool hasQrVerified(String storeId) => qrVerifiedStoreIds.contains(storeId);

  bool canWriteReview(String storeId) => unreviewedQrVisit(storeId) != null;

  Reservation? activeReservation(String storeId) {
    for (final item in reservations) {
      if (item.storeId == storeId && item.isOpenReservation) return item;
    }
    return null;
  }

  Reservation? unreviewedQrVisit(String storeId) {
    for (final item in reservations) {
      if (item.storeId == storeId && item.isQrVisit && !item.hasReview) {
        return item;
      }
    }
    return null;
  }

  bool canWriteReviewFor(Reservation item) =>
      item.isQrVisit && !item.hasReview;

  /// 예약이 있을 때만 수령 인증으로 바꾼다. 예약 없이 방문 기록을 만들지 않는다.
  bool markQrVerified(Store store) {
    final reservation = activeReservation(store.id);
    if (reservation == null) return false;
    reservation.status = ReservationStatus.visited;
    qrVerifiedStoreIds.add(store.id);
    notifyListeners();
    return true;
  }

  StampGrant addDemoVisitStamp() {
    return addDemoVisitStamps(1);
  }

  StampGrant addDemoVisitStamps(int count) {
    TitleTier? latest;
    final marketIds = GwangjuMarkets.yangdong.stores.map((s) => s.id).toList();
    for (var i = 0; i < count; i++) {
      final unused = marketIds.where((id) => !uniqueVisitStoreIds.contains(id));
      final id = unused.isEmpty
          ? 'demo-store-${uniqueVisitCount + 1}'
          : unused.first;
      lastVisitStampAt[id] = DateTime.now();
      uniqueVisitStoreIds.add(id);
      _appendStamp(source: 'visit');
      latest = _unlockTitles() ?? latest;
    }
    notifyListeners();
    return StampGrant(
      added: true,
      message: latest == null
          ? '시연 스탬프 +$count (방문 $uniqueVisitCount곳 · 보드 $stampCount개)'
          : '${latest.korean}(${latest.english}) 칭호 해금! 상품권이 지급 내역에 추가되었습니다.',
      unlockedTitle: latest,
    );
  }

  StampGrant addVisitStamp(String storeId) {
    if (hasVisitStampToday(storeId)) {
      return const StampGrant(
        added: false,
        message: '이 가게 스탬프는 하루에 1회만 받을 수 있습니다.',
      );
    }
    lastVisitStampAt[storeId] = DateTime.now();
    uniqueVisitStoreIds.add(storeId);
    _appendStamp(source: 'visit');
    final title = _unlockTitles();
    notifyListeners();
    return StampGrant(
      added: true,
      message: title == null
          ? '방문 스탬프가 체크판에 찍혔습니다.'
          : '${title.korean}(${title.english}) 칭호와 상품권이 지급되었습니다.',
      unlockedTitle: title,
    );
  }

  StampGrant addReviewBonusStamp() {
    _appendStamp(source: 'review');
    notifyListeners();
    return const StampGrant(
      added: true,
      message: '포토 리뷰 보너스 스탬프 +1 (칭호작 방문 횟수에는 포함되지 않습니다).',
    );
  }

  String? recommendReview(String reviewId) {
    _rollRecommendDay();
    if (recommendsToday >= dailyRecommendLimit) {
      return '추천은 하루 2회까지입니다.';
    }
    if (likedReviewIds.contains(reviewId)) {
      return '이미 추천한 리뷰입니다.';
    }
    Review? review;
    for (final item in reviews) {
      if (item.id == reviewId) {
        review = item;
        break;
      }
    }
    if (review == null) return '리뷰를 찾을 수 없습니다.';
    if (review.isMine) return '내 리뷰는 추천할 수 없습니다.';

    likedReviewIds.add(reviewId);
    review.likes += 1;
    recommendsToday += 1;
    recommendCountTowardBonus += 1;
    var bonus = false;
    if (recommendCountTowardBonus >= recommendsForBonus) {
      recommendCountTowardBonus = 0;
      _appendStamp(source: 'recommend');
      bonus = true;
    }
    notifyListeners();
    return bonus
        ? '추천 10회 달성! 보너스 스탬프가 지급되었습니다.'
        : '추천했습니다. 오늘 $recommendsToday/$dailyRecommendLimit회';
  }

  /// 이미 진행 중인 예약이 있으면 false. 수량은 1개 이상인 메뉴만 담는다.
  bool reserveFoods({
    required Store store,
    required List<ReservedItem> items,
  }) {
    final chosen = [
      for (final item in items)
        if (item.quantity > 0) item,
    ];
    if (chosen.isEmpty || activeReservation(store.id) != null) return false;
    reservations.insert(
      0,
      Reservation(
        id: 'rsv-${DateTime.now().microsecondsSinceEpoch}',
        storeId: store.id,
        storeName: store.name,
        items: chosen,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  bool cancelReservation(String id) {
    final index = reservations.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    final item = reservations[index];
    if (!item.isOpenReservation || item.hasReview) return false;
    reservations.removeAt(index);
    notifyListeners();
    return true;
  }

  StampGrant addPhotoReview({
    required Store store,
    required String body,
    required String photoAsset,
    String? visitId,
  }) {
    Reservation? visit;
    if (visitId != null) {
      for (final item in reservations) {
        if (item.id == visitId) {
          visit = item;
          break;
        }
      }
    }
    visit ??= unreviewedQrVisit(store.id);
    if (visit == null || visit.hasReview) {
      return const StampGrant(
        added: false,
        message: '예약한 뒤 QR로 수령 인증한 식당만 리뷰를 남길 수 있습니다.',
      );
    }

    final review = Review(
      id: 'mine-${DateTime.now().microsecondsSinceEpoch}',
      author: displayName,
      storeId: store.id,
      storeName: store.name,
      body: body,
      photoAsset: photoAsset,
      createdAt: DateTime.now(),
      isMine: true,
      eatenFoods: visit.eatenFoods,
    );
    reviews.insert(0, review);
    visit.reviewId = review.id;
    qrVerifiedStoreIds.add(store.id);
    StampGrant grant;
    if (!hasEverVisited(store.id) || !hasVisitStampToday(store.id)) {
      lastVisitStampAt[store.id] = DateTime.now();
      uniqueVisitStoreIds.add(store.id);
      _appendStamp(source: 'visit');
      final title = _unlockTitles();
      grant = StampGrant(
        added: true,
        message: title == null
            ? '리뷰가 등록되어 방문 완료 · 스탬프 · 지도 색칠이 반영되었습니다.'
            : '${title.korean}(${title.english}) 칭호와 상품권이 지급되었습니다.',
        unlockedTitle: title,
      );
    } else {
      grant = const StampGrant(
        added: false,
        message: '리뷰가 등록되어 지도에 색칠되었습니다. 오늘 스탬프는 이미 받았습니다.',
      );
    }
    notifyListeners();
    return grant;
  }

  List<Review> weeklyRanking() {
    final copy = [...reviews]..sort((a, b) => b.likes.compareTo(a.likes));
    return copy.take(3).toList();
  }

  List<Review> reviewsForStore(String storeId) {
    return reviews.where((r) => r.storeId == storeId).toList();
  }

  Review? reviewById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final review in reviews) {
      if (review.id == id) return review;
    }
    return null;
  }

  TitleTier? nextTitle() {
    for (final tier in TitleCatalog.all) {
      if (!earnedTitleIds.contains(tier.id)) return tier;
    }
    return null;
  }

  void _appendStamp({required String source}) {
    final roll = Random();
    stamps.add(
      CollectedStamp(
        landmarkId: GwangjuLandmarks.random().id,
        source: source,
        at: DateTime.now(),
        points: 100 + roll.nextInt(11) * 10,
      ),
    );
    final packs = stampCount ~/ repeatingStampGoal;
    if (packs > repeatingPacksClaimed) {
      repeatingPacksClaimed = packs;
      voucherLog.add('반복 미션: 스탬프 $repeatingStampGoal개 → 지역사랑상품권 1만 원');
    }
  }

  TitleTier? _unlockTitles() {
    TitleTier? latest;
    for (final tier in TitleCatalog.all) {
      if (uniqueVisitCount >= tier.uniqueStores &&
          !earnedTitleIds.contains(tier.id)) {
        earnedTitleIds.add(tier.id);
        voucherLog.add(
          '${tier.korean} 달성 · 지역사랑상품권 ${_won(tier.voucherWon)}',
        );
        latest = tier;
      }
    }
    return latest;
  }

  void _rollRecommendDay() {
    final today = DateTime.now();
    if (recommendDay == null || !_sameDay(recommendDay!, today)) {
      recommendDay = today;
      recommendsToday = 0;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

Review _seedReview({
  required String id,
  required String author,
  required String storeId,
  required String storeName,
  required String body,
  required String photoAsset,
  required DateTime createdAt,
  required int likes,
  required String eaten,
}) {
  return Review(
    id: id,
    author: author,
    storeId: storeId,
    storeName: storeName,
    body: body,
    photoAsset: photoAsset,
    createdAt: createdAt,
    likes: likes,
    eatenFoods: [eaten],
  );
}

List<Review> _seedReviews() {
  final now = DateTime.now();
  return [
    _seedReview(
      id: 'r1',
      author: '충장로막내',
      storeId: 'yd-honguh',
      storeName: '양동홍어타운',
      body: '홍어모둠이 푸짐해요. 시장 골목 분위기 그대로라 또 오고 싶습니다.',
      photoAsset: AppAssets.foodHonguh,
      createdAt: now.subtract(const Duration(hours: 5)),
      likes: 21,
      eaten: '홍어모둠 × 1',
    ),
    Review(
      id: 'r2',
      author: '무등산토끼',
      storeId: 'yd-gukbap',
      storeName: '천변국밥',
      body: '국물이 진하고 픽업이 빨라요. 포토 남기러 온 보람 있습니다.',
      photoAsset: AppAssets.foodReviewGukbap,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      eatenFoods: const ['국밥 × 1'],
      likes: 34,
    ),
    Review(
      id: 'r3',
      author: '양림골목',
      storeId: 'yd-gimbap',
      storeName: '양동김밥명가',
      body: '김밥 4줄 마감백 가성비 최고. 스탬프 찍고 바로 먹었습니다.',
      photoAsset: AppAssets.foodGimbap,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      eatenFoods: const ['김밥 × 4'],
      likes: 17,
    ),
    Review(
      id: 'r4',
      author: 'ACC나들이',
      storeId: 'yd-fruit',
      storeName: '햇살과일',
      body: '제철 과일 모음이 신선합니다. 사진으로 남기기 좋아요.',
      photoAsset: AppAssets.foodFruit,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      eatenFoods: const ['제철 과일 × 1'],
      likes: 12,
    ),
    Review(
      id: 'r5',
      author: '민주광장지기',
      storeId: 'yd-jeon',
      storeName: '할머니전집',
      body: '모둠전이 바삭. 시장 구경 코스로 추천합니다.',
      photoAsset: AppAssets.foodJeon,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      eatenFoods: const ['모둠전 × 1'],
      likes: 9,
    ),
    Review(
      id: 'r6',
      author: '양동단골',
      storeId: 'yd-honguh',
      storeName: '양동홍어타운',
      body: '홍어찜도 잡내 없이 깔끔합니다. 저녁 픽업 추천.',
      photoAsset: AppAssets.foodSeafood,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      eatenFoods: const ['홍어찜 × 1'],
      likes: 6,
    ),
    Review(
      id: 'r7',
      author: '송정역나그네',
      storeId: 'yd-yukhoe',
      storeName: '빛고을육회',
      body: '육회가 달고 고소해요. 마감팩이라 양이 알찹니다.',
      photoAsset: AppAssets.foodYukhoe,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      eatenFoods: const ['육회 × 1'],
      likes: 19,
    ),
    Review(
      id: 'r8',
      author: '하남별빛',
      storeId: 'yd-susan',
      storeName: '싱싱수산',
      body: '고등어 구이 껍질이 바삭. 갈치까지 한 팩이라 저녁이 해결됐어요.',
      photoAsset: AppAssets.foodMackerel,
      createdAt: DateTime.now().subtract(const Duration(hours: 11)),
      eatenFoods: const ['고등어구이 × 1'],
      likes: 14,
    ),
    Review(
      id: 'r9',
      author: '첨단산책러',
      storeId: 'yd-tteok',
      storeName: '양동떡집',
      body: '인절미가 쫄깃하고 콩가루가 고소합니다. 간식용으로 최고.',
      photoAsset: AppAssets.foodTteok,
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      eatenFoods: const ['인절미 × 1'],
      likes: 11,
    ),
    Review(
      id: 'r10',
      author: '양동야시장',
      storeId: 'yd-gunbam',
      storeName: '밤마실군밤',
      body: '군밤이 달고 따뜻해요. 골목에서 먹으니 더 맛있습니다.',
      photoAsset: AppAssets.foodGunbam,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      eatenFoods: const ['군밤 × 1'],
      likes: 16,
    ),
    Review(
      id: 'r11',
      author: '동명골목',
      storeId: 'yd-gimbap',
      storeName: '양동김밥명가',
      body: '떡볶이 국물이 칼칼하고 매콤해요. 김밥이랑 같이 픽업 강추.',
      photoAsset: AppAssets.foodTteokbokki,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      eatenFoods: const ['떡볶이 × 1'],
      likes: 13,
    ),
    Review(
      id: 'r12',
      author: '풍암주부',
      storeId: 'yd-hanbok',
      storeName: '고운한복',
      body: '손수건 세트가 단정하고 포장도 예뻐요. 선물용으로 샀습니다.',
      photoAsset: AppAssets.foodBojagi,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      eatenFoods: const ['손수건 세트 × 1'],
      likes: 8,
    ),
    Review(
      id: 'r13',
      author: '수완저녁',
      storeId: 'yd-gukbap',
      storeName: '천변국밥',
      body: '수육 포장도 야들야들. 국밥이랑 같이 시키면 든든합니다.',
      photoAsset: AppAssets.foodSuyuk,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      eatenFoods: const ['수육 × 1'],
      likes: 10,
    ),
    Review(
      id: 'r14',
      author: '상무로터리',
      storeId: 'yd-susan',
      storeName: '싱싱수산',
      body: '굴비 소팩이 짜지 않고 담백해요. 밥반찬으로 딱입니다.',
      photoAsset: AppAssets.foodDried,
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 8)),
      eatenFoods: const ['굴비 × 1'],
      likes: 7,
    ),
    Review(
      id: 'r15',
      author: '법성포길손',
      storeId: 'yd-gulbi',
      storeName: '영광굴비',
      body: '굴비가 기름지고 간도 세지 않아요. A동 건어물 코스로 추천합니다.',
      photoAsset: AppAssets.foodDried,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      eatenFoods: const ['굴비 × 1'],
      likes: 15,
    ),
    Review(
      id: 'r16',
      author: '통영나들이',
      storeId: 'yd-myeolchi',
      storeName: '통영멸치',
      body: '볶음멸치가 바삭하고 달지 않아요. 국물멸치도 시원합니다.',
      photoAsset: AppAssets.foodDried,
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      eatenFoods: const ['볶음멸치 × 1'],
      likes: 9,
    ),
  ];
}
