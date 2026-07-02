import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbank_user/repository/response/account_search/account_searchtype_response.dart';
import 'package:tbank_user/repository/response/transaction_history/transaction_history_response.dart';
import 'package:tbank_user/repository/system_repository.dart';
import 'package:tbank_user/repository/transfer_repository.dart';
import 'package:tbank_user/util/helper/app_exception.dart';
import 'package:tbank_user/view/transfer/transfer_view_model.dart';
import 'package:tbank_user/view/transfer/transfer_view_state.dart';

// =============================================================================
// Fake TransferRepository — transfer / searchAccount 제어 (+ 인자 캡처)
// =============================================================================
class FakeTransferRepository implements TransferRepository {
  bool transferResult;
  Object? transferThrow;
  AccountSearchResponse? searchResult;
  Object? searchThrow;

  // 인자 캡처
  Map<String, String>? lastTransferArgs;

  FakeTransferRepository({
    this.transferResult = true,
    this.transferThrow,
    this.searchResult,
    this.searchThrow,
  });

  @override
  Future<bool> transfer({
    required String fromAccountNumber,
    required String toAccountNumber,
    required String amount,
    required String memo,
  }) async {
    lastTransferArgs = {
      'from': fromAccountNumber,
      'to': toAccountNumber,
      'amount': amount,
      'memo': memo,
    };
    if (transferThrow != null) throw transferThrow!;
    return transferResult;
  }

  @override
  Future<AccountSearchResponse?> searchAccount({
    required String accountNumber,
    required AccountSearchType type,
  }) async {
    if (searchThrow != null) throw searchThrow!;
    return searchResult;
  }

  @override
  Future<TransactionHistoryResponse> fetchHistory(
    String accountNumber, {
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) => throw UnimplementedError();
}

// =============================================================================
// Fake SystemRepository — getSystemConfig 제어
// =============================================================================
class FakeSystemRepository implements SystemRepository {
  String? configResult;
  Object? configThrow;

  FakeSystemRepository({this.configResult, this.configThrow});

  @override
  Future<String?> getSystemConfig() async {
    if (configThrow != null) throw configThrow!;
    return configResult;
  }
}

ProviderContainer buildContainer({
  FakeTransferRepository? transRepo,
  FakeSystemRepository? systemRepo,
}) {
  final c = ProviderContainer(
    overrides: [
      transRepositoryProvider.overrideWithValue(
        transRepo ?? FakeTransferRepository(),
      ),
      systemRepositoryProvider.overrideWithValue(
        systemRepo ?? FakeSystemRepository(),
      ),
    ],
  );
  // autoDispose 유지: 실제 앱에서는 View가 구독하므로, 비동기 작업(타이머 등)
  // 중간에 notifier가 폐기되지 않도록 테스트에서도 리스너를 건다.
  c.listen(transferViewModelProvider, (_, __) {});
  return c;
}

void main() {
  ProviderContainer container = ProviderContainer();
  tearDown(() => container.dispose());

  TransferViewModel readVm(ProviderContainer c) =>
      c.read(transferViewModelProvider.notifier);
  TransferViewState readState(ProviderContainer c) =>
      c.read(transferViewModelProvider);

  // ==========================================================================
  group('초기 상태 (build)', () {
    test('isBusy/isError=false, errorMessage 빈 문자열, isTransferOk=false', () {
      container = buildContainer();
      final s = readState(container);

      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
      expect(s.errorMessage, isEmpty);
      expect(s.isTransferOk, isFalse);
    });
  });

  // ==========================================================================
  group('transfer() — 이체 실행', () {
    test('성공 시 isTransferOk=true, isBusy=false, isError=false', () async {
      container = buildContainer();
      final vm = readVm(container);

      await vm.transfer(
        fromAccountNumber: '110-1',
        toAccountNumber: '220-2',
        amount: '10000',
        memo: '월세',
      );
      final s = readState(container);

      expect(s.isTransferOk, isTrue);
      expect(s.isBusy, isFalse);
      expect(s.isError, isFalse);
    });

    test('입력한 인자가 Repository로 그대로 전달된다', () async {
      final repo = FakeTransferRepository();
      container = buildContainer(transRepo: repo);
      final vm = readVm(container);

      await vm.transfer(
        fromAccountNumber: '110-1',
        toAccountNumber: '220-2',
        amount: '5000',
        memo: '용돈',
      );

      expect(repo.lastTransferArgs, {
        'from': '110-1',
        'to': '220-2',
        'amount': '5000',
        'memo': '용돈',
      });
    });

    test(
      'AppException 발생 시 isError=true, errorMessage=e.message, isTransferOk=false',
      () async {
        final repo = FakeTransferRepository(
          transferThrow: AppException('잔액이 부족합니다.'),
        );
        container = buildContainer(transRepo: repo);
        final vm = readVm(container);

        await vm.transfer(
          fromAccountNumber: '110-1',
          toAccountNumber: '220-2',
          amount: '999999',
          memo: '',
        );
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.errorMessage, '잔액이 부족합니다.');
        expect(s.isTransferOk, isFalse);
        expect(s.isBusy, isFalse);
      },
    );

    test('일반 예외 발생 시 "송금 중 오류가 발생했습니다." 메시지로 처리된다', () async {
      final repo = FakeTransferRepository(transferThrow: Exception('socket'));
      container = buildContainer(transRepo: repo);
      final vm = readVm(container);

      await vm.transfer(
        fromAccountNumber: '110-1',
        toAccountNumber: '220-2',
        amount: '10000',
        memo: '',
      );
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.errorMessage, '송금 중 오류가 발생했습니다.');
      expect(s.isTransferOk, isFalse);
      expect(s.isBusy, isFalse);
    });
  });

  // ==========================================================================
  group('fetchSystemConfig() — 수수료 조회', () {
    test('수수료 문자열을 받으면 fee가 int로 파싱된다', () async {
      final sys = FakeSystemRepository(configResult: '300');
      container = buildContainer(systemRepo: sys);
      final vm = readVm(container);

      await vm.fetchSystemConfig();
      final s = readState(container);

      expect(s.fee, 300);
      expect(s.isLoadingFee, isFalse);
    });

    test('숫자가 아닌 문자열이면 fee=0으로 폴백된다', () async {
      final sys = FakeSystemRepository(configResult: 'free');
      container = buildContainer(systemRepo: sys);
      final vm = readVm(container);

      await vm.fetchSystemConfig();

      expect(readState(container).fee, 0);
    });

    test('null을 받으면 fee=0, isError=true', () async {
      final sys = FakeSystemRepository(configResult: null);
      container = buildContainer(systemRepo: sys);
      final vm = readVm(container);

      await vm.fetchSystemConfig();
      final s = readState(container);

      expect(s.fee, 0);
      expect(s.isError, isTrue);
      expect(s.isLoadingFee, isFalse);
    });

    test('예외 발생 시 fee=0, isError=true, isLoadingFee=false', () async {
      final sys = FakeSystemRepository(configThrow: AppException('서버 오류'));
      container = buildContainer(systemRepo: sys);
      final vm = readVm(container);

      await vm.fetchSystemConfig();
      final s = readState(container);

      expect(s.fee, 0);
      expect(s.isError, isTrue);
      expect(s.isLoadingFee, isFalse);
    });
  });

  // ==========================================================================
  group('checkAccountName() — 예금주 실명 조회', () {
    test('조회 성공 시 accountName이 설정되고 isVerifying=false', () async {
      final repo = FakeTransferRepository(
        searchResult: AccountSearchResponse(accountName: '홍길동'),
      );
      container = buildContainer(transRepo: repo);
      final vm = readVm(container);

      await vm.checkAccountName('220-2');
      final s = readState(container);

      expect(s.accountName, '홍길동');
      expect(s.isVerifying, isFalse);
      expect(s.isError, isFalse);
    });

    test(
      'AppException 발생 시 isError=true, errorMessage=e.message, isVerifying=false',
      () async {
        final repo = FakeTransferRepository(
          searchThrow: AppException('존재하지 않는 계좌입니다.'),
        );
        container = buildContainer(transRepo: repo);
        final vm = readVm(container);

        await vm.checkAccountName('999-9');
        final s = readState(container);

        expect(s.isError, isTrue);
        expect(s.errorMessage, '존재하지 않는 계좌입니다.');
        expect(s.isVerifying, isFalse);
      },
    );

    test('일반 예외 발생 시 "서버 통신 중 오류가 발생했습니다." 메시지로 처리된다', () async {
      final repo = FakeTransferRepository(searchThrow: Exception('timeout'));
      container = buildContainer(transRepo: repo);
      final vm = readVm(container);

      await vm.checkAccountName('220-2');
      final s = readState(container);

      expect(s.isError, isTrue);
      expect(s.errorMessage, '서버 통신 중 오류가 발생했습니다.');
      expect(s.isVerifying, isFalse);
    });

    test(
      '조회 결과가 null이면 accountName은 갱신되지 않는다 (현재 구현: isVerifying 유지)',
      () async {
        // 문서화: searchAccount가 null을 반환하면 if 블록을 건너뛰어
        // accountName=null, isVerifying=true 상태로 남는다.
        final repo = FakeTransferRepository(searchResult: null);
        container = buildContainer(transRepo: repo);
        final vm = readVm(container);

        await vm.checkAccountName('220-2');
        final s = readState(container);

        expect(s.accountName, isNull);
        expect(s.isVerifying, isTrue);
      },
    );
  });

  // ==========================================================================
  group('getTransferFee() — 수수료 시뮬레이션', () {
    test('호출 후 fee=500, isLoadingFee=false로 설정된다', () async {
      container = buildContainer();
      final vm = readVm(container);

      await vm.getTransferFee(10000);
      final s = readState(container);

      expect(s.fee, 500);
      expect(s.isLoadingFee, isFalse);
    });
  });

  // ==========================================================================
  group('reset() — 상태 초기화', () {
    test('이체 성공 후 reset하면 초기 상태로 돌아온다', () async {
      container = buildContainer();
      final vm = readVm(container);
      await vm.transfer(
        fromAccountNumber: '110-1',
        toAccountNumber: '220-2',
        amount: '10000',
        memo: '',
      );
      expect(readState(container).isTransferOk, isTrue);

      vm.reset();
      final s = readState(container);

      expect(s.isTransferOk, isFalse);
      expect(s.accountName, isNull);
      expect(s.fee, isNull);
    });
  });
}
