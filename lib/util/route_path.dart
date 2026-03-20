import 'package:flutter/material.dart';

import '../theme/constrained_screen.dart';
import '../view/authority/authority_view.dart';
import '../view/home/home_view.dart';
import '../view/login/login_view.dart';
import '../view/register/register_view.dart';
import '../view/splash/splash_view.dart';
import '../view/transaction_history/transation_history_view.dart';
import '../view/transfer/transfer_view.dart';

/// ----------------------------------------------------------------------------
/// [RoutePath]
/// 앱의 모든 화면 이동 경로(Route)를 관리하는 클래스입니다.
/// 라우트 이름 상수와 화면 생성 로직(onGenerateRoute)을 포함합니다.
/// ----------------------------------------------------------------------------
abstract class RoutePath {
  // 1. 라우트 이름 상수 정의 (오타 방지 및 유지보수 용이)
  static const String login = 'login';
  static const String home = 'home';
  static const String splash = 'splash';
  static const String register = 'register';
  static const String transfer_history = 'transfer_history';
  static const String account_authority = 'account_authority';

  // 2. 라우트 생성자 (Navigator.pushNamed 호출 시 실행됨)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    late final Widget page;

    // 전달된 이름(settings.name)에 따라 이동할 화면 결정
    switch (settings.name) {
      case RoutePath.login:
        page = const LoginView();
        break;

      case RoutePath.splash:
        page = const SplashView();
        break;

      case RoutePath.register:
        page = const RegisterView();
        break;

    // [파라미터 전달 예시 1] 단순 String 전달
      case RoutePath.account_authority:
      // arguments를 String으로 안전하게 캐스팅 (없으면 빈 문자열)
        final accountNumber = settings.arguments as String? ?? '';
        page = AccountPermissionScreen(
          accountNumber: accountNumber,
        );
        break;

      case RoutePath.home:
        page = const HomeView();
        break;

    // [파라미터 전달 예시 2] 여러 값을 Map으로 전달
      case RoutePath.transfer_history:
      // arguments를 Map으로 캐스팅
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        page = TransactionHistoryScreen(
          // Map에서 키를 통해 데이터 추출 후 위젯에 전달
          accountNumber: args['senderAccountNumber'] ?? '',
          isMyAccount: args['isMyAccount'] ?? false,
          accountName: args['accountName'],
        );
        break;

      default:
      // 정의되지 않은 라우트일 경우 스플래시 화면으로 이동 (혹은 에러 페이지)
        page = const SplashView();
    }

    // 3. 최종 페이지 반환
    // ✨ 모든 화면을 ConstrainedScreen으로 감싸서 웹/태블릿에서 너무 넓어지는 것을 방지
    return MaterialPageRoute(
      builder: (context) => ConstrainedScreen(child: page),
    );
  }
}