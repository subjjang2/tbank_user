import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';

import '../../theme/button/button.dart';
import '../../theme/hide_keyboard.dart';
import '../../theme/input_field.dart';
import '../../util/route_path.dart';
import '../base_view.dart';
import 'login_view_model.dart';

/// ----------------------------------------------------------------------------
/// [LoginView]
/// 사용자 로그인 화면입니다.
/// 아이디/비밀번호 입력, 로그인 시도, 에러 메시지 표시, 회원가입 이동 기능을 제공합니다.
/// ----------------------------------------------------------------------------
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  // 1. 입력 컨트롤러 (UI 상태)
  // TextEditingController는 메모리 누수 방지를 위해 Stateful 위젯에서 관리하고 dispose 해야 합니다.
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. 기본 레이아웃 구성
    return BaseView(
      viewModelProvider: loginViewModelProvider, // ViewModel 연결
      builder: (ref, viewModel, state) => HideKeyboard( // 화면 터치 시 키보드 내림
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // 3. 로고 영역
              Center(
                child: Text(
                  "T-Bank",
                  style: ref.typo.headline1.copyWith(
                    fontWeight: ref.typo.semiBold,
                    color: ref.color.primary,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // 4. 입력 필드 영역
              Text("ID", style: ref.typo.headline6),
              const SizedBox(height: 8),
              InputField(
                controller: _idController,
                hint: "아이디를 입력하세요",
              ),
              const SizedBox(height: 24),

              Text("Password", style: ref.typo.headline6),
              const SizedBox(height: 8),
              InputField(
                controller: _pwController,
                hint: "비밀번호를 입력하세요",
              ),
              const SizedBox(height: 23),

              // 5. [에러 메시지] 로그인 실패 시에만 표시 (state.isError)
              if (state.isError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage ?? "로그인에 실패했습니다.",
                          style: ref.typo.body1.copyWith(
                            color: Colors.red,
                            fontWeight: ref.typo.semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 6. 로그인 버튼
              Button(
                width: double.infinity,
                size: ButtonSize.large,
                text: "로그인",
                onPressed: () => _onLoginPressed(viewModel, context),
              ),
              const SizedBox(height: 12),

              // 7. 회원가입 이동 링크
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RoutePath.register);
                  },
                  child: const Text(
                    "👉 아직 계정이 없으신가요? 회원가입하기",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [로직] 로그인 버튼 클릭 시 실행
  // ---------------------------------------------------------------------------
  void _onLoginPressed(LoginViewModel viewModel, BuildContext context) async {
    // 1. ViewModel에 로그인 요청 (비동기)
    // 성공/실패 결과만 boolean으로 받음 (에러 상태는 state에 저장됨)
    final success = await viewModel.login(
        id: _idController.text,
        password: _pwController.text
    );

    // 2. 성공 시 홈 화면으로 이동
    if (success) {
      if (!context.mounted) return; // 비동기 후 context 유효성 체크
      // pushReplacementNamed: 뒤로가기 눌렀을 때 로그인 화면으로 돌아오지 않도록 함
      Navigator.pushReplacementNamed(context, RoutePath.home);
    }
  }
}