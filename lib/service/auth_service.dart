import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../common/app_keys.dart';
import '../model/user.dart';
import '../repository/auth_repository.dart';


final authServiceProvider = NotifierProvider<AuthService, User?>(AuthService.new);

class AuthService extends Notifier<User?> {
  @override
  User? build() => null;
  // 안전한 저장소 인스턴스 (토큰 관리용)
  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  //로그인
  Future<bool> login(String id, String password) async {
    try {
      // 1. 리포지토리 호출
      // (성공 시: { 'user': User객체, 'accessToken': '토큰문자열' } 리턴)
      // (실패 시: Repository 내부에서 에러 throw -> catch로 이동)
      final result = await ref.read(authRepositoryProvider).login(id: id, password: password, getFcmToken: '');

      final User user = result['user'];       // 이미 Repository에서 User 객체로 변환됨
      final String token = result['accessToken'];

      // 2. 안전한 저장소에 토큰 저장
      await _storage.write(key: AppKeys.accessToken, value: token);
      await _storage.write(key: AppKeys.userId, value: user.userId); // 자동 로그인용

      // 3. 상태 업데이트 (로그인 성공 상태로 변경)
      state = user;

      return true; // UI에 성공 알림

    } catch (e) {
      // 4. 실패 처리
      // (Repository에서 던진 AppException 메시지가 e에 담겨있음)
      print("로그인 실패: $e");

      // 필요하다면 state를 초기화하거나 에러 상태로 변경
      // state = null;

      return false; // UI에 실패 알림
    }
  }


  // 1. 인증코드 전송
  Future<String?> sendVerificationCode(String email) async {
    try {
      await ref.read(authRepositoryProvider).sendVerificationCode(email);
      return null; // 성공 시 null 반환
    } catch (e) {
      return e.toString(); // 에러 메시지 반환
    }
  }

  // 2. 인증코드 확인
  Future<String?> verifyEmailCode(String email, String code) async {
    try {
      await ref.read(authRepositoryProvider).verifyEmailCode(email, code);
      return null; // 성공
    } catch (e) {
      return e.toString();
    }
  }


  // [회원가입]
  // ✨ 리턴 타입 수정: Map -> String?
  Future<String?> signup({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String accountName,
    required bool isAuditorAllowed,
  }) async {
    try {
      // Repository 호출 (메서드명이 register라면 register로 호출)
      await ref.read(authRepositoryProvider).signup(
        userId: userId,
        name: name,
        email: email,
        password: password,
        accountName: accountName,
        isAuditorAllowed: isAuditorAllowed,
      );

      return null; // ✅ 성공 (에러 없음)
    } catch (e) {
      // ❌ 실패 (에러 메시지 반환)
      return e.toString();
    }
  }

  // 로그아웃
  void logout() {
    state = null;
  }
}