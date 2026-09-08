import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'config/env.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterNaverMap().init(
    clientId: Env.naverMapClientId,
    onAuthFailed: (ex) {
      debugPrint('Naver Map auth failed: $ex');
    },
  );
  runApp(const TradadaApp());
}

class TradadaApp extends StatelessWidget {
  const TradadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '트라다다 GO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginScreen(),
    );
  }
}
