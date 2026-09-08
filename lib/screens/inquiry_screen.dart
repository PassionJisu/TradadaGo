import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../util/app_notice.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _kind = '문의';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      await showAppNotice(context, '제목과 내용을 입력해주세요.');
      return;
    }
    await showAppNotice(context, '$_kind가 접수되었습니다. (데모)');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyLight,
      appBar: AppBar(title: const Text('신고 / 문의하기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '문의', label: Text('문의')),
              ButtonSegment(value: '신고', label: Text('신고')),
            ],
            selected: {_kind},
            onSelectionChanged: (set) => setState(() => _kind = set.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: '제목',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: '내용',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: Text('$_kind 보내기'),
          ),
        ],
      ),
    );
  }
}
