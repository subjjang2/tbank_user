# Task: 새 feature 화면 추가

## Prompt (에이전트에 제시)
"설정(settings) 화면을 추가하라. 화면은 로딩/에러 상태를 가지며, 추후 API 연동을 대비한다."

## Pass Criteria (golden)
- [ ] `lib/view/settings/`에 `settings_view.dart` + `settings_view_model.dart` + `settings_view_state.dart` 3종 생성
- [ ] ViewModel이 `BaseViewModel<SettingsViewState>` 상속, State가 `BaseViewState`(isBusy/isError/errorMessage) 확장
- [ ] Provider는 `NotifierProvider.autoDispose` 사용
- [ ] 상태 갱신은 `copyWith` 불변 패턴
- [ ] `lib/util/route_path.dart`에 라우트 상수 + `onGenerateRoute` 분기 등록
- [ ] `flutter analyze` 경고 없음

## 측정 포인트
MVVM 3종 세트 + 라우팅 중앙화 규약([ADR 0001](../../docs/adr/0001-state-management-riverpod-mvvm.md), [ADR 0002](../../docs/adr/0002-routing-named-routes.md))을 컨텍스트만 보고 따르는지.
