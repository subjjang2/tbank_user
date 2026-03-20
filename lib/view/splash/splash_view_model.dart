import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../common/app_keys.dart';
import '../base_view_model.dart';
import 'splash_view_state.dart';
// User 모델과 AuthService가 필요하다면 import
import '../../../model/user.dart';


final splashViewModelProvider =
AutoDisposeNotifierProvider<SplashViewModel, SplashViewState>(
      () => SplashViewModel(),
);

class SplashViewModel extends BaseViewModel<SplashViewState> {
  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  @override
  SplashViewState build() {
    // 변경 1: 시작하자마자 isBusy를 true로 설정 (스플래시는 어차피 로딩 화면이므로)
    return const SplashViewState(isBusy: true, errorMessage: "", isError: false);
  }

  Future<bool> checkLoginStatus() async {
    // 변경 2: 여기서 state = ... (isBusy: true) 하는 코드를 삭제
    // state = state.copyWith(isBusy: true, errorMessage: null); <--- 삭제

    await Future.delayed(const Duration(seconds: 1));
    try {
      final token = await _storage.read(key: AppKeys.accessToken);

      // 로직 완료 후 isBusy를 false로 변경
      state = state.copyWith(isBusy: false, errorMessage: null);

      if (token != null) {
        return true;
      }
      return false;
    } catch (e) {
      // 에러 발생 시에도 상태 업데이트
      state = state.copyWith(isBusy: false, isError: true, errorMessage: e.toString());
      return false;
    }
  }
}