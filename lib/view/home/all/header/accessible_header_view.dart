import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';

import '../../../../theme/refresh/refresh_btn.dart';
import '../accessible_view_model.dart';


class AccessibleAccountsHeader extends ConsumerWidget {
  final ScrollController scrollController;

  const AccessibleAccountsHeader({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 상태 및 뷰모델 구독
    final state = ref.watch(accessibleAccountsViewModelProvider);
    final viewModel = ref.read(accessibleAccountsViewModelProvider.notifier);
    final primaryColor = ref.color.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3F51B5), // Deep Indigo (참조 코드와 동일)
            primaryColor,            // Theme Primary
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
            // 상단 Row (뒤로가기 + 타이틀 + 새로고침)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // [좌측] 뒤로가기 + 아이콘 + 타이틀
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,

                  children: [
                    // 뒤로가기 버튼
                    // 아이콘 (권한/이체 = 열쇠)
                    const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    // 타이틀
                    const Text(
                      "이체 권한",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),

                // [우측] 새로고침 버튼
                RefreshIconButton(
                  scrollController: scrollController,
                  // AccessibleState에 isHeaderRefreshing이 없다면 isBusy로 대체
                  isLoading: state.isBusy,
                  onPressed: () async {
                    await viewModel.refresh();
                  },
                ),
              ],
            ),


            // [하단] 계좌 개수 요약 정보 (선택 사항)

          ],
        ),
      ),
    );
  }
}