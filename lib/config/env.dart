/// 네이버 클라우드 Maps(Dynamic Map) 인증.
///
/// 모바일 SDK에는 Client ID만 넣습니다. Client Secret은 앱에 포함하지 마세요.
abstract final class Env {
  static const naverMapClientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: '8g5kdjjd6g',
  );

  static const adminId = 'admin';
  static const adminPassword = 'tradada123';
}
