import 'package:dio/dio.dart';
import 'app_exception.dart';

class ApiErrorHandler {
  static AppException parse(Object e) {
    if (e is DioException) {

      // 🚨 1. [가장 중요] 서버 응답(Response) 자체가 없는 경우 먼저 처리
      // (와이파이 꺼짐, 서버 다운, IP 틀림, 시간 초과 등)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AppException("서버 연결 시간이 초과되었습니다.\n인터넷 상태를 확인해주세요.");
      }

      if (e.type == DioExceptionType.connectionError) {
        // 아예 연결 시도조차 실패한 경우 (서버 꺼짐, 주소 틀림, 비행기 모드 등)
        return AppException("서버와 연결할 수 없습니다.\n(네트워크 상태 또는 서버 점검 중)");
      }

      if (e.type == DioExceptionType.cancel) {
        return AppException("요청이 취소되었습니다.");
      }

      // -----------------------------------------------------------
      // ✅ 2. 서버가 응답은 줬는데, 에러 상태코드(4xx, 5xx)인 경우
      // -----------------------------------------------------------
      if (e.response != null) {
        // (1) 서버가 보낸 커스텀 에러 메시지("잔액 부족" 등) 확인
        String? serverMessage;
        try {
          final data = e.response!.data;
          if (data is Map<String, dynamic>) {
            if (data['message'] != null) {
              serverMessage = data['message'].toString();
            } else if (data['error'] != null) {
              serverMessage = data['error'].toString();
            }
          } else if (data is String) {
            serverMessage = data;
          }
        } catch (_) {}

        if (serverMessage != null && serverMessage.isNotEmpty) {
          return AppException(serverMessage);
        }

        // (2) 메시지가 없으면 상태 코드별 기본 문구
        switch (e.response!.statusCode) {
          case 400: return AppException("잘못된 요청입니다.");
          case 401: return AppException("로그인 정보가 만료되었습니다.\n다시 로그인해주세요.");
          case 403: return AppException("접근 권한이 없습니다.");
          case 404: return AppException("요청한 주소를 찾을 수 없습니다.");
          case 409: return AppException("이미 처리된 요청이거나 데이터가 존재합니다.");
          case 500: return AppException("서버 내부 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.");
          case 503: return AppException("서버 점검 중입니다.");
          default: return AppException("응답 오류 (${e.response!.statusCode})");
        }
      }
    }

    // Dio 에러가 아닌 코드 내부 에러 등
    if (e is AppException) return e;

    // 진짜 원인을 알 수 없는 경우 (로그에는 찍히게 e.toString() 포함 추천)
    return AppException("알 수 없는 오류가 발생했습니다.\n($e)");
  }
}