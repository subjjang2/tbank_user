import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/repository/response/authority/account_authority_response.dart';
import 'package:tbank_user/util/app_config.dart';


import '../model/user_profile_model.dart';
import '../util/helper/api_error_handler.dart';
import '../util/helper/app_exception.dart';
import '../util/helper/network_helper.dart';

// =============================================================================
// 1. Provider 설정
// =============================================================================
// 앱 전역에서 AccountRepository를 사용할 수 있도록 의존성을 주입합니다.
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.read(dioProvider));
});

// =============================================================================
// 2. Repository 클래스
// =============================================================================
class AccountRepository {
  final Dio _dio;

  const AccountRepository(this._dio);

  // ---------------------------------------------------------------------------
  // [API] 내 프로필 조회
  // GET /users/me
  // ---------------------------------------------------------------------------
  Future<UserProfileModel> getMyProfile() async {
    try {
      final response = await _dio.get('/users/me');
      final dynamic responseBody = response.data;

      return UserProfileModel.fromJson(responseBody['data']);
    } catch (e) {
      // ⚡️ 공통 에러 핸들러: 서버 에러 메시지 파싱
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 공유 계좌 목록 조회 (이체 가능 권한)
  // GET /accounts/accessible
  // ---------------------------------------------------------------------------
  Future<AccountResponse> getAccessibleAccounts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/accounts/accessible',
        queryParameters: {
          'page': page,
          'limit': AppConfig.defaultLimit,
        },
      );
      final dynamic responseBody = response.data;
      return AccountResponse.fromJson(responseBody['data']);
    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 조회 전용 계좌 목록 조회 (감찰/조회 권한)
  // GET /accounts/viewer
  // ---------------------------------------------------------------------------
  Future<AccountResponse> getViewerAccounts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/accounts/viewer',
        queryParameters: {
          'page': page,
          'limit': AppConfig.defaultLimit,
        },
      );
      final dynamic responseBody = response.data;
      return AccountResponse.fromJson(responseBody['data']);
    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 권한 변경 요청 (감찰 설정 및 사용자 권한 수정)
  // POST /accounts/permissions/request
  // ---------------------------------------------------------------------------
  Future<void> requestPermissionChange({
    required String targetAccountNo,
    required bool auditEnabled,
    required List<Permission> permissions,
  }) async {
    try {
      // 1. DTO 매핑: Permission 객체 -> Map 변환
      final permissionList = permissions.map((p) =>
      {
        "userId": p.userId,
        "type": p.type,
      }).toList();

      // 2. API 전송
      await _dio.post(
        '/accounts/permissions/request',
        data: {
          "targetAccountNo": targetAccountNo,
          "auditEnabled": auditEnabled,
          "permissions": permissionList,
        },
      );

    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 권한 부여를 위한 사용자 검색
  // GET /users/search
  // ---------------------------------------------------------------------------
  Future<User?> searchUserForPermission(String userId) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'userId': userId},
      );
      final responseBody = response.data;
      return User.fromJson(responseBody['data']);

    } on DioException catch (e) {
      // ✨ 404(User Not Found)는 에러가 아니라 '결과 없음(null)'으로 처리
      if (e.response?.statusCode == 404) {
        return null;
      }
      // 그 외 에러는 예외 던짐
      throw ApiErrorHandler.parse(e);
    } catch (e) {
      throw AppException("데이터 처리 중 오류가 발생했습니다.");
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 특정 계좌의 현재 권한 설정 조회
  // GET /accounts/{accountNumber}/permissions
  // ---------------------------------------------------------------------------
  Future<AccountAuthorityResponse> getPermissions({required String accountNumber}) async {
    try {
      final response = await _dio.get(
        '/accounts/$accountNumber/permissions',
        queryParameters: {'accountNumber': accountNumber},
      );

      final responseBody = response.data;
      return AccountAuthorityResponse.fromJson(responseBody['data']);
    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 신규 개인 계좌 개설 신청
  // POST /accounts/createPersonal
  // ---------------------------------------------------------------------------
  Future<void> createPersonalAccount({
    required String accountName,
    required bool isAuditorAllowed,
  }) async {
    try {
      await _dio.post(
        '/accounts/createPersonal',
        data: {
          'accountName': accountName,
          'isAuditorAllowed': isAuditorAllowed,
        },
      );
    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }

  // ---------------------------------------------------------------------------
  // [API] 내 보유 계좌 목록 조회 (페이징)
  // GET /accounts/accountList
  // ---------------------------------------------------------------------------
  Future<AccountResponse> fetchMyAccounts({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/accounts/accountList',
        queryParameters: {
          'page': page,
          'limit': AppConfig.defaultLimit,
        },
      );
      final dynamic responseBody = response.data;
      return AccountResponse.fromJson(responseBody['data']);

    } catch (e) {
      throw ApiErrorHandler.parse(e);
    }
  }
}