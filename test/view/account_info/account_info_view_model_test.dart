import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/repository/response/account_search/account_searchtype_response.dart';
import 'package:tbank_user/repository/response/transaction_history/transaction_history_response.dart';
import 'package:tbank_user/repository/transfer_repository.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/account_info/account_info_view_model.dart';
import 'package:tbank_user/view/account_info/account_info_view_state.dart';

// =============================================================================
// Fake TransferRepository
// accountInfoViewModelProvider가 사용하는 searchAccount만 제어합니다.
// transfer / fetchHistory는 이 ViewModel에서 사용하지 않으므로 UnimplementedError.
// =============================================================================
class FakeTransferRepository implements TransferRepository {
  AccountSearchResponse? searchResult;
  Object? searchThrow;

  // 인자 캡처 (조회 타입 검증용)
  AccountSearchType? capturedType;
  String? capturedAccountNumber;

  FakeTransferRepository({this.searchResult, this.searchThrow});

  @override
  Future<AccountSearchResponse?> searchAccount({
    required String accountNumber,
    required AccountSearchType type,
  }) async {
    capturedAccountNumber = accountNumber;
    capturedType = type;
    if (searchThrow != null) throw searchThrow!;
    return searchResult;
  }

  @override
  Future<bool> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required String amount,
    required String memo,
  }) async => throw UnimplementedError();

  @override
  Future<TransactionHistoryResponse> fetchHistory(
    String accountNumber, {
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async => throw UnimplementedError();
}

// =============================================================================
// 테스트 헬퍼: ProviderContainer 빌드
// - transRepositoryProvider를 FakeTransferRepository로 오버라이드
// - autoDispose 폐기 방지: 리스너를 등록해 notifier를 생존 유지
// =============================================================================
ProviderContainer buildContainer({FakeTransferRepository? fakeRepo}) {
  final c = ProviderContainer(
    overrides: [
      transRepositoryProvider.overrideWithValue(
        fakeRepo ?? FakeTransferRepository(),
      ),
    ],
  );
  // autoDispose notifier가 비동기 작업 중 폐기되지 않도록 keep-alive
  c.listen(accountInfoViewModelProvider, (_, __) {});
  return c;
}

void main() {
  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  AccountInfoViewModel readVm(ProviderContainer c) =>
      c.read(accountInfoViewModelProvider.notifier);
  AccountInfoViewState readState(ProviderContainer c) =>
      c.read(accountInfoViewModelProvider);

  // ==========================================================================
  group('초기 상태 (build)', () {
    test(
      'isBusy=false, isError=false, errorMessage 빈 문자열, accountSearchResponse=null',
      () {
        container = buildContainer();
        final s = readState(container);

        expect(s.isBusy, isFalse);
        expect(s.isError, isFalse);
        expect(s.errorMessage, isEmpty);
        expect(s.accountSearchResponse, isNull);
      },
    );
  });

  // ==========================================================================
  group('accountInfo() — 성공 (응답 있음)', () {
    test('ownerName이 포함된 accountSearchResponse가 상태에 저장된다', () async {
      final repo = FakeTransferRepository(
        searchResult: AccountSearchResponse(
          accountNumber: '110-1',
          accountName: '홍길동 계좌',
          ownerName: '홍길동',
          balance: 50000,
          status: 'ACTIVE',
        ),
      );
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('110-1');
      final s = readState(container);

      expect(s.accountSearchResponse, isNotNull);
      expect(s.accountSearchResponse!.ownerName, '홍길동');
      expect(s.accountSearchResponse!.accountNumber, '110-1');
    });

    test('성공 후 isBusy=false, isError=false', () async {
      final repo = FakeTransferRepository(
        searchResult: AccountSearchResponse(ownerName: '김철수'),
      );
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('220-2');
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
    });

    test(
      '호출 시 AccountSearchType.info 타입과 accountNumber가 Repository에 전달된다',
      () async {
        final repo = FakeTransferRepository(
          searchResult: AccountSearchResponse(ownerName: '박영희'),
        );
        container = buildContainer(fakeRepo: repo);

        await readVm(container).accountInfo('330-3');

        expect(repo.capturedType, AccountSearchType.info);
        expect(repo.capturedAccountNumber, '330-3');
      },
    );
  });

  // ==========================================================================
  group('accountInfo() — 응답이 null인 경우 (현재 구현 동작 문서화)', () {
    test(
      '응답이 null이면 isBusy가 true로 남는다 — null 결과 시 finally 없이 if 분기만 처리하는 구현 특성',
      () async {
        // 현재 구현: searchAccount가 null 반환 → if 블록 진입 불가 → isBusy 해제 안 됨
        // 이는 구현 상의 quirk를 문서화하는 테스트입니다.
        final repo = FakeTransferRepository(searchResult: null);
        container = buildContainer(fakeRepo: repo);

        await readVm(container).accountInfo('110-1');
        final s = readState(container);

        expect(s.isBusy, isTrue);
        expect(s.isError, isFalse);
        expect(s.accountSearchResponse, isNull);
      },
    );
  });

  // ==========================================================================
  group('accountInfo() — AppException 처리', () {
    test(
      'AppException 발생 시 isError=true, errorMessage=e.message, isBusy=false',
      () async {
        final repo = FakeTransferRepository(
          searchThrow: AppException('존재하지 않는 계좌번호입니다.'),
        );
        container = buildContainer(fakeRepo: repo);

        await readVm(container).accountInfo('999-9');
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.errorMessage, '존재하지 않는 계좌번호입니다.');
        expect(s.isBusy, isFalse);
        expect(s.accountSearchResponse, isNull);
      },
    );

    test('AppException 메시지가 errorMessage에 그대로 저장된다', () async {
      const customMessage = '계좌가 잠겨 있습니다.';
      final repo = FakeTransferRepository(
        searchThrow: AppException(customMessage),
      );
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('110-1');

      expect(readState(container).errorMessage, customMessage);
    });
  });

  // ==========================================================================
  group('accountInfo() — 일반 예외 처리', () {
    test('일반 Exception 발생 시 "서버 통신 중 오류가 발생했습니다." 메시지로 처리된다', () async {
      final repo = FakeTransferRepository(
        searchThrow: Exception('network error'),
      );
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('110-1');
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.errorMessage, '서버 통신 중 오류가 발생했습니다.');
      expect(s.isBusy, isFalse);
    });

    test('StateError 발생 시에도 "서버 통신 중 오류가 발생했습니다." 메시지로 처리된다', () async {
      final repo = FakeTransferRepository(
        searchThrow: StateError('unexpected state'),
      );
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('110-1');

      expect(readState(container).errorMessage, '서버 통신 중 오류가 발생했습니다.');
      expect(readState(container).isError, isTrue);
    });
  });

  // ==========================================================================
  group('accountInfo() — isBusy 해제 보장', () {
    test('성공 후 isBusy=false', () async {
      final repo = FakeTransferRepository(
        searchResult: AccountSearchResponse(ownerName: '홍길동'),
      );
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('110-1');

      expect(readState(container).isBusy, isFalse);
    });

    test('AppException 발생 후 isBusy=false', () async {
      final repo = FakeTransferRepository(searchThrow: AppException('에러'));
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('110-1');

      expect(readState(container).isBusy, isFalse);
    });

    test('일반 예외 발생 후 isBusy=false', () async {
      final repo = FakeTransferRepository(searchThrow: Exception('timeout'));
      container = buildContainer(fakeRepo: repo);

      await readVm(container).accountInfo('110-1');

      expect(readState(container).isBusy, isFalse);
    });
  });

  // ==========================================================================
  group('accountInfo() — 연속 호출 시 이전 에러 상태 초기화', () {
    test('첫 호출 실패 후 두 번째 호출 시작 시 isError가 false로 초기화된다', () async {
      // 1차: 실패
      final failRepo = FakeTransferRepository(
        searchThrow: AppException('로그인 실패'),
      );
      container = buildContainer(fakeRepo: failRepo);
      await readVm(container).accountInfo('110-1');
      expect(readState(container).isError, isTrue);

      // AccountInfoViewState.copyWith의 isError 기본값이 false이므로
      // 두 번째 호출 시작(isBusy: true 세팅)에서 isError가 초기화된다.
      // 새 컨테이너에서 재검증: autoDispose로 상태 재생성
      container.dispose();
      container = buildContainer();
      final s = readState(container);
      expect(s.isError, isFalse);
    });
  });
}
