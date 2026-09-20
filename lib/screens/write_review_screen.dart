import 'package:flutter/material.dart';

import '../config/assets.dart';
import '../models/store.dart';
import '../state/app_session.dart';
import '../theme/app_colors.dart';
import '../util/app_notice.dart';

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
    final storePhotos = widget.store.products
        .map((product) => product.imageAsset)
        .whereType<String>()
        .toSet()
        .toList();
    final extras = [
      AppAssets.foodGimbap,
      AppAssets.foodChicken,
      AppAssets.foodTteokbokki,
      AppAssets.foodJeon,
      AppAssets.foodFruit,
    ];
    return {...storePhotos, ...extras}.toList();
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
          const Text('사진은 필수입니다. 허위·성의 없는 글만 있는 리뷰는 받지 않습니다.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
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
          const SizedBox(height: 6),
          Text(
            _photo == null ? '시연용 사진 중 하나를 선택하세요.' : '사진이 첨부되었습니다.',
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
