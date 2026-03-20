import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../common/app_keys.dart';
import '../../model/user.dart';
import '../../repository/auth_repository.dart';

import '../../service/fcm_service.dart';
import '../../theme/toast/toast.dart';
import '../../util/helper/app_exception.dart';
import '../../util/route_path.dart';
import '../base_view_model.dart';
import 'login_view_state.dart';


// =============================================================================
// 1. Provider 설정
// =============================================================================
// autoDispose: 로그인 화면을 나가면 상태를 초기화하여, 보안을 강화하고 메모리를 절약합니다.
final loginViewModelProvider =
NotifierProvider.autoDispose<LoginViewModel, LoginViewState>(
    LoginViewModel.new);

// =============================================================================
// 2. ViewModel 클래스
// =============================================================================
class LoginViewModel extends BaseViewModel<LoginViewState> {
  @override
  LoginViewState build() => const LoginViewState(isBusy: false, isError: false, errorMessage: "");

  // ---------------------------------------------------------------------------
  // [기능] 로그인 요청
  // ---------------------------------------------------------------------------
  Future<bool> login({required String id, required String password}) async {
    // 1. 로딩 시작 & 상태 초기화
    state = const LoginViewState(isBusy: true, errorMessage: "", isError: false);

    // 보안 저장소(SecureStorage) 초기화
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
    );

    try {
      // 2. 유효성 검사 (빈 값 체크, trim 적용)
      if (id.trim().isEmpty || password.trim().isEmpty) {
        throw AppException("아이디 비밀번호를 모두 입력해주세요.");
      }

      // 3. FCM 토큰 가져오기 (푸시 알림 수신용)
      final token = ref.read(fcmTokenProvider);

      // 4. API 호출 (Repository에게 로그인 요청)
      final result = await ref.read(authRepositoryProvider).login(
        id: id,
        password: password,
        getFcmToken: token ?? "", // 토큰이 없으면 빈 문자열 전송
      );

      // 5. 로그인 성공 처리
      final User user = result['user'];
      final String accessToken = result['accessToken'];

      // (1) 중요 정보(토큰, ID, 이름)를 기기 내 보안 저장소에 저장
      // 앱을 재시작해도 로그인이 유지되도록 함
      await storage.write(key: AppKeys.accessToken, value: accessToken);
      await storage.write(key: AppKeys.userId, value: user.userId);
      await storage.write(key: AppKeys.userName, value: user.name);

      return true; // 성공 반환 (화면 이동 트리거)

    } on AppException catch (e) {
      // 6. 비즈니스 로직 에러 처리 (예: 아이디 없음, 비번 틀림)
      state = state.copyWith(errorMessage: e.message, isBusy: false, isError: true);
      return false;

    } catch (e) {
      // 7. 기타 시스템 에러 처리
      state = state.copyWith(errorMessage: "알 수 없는 오류가 발생했습니다.", isBusy: false, isError: true);
      return false;

    } finally {
      // 8. 로딩 종료 (안전 장치)
      if (state.isBusy) {
        state = state.copyWith(isBusy: false, isError: false);
      }
    }
  }
}