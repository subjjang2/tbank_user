import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/user.dart';
import '../util/helper/api_error_handler.dart';
import '../util/helper/app_exception.dart';
import '../util/helper/network_helper.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// 앱 전역에서 AuthRepository를 사용할 수 있도록 제공합니다. (Dio 주입)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

// =============================================================================
// 2. Repository 클래스
// =============================================================================
class AuthRepository {
  final Dio _dio;
  const AuthRepository(this._dio);

  // ---------------------------------------------------------------------------
  // [기능] 이메일 인증 관련
  // ---------------------------------------------------------------------------

  // 1. 인증코드 발송 요청
  Future<void> sendVerificationCode(String email) async {
    await _dio.post('/auth/send-code', data: {'email': email});
  }

  // 2. 인증코드 검증 요청
  Future<void> verifyEmailCode(String email, String code) async {
    await _dio.post('/auth/verify-code', data: {'email': email, 'code': code});
  }

  // ---------------------------------------------------------------------------
  // [기능] 회원가입
  // 사용자 정보 + 초기 계좌 정보 + 감찰 동의 여부를 전송합니다.
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> signup({
    required String userId,
    required String name,
    required String email,
    required String password,
    required String accountName,
    required bool isAuditorAllowed,
  }) async {
    try {
      final res = await _dio.post('/users/signup', data: {
        'userId': userId,
        'name': name,
        'email': email,
        'password': password,
        'accountName': accountName,
        'isAuditorAllowed': isAuditorAllowed,
      });

      // 응답 구조: { success: true, message: "...", data: { ... } }
      // 실질적인 데이터인 'data' 객체를 반환합니다.
      return res.data['data'];

    } catch (e) {
      // 공통 에러 핸들러를 통해 서버 에러 메시지를 파싱하여 던짐
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [기능] 로그인
  // 아이디/비번 + 푸시 알림용 FCM 토큰을 함께 전송합니다.
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String id,
    required String password,
    required String getFcmToken
  }) async {
    try {
      final res = await _dio.post(
        '/users/login',
        data: {'userId': id, 'password': password, 'fcmToken': getFcmToken},
      );

      // 1. HTTP 상태 코드 확인
      if (res.statusCode == 200 || res.statusCode == 201) {
        final responseBody = res.data;

        // 2. API 응답의 success 플래그 확인
        if (responseBody['success'] == true) {
          final realData = responseBody['data'];

          // 3. User 객체 변환 및 토큰 반환
          return {
            'user': User.fromJson(realData['user']), // 사용자 정보 객체화
            'accessToken': realData['accessToken'],  // JWT 토큰
          };
        }
      }

      // 성공 응답이 아닐 경우 예외 발생
      throw AppException("서버 응답이 올바르지 않습니다.");

    } catch (e) {
      // 에러 파싱 및 전달
      throw ApiErrorHandler.parse(e);
    }
  }
}