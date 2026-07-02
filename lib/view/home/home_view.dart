import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';
import 'package:tbank_user/view/home/view/viewer_view.dart';
import '../../res/palette.dart';
import '../create_account/create_account_view.dart';
import 'all/accessible_view.dart';
import 'my/my_account_view.dart';

/// ----------------------------------------------------------------------------
/// [HomeView]
/// 로그인 후 진입하는 메인 화면입니다.
/// 하단 탭(BottomNavigationBar)을 통해 계좌 목록 및 개설 화면으로 이동합니다.
/// ----------------------------------------------------------------------------
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _selectedIndex = 0; // 현재 활성화된 탭의 인덱스 (0~3)

  @override
  void initState() {
    super.initState();
  }

  // 탭 클릭 시 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 화면 갱신하여 탭 전환
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.color.background, // 테마 배경색 적용

      // ✨ [IndexedStack 사용]
      // 탭을 이동해도 페이지가 파괴되지 않고 '상태를 유지'합니다. (스크롤 위치 등)
      // 단순히 화면의 순서(Z-index)만 바꿔서 보여주는 방식입니다.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // [탭 0] 내 계좌 목록 (메인 기능)
          MyAccountView(),

          // [탭 1] 공유 계좌 (이체 권한이 있는 타인 계좌)
          AccessibleAccountsView(),

          // [탭 2] 조회 계좌 (감찰/조회 권한만 있는 계좌)
          ViewerAccountsView(),

          // [탭 3] 계좌 개설 화면
          const Center(child: CreateAccountView()),
        ],
      ),

      // 하단 내비게이션 바
      bottomNavigationBar: ClipRRect(
        // 상단 모서리를 둥글게 깎아서 부드러운 디자인 적용
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black, // 선택된 아이콘 색상
          unselectedItemColor: Colors.grey, // 선택되지 않은 아이콘 색상
          type: BottomNavigationBarType.fixed, // 탭 개수가 많아도 간격 고정
          backgroundColor: Palette.white,

          // 탭 아이템 정의
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '내계좌'),
            BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: '공유계좌'),
            BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye_rounded), label: '조회계좌'),
            BottomNavigationBarItem(icon: Icon(Icons.add_card), label: '계좌개설'),
          ],
        ),
      ),
    );
  }
}