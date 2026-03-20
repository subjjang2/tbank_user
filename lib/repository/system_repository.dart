import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../util/helper/api_error_handler.dart';
import '../util/helper/app_exception.dart';
import '../util/helper/network_helper.dart'; // dioProvider 위치에 맞게 수정

// Provider 정의
final systemRepositoryProvider = Provider<SystemRepository>((ref) {
  return SystemRepository(ref.read(dioProvider));
});

class SystemRepository {
  final Dio _dio;
  const SystemRepository(this._dio);

  // GET /system/config
  Future<String?> getSystemConfig() async {
    try {
      final res = await _dio.get('/config/info');

        final bool isSuccess = res.data['success'] ?? false;


        if (isSuccess) {
          // 2. data 객체 파싱
          final data = res.data['data'];

          return data['transferFee'];
        }

      return null;
    } catch (e) {
      // ⚡️ 여기가 핵심: "무슨 에러든 에러 핸들러야 네가 해석해서 던져줘"
      throw ApiErrorHandler.parse(e);
    }
  }
}