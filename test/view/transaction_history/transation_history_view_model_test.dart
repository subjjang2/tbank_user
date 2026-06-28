import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/model/transaction.dart';
import 'package:tbank_user/repository/response/account_search/account_searchtype_response.dart';
import 'package:tbank_user/repository/response/transation_history/transation_history_response.dart';
import 'package:tbank_user/repository/transfer_repository.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/transaction_history/transation_history_view_model.dart';
import 'package:tbank_user/view/transaction_history/transation_history_view_state.dart';

// =============================================================================
// Fake TransferRepository — fetchHistory만 제어 (+ 호출 인자/횟수 캡처)
// =============================================================================
class FakeTransferRepository implements TransferRepository {
  /// page별 응답. 없으면 defaultResponse 사용.
  Map<int, TransactionHistoryResponse> responsesByPage;
  TransactionHistoryResponse? defaultResponse;
  Object? throwError;

  // 캡처
  int callCount = 0;
  int? lastPage;
  DateTime? lastStartDate;
  DateTime? lastEndDate;

  FakeTransferRepository({
    Map<int, TransactionHistoryResponse>? responsesByPage,
    this.defaultResponse,
    this.throwError,
  }) : responsesByPage = responsesByPage ?? {};

  @override
  Future<TransactionHistoryResponse> fetchHistory(
    String accountNumber, {
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    callCount++;
    lastPage = page;
    lastStartDate = startDate;
    lastEndDate = endDate;
    if (throwError != null) throw throwError!;
    return responsesByPage[page] ?? defaultResponse ?? _emptyResponse();
  }

  @override
  Future<bool> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required String amount,
    required String memo,
  }) => throw UnimplementedError();

  @override
  Future<AccountSearchResponse?> searchAccount({
    required String accountNumber,
    required AccountSearchType type,
  }) => throw UnimplementedError();
}

Transaction _tx(int id) => Transaction(
  id: id,
  createdAt: '2026-01-01T10:00:00',
  amount: 1000,
  fee: 0,
  isWithdrawal: false,
  displayType: '이체',
  displayAmount: 1000,
  counterpartyName: '상대$id',
);

TransactionHistoryResponse _resp({
  required List<Transaction> data,
  int totalCount = 0,
  String balance = '50000',
  String accountName = '내통장',
  int currentPage = 1,
}) => TransactionHistoryResponse(
  balance: balance,
  accountName: accountName,
  totalCount: totalCount,
  totalPage: 1,
  currentPage: currentPage,
  data: data,
);

TransactionHistoryResponse _emptyResponse() =>
    _resp(data: const [], totalCount: 0);

const _account = '110-123';

ProviderContainer buildContainer(FakeTransferRepository repo) {
  final c = ProviderContainer(
    overrides: [transRepositoryProvider.overrideWithValue(repo)],
  );
  // family.autoDispose 유지: fetch 내부 Future.delayed(250ms) 동안 폐기 방지
  c.listen(transactionViewModelProvider(_account), (_, __) {});
  return c;
}

void main() {
  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  TransactionViewModel readVm(ProviderContainer c) =>
      c.read(transactionViewModelProvider(_account).notifier);
  TransactionViewState readState(ProviderContainer c) =>
      c.read(transactionViewModelProvider(_account));

  // ==========================================================================
  group('초기 상태 (build/initial)', () {
    test(
      'transactions 빈 리스트, isBusy/isError=false, page=1, isAllClick=true',
      () {
        container = buildContainer(FakeTransferRepository());
        final s = readState(container);

        expect(s.transactions, isEmpty);
        expect(s.isBusy, isFalse);
        expect(s.isError, isFalse);
        expect(s.page, 1);
        expect(s.totalCount, 0);
        expect(s.isAllClick, isTrue);
        expect(s.hasMore, isFalse); // 0 < 0 == false
      },
    );
  });

  // ==========================================================================
  group('refresh() — 새로고침', () {
    test('성공 시 1페이지 데이터/잔액/계좌명/총개수가 반영되고 isBusy=false', () async {
      final repo = FakeTransferRepository(
        defaultResponse: _resp(
          data: [_tx(1), _tx(2)],
          totalCount: 2,
          balance: '99000',
          accountName: '월급통장',
        ),
      );
      container = buildContainer(repo);
      final vm = readVm(container);

      await vm.refresh();
      final s = readState(container);

      expect(s.transactions, hasLength(2));
      expect(s.balance, '99000');
      expect(s.accountName, '월급통장');
      expect(s.totalCount, 2);
      expect(s.page, 1);
      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
      expect(repo.lastPage, 1);
    });

    test(
      'AppException 발생 시 isError=true, errorMessage=e.message, isBusy=false',
      () async {
        final repo = FakeTransferRepository(
          throwError: AppException('권한이 없습니다.'),
        );
        container = buildContainer(repo);
        final vm = readVm(container);

        await vm.refresh();
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.errorMessage, '권한이 없습니다.');
        expect(s.isBusy, isFalse);
      },
    );

    test('일반 예외 발생 시 "알 수 없는 오류가 발생했습니다." 메시지로 처리된다', () async {
      final repo = FakeTransferRepository(throwError: Exception('parse error'));
      container = buildContainer(repo);
      final vm = readVm(container);

      await vm.refresh();
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.errorMessage, '알 수 없는 오류가 발생했습니다.');
      expect(s.isBusy, isFalse);
    });
  });

  // ==========================================================================
  group('updateDateRange() — 기간 필터', () {
    test(
      '필터 적용 시 startDate/endDate가 Repository로 전달되고 isAllClick=false, page=1',
      () async {
        final repo = FakeTransferRepository(
          defaultResponse: _resp(data: [_tx(1)], totalCount: 1),
        );
        container = buildContainer(repo);
        final vm = readVm(container);

        final start = DateTime(2026, 1, 1);
        final end = DateTime(2026, 1, 31);
        await vm.updateDateRange(start, end, days: 30);
        final s = readState(container);

        expect(s.isAllClick, isFalse);
        expect(s.selectedPeriodDays, 30);
        expect(s.startDate, start);
        expect(s.endDate, end);
        expect(s.page, 1);
        expect(repo.lastStartDate, start);
        expect(repo.lastEndDate, end);
        expect(s.transactions, hasLength(1));
      },
    );
  });

  // ==========================================================================
  group('loadMore() — 무한 스크롤', () {
    test('hasMore=true면 다음 페이지를 불러와 기존 리스트에 누적된다', () async {
      final repo = FakeTransferRepository(
        responsesByPage: {
          1: _resp(data: [_tx(1), _tx(2)], totalCount: 4),
          2: _resp(data: [_tx(3), _tx(4)], totalCount: 4, currentPage: 2),
        },
      );
      container = buildContainer(repo);
      final vm = readVm(container);

      await vm.refresh(); // page 1: 2건 (totalCount 4 → hasMore)
      expect(readState(container).hasMore, isTrue);

      await vm.loadMore(); // page 2: +2건
      final s = readState(container);

      expect(s.transactions, hasLength(4));
      expect(s.page, 2);
      expect(repo.lastPage, 2);
      expect(s.hasMore, isFalse); // 4 < 4 == false
    });

    test('hasMore=false면 추가 요청하지 않는다 (no-op)', () async {
      final repo = FakeTransferRepository(
        defaultResponse: _resp(
          data: [_tx(1)],
          totalCount: 1,
        ), // 1==1 → hasMore false
      );
      container = buildContainer(repo);
      final vm = readVm(container);
      await vm.refresh();
      expect(readState(container).hasMore, isFalse);
      final callsAfterRefresh = repo.callCount;

      await vm.loadMore();

      expect(repo.callCount, callsAfterRefresh); // 추가 호출 없음
    });
  });
}
