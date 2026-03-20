import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/view/login/login_view_state.dart';

// =============================================================================
// LoginViewState 단위 테스트
//
// 커버 항목:
//  - 생성자: 필수 필드 정상 할당 검증
//  - copyWith: 각 필드의 선택적 교체 및 불변성 검증
//  - 초기 상태 값 검증 (ViewModel의 build() 기본값 기준)
// =============================================================================
void main() {
  group('LoginViewState', () {
    // -------------------------------------------------------------------------
    // 생성자 테스트
    // -------------------------------------------------------------------------
    group('constructor', () {
      test('모든 필드가 지정한 값으로 생성된다', () {
        const state = LoginViewState(
          isBusy: true,
          isError: true,
          errorMessage: '오류 메시지',
        );

        expect(state.isBusy, isTrue);
        expect(state.isError, isTrue);
        expect(state.errorMessage, '오류 메시지');
      });

      test('isBusy=false, isError=false, errorMessage 빈 문자열로 초기 상태 생성', () {
        const state = LoginViewState(
          isBusy: false,
          isError: false,
          errorMessage: '',
        );

        expect(state.isBusy, isFalse);
        expect(state.isError, isFalse);
        expect(state.errorMessage, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // copyWith 테스트
    // -------------------------------------------------------------------------
    group('copyWith', () {
      const baseState = LoginViewState(
        isBusy: false,
        isError: false,
        errorMessage: '',
      );

      test('isBusy만 교체하면 나머지 필드는 기존 값 유지', () {
        final updated = baseState.copyWith(isBusy: true);

        expect(updated.isBusy, isTrue);
        expect(updated.isError, isFalse);   // 기존 값 유지
        expect(updated.errorMessage, '');   // 기존 값 유지
      });

      test('isError만 교체하면 나머지 필드는 기존 값 유지', () {
        final updated = baseState.copyWith(isError: true);

        expect(updated.isBusy, isFalse);    // 기존 값 유지
        expect(updated.isError, isTrue);
        expect(updated.errorMessage, '');   // 기존 값 유지
      });

      test('errorMessage만 교체하면 나머지 필드는 기존 값 유지', () {
        final updated = baseState.copyWith(errorMessage: '아이디 비밀번호를 모두 입력해주세요.');

        expect(updated.isBusy, isFalse);    // 기존 값 유지
        expect(updated.isError, isFalse);   // 기존 값 유지
        expect(updated.errorMessage, '아이디 비밀번호를 모두 입력해주세요.');
      });

      test('모든 필드를 동시에 교체할 수 있다', () {
        final updated = baseState.copyWith(
          isBusy: true,
          isError: true,
          errorMessage: '알 수 없는 오류',
        );

        expect(updated.isBusy, isTrue);
        expect(updated.isError, isTrue);
        expect(updated.errorMessage, '알 수 없는 오류');
      });

      test('인자 없이 호출하면 모든 필드가 기존 값 그대로 유지된다', () {
        const original = LoginViewState(
          isBusy: true,
          isError: true,
          errorMessage: '기존 메시지',
        );
        final copy = original.copyWith();

        expect(copy.isBusy, isTrue);
        expect(copy.isError, isTrue);
        expect(copy.errorMessage, '기존 메시지');
      });

      test('copyWith 결과는 원본 객체와 다른 인스턴스이다 (불변성)', () {
        final updated = baseState.copyWith(isBusy: true);
        // 원본이 변경되지 않아야 한다
        expect(baseState.isBusy, isFalse);
        // 복사본은 새 인스턴스
        expect(identical(baseState, updated), isFalse);
      });

      test('errorMessage를 빈 문자열로 초기화할 수 있다', () {
        const errorState = LoginViewState(
          isBusy: false,
          isError: true,
          errorMessage: '이전 오류',
        );
        final cleared = errorState.copyWith(
          isError: false,
          errorMessage: '',
        );

        expect(cleared.isError, isFalse);
        expect(cleared.errorMessage, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // 상태 전이 시나리오 테스트
    // -------------------------------------------------------------------------
    group('상태 전이 시나리오', () {
      test('초기 상태 -> 로딩 상태로 전이', () {
        const initial = LoginViewState(
          isBusy: false,
          isError: false,
          errorMessage: '',
        );
        final loading = initial.copyWith(isBusy: true);

        expect(loading.isBusy, isTrue);
        expect(loading.isError, isFalse);
        expect(loading.errorMessage, isEmpty);
      });

      test('로딩 상태 -> 에러 상태로 전이', () {
        const loading = LoginViewState(
          isBusy: true,
          isError: false,
          errorMessage: '',
        );
        final error = loading.copyWith(
          isBusy: false,
          isError: true,
          errorMessage: '아이디 비밀번호를 모두 입력해주세요.',
        );

        expect(error.isBusy, isFalse);
        expect(error.isError, isTrue);
        expect(error.errorMessage, '아이디 비밀번호를 모두 입력해주세요.');
      });

      test('에러 상태 -> 초기 상태로 재설정', () {
        const error = LoginViewState(
          isBusy: false,
          isError: true,
          errorMessage: '로그인 실패',
        );
        const reset = LoginViewState(
          isBusy: false,
          isError: false,
          errorMessage: '',
        );

        expect(reset.isBusy, isFalse);
        expect(reset.isError, isFalse);
        expect(reset.errorMessage, isEmpty);
      });
    });
  });
}
