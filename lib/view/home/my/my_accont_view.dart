import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:tbank_user/repository/response/account_response.dart';
import 'package:tbank_user/res/palette.dart';
import 'package:tbank_user/service/theme_service.dart';

import '../../../enum/account_status.dart';
import '../../../provider/account_status_provider.dart';
import '../../../util/helper/IntlHelper.dart';
import '../../../util/route_path.dart';
import '../../transfer/transfer_view.dart';
import 'header/my_account_header_view.dart';
import 'my_account_view_state.dart';
import 'my_account_view_model.dart';

/// ----------------------------------------------------------------------------
/// [MyAccountView]
/// 내 계좌 목록을 보여주는 메인 탭 화면입니다.
/// 기능: 계좌 목록 조회, 무한 스크롤, 당겨서 새로고침, 이체 화면 이동, 상세 내역 이동
/// ----------------------------------------------------------------------------
class MyAccountView extends ConsumerStatefulWidget {
  const MyAccountView({super.key});

  @override
  ConsumerState<MyAccountView> createState() => _MyAccountViewState();
}

class _MyAccountViewState extends ConsumerState<MyAccountView> {
  // 무한 스크롤 감지용 컨트롤러
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 1. 초기 데이터 로드 (화면이 그려진 직후 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myAccountViewModelProvider.notifier).refresh();
    });

    // 2. 스크롤 리스너 등록
    _scrollController.addListener(_onScroll);
  }

  // 🔹 [무한 스크롤 로직]
  void _onScroll() {
    // 스크롤이 바닥에서 100px 남았을 때 다음 페이지 요청
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(myAccountViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel 상태 구독 (UI 업데이트용)
    final state = ref.watch(myAccountViewModelProvider);

    // 🔹 [에러 리스너] 에러 발생 시 스낵바 표시
    ref.listen(myAccountViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: ref.color.background,
      body: Column(
        children: [
          // 1. 상단 헤더 (고정)
          MyAccountHeader(scrollController: _scrollController,),

          // 2. 메인 리스트 (새로고침 가능)
          Expanded(
            child: LiquidPullToRefresh(
              onRefresh: () async {
                await ref.read(myAccountViewModelProvider.notifier).refresh();
              },
              color: ref.color.background, // 로딩 배경색
              backgroundColor: ref.color.primary, // 로딩 물방울 색
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

  /// 🔹 [Body Builder] 데이터 상태에 따른 분기 처리
  Widget _buildBody(AccountViewState state) {
    // 1. [초기 로딩] 데이터가 없고 로딩 중일 때
    if (state.accounts.isEmpty && state.isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. [에러] 데이터가 없고 에러 발생 시
    if (state.accounts.isEmpty && state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("데이터를 불러올 수 없습니다.\n${state.errorMessage}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(myAccountViewModelProvider.notifier).refresh(),
              child: const Text("다시 시도"),
            )
          ],
        ),
      );
    }

    // 3. [데이터 없음] 정상 로드되었으나 계좌가 0개일 때
    if (state.accounts.isEmpty) {
      return _buildEmptyState();
    }

    // 4. [리스트 출력]
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(), // 내용이 적어도 스크롤 가능하게 (Refresh 동작 위해)
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: state.accounts.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        // 마지막 아이템 아래에 로딩 인디케이터 표시 (무한 스크롤 중일 때)
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

    // 계좌 상태 확인 (승인 대기중인지)
    final bool isPending = AccountStatus.getByCode(account.status) == AccountStatus.pending;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      // 카드 전체 클릭 시: 상세 내역으로 이동
      onTap: () async {
        // ✨ 최신 상태를 비동기로 한 번 더 확인 (보안/데이터 무결성)
        final status = await ref.read(accountStatusProvider(account.accountNumber).future);

        if (AccountStatus.getByCode(status) == AccountStatus.active) {
          // 1. 활성 계좌 -> 거래 내역 화면으로 이동
          await Navigator.pushNamed(
            context,
            RoutePath.transfer_history,
            arguments: {
              'senderAccountNumber': account.accountNumber,
              'isMyAccount': true, // 내 계좌임
              'accountName': account.accountName,
            },
          );

          // 2. 돌아왔을 때 데이터 갱신 (잔액 변동 반영)
          if (context.mounted) {
            ref.read(myAccountViewModelProvider.notifier).refresh();
          }
        }
        else if (AccountStatus.getByCode(status) == AccountStatus.unknown) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("에러가 발생 했습니다."), backgroundColor: Colors.red),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("관리자 승인이 필요합니다."), backgroundColor: Colors.red),
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
              // [상단] 계좌 정보 + 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측: 계좌 별칭 및 번호
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ref.color.text),
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
                              style: TextStyle(fontSize: 13, color: Palette.grey600, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 우측: 상태에 따른 버튼 표시
                  if (!isPending)
                  // 정상 계좌: '이체' 버튼 표시
                    SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          // 이체 화면으로 이동
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
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("이체", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                  // 대기 계좌: '승인 대기' 배지 표시
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
              Divider(height: 1, color: Color(0xFFEEEEEE)),

              // [하단] 잔액 정보 (정상 계좌일 때만)
              if (!isPending) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("현재 잔액", style: TextStyle(fontSize: 13, color: Palette.grey600)),
                    Row(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: formattedBalance,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ref.color.text),
                              ),
                              TextSpan(
                                text: " cas",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ref.color.primary),
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

  /// 🔹 [Empty State] 계좌가 하나도 없을 때
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ref.color.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_wallet_outlined, size: 48, color: ref.color.primary),
          ),
          const SizedBox(height: 24),
          Text(
            "개설된 계좌가 없어요",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ref.color.text),
          ),
          const SizedBox(height: 8),
          Text(
            "새로운 계좌를 만들어\nT-BANK의 서비스를 이용해보세요.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}