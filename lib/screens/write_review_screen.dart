import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/market_demo_shops.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';
import '../widgets/review_photo.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, required this.store, this.visitId});

  final Store store;
  final String? visitId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _body = TextEditingController();
  String? _photo;

  List<String> get _demoPhotos {
    final eaten = widget.store.products
        .map((product) => product.reviewImageAsset)
        .whereType<String>();
    final fallback = eaten.isEmpty
        ? widget.store.products
            .map((product) => product.imageAsset)
            .whereType<String>()
        : eaten;
    return {...fallback, ...MarketDemoShops.reviewPhotos}.toList();
  }

  Future<void> _attach(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      setState(() => _photo = file.path);
    } catch (_) {
      if (!mounted) return;
      showAppNotice(context, '사진을 불러오지 못했습니다. 시연용 사진을 선택해도 됩니다.');
    }
  }

  void _chooseSource() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('사진 보관함'),
                onTap: () {
                  Navigator.pop(ctx);
                  _attach(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('사진 촬영'),
                onTap: () {
                  Navigator.pop(ctx);
                  _attach(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_photo == null) {
      await showAppNotice(context, '포토 리뷰만 가능합니다. 사진을 첨부해주세요.');
      return;
    }
    if (_body.text.trim().length < 8) {
      await showAppNotice(context, '리뷰를 조금 더 적어주세요.');
      return;
    }
    final grant = AppSession.instance.addPhotoReview(
      store: widget.store,
      body: _body.text.trim(),
      photoAsset: _photo!,
      visitId: widget.visitId,
    );
    await showAppNotice(context, grant.message);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyLight,
      appBar: AppBar(
        title: const Text('포토 리뷰'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.store.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          _EatenFoods(storeId: widget.store.id, visitId: widget.visitId),
          const SizedBox(height: 8),
          const Text('사진은 필수입니다. 위 메뉴가 먹은 음식으로 리뷰에 함께 기록됩니다.'),
          const SizedBox(height: 14),
          if (_demoPhotos.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final asset in _demoPhotos)
                  GestureDetector(
                    onTap: () => setState(() => _photo = asset),
                    child: Container(
                      width: 96,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _photo == asset
                              ? AppColors.goldDeep
                              : const Color(0xFFE5E7EB),
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: AssetImage(asset),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _chooseSource,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('사진 첨부하기'),
          ),
          if (_photo != null && !ReviewPhoto.isAsset(_photo!)) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ReviewPhoto(source: _photo!, height: 160, width: double.infinity),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _photo == null ? '시연용 사진을 고르거나 직접 첨부하세요.' : '사진이 첨부되었습니다.',
            style: TextStyle(
              color: _photo == null ? AppColors.pinRed : AppColors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _body,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '오늘 픽업한 맛을 남겨주세요.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: const Text('리뷰 올리고 방문 완료하기'),
          ),
        ],
      ),
    );
  }
}

class _EatenFoods extends StatelessWidget {
  const _EatenFoods({required this.storeId, required this.visitId});

  final String storeId;
  final String? visitId;

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    var visit = session.unreviewedQrVisit(storeId);
    if (visitId != null) {
      for (final item in session.reservations) {
        if (item.id == visitId) {
          visit = item;
          break;
        }
      }
    }
    final foods = visit?.eatenFoods ?? const <String>[];
    if (foods.isEmpty) {
      return const Text(
        '예약한 뒤 QR로 수령한 메뉴가 없습니다.',
        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.pinRed),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '예약하고 먹은 음식',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        const SizedBox(height: 4),
        for (final food in foods)
          Text(food, style: const TextStyle(height: 1.4)),
      ],
    );
  }
}
