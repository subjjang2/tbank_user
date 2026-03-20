import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';
import 'package:tbank_user/view/splash/splash_view_model.dart';
import '../../../../util/route_path.dart';
import '../base_view.dart';


class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {

  @override
  void initState() {
    super.initState();
    // 화면 시작 시 검사 실행
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final viewModel = ref.read(splashViewModelProvider.notifier);
    final isLoggedIn = await viewModel.checkLoginStatus();

    if (!mounted) return;

    if (isLoggedIn) {
      // 로그인 되어있으면 메인 화면으로
      Navigator.pushReplacementNamed(context, RoutePath.login);
    } else {
      // 아니면 로그인 화면으로
      Navigator.pushReplacementNamed(context, RoutePath.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      viewModelProvider: splashViewModelProvider,
      builder: (ref, viewModel, state) {
        // 테마 컬러 가져오기 (코드는 그대로 유지하되 활용)
        final primaryColor = ref.color.primary;
        // 배경색을 primary로 하고 아이콘을 흰색으로 반전시킬 수도 있습니다.
        // 여기서는 배경을 흰색(기본 Scaffold), 아이콘을 Primary로 유지합니다.

        return Scaffold(
          backgroundColor: Colors.white, // 혹은 ref.color.background
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 로고 아이콘 (크기 약간 키움)
                Icon(Icons.account_balance_rounded, size: 100, color: primaryColor),
                const SizedBox(height: 24),

                // 2. 앱 이름 텍스트 추가
                Text(
                  'T BANK',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),


                const SizedBox(height: 48),

                // 4. 로딩 인디케이터 (로그인 체크가 길어질 경우 대비)

              ],
            ),
          ),
        );
      },
    );
  }
}