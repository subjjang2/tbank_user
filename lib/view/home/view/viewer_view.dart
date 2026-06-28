import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/service/theme_service.dart';

import 'package:tbank_user/view/home/view/viewer_state.dart';
import 'package:tbank_user/view/home/view/viewer_view_model.dart';

import '../../../provider/account_status_provider.dart';
import '../../../theme/refresh/refresh_btn.dart';
import '../../../util/helper/IntlHelper.dart';
import '../../../util/route_path.dart';
import '../my/my_account_view_model.dart';

/// ----------------------------------------------------------------------------
/// [ViewerAccountsView]
/// 사용자에게 '조회 권한'이 있는 계좌 목록을 보여주는 화면입니다.
/// (예: 감찰관이 조회하는 사원 계좌, 부모가 조회하는 자녀 계좌 등)
/// ----------------------------------------------------------------------------
class ViewerAccountsView extends ConsumerStatefulWidget {
  const ViewerAccountsView({super.key});

  @override
  ConsumerState<ViewerAccountsView> createState() => _ViewerAccountsViewState();
}

class _ViewerAccountsViewState extends ConsumerState<ViewerAccountsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 1. 화면 진입 후 데이터 초기화 (Refresh)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(viewerAccountProvider.notifier).refresh();
    });

    // 2. 무한 스크롤 리스너 등록
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤이 바닥에 가까워지면 다음 페이지 요청
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(viewerAccountProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel 상태 구독
    final state = ref.watch(viewerAccountProvider);
    final viewerPrimaryColor = ref.color.primary;

    // 🔹 [에러 리스너] 에러 발생 시 스낵바 표시 (accessible_view와 동일 패턴)
    ref.listen(viewerAccountProvider, (previous, next) {
      if (next.errorMessage.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        if (!next.isError) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: ref.color.background,
      body: Column(
        children: [
          // 상단 헤더 (타이틀 + 새로고침 버튼)
          _buildHeader(ref, state, viewerPrimaryColor),

          // 리스트 영역 (당겨서 새로고침 지원)
          Expanded(
            child: LiquidPullToRefresh(
              onRefresh: () async {
                await ref.read(viewerAccountProvider.notifier).refresh();
              },
              color: ref.color.background,
              backgroundColor: viewerPrimaryColor,
              height: 60,
              showChildOpacityTransition: false,
              animSpeedFactor: 2.0,
              springAnimationDurationInMilliseconds: 400,
              child: _buildBody(state, viewerPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [Body Builder] 데이터 상태에 따른 분기 처리
  // ---------------------------------------------------------------------------
  Widget _buildBody(ViewerAccountsState state, Color primaryColor) {
    // 1. 에러 발생 (데이터 없음) — accessible_view와 동일 패턴
    if (state.accounts.isEmpty && state.isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "데이터를 불러올 수 없습니다.\n${state.errorMessage}",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(viewerAccountProvider.notifier).refresh(),
              child: const Text("다시 시도"),
            ),
          ],
        ),
      );
    }

    // 2. 데이터 없음 (빈 화면 표시)
    if (state.accounts.isEmpty) {
      return _buildEmptyState();
    }

    // 2. 데이터 있음 (리스트 표시)
    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(), // 내용이 적어도 스크롤 가능하게 (Refresh 동작 위해)
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: state.accounts.length + (state.hasMore ? 1 : 0), // 로딩 인디케이터 포함
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        // 마지막 아이템 아래에 로딩 표시 (무한 스크롤 중일 때)
        if (index == state.accounts.length) {
          if (state.hasMore && state.isBusy) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 3,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        // 계좌 카드 아이템
        return _buildViewerAccountCard(state.accounts[index], primaryColor);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // [Header Widget] 커스텀 그라데이션 헤더
  // ---------------------------------------------------------------------------
  Widget _buildHeader(
    WidgetRef ref,
    ViewerAccountsState state,
    Color primaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3F51B5), // 상단 포인트 컬러
            primaryColor, // 테마 메인 컬러
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 타이틀
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.remove_red_eye_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "조회 권한",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                // 우측 상단 수동 새로고침 버튼
                RefreshIconButton(
                  scrollController: _scrollController,
                  isLoading: state.isHeaderRefreshing,
                  onPressed: () async {
                    await ref.read(viewerAccountProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [Card Widget] 계좌 정보 카드
  // ---------------------------------------------------------------------------
  Widget _buildViewerAccountCard(Account account, Color primaryColor) {
    final formattedBalance = IntlHelper.currency(account.balance);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        // ✨ 클릭 시 계좌 상태 확인 (ACTIVE 인지 체크)
        final status = await ref.read(
          accountStatusProvider(account.accountNumber).future,
        );

        if (status.toString() == "ACTIVE") {
          // 정상 계좌면 거래 내역 화면으로 이동
          Navigator.pushNamed(
            context,
            RoutePath.transfer_history,
            arguments: {
              'senderAccountNumber': account.accountNumber,
              'isMyAccount': false, // 조회용이므로 내 계좌 아님 표시
              'accountName': '',
            },
          );
        } else {
          // 비정상 계좌면 스낵바 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("관리자 승인이 필요합니다."),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 계좌명 & 번호
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.accountName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            account.accountNumber,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 소유자 표시 (Viewer는 남의 계좌를 보는 것이므로 중요)
                  if (account.owner != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 12, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            account.owner!.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              // 잔액 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "현재 잔액",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formattedBalance,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(
                          text: " cas",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [Empty State] 데이터가 없을 때
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      // ✨ 중요: ListView로 감싸야 내용이 없어도 당겨서 새로고침(LiquidPullToRefresh)이 동작함
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.visibility_off_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  "조회 가능한 계좌가 없습니다.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                // 데이터 없음 상태에서도 새로고침 할 수 있는 버튼
                ElevatedButton.icon(
                  onPressed: () async {
                    ref.read(viewerAccountProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("새로고침"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ref.color.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
