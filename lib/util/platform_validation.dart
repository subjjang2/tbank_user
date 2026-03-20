// lib/config/app_config.dart

// 앱이 실행되는 플랫폼의 종류를 정의합니다.
enum PlatformType {
  desktop,
  mobile,
}

/// 앱 전역에서 사용할 플랫폼 타입 변수입니다.
/// main() 함수에서 앱이 시작될 때 실제 값으로 초기화됩니다.
late PlatformType G_platformType;
