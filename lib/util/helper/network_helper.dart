import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_config.dart';
import '../../common/app_keys.dart';



// Dio Provider 정의
final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: AppConfig.baseUrl, // 설정된 주소 사용
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    sendTimeout: const Duration(seconds: 5),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  // 인터셉터 추가
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
    if (kDebugMode) {
      print('🚀 [Request] Path: ${options.path}');
    }

    // 2. 스토리지에서 토큰 읽기 시도
    try {
      final token = await storage.read(key: AppKeys.accessToken);

      // 3. 토큰 상태 확인
      if (token == null) {
        if (kDebugMode) {
          print('❌ [Error] 토큰이 NULL입니다! (저장된 토큰 없음 or 읽기 실패)');
        }
      } else {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 [Critical] 스토리지 읽기 에러 발생: $e');
      }
    }

    return handler.next(options);
  },

    onError: (DioException e, handler) {
      // 에러 로깅 (상태 코드만, 응답 바디는 민감 정보라 제외)
      if (kDebugMode) {
        print('API Error: ${e.response?.statusCode}');
      }
      return handler.next(e);
    },
  ));

  return dio;
});

// (하위 호환성을 위해 ApiClient 클래스 유지 또는 삭제 가능)
// 여기서는 Provider를 직접 쓰는 것을 권장하므로 ApiClient 클래스는 제거하거나
// dioProvider를 감싸는 형태로 변경할 수 있습니다.
// T-Bank 아키텍처에서는 Repository가 dioProvider를 ref.read로 읽어서 사용합니다.