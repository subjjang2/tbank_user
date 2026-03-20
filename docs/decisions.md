# 🧠 프로젝트 주요 의사 결정 기록 (ADR)

이 문서는 프로젝트(T-BANK 아키텍처 기반)를 진행하며 내린 핵심 기술 결정과 그 이유(Why)를 기록합니다.
Claude는 코드를 작성하거나 리팩토링할 때, 아래의 결정을 절대적으로 존중해야 하며 임의로 다른 기술 스택이나 패턴을 제안해서는 안 됩니다.

## 1. 상태 관리: Riverpod + MVVM 패턴 (2026-03)
* **결정:** 전역 및 로컬 상태 관리를 위해 `flutter_riverpod`을 사용하고, View-ViewModel-State 구조를 강제한다. GetX나 Provider, Bloc 등으로 대체하지 않는다.
* **이유:** 컴파일 타임의 안정성을 보장받고, 비즈니스 로직(ViewModel)과 UI(View)의 의존성을 완전히 분리하여 유지보수성을 극대화하기 위함이다.

## 2. 공통 UI 처리: BaseView의 선택적 활용 (2026-03)
* **결정:** 모든 화면에 `BaseView` 사용을 강제하지 않고, 일반 `Scaffold` 사용을 허용한다. 로딩과 키보드 제어가 '실제로 필요한 화면'에만 `BaseView`를 적용한다.
* **이유:** BaseView를 강제화할 경우, 단순한 화면이나 정적인 UI에서도 불필요한 상태(State/ViewModel)를 만들어야 하는 등 오버엔지니어링과 에러가 발생할 수 있기 때문이다. 개발 생산성과 유연성을 우선한다.

## 3. 네트워크 통신: Dio Interceptor + 전역 에러 핸들링 (2026-03)
* **결정:** HTTP 통신은 `dio` 패키지를 사용하며, API 요청 시 Authorization 헤더에 토큰을 넣는 작업은 `dioProvider` 내부의 Interceptor에 전적으로 위임한다. API 에러는 뷰모델에서 직접 처리하지 않고 반드시 `ApiErrorHandler.parse(e)`로 변환하여 던진다(throw).
* **이유:** API 호출 함수마다 토큰을 수동으로 넣는 실수를 원천 차단하고, 서버의 에러 응답 코드를 앱 전체에서 동일한 규격의 `AppException`으로 파싱하여 뷰모델(`state.errorMessage`)로 안전하게 전달하기 위함이다.

## 4. 디자인 시스템: 하드코딩 금지 및 ThemeService 활용 (2026-03)
* **결정:** UI 위젯에 `Colors.black`이나 `FontWeight.bold` 같은 기본 값을 절대 하드코딩하지 않는다. 반드시 `ref.color.primary` 나 `ref.typo.headline1` 처럼 `ThemeService`를 통해 주입받은 커스텀 테마 값을 사용한다.
* **이유:** 다크모드/라이트모드 전환에 유연하게 대응하고, 디자인 시스템(`Palette`, `Typo`)을 앱 전체에 일관성 있게 유지하기 위함이다.