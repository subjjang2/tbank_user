import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 클립보드 복사용
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:tbank_user/res/palette.dart';
import 'package:tbank_user/service/theme_service.dart';
import 'package:tbank_user/view/transaction_history/transation_history_view_state.dart';
import '../../model/transaction.dart';
import '../../theme/skeleton_box.dart';
import '../../util/app_dialog.dart';
import '../../util/route_path.dart';
import 'transation_history_view_model.dart';
import '../../util/helper/IntlHelper.dart';

/// ----------------------------------------------------------------------------
/// [TransactionHistoryScreen]
/// 특정 계좌(accountNumber)의 입출금 내역을 보여주는 화면입니다.
/// 무한 스크롤, 기간 조회, 새로고침 기능을 제공합니다.
/// ----------------------------------------------------------------------------
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String accountNumber;
  final String? accountName;
  final bool isMyAccount; // 내 계좌인지 여부 (설정 버튼 표시용)

  const TransactionHistoryScreen({
    super.key,
    required this.accountNumber,
    required this.isMyAccount,
    this.accountName,
  });

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTimeRange? getPicked; // 선택된 날짜 범위
  bool isAllClick = true;   // '전체' 필터 선택 여부

  @override
  void initState() {
    super.initState();
    // 1. 화면 진입 후 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // family provider이므로 accountNumber를 넘겨서 인스턴스 찾기
      final viewModel = ref.read(transactionViewModelProvider(widget.accountNumber).notifier);
      viewModel.refresh();
    });

    // 2. 스크롤 리스너 등록 (무한 스크롤용)
    _scrollController.addListener(_onScroll);
  }

  // 🔹 [무한 스크롤 로직]
  // 스크롤이 바닥에 가까워지면(200px 남음) 다음 페이지 데이터를 요청합니다.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state =
      ref.read(transactionViewModelProvider(widget.accountNumber));
      final viewModel = ref
          .read(transactionViewModelProvider(widget.accountNumber).notifier);

      // 로딩 중이 아니고, 더 가져올 데이터(hasMore)가 있을 때만 요청
      if (!state.isBusy && state.hasMore) {
        viewModel.loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // 🔹 [에러 리스너]
    // 상태가 변할 때 에러가 발생했다면 다이얼로그를 띄웁니다.
    ref.listen<TransactionViewState>(transactionViewModelProvider(widget.accountNumber), (previous, next) {
      if (next.isError && (previous?.isError == false)) {
        AppDialog.showError(
          context,
          message: next.errorMessage ?? "알 수 없는 오류가 발생했습니다.",
          onConfirm: () {
            Navigator.pop(context); // 다이얼로그 닫기
          },
        );
      }
    });

    // 상태 감지 (Watch)
    final state = ref.watch(transactionViewModelProvider(widget.accountNumber));
    final viewModel = ref.read(transactionViewModelProvider(widget.accountNumber).notifier);
    isAllClick = state.isAllClick;

    final primaryColor = ref.color.primary;
    const backgroundColor = Colors.white;
    final textColor = ref.color.text;
    final subTextColor = ref.color.subtext;

    // 데이터가 아예 없는지 확인 (로딩이 끝난 상태에서)
    bool isEmpty = state.transactions.isEmpty && !state.isBusy;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(state.accountName ?? "내 계좌",
            style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          // 내 계좌일 경우에만 '관리(설정)' 버튼 표시
          if (widget.isMyAccount)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RoutePath.account_authority,
                  arguments: widget.accountNumber,
                );
              },
            ),
        ],
      ),
      // 🔹 [당겨서 새로고침] Liquid 효과 적용
      body: LiquidPullToRefresh(
        onRefresh: () async {
          await viewModel.refresh();
        },
        color: primaryColor.withOpacity(0.9),
        backgroundColor: Colors.white,
        height: 60,
        animSpeedFactor: 2.0,
        showChildOpacityTransition: false,
        springAnimationDurationInMilliseconds: 300,
        child: _buildBody(state, isEmpty, viewModel, primaryColor, textColor, subTextColor),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [Body Builder] 상태에 따라 다른 위젯(스켈레톤, 빈 화면, 리스트) 반환
  // ---------------------------------------------------------------------------
  Widget _buildBody(TransactionViewState state, bool isEmpty, TransactionViewModel viewModel, Color primaryColor, Color textColor, Color subTextColor) {

    // 1. 초기 로딩 중 (데이터 없음) -> 전체 스켈레톤 화면
    if (state.transactions.isEmpty && state.isBusy) {
      return _buildSkeletonFullPage();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      // 아이템 개수: 헤더(1) + (빈화면 or 데이터개수) + (로딩인디케이터 if hasMore)
      itemCount: 1 + (isEmpty ? 1 : state.transactions.length) + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {

        // 예외 처리: 데이터 없고 로딩 중일 때 (위에서 처리했지만 안전장치)
        if (state.transactions.isEmpty && state.isBusy) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
            ),
          );
        }

        // 1. [헤더] 잔액 정보 + 필터 칩
        if (index == 0) {
          return Column(
            children: [
              _buildAccountHeader(context, state, textColor, subTextColor),
              _buildFilterChips(context, viewModel, state, ref),
            ],
          );
        }

        // 2. [빈 화면] 내역 없음
        if (isEmpty) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(subTextColor),
          );
        }

        // 3. [리스트 아이템]
        final dataIndex = index - 1; // 헤더 때문에 인덱스 -1

        // 마지막 아이템 밑에 로딩 표시 (더 불러오는 중일 때)
        if (dataIndex == state.transactions.length) {
          if (state.hasMore && state.isBusy) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: CircularProgressIndicator(color: ref.color.secondary, strokeWidth: 3),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final tx = state.transactions[dataIndex];
        return _buildTransactionRow(context, tx, textColor, subTextColor, primaryColor);
      },
    );
  }

  // --- Components ---

  // 상단 헤더 (계좌번호 복사 및 잔액)
  Widget _buildAccountHeader(BuildContext context, TransactionViewState state,
      Color textColor, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 계좌번호 (클릭 시 복사)
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("계좌번호가 복사되었습니다."), duration: Duration(seconds: 1)),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.accountNumber,
                    style: TextStyle(color: subTextColor, fontSize: 15, decoration: TextDecoration.underline),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.copy, size: 12, color: subTextColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 잔액 표시
          Text(
            "${IntlHelper.currency(state.balance)} cas",
            style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: subTextColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("거래 내역이 없습니다.", style: TextStyle(color: subTextColor, fontSize: 16)),
        ],
      ),
    );
  }

  // 🔹 [거래 내역 행] 실행자 정보 포함
  Widget _buildTransactionRow(
      BuildContext context,
      Transaction tx,
      Color textColor,
      Color subTextColor,
      Color primaryColor,
      ) {
    bool isWithdraw = tx.isWithdrawal;
    final amountColor = isWithdraw ? textColor : primaryColor;
    final prefix = isWithdraw ? "" : "+ ";

    final dt = IntlHelper.dateTime(tx.createdAt);
    final dateStr = DateFormat('MM.dd').format(dt!);
    final timeStr = DateFormat('HH:mm').format(dt);

    return InkWell(
      onTap: () => _showDetailDialog(context, tx), // 상세 다이얼로그 호출
      highlightColor: Colors.grey.withOpacity(0.1),
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [좌측] 날짜/시간
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(timeStr, style: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 12)),
              ],
            ),
            const SizedBox(width: 20),

            // [중앙] 거래 대상 및 실행자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 거래 대상 이름
                  Text(
                    tx.counterpartyName,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // ✨ [실행자 표시 UI] (누가 이체했는지)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 아이콘: 시스템(로봇) vs 사용자(사람)
                        Icon(
                          (tx.executor == null) ? Icons.smart_toy_outlined : Icons.account_circle,
                          size: 11,
                          color: const Color(0xFF6B7684),
                        ),
                        const SizedBox(width: 4),

                        // 이름: "시스템" or "유저이름"
                        Text(
                          tx.executor == null ? "시스템" : tx.executor!.name,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7684),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 메모가 있으면 표시
                  if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx.memo!,
                      style: TextStyle(color: subTextColor, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),

            // [우측] 거래 금액
            Text(
              "$prefix${tx.formattedDisplayAmount} cas",
              style: TextStyle(color: amountColor, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 [상세 다이얼로그] 거래 상세 정보 표시
  void _showDetailDialog(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tx.displayType, style: const TextStyle(color: Color(0xFF8B95A1), fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                "${tx.formattedDisplayAmount} cas",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF191F28)),
              ),
              const SizedBox(height: 24),
              Divider(color: Palette.grey300, thickness: 1),
              const SizedBox(height: 16),

              // 상세 정보 행들
              _detailRow("거래일시", IntlHelper.dateTimeStr(tx.createdAt)),
              const SizedBox(height: 12),
              _detailRow(tx.isWithdrawal ? "받는 사람" : "보낸 사람", tx.counterpartyName),
              const SizedBox(height: 12),
              _detailRow(tx.isWithdrawal ? "받는 계좌" : "보낸 계좌", tx.counterpartyAccount ?? "-"),
              const SizedBox(height: 6),

              // 실행자 상세 표시
              _detailRow(
                "거래 실행",
                tx.executor != null
                    ? "${tx.executor!.name} (${tx.executor!.userId})"
                    : "시스템 (자동 처리)",
                color: ref.color.secondary,
              ),

              if (tx.memo != null && tx.memo!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailRow("메모", tx.memo!),
              ],
              const SizedBox(height: 30),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ref.color.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("확인", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // 상세 다이얼로그 내부 행 위젯
  Widget _detailRow(String label, String value, {Color color = const Color(0xFF333D4B)}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8B95A1), fontSize: 14)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // 🔹 [필터 칩] 전체보기 / 기간설정 버튼
  Widget _buildFilterChips(BuildContext context, TransactionViewModel viewModel, TransactionViewState state, WidgetRef ref) {
    // '전체' 버튼
    Widget buildAllChip() {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          onTap: () async {
            await viewModel.refresh(); // 초기화
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: state.isAllClick ? ref.color.primary : const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "전체",
              style: TextStyle(
                color: state.isAllClick ? Colors.white : const Color(0xFF6B7684),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // '기간 설정' 버튼
    Widget buildCustomChip() {
      bool isSelected = !state.isAllClick;
      String label = "기간 설정";
      if (isSelected && state.startDate != null && state.endDate != null) {
        label = "${DateFormat('MM.dd').format(state.startDate!)} ~ ${DateFormat('MM.dd').format(state.endDate!)}";
      }

      return InkWell(
        onTap: () => _pickDateRange(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? ref.color.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFD1D6DB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7684),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7684)),
              ]
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF2F4F6), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            buildAllChip(),
            buildCustomChip(),
          ],
        ),
      ),
    );
  }

  // 기간 선택 다이얼로그 (Date Range Picker)
  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(transactionViewModelProvider(widget.accountNumber).notifier);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      helpText: '조회할 기간을 선택해주세요',
      cancelText: '취소',
      confirmText: '조회',
      saveText: '저장',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ref.color.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      getPicked = picked;
      await viewModel.updateDateRange(picked.start, picked.end, days: null);
    }
  }

  // 🔹 [스켈레톤] 전체 로딩 화면
  Widget _buildSkeletonFullPage() {
    return Column(
      children: [
        _buildSkeletonHeader(),
        Container(
          height: 1,
          color: const Color(0xFFF2F4F6),
          margin: const EdgeInsets.symmetric(vertical: 12),
        ),
        Expanded(child: _buildSkeletonList()),
      ],
    );
  }

  // 스켈레톤 헤더
  Widget _buildSkeletonHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SkeletonBox(width: 140, height: 16),
          SizedBox(height: 16),
          SkeletonBox(width: 200, height: 34, radius: 8),
        ],
      ),
    );
  }

  // 스켈레톤 리스트
  Widget _buildSkeletonList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 40, height: 14),
                  const SizedBox(height: 6),
                  SkeletonBox(width: 30, height: 12),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 120, height: 16),
                    SizedBox(height: 8),
                    SkeletonBox(width: 80, height: 12),
                  ],
                ),
              ),
              const SkeletonBox(width: 90, height: 20, radius: 4),
            ],
          ),
        );
      },
    );
  }
}