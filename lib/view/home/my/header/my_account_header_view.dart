import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';
import '../../../../theme/refresh/refresh_btn.dart';
import '../my_account_view_model.dart';

/// ----------------------------------------------------------------------------
/// [MyAccountHeader]
/// 내 계좌 탭의 상단 헤더 위젯입니다.
/// 기능: 앱 로고, 새로고침 버튼, 사용자 이름/ID 표시, 관리자 권한 배지 표시
/// ----------------------------------------------------------------------------
class MyAccountHeader extends ConsumerWidget {
  final ScrollController scrollController;

  const MyAccountHeader({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ViewModel 상태 구독 (이름, 권한, 로딩 상태 등 변경 시 리빌드)
    final accountState = ref.watch(myAccountViewModelProvider);
    // 2. 이벤트 호출용 Notifier 가져오기 (새로고침 기능)
    final accountViewModel = ref.read(myAccountViewModelProvider.notifier);

    // 3. 테마 컬러 가져오기
    final primaryColor = ref.color.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      // 배경 스타일링 (그라데이션 + 하단 둥근 모서리 + 그림자)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
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

            // -----------------------------------------------------------------
            // [상단] 앱 로고 & 새로고침 버튼
            // -----------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 로고 + 앱 이름
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "T-BANK",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),

                // 새로고침 버튼 (커스텀 위젯)
                RefreshIconButton(
                  scrollController: scrollController,
                  isLoading: accountState.isHeaderRefreshing,
                  onPressed: () async {
                    // 전체 데이터(프로필 + 계좌) 새로고침 요청
                    await accountViewModel.refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // [중단] 사용자 정보 및 권한 배지
            // -----------------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 사용자 이름
                Text(
                  "${accountState.userName ?? '...'}님,",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),

                // ✨ [권한 배지] 관리자(isAdmin) 또는 감찰부(isAuditor)일 경우 표시
                if (accountState.isAdmin == true || accountState.isAuditor == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // 반투명 흰색 배경
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        // 아이콘 (관리자 vs 감찰)
                        Icon(
                          accountState.isAdmin ? Icons.admin_panel_settings : Icons.remove_red_eye,
                          size: 14,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        // 텍스트
                        Text(
                          accountState.isAdmin ? '관리자' : '감찰부',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // -----------------------------------------------------------------
            // [하단] 사용자 ID
            // -----------------------------------------------------------------
            Text(
              "ID: ${accountState.userId ?? '...'}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}