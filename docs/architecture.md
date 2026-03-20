# 🏛️ 프로젝트 아키텍처 및 코딩 컨벤션

이 문서는 본 Flutter 프로젝트의 핵심 구조와 개발 원칙을 정의합니다.
AI(Claude)는 새로운 코드를 작성하거나 기존 코드를 수정할 때 **반드시 이 문서의 규칙을 100% 준수**해야 합니다.

## 1. 기술 스택 (Tech Stack)
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Architecture Pattern:** MVVM (Model - View - ViewModel)
- **Network:** `dio` (with Interceptors)
- **Local Storage:** `flutter_secure_storage`

---

## 2. 디렉토리 구조 (Directory Structure)
프로젝트의 `lib/` 하위 폴더는 다음과 같은 역할을 가집니다. 임의로 새로운 폴더 규칙을 만들지 마십시오.

lib/
┣ 📂 common/     # 앱 전역 설정 (app_global.dart, app_keys.dart 등)
┣ 📂 model/      # 데이터 모델 클래스 (Data classes)
┣ 📂 repository/ # Dio 기반 API 호출 및 데이터 소스 접근 로직
┣ 📂 service/    # 비즈니스 서비스 (auth_service.dart, fcm_service.dart 등)
┣ 📂 theme/      # UI 컴포넌트, 색상, 폰트, 반응형 레이아웃 (palette.dart, typo.dart 등)
┣ 📂 util/       # 유틸리티 함수, 예외 처리, 라우트 정의 (route_path.dart 등)
┣ 📂 view/       # 화면 단위 폴더 (각 기능별로 묶음)
┃ ┣ 📂 base/     # BaseView, BaseViewModel, BaseViewState
┃ ┗ 📂 login/    # 예: 기능별 View, ViewModel, State 파일이 함께 위치
┗ 📜 main.dart   # 엔트리 포인트 (Riverpod ProviderScope 수동 주입)

---

## 3. 핵심 아키텍처 패턴 (MVVM + Riverpod)

새로운 화면(Feature)을 생성할 때는 반드시 아래의 View - ViewModel - State 3가지 세트를 생성하고 Base 클래스를 상속받아야 합니다.

### [규칙 1] 상태(State)와 뷰모델(ViewModel)
- **State:** 모든 상태 클래스는 `BaseViewState`를 상속받으며, 불변 객체(Immutable)로 `copyWith`를 제공해야 합니다. `isBusy`, `isError`, `errorMessage` 필드를 반드시 포함합니다.
- **ViewModel:** `BaseViewModel<상태클래스>`를 상속받습니다. 로직 시작 전 `state = state.copyWith(isBusy: true)`를 호출하고, `finally` 구문에서 `isBusy: false`로 되돌리는 패턴을 엄격히 지킵니다.

### [규칙 2] 뷰 (View)
- 화면 구성 시 기본적으로 `Scaffold`를 자유롭게 사용할 수 있습니다.
- 단, **API 통신 등으로 인한 전역 로딩 상태(`isBusy`) 표시가 필요하거나, 화면 터치 시 키보드를 숨겨야 하는 입력 폼 화면**인 경우에 한하여 `BaseView`를 선택적으로 활용하십시오. 불필요한 에러나 억지스러운 코드 추가는 지양합니다.
- 키보드 숨김 처리가 필요한 독립된 위젯은 `HideKeyboard` 위젯으로 감싸십시오.

---

## 4. 네트워크 및 인증 통신 (Network & Auth)

### [규칙 1] API 호출 (Repository)
- API 호출은 `dioProvider`를 통해 주입받은 `Dio` 인스턴스를 사용합니다.
- Repository 클래스에서 `dio.get()` 또는 `dio.post()`를 수행합니다.
- **에러 핸들링:** 모든 `catch (e)` 블록에서는 `ApiErrorHandler.parse(e)`를 호출하여 서버 에러를 파싱해 던져야(`throw`) 합니다.

### [규칙 2] 토큰 관리 및 서비스 (Service)
- `dioProvider` 내부에 이미 Interceptor가 구현되어 있어, API 요청 시 자동으로 토큰을 주입합니다. API 호출부에서 토큰을 수동으로 넣지 마십시오.
- 비즈니스 상태(예: 로그인 여부 확인 등) 관리는 `NotifierProvider` 기반의 `AuthService` 등을 활용합니다.

---

## 5. UI 및 스타일링 규칙 (Theme & Layout)
- **절대 하드코딩 금지:** 색상이나 폰트는 절대 하드코딩하지 않습니다.
- **테마 사용:** `ThemeService`를 통해 주입받은 커스텀 테마를 사용하십시오.
    - 색상: `ref.color.primary`, `ref.color.text`, `ref.color.hintContainer` 등
    - 폰트: `ref.typo.headline1`, `ref.typo.body1` 등
- **반응형 화면:** 데스크톱 사이즈 등을 고려해야 할 경우 `ConstrainedScreen` 위젯으로 화면을 감싸 최대 너비를 제한하십시오.
- **아이콘:** 기본 아이콘 대신 SVG 렌더링을 지원하는 커스텀 `AssetIcon` 컴포넌트를 사용하십시오.