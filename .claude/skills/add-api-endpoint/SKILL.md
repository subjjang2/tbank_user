---
name: add-api-endpoint
description: T-BANK 프로젝트에 새 API 엔드포인트를 추가할 때 사용. Repository 메서드 추가, 응답 모델(freezed) 생성, build_runner 실행, ViewModel 연결까지 기존 프로젝트 패턴을 그대로 따른다. "API 추가", "엔드포인트 만들기", "Repository에 호출 추가", "새 API 붙이기" 같은 요청에 트리거.
---

# 새 API 엔드포인트 추가

T-BANK 사용자 앱(Flutter + Riverpod + Repository)에 새 REST API 호출을 붙이는 절차.
데이터 흐름은 단방향: **View → ViewModel → Repository → Dio → API**.

## 시작 전 확인할 것
- HTTP 메서드/경로 (예: `GET /accounts/accessible`)
- 요청 파라미터 (query / body)
- 응답 JSON 형태 — 본문은 거의 항상 `res.data['data']` 안에 래핑됨
- 어느 Repository에 속하는가: `auth`(로그인·회원가입), `account`(계좌·프로필·권한), `transfer`(송금·계좌검색), `bank`(은행), `system`(메타)

## 절차

### 1. 응답 모델 추가 (`lib/repository/response/`)
- 단순 void(POST 등)면 모델 불필요 → 4단계로.
- 새 데이터를 받으면 freezed 모델을 **새 파일**로 생성 (`lib/repository/response/<name>_response.dart`).
- 기존 `account_response.dart` 패턴을 따른다:
  - `part '<name>_response.freezed.dart';` / `part '<name>_response.g.dart';`
  - `@freezed` + `const factory ... = _X;` + `factory X.fromJson(...)`
  - 서버 타입이 들쭉날쭉하므로 안전 파싱 헬퍼(`_parseInt`, `_parseString`) + `@JsonKey(fromJson:, defaultValue:)` 사용
  - null 대비 `@Default([])`, `.empty()` 팩토리 제공

### 2. 코드 생성 (freezed 모델 추가/수정 시 필수)
```bash
dart run build_runner build --delete-conflicting-outputs
```
`*.freezed.dart`, `*.g.dart`가 재생성된다. 이걸 안 돌리면 컴파일 에러.

### 3. Repository에 메서드 추가 (`lib/repository/<x>_repository.dart`)
기존 메서드 위에 주석 헤더 블록을 그대로 맞춰서 추가한다:
```dart
// ---------------------------------------------------------------------------
// [API] 설명
// GET /path
// ---------------------------------------------------------------------------
Future<XResponse> fetchX({int page = 1}) async {
  try {
    final response = await _dio.get(
      '/path',
      queryParameters: {'page': page, 'limit': AppConfig.defaultLimit},
    );
    final dynamic responseBody = response.data;
    return XResponse.fromJson(responseBody['data']);
  } catch (e) {
    throw ApiErrorHandler.parse(e); // ⚠️ 항상 이 패턴 — bool/null 반환 금지
  }
}
```
규칙:
- **에러 계약:** Repository는 항상 `throw ApiErrorHandler.parse(e)`. 성공값만 반환, 에러는 던진다.
- **예외 케이스:** "결과 없음"을 null로 표현해야 하면 `searchUserForPermission`처럼 `on DioException`으로 404만 잡아 `return null` (반환 타입 `XResponse?`).
- POST는 `data: {...}`, GET은 `queryParameters: {...}`.
- 페이징은 `AppConfig.defaultLimit` 사용.
- `_dio`는 생성자 주입된 `dioProvider` (토큰 인터셉터 포함, 직접 헤더 세팅 불필요).

### 4. ViewModel에서 호출 (`lib/view/<feature>/<feature>_view_model.dart`)
```dart
Future<void> action() async {
  state = state.copyWith(isBusy: true, isError: false, errorMessage: null);
  try {
    final res = await ref.read(xRepositoryProvider).fetchX();
    state = state.copyWith(isBusy: false, data: res);
  } on AppException catch (e) {
    state = state.copyWith(isBusy: false, isError: true, errorMessage: e.message);
  } catch (e) {
    state = state.copyWith(isBusy: false, isError: true, errorMessage: "서버 통신 중 오류가 발생했습니다.");
  }
}
```
- Repository 호출은 `ref.read(xRepositoryProvider)`.
- State는 `copyWith` 불변 업데이트. 공통 필드 `isBusy`/`isError`/`errorMessage` 사용.

### 5. 검증
```bash
flutter analyze
flutter test   # 관련 테스트 있으면
```

## 주의 (프로젝트 고유)
- `response/` 하위에 오타 폴더 `transation_history`(→transaction) 존재 — 신규는 정확한 철자로.
- ViewModel 반환 타입(bool/void/String?)과 View 에러 UI(SnackBar/state렌더/AppDialog/Toast)가 혼용 상태다. 새 코드는 **연결하는 feature가 쓰는 기존 방식 하나에 맞춰** 일관되게.
- 모델 정의가 freezed/수동 class 혼용이지만 **새 응답 모델은 freezed 권장**.
- API base URL 전환은 `lib/util/app_config.dart`의 `currentEnv`(local/prod).
