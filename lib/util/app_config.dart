/// 환경 구분 (로컬 / 실서버)
enum AppEnv {
  local, // 내 컴퓨터 (로컬 서버)
  prod,  // 실제 운영 서버

}

class AppConfig {
  /// ⚡️ [스위치] 여기만 변경하면 됩니다!
  static const AppEnv currentEnv = AppEnv.local;
// 최소 로딩 시간 (깜빡임 방지용)
  static const minLoadingDuration = Duration(milliseconds: 250);
  // ✨ [추가] 페이지네이션 개수 제한 (한 번에 가져올 개수)
  static const int defaultLimit = 20;

  /// 1. 로컬 서버 주소 (IP 입력)
  /// 주의: 안드로이드 에뮬레이터에서 로컬호스트 접속 시 '10.0.2.2' 사용
  /// iOS 시뮬레이터는 '127.0.0.1' 또는 'localhost' 사용
  /// 실제 기기는 PC의 내부 IP (예: 192.168.0.x) 사용
  static const String _localUrl = 'http://192.168.1.106:3000';



  /// 2. 실제 서버 주소 (운영)
  static const String _prodUrl = 'https://t-bank-backend-production.up.railway.app';

  /// 현재 설정된 Base URL 반환
  static String get baseUrl {
    switch (currentEnv) {
      case AppEnv.local:
        return _localUrl;
      case AppEnv.prod:
        return _prodUrl;
    }
  }
}