import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

// =============================================================================
// Repository 단위 테스트용 Dio Mock 헬퍼
//
// 실제 네트워크 없이 Dio의 httpClientAdapter만 교체하여, Repository 코드 경로
// (응답 파싱 + ApiErrorHandler.parse 전체)를 그대로 실행시킨다.
//
// - 성공/에러 상태코드: handler가 MockReply 반환 → Dio가 validateStatus로 판단
//   (4xx/5xx는 DioException(type: badResponse, response: ...)로 throw됨)
// - 타임아웃/연결에러: handler 안에서 DioException을 직접 throw하면 그대로 전파됨
// =============================================================================

/// handler가 반환하는 가짜 응답.
class MockReply {
  final int statusCode;

  /// Map/List/String 등 — JSON 인코딩되어 응답 본문이 된다.
  final dynamic data;

  MockReply(this.statusCode, this.data);
}

/// 요청을 받아 응답(MockReply)을 결정하거나 DioException을 throw하는 함수.
typedef MockHandler = MockReply Function(RequestOptions options);

class _MockAdapter implements HttpClientAdapter {
  final MockHandler handler;

  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // handler가 throw하면(DioException 등) Dio가 그대로 전파한다.
    final reply = handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.data),
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// [handler]로 응답을 제어하는 테스트용 Dio를 생성한다.
Dio buildMockDio(MockHandler handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.httpClientAdapter = _MockAdapter(handler);
  return dio;
}

/// 지정한 [type]의 DioException을 던지는 handler를 만든다. (타임아웃/연결에러 시뮬레이션)
MockHandler throwsDioType(DioExceptionType type) =>
    (options) => throw DioException(requestOptions: options, type: type);

/// [statusCode] + [body]로 에러 응답(badResponse)을 내는 handler를 만든다.
/// Dio가 4xx/5xx를 DioException으로 변환하므로, 단순히 그 상태코드를 반환하면 된다.
MockHandler respondsWith(int statusCode, dynamic body) =>
    (options) => MockReply(statusCode, body);
