# repository/ — 데이터 계층

## Overview / Owns
REST API 호출을 담당. ViewModel·Service가 이 계층을 통해서만 서버와 통신한다.
각 Repository는 `Provider`로 노출되고 `dioProvider`(`../util/helper/network_helper.dart`)를 주입받는다.

## Key Files
- `auth_repository.dart` — 로그인/회원가입/이메일 인증 (`authRepositoryProvider`)
- `account_repository.dart` — 계좌 목록·프로필·사용자 검색 (`accountRepositoryProvider`)
- `transfer_repository.dart` — 송금·계좌검색 (`transRepositoryProvider`)
- `bank_repository.dart` · `system_repository.dart` — 은행·시스템 메타
- `response/` — API 응답 모델 (`account_response`, `authority/`, `account_search/`, `transation_history/` — 일부 freezed)

## Common Change Patterns
```dart
Future<T> someCall(...) async {
  try {
    final res = await _dio.get('/path', queryParameters: {...});
    return T.fromJson(res.data['data']);
  } catch (e) {
    throw ApiErrorHandler.parse(e); // 항상 이 패턴
  }
}
```
- 응답은 보통 `res.data['data']` 안에 래핑됨
- 새 응답 모델은 `response/`에 추가 (freezed 권장, 생성 명령 필수)

## Non-obvious / Gotchas
- **에러 계약:** Repository는 **항상 `AppException`을 throw** (bool/null 반환 안 함) → 호출부에서 catch
- **예외:** `account_repository.searchUserForPermission`은 404를 에러가 아닌 `null`(결과 없음)로 처리
- `response/` 하위 폴더명에 오타 존재: `transation_history` (→transaction)

## Dependencies
- 의존: `../util/helper/network_helper.dart`(dioProvider), `../util/helper/api_error_handler.dart`, `../model/`
- 피의존: `../view/*_view_model.dart`, `../service/`, `../provider/`
