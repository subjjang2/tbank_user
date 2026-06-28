import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/repository/system_repository.dart';
import 'package:tbank_user/util/helper/app_exception.dart';

import 'mock_dio.dart';

// =============================================================================
// SystemRepository 단위 테스트
//
// 대상: getSystemConfig() — GET /config/info
//   - 응답 { success, data: { transferFee } } 에서 transferFee 추출
//   - success=false 또는 키 없음 → null
//   - 통신/HTTP 에러 → ApiErrorHandler.parse 경유 AppException throw
// =============================================================================
void main() {
  SystemRepository build(MockHandler handler) =>
      SystemRepository(buildMockDio(handler));

  group('getSystemConfig() — 정상 응답', () {
    test('success=true이면 data.transferFee를 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {
          'success': true,
          'data': {'transferFee': '500'},
        }),
      );

      final result = await repo.getSystemConfig();

      expect(result, '500');
    });

    test('요청 경로가 /config/info 이다', () async {
      String? calledPath;
      final repo = build((o) {
        calledPath = o.path;
        return MockReply(200, {
          'success': true,
          'data': {'transferFee': '0'},
        });
      });

      await repo.getSystemConfig();

      expect(calledPath, '/config/info');
    });
  });

  group('getSystemConfig() — null 반환 케이스', () {
    test('success=false이면 null을 반환한다', () async {
      final repo = build(
        (o) => MockReply(200, {
          'success': false,
          'data': {'transferFee': '500'},
        }),
      );

      expect(await repo.getSystemConfig(), isNull);
    });

    test('success 키가 없으면(기본 false) null을 반환한다', () async {
      final repo = build((o) => MockReply(200, {'data': {}}));

      expect(await repo.getSystemConfig(), isNull);
    });
  });

  group('getSystemConfig() — 에러 계약 (AppException throw)', () {
    test('500 응답이면 AppException을 throw한다', () async {
      final repo = build(respondsWith(500, {'message': null}));

      expect(() => repo.getSystemConfig(), throwsA(isA<AppException>()));
    });

    test('서버가 message를 주면 그 메시지로 AppException을 throw한다', () async {
      final repo = build(respondsWith(400, {'message': '설정을 불러올 수 없습니다.'}));

      await expectLater(
        repo.getSystemConfig(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            '설정을 불러올 수 없습니다.',
          ),
        ),
      );
    });

    test('연결 타임아웃이면 타임아웃 안내 메시지로 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionTimeout));

      await expectLater(
        repo.getSystemConfig(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('시간이 초과'),
          ),
        ),
      );
    });

    test('연결 실패(connectionError)면 서버 연결 불가 메시지로 throw한다', () async {
      final repo = build(throwsDioType(DioExceptionType.connectionError));

      await expectLater(
        repo.getSystemConfig(),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('연결할 수 없습니다'),
          ),
        ),
      );
    });
  });
}
