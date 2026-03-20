import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/auth_repository.dart';
import '../base_view_model.dart';
import 'register_view_state.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// AutoDisposeNotifierProvider:
// 회원가입 화면을 벗어나면(pop), 입력했던 데이터나 상태를 메모리에서 제거(초기화)합니다.
// 다시 들어오면 깨끗한 상태로 시작할 수 있습니다.
final registerViewModelProvider =
AutoDisposeNotifierProvider<RegisterViewModel, RegisterViewState>(
      () => RegisterViewModel(),
);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class RegisterViewModel extends BaseViewModel<RegisterViewState> {

  @override
  RegisterViewState build() {
    // 초기 상태 설정 (로딩 X, 에러 X, 감찰 동의 false 등)
    return const RegisterViewState(isBusy: false, isError: false, errorMessage: '');
  }

  // ---------------------------------------------------------------------------
  // [UI 로직] 감찰 동의 체크박스 토글
  // ---------------------------------------------------------------------------
  void toggleAuditorAllowed(bool? value) {
    if (value != null) {
      // 상태 불변성 유지하며 값 업데이트 (copyWith)
      state = state.copyWith(isAuditorAllowed: value);
    }
  }

  // ---------------------------------------------------------------------------
  // [API 로직] 이메일 인증 코드 전송 (현재는 미구현/Placeholder)
  // ---------------------------------------------------------------------------
  Future<String?> sendVerificationCode(String email) async {
    // 추후 구현: '/auth/send-code' API 호출
    // 현재는 바로 null(성공) 반환
    return null;
  }

  // [API 로직] 이메일 인증 코드 확인 (현재는 미구현/Placeholder)
  Future verifyEmailCode(String email, String code) async {
    // 추후 구현: '/auth/verify-code' API 호출
  }

  // ---------------------------------------------------------------------------
  // [핵심 로직] 최종 회원가입 요청
  // ---------------------------------------------------------------------------
  // 반환값: 성공 시 null, 실패 시 에러 메시지(String) 반환
  // View에서는 이 반환값을 보고 화면 이동 or 에러 팝업을 결정합니다.
  Future<String?> signup({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String accountName,
  }) async {
    try {
      // 1. 로딩 시작 (버튼 비활성화)
      state = state.copyWith(
        isBusy: true,
      );

      // 2. Repository 호출 (서버 통신)
      // state.isAuditorAllowed(체크박스 값)도 함께 전송
      await ref.read(authRepositoryProvider).signup(
        userId: userId,
        name: name,
        email: email,
        password: password,
        accountName: accountName,
        isAuditorAllowed: state.isAuditorAllowed,
      );

      // 3. 로딩 종료
      state = state.copyWith(
        isBusy: false,
      );

      return null; // ✅ 성공 (View에서 로그인 화면으로 이동)

    } catch (e) {
      // 4. 에러 발생 시 처리
      state = state.copyWith(
        isBusy: false,
      );

      // ❌ 실패 메시지 반환 (View에서 알림창 표시)
      return e.toString();
    }
  }
}