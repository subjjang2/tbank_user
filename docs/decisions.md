# 🧭 결정 기록 (Decisions)

> **이 문서의 용도** — "왜 이렇게 했나"를 한곳에 가볍게 모으는 **허브**입니다.
> 확정·되돌리기 어려운 기술 결정은 [`docs/adr/`](adr/README.md)에 정식 기록하고,
> 그 외(아직 확정 안 된 추론, 비즈니스 룰, 도메인 규칙)는 여기에 캡처합니다.
>
> **사용법** — 기억나는 룰·결정 이유를 아무 형식으로 **한 줄씩** 추가하세요.
> 인덱싱·정리·중복 제거·ADR 승격은 AI가 맡습니다. 형식 고민 없이 일단 적어두면 됩니다.
>
> **표기 규칙**
> - ✅ **확정(ADR)** — ADR로 정식 기록된 결정. 본문은 ADR 참조.
> - ❓ **확실하지 않음** — 코드에서 추론했으나 "왜"가 미문서화. 사용자 보강 필요.
> - ✍️ **사용자 확인 필요** — 코드만으로 알 수 없음. 사용자가 직접 채울 영역.

---

## 1. 확정 결정 인덱스 (ADR)

이미 ADR로 확정된 기술 결정. 상세 근거·맥락은 링크 참조 (여기엔 중복 기재하지 않음).

| # | 결정 | 한 줄 요약 | 근거 |
|---|------|-----------|------|
| 0001 | 상태관리 Riverpod + MVVM | 화면 = `*_view`/`*_view_model`/`*_view_state` 3종, `BaseViewModel<S> extends AutoDisposeNotifier<S>`, `copyWith` 불변 | [ADR 0001](adr/0001-state-management-riverpod-mvvm.md) |
| 0002 | 라우팅 Named Route | go_router 미채택, Flutter 기본 Named Route + `onGenerateRoute`, 전역은 `navigatorKey` | [ADR 0002](adr/0002-routing-named-routes.md) |
| 0003 | 에러 처리 계약 | 모든 Dio 에러 → `ApiErrorHandler.parse()` → `AppException`(한글). Repository는 항상 throw | [ADR 0003](adr/0003-error-handling-exception-contract.md) |
| 0004 | 중복/혼용 부채 | 신규 코드 통일 방향(모델=freezed, State=factory.initial 등). 기존은 "건드릴 때 통일" | [ADR 0004](adr/0004-known-duplication-debt.md) |
| 0005 | API 호출 경로 | API는 ViewModel → Repository 직접 호출 표준. 미사용 Service 래퍼 제거, `service/`는 fcm·theme만 | [ADR 0005](adr/0005-api-call-via-repository.md) |

---

## 2. 코드에서 추론된 결정 (❓ 확실하지 않음 — 사용자 보강 대상)

ADR에 없거나 "왜"가 문서화되지 않은 항목. 코드 근거는 확실하지만 **의도는 추측**입니다.
맞으면 확정 표시로, 아니면 정정해 주세요. 굳어지면 ADR로 승격합니다.

### 2.1 로컬 저장 = flutter_secure_storage 단일
- **결정(추론):** 토큰·`userId`·`userName`을 모두 `flutter_secure_storage`에 저장. `shared_preferences`는 의존성에 있으나 코드상 미사용.
- **추론한 이유:** 저장 대상이 전부 민감 정보(인증·신원)라 암호화 저장소로 통합. iOS Keychain / Android EncryptedSharedPreferences 자동 통일.
- **❓ 미확인:** 왜 secure_storage 단일인가? 비민감 설정 저장 계획이 생기면 `shared_preferences`를 쓸 것인가, 아니면 의존성에서 제거 대상인가?
- **근거:** `lib/common/app_keys.dart`, `lib/util/helper/network_helper.dart`, `lib/view/splash/splash_view_model.dart`

### 2.2 네트워크 = Dio + 인터셉터 토큰 주입, 5초 타임아웃
- **결정(추론):** `dioProvider` 단일 인스턴스, 인터셉터에서 `accessToken`을 읽어 `Authorization: Bearer` 자동 주입. `http` 패키지는 미사용. connect/receive/send 타임아웃 5초.
- **추론한 이유:** 모든 API에 토큰을 수동 추가하지 않으려고 인터셉터로 중앙화. Dio가 인터셉터·타임아웃 통합 설정에 유리.
- **❓ 미확인:** 5초 타임아웃은 의도한 값인가, 임시값인가? `http` 패키지는 제거 대상인가?
- **근거:** `lib/util/helper/network_helper.dart` (`dioProvider`)

### 2.3 라우팅 go_router 미채택 (ADR 0002 보강)
- **결정:** [ADR 0002](adr/0002-routing-named-routes.md)로 확정됨.
- **❓ 추론 보강:** 라우트 수가 적고(~6개) 의존성 추가 비용 > 편익이라 미채택한 것으로 추정. FCM 딥링크는 `navigatorKey`로 충분. — ADR 본문에 이 "왜"가 충분한지 확인 필요.

### 2.4 코드생성 = freezed 부분 도입
- **결정(추론):** 큰 API 응답 모델은 freezed(`repository/response/*`), 단순/구형 도메인 모델은 수동 class(`model/*`). [ADR 0004]가 "freezed로 통일" 방향 제시.
- **추론한 이유:** 복잡한 응답부터 freezed로 불변성·직렬화 자동화. 단순 모델은 비용 대비 효과가 낮아 수동 유지.
- **❓ 미확인:** 전면 freezed 전환의 목표 시점·범위는? 아니면 "신규만 freezed, 구형은 방치" 유지인가?
- **근거:** `lib/repository/response/account_response.dart`(freezed) vs `lib/model/user.dart`(수동)

### 2.5 View=Feature-First / Data=Layer-First 혼합
- **결정(추론):** `view/`는 화면 단위 폴더(Feature-First), `repository/`·`service/`는 계층 단위(Layer-First).
- **추론한 이유:** View는 화면 응집(한 화면 = 한 폴더)이, 데이터는 도메인 응집이 유지보수에 유리하다는 판단.
- **❓ 미확인:** 의도적 설계인가, 자연 발생인가? — 의도라면 ADR 승격 후보.
- **근거:** `lib/view/<feature>/` 구조 vs `lib/repository/`·`lib/service/`

### 2.6 pubspec.yaml 런타임 패키지가 dev_dependencies에 배치
- **현상:** 런타임 패키지 다수(flutter_riverpod, http, shared_preferences, flutter_svg, permission_handler, image_picker 등)가 `dev_dependencies`에 위치. `flutter pub get`은 통과.
- **❓ 미확인:** 의도인가 실수인가? (실수로 추정) 정리(=`dependencies`로 이동) 대상인가?
- **근거:** `pubspec.yaml`

### 2.7 Riverpod 컨테이너 수동 생성 + UncontrolledProviderScope ✅ 확정
- **결정:** `runApp` 전에 `ProviderContainer()`를 직접 만들어 FCM을 초기화하고, 그 컨테이너를 `UncontrolledProviderScope`로 앱에 주입(일반 `ProviderScope` 미사용).
- **이유(확정):** 렌더링 전에 Provider(FCM 토큰·권한·리스너)를 초기화해야 함. 일반 `ProviderScope`를 쓰면 새 컨테이너가 생겨 초기화가 증발하므로, 동일 컨테이너를 주입하는 `UncontrolledProviderScope`가 필수.
- **근거:** `lib/main.dart` (`main()`의 `ProviderContainer`/`UncontrolledProviderScope`)

### 2.8 BaseView 제네릭 래퍼로 MVVM 보일러플레이트 통일
- **결정(추론):** `BaseView<VM, S>`가 `ref.watch(상태)` + `ref.read(notifier)` + 로딩 오버레이를 한 번에 처리하고, 각 화면은 `builder(ref, viewModel, state)` 콜백만 작성.
- **추론한 이유:** 화면마다 watch/read·Scaffold·로딩 처리를 반복하지 않으려는 의도. `state.isBusy` → `CircularIndicator`로 로딩 표시를 중앙화.
- **❓ 미확인:** 모든 신규 화면이 `BaseView`를 의무적으로 거쳐야 하는가, 아니면 권장인가? (현재 강제 장치 없음)
- **근거:** `lib/view/base_view.dart`, `lib/view/base_view_model.dart`(`AutoDisposeNotifier`)

### 2.9 전역 로딩 = EasyLoading (init builder)
- **결정(추론):** `MaterialApp(builder: EasyLoading.init())`로 전역 로딩 오버레이를 깔고, 화면 단위 로딩은 `BaseView`의 `CircularIndicator(isBusy:)`로 처리.
- **추론한 이유:** context 없이도 어디서든 로딩을 띄우기 위함. 두 로딩 메커니즘(EasyLoading 전역 / CircularIndicator 화면)이 공존.
- **❓ 미확인:** EasyLoading과 BaseView 로딩의 역할 구분 기준은? (전역 비동기 vs 화면 액션) 둘 중 하나로 통일할 계획이 있는가?
- **근거:** `lib/main.dart`(`EasyLoading.init()`), `lib/view/base_view.dart`(`CircularIndicator`)

### 2.10 전역 키(navigatorKey / scaffoldMessengerKey) — context 없는 제어 ✅ 확정
- **결정:** `MaterialApp`에 `navigatorKey`·`scaffoldMessengerKey`를 등록해 context 없이 네비게이션·스낵바를 제어. FCM 콜백(`fcm_service.dart`)이 이를 사용.
- **이유(확정):** FCM 메시지 핸들러는 위젯 트리 밖에서 실행돼 `BuildContext`가 없으므로 전역 키가 **반드시** 필요. 선택이 아닌 필연적 결정.
- **근거:** `lib/main.dart`, `lib/common/app_global.dart`, `lib/service/fcm_service.dart`

### 2.11 화면 공통 래핑 = ConstrainedScreen (반응형 maxWidth) ✅ 확정
- **결정:** `onGenerateRoute`가 모든 라우트를 `ConstrainedScreen`으로 감싸 최대 폭을 제약.
- **이유(확정):** 모바일 앱이지만 태블릿/넓은 화면에서 레이아웃이 과도하게 늘어나는 것을 방지하기 위함.
- **근거:** `lib/util/route_path.dart`(`onGenerateRoute`의 `ConstrainedScreen` 래핑)

---

## 3. 비즈니스 룰 / 도메인 규칙 (✍️ 사용자가 한 줄씩)

코드만으로는 알 수 없는 **도메인 진실**. 기억나는 대로 한 줄씩 추가하세요. (AI가 나중에 정리)

### 계좌 (Account)
- _(예: 계좌 상태 종류, 개설 제약, 계좌번호 규칙 등 — 비어 있음)_

### 송금 (Transfer)
- _(예: 한도, 검증 순서, 실패/취소 처리, 수수료 규칙 등 — 비어 있음)_

### 권한 (Authority)
- _(예: 권한 종류(full/info/check 등) 의미, 부여·회수 규칙 등 — 비어 있음)_

### 인증 / 세션
- _(예: 토큰 만료·갱신 정책, 자동 로그아웃 조건 등 — 비어 있음)_

### 기타 도메인
- _(비어 있음)_

---

## 4. 미분류 캡처 (✍️ 자유 메모)

형식 없이 일단 던지는 곳. 결정이든 룰이든 의문이든 한 줄씩 적어두면 AI가 위 섹션/ADR로 분류합니다.

- _(비어 있음)_
