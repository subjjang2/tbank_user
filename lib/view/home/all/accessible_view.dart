import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/res/palette.dart';
import 'package:tbank_user/service/theme_service.dart';

import '../../../model/account.dart';
import '../../../enum/account_status.dart';
import '../../../provider/account_status_provider.dart';
import '../../../util/helper/IntlHelper.dart';
import '../../../util/route_path.dart';
import '../../transfer/transfer_view.dart';
import 'access_state.dart';
import 'accessible_view_model.dart';
import 'header/accessible_header_view.dart';

/// ----------------------------------------------------------------------------
/// [AccessibleAccountsView]
/// 사용자에게 '이체 권한(ALL)'이 부여된 공유 계좌 목록을 보여주는 화면입니다.
/// (예: 부부 공유 통장, 모임 통장, 회비 통장 등)
/// ----------------------------------------------------------------------------
class AccessibleAccountsView extends ConsumerStatefulWidget {
  const AccessibleAccountsView({super.key});

  @override
  ConsumerState<AccessibleAccountsView> createState() => _AccessibleAccountsViewState();
}

class _AccessibleAccountsViewState extends ConsumerState<AccessibleAccountsView> {
  // 무한 스크롤 제어를 위한 컨트롤러
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 1. 화면 진입 시 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accessibleAccountsViewModelProvider.notifier).refresh();
    });

    // 2. 스크롤 리스너 등록 (바닥 감지 시 loadMore)
    _scrollController.addListener(_onScroll);
  }

  // 🔹 [무한 스크롤 로직]
  void _onScroll() {
    // 스크롤이 바닥에서 100px 남았을 때 다음 페이지 데이터 요청
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(accessibleAccountsViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel 상태 구독
    final state = ref.watch(accessibleAccountsViewModelProvider);

    // 🔹 [에러 리스너] 에러 발생 시 스낵바 표시
    ref.listen(accessibleAccountsViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        if (!next.isError) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: ref.color.background,
      body: Column(
        children: [
          // 1. 상단 헤더 (공유 계좌 전용 헤더)
          AccessibleAccountsHeader(scrollController: _scrollController,),

          // 2. 메인 리스트 (당겨서 새로고침 지원)
          Expanded(
            child: LiquidPullToRefresh(
              onRefresh: () async {
                await ref.read(accessibleAccountsViewModelProvider.notifier).refresh();
              },
              color: ref.color.background,
              backgroundColor: ref.color.primary,
              height: 60,
              showChildOpacityTransition: false,
              springAnimationDurationInMilliseconds: 400,
              animSpeedFactor: 2.0,
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 [Body Builder] 데이터 상태별 UI 분기
  Widget _buildBody(AccessibleAccountsState state) {
    // 1. 초기 로딩 (데이터 없음) - 스켈레톤이나 로딩바 처리 필요 (현재 비어있음)
    if (state.accounts.isEmpty && state.isBusy) {
      // return const Center(child: CircularProgressIndicator());
    }

    // 2. 에러 발생 (데이터 없음)
    if (state.accounts.isEmpty && state.isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("데이터를 불러올 수 없습니다.\n${state.errorMessage ?? ''}", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(accessibleAccountsViewModelProvider.notifier).refresh(),
              child: const Text("다시 시도"),
            )
          ],
        ),
      );
    }

    // 3. 데이터 없음 (정상 로드 완료)
    if (state.accounts.isEmpty) {
      return _buildEmptyState();
    }

    // 4. 리스트 출력
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(), // 내용 적어도 스크롤 허용 (새로고침 위해)
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: state.accounts.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        // 마지막 아이템 아래 로딩 인디케이터 (더보기 로딩 중일 때)
        if (index == state.accounts.length) {
          if (state.hasMore && state.isBusy) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: CircularProgressIndicator(
                  color: ref.color.primary,
                  strokeWidth: 3,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return _buildAccountCard(state.accounts[index]);
      },
    );
  }

  /// 🔹 [계좌 카드 위젯]
  Widget _buildAccountCard(Account account) {
    final formattedBalance = IntlHelper.currency(account.balance);

    // 계좌 승인 대기 상태 확인
    final bool isPending = AccountStatus.getByCode(account.status) == AccountStatus.pending;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      // 카드 클릭 시 상세 내역으로 이동
      onTap: () async {
        Navigator.pushNamed(
          context,
          RoutePath.transfer_history,
          arguments: {
            'senderAccountNumber': account.accountNumber,
            'isMyAccount': false, // 공유 계좌이므로 내 계좌 아님 표시 (설정 버튼 숨김 등)
            'accountName': account.accountName,
          },
        );
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
              // [상단] 계좌 정보 및 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ref.color.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.credit_card, size: 12, color: Palette.grey500),
                            const SizedBox(width: 4),
                            Text(
                              account.accountNumber,
                              style: TextStyle(
                                fontSize: 13,
                                color: Palette.grey600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 우측 버튼 (정상: 이체, 대기중: 배지)
                  if (!isPending)
                    SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          // 이체 화면 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransferScreen(
                                senderAccountNumber: account.accountNumber,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ref.color.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text("이체"),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "승인 대기",
                        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // [하단] 잔액 정보 (정상 상태일 때만)
              if (!isPending) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "현재 잔액",
                      style: TextStyle(fontSize: 13, color: Palette.grey600),
                    ),
                    Row(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: formattedBalance,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: ref.color.text,
                                ),
                              ),
                              TextSpan(
                                text: " cas",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ref.color.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 [Empty State] 공유 계좌가 없을 때
  Widget _buildEmptyState() {
    return Center(
      // ✨ ListView로 감싸야 내용이 없어도 당겨서 새로고침 제스처가 동작합니다.
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.vpn_key_off_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "이체 가능한 계좌가 없습니다.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 24),

                // 새로고침 버튼
                ElevatedButton.icon(
                  onPressed: () async {
                    ref.read(accessibleAccountsViewModelProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("새로고침"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ref.color.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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