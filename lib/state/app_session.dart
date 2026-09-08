import 'package:flutter/foundation.dart';

import '../config/assets.dart';
import '../config/env.dart';
import '../data/gwangju_landmarks.dart';
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

  final Set<String> uniqueVisitStoreIds = {};
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
  int get boardIndex => stampCount == 0 ? 0 : (stampCount - 1) ~/ boardSize;
  int get boardFillCount {
    if (stampCount == 0) return 0;
    final filled = stampCount % boardSize;
    return filled == 0 ? boardSize : filled;
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

  StampGrant addDemoVisitStamp() {
    return addDemoVisitStamps(1);
  }

  StampGrant addDemoVisitStamps(int count) {
    TitleTier? latest;
    for (var i = 0; i < count; i++) {
      final id = 'demo-store-${uniqueVisitCount + 1}';
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

  void addReservation({
    required Store store,
    required String productName,
    required int price,
  }) {
    reservations.insert(
      0,
      Reservation(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        storeId: store.id,
        storeName: store.name,
        productName: productName,
        price: price,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addPhotoReview({
    required Store store,
    required String body,
    required String photoAsset,
  }) {
    reviews.insert(
      0,
      Review(
        id: 'mine-${DateTime.now().microsecondsSinceEpoch}',
        author: displayName,
        storeId: store.id,
        storeName: store.name,
        body: body,
        photoAsset: photoAsset,
        createdAt: DateTime.now(),
        isMine: true,
      ),
    );
    addReviewBonusStamp();
  }

  List<Review> weeklyRanking() {
    final copy = [...reviews]..sort((a, b) => b.likes.compareTo(a.likes));
    return copy.take(3).toList();
  }

  TitleTier? nextTitle() {
    for (final tier in TitleCatalog.all) {
      if (!earnedTitleIds.contains(tier.id)) return tier;
    }
    return null;
  }

  void _appendStamp({required String source}) {
    stamps.add(
      CollectedStamp(
        landmarkId: GwangjuLandmarks.atIndex(stamps.length).id,
        source: source,
        at: DateTime.now(),
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

List<Review> _seedReviews() {
  return [
    Review(
      id: 'r1',
      author: '충장로막내',
      storeId: 'yd-honguh',
      storeName: '양동홍어타운',
      body: '마감 세트가 푸짐해요. 시장 골목 분위기도 그대로라 또 오고 싶습니다.',
      photoAsset: AppAssets.landmarkChungjang,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 21,
    ),
    Review(
      id: 'r2',
      author: '무등산토끼',
      storeId: 'yd-gukbap',
      storeName: '천변국밥',
      body: '국물이 진하고 픽업이 빨라요. 포토 남기러 온 보람 있습니다.',
      photoAsset: AppAssets.landmarkMudeung,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      likes: 34,
    ),
    Review(
      id: 'r3',
      author: '양림골목',
      storeId: 'yd-gimbap',
      storeName: '양동김밥명가',
      body: '김밥 4줄 마감백 가성비 최고. 스탬프 찍고 바로 먹었습니다.',
      photoAsset: AppAssets.landmarkYangnim,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likes: 17,
    ),
    Review(
      id: 'r4',
      author: 'ACC나들이',
      storeId: 'yd-fruit',
      storeName: '햇살과일',
      body: '제철 과일 모음이 신선합니다. 사진으로 남기기 좋아요.',
      photoAsset: AppAssets.landmarkAcc,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      likes: 12,
    ),
    Review(
      id: 'r5',
      author: '민주광장지기',
      storeId: 'yd-jeon',
      storeName: '할머니전집',
      body: '모둠전이 바삭. 시장 구경 코스로 추천합니다.',
      photoAsset: AppAssets.landmark518,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likes: 9,
    ),
  ];
}
