# 📱 프로젝트 개요
- Flutter 모바일 앱 (SDK ^3.8.1)

# 🛠️ 명령어 (Commands)
- **의존성 설치:** `flutter pub get`
- **코드 생성(필수):** `dart run build_runner build --delete-conflicting-outputs`
  - freezed/json_serializable 모델 수정 시 반드시 실행 (`*.freezed.dart`, `*.g.dart` 재생성)
- **실행:** `flutter run`
- **분석/린트:** `flutter analyze`
- **테스트:** `flutter test`

# ⚡️ 트리거 키워드 및 행동 강령
- **플랜 모드 필수:** 코드를 즉시 치지 말고 반드시 `Plan`을 먼저 제시해라.
- **에러 로그:** 에러가 나면 네가 요약하지 말고 스택 트레이스 원문을 나에게 보여라.