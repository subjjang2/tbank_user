import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';
import 'package:tbank_user/view/register/register_view_model.dart';
import '../../../../theme/foundation/app_theme.dart';
import '../../../../util/route_path.dart';

import '../base_view.dart';
import 'register_view_model.dart';

/// ----------------------------------------------------------------------------
/// [RegisterView]
/// 사용자 회원가입 화면입니다.
/// 아이디, 이름, 비밀번호, 그리고 초기 계좌 정보를 입력받아 가입을 진행합니다.
/// ----------------------------------------------------------------------------
class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  // ---------------------------------------------------------------------------
  // 1. 상태 관리 변수들
  // ---------------------------------------------------------------------------
  // UI 로딩 상태 (버튼 스피너 등)
  bool isVerifyingCode = false; // 인증 확인 중
  bool isRegistering = false;   // 가입 요청 중
  bool isSendingCode = false;   // 인증 코드 발송 중

  // 이메일 인증 관련 상태 (현재는 UI 주석 처리됨)
  bool codeSent = false;           // 코드 전송 여부
  bool showVerificationUI = false; // 인증 코드 입력창 표시 여부
  bool codeSentOk = true;          // 인증 성공 여부 (기본값 true로 임시 설정)

  // 유효성 검사 (에러 표시용)
  bool _showErrors = false;        // '가입하기' 버튼 클릭 시 true로 변경
  String? verificationError;       // 인증 에러 메시지

  // ---------------------------------------------------------------------------
  // 2. 컨트롤러 (입력값 제어)
  // ---------------------------------------------------------------------------
  final idController = TextEditingController();
  final nameController = TextEditingController();
  final emailIdController = TextEditingController(); // 현재 미사용
  final codeController = TextEditingController();    // 현재 미사용
  final pwController = TextEditingController();
  final confirmPwController = TextEditingController();

  // ✨ 계좌명 입력 (사업부, 개인 등)
  final _accountNameController = TextEditingController();

  @override
  void dispose() {
    // 메모리 누수 방지
    idController.dispose();
    nameController.dispose();
    emailIdController.dispose();
    codeController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // 3. 유효성 검사 (실시간 UI 업데이트용)
    // -------------------------------------------------------------------------
    // _showErrors가 true일 때(버튼 클릭 후)만 빨간 에러 메시지를 보여줍니다.
    final idEmpty = _showErrors && idController.text.isEmpty;
    final nameEmpty = _showErrors && nameController.text.isEmpty;
    final accountNameEmpty = _showErrors && _accountNameController.text.isEmpty;
    final pwShort = _showErrors && pwController.text.length < 6;
    final pwMismatch = _showErrors && pwController.text != confirmPwController.text;

    return BaseView(
      appBar: AppBar(
        title: const Text("회원가입"),
        backgroundColor: ref.color.background, // 테마 색상 적용
        centerTitle: true,
      ),
      viewModelProvider: registerViewModelProvider,
      builder: (ref, viewModel, state) {
        return Center(
          child: Container(
            width: 400, // 웹/태블릿 대응용 최대 너비 제한
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // -----------------------------------------------------------
                  // [섹션 1] 초기 계좌 설정 및 권한 동의
                  // -----------------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 계좌 별칭 입력
                        _buildLabeledField(
                            10,
                            "계좌 별칭",
                            Icons.account_balance_wallet,
                            _accountNameController,
                            "예: 사업부, 개인통장",
                            showError: accountNameEmpty,
                            errorMsg: "계좌명을 입력해주세요."
                        ),
                        const SizedBox(height: 10),

                        // 감찰 동의 체크박스
                        InkWell(
                          onTap: () => viewModel.toggleAuditorAllowed(!state.isAuditorAllowed),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24, width: 24,
                                child: Checkbox(
                                  value: state.isAuditorAllowed,
                                  activeColor: ref.color.primary,
                                  onChanged: (val) => viewModel.toggleAuditorAllowed(val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text("감찰부의 거래 내역 조회를 허용합니다.", style: TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // -----------------------------------------------------------
                  // [섹션 2] 기본 정보 입력 (아이디, 이름)
                  // -----------------------------------------------------------
                  _buildLabeledField(10, "아이디", Icons.person, idController, "사용할 아이디를 입력하세요", showError: idEmpty, errorMsg: "아이디를 입력해주세요."),
                  const SizedBox(height: 16),
                  _buildLabeledField(10, "이름", Icons.credit_card, nameController, "이름을 입력하세요", showError: nameEmpty, errorMsg: "이름을 입력해주세요."),
                  const SizedBox(height: 16),

                  // [섹션 3] 이메일 인증 (현재 주석 처리됨)
                  /* ...이메일 인증 UI 코드... */

                  // -----------------------------------------------------------
                  // [섹션 4] 비밀번호 설정
                  // -----------------------------------------------------------
                  _buildLabeledField(10, "비밀번호", Icons.lock, pwController, "비밀번호를 입력하세요", obscure: false, showError: pwShort, errorMsg: "비밀번호는 6자 이상이어야 합니다."),
                  const SizedBox(height: 16),
                  _buildLabeledField(10, "비밀번호 확인", Icons.lock, confirmPwController, "비밀번호를 다시 입력하세요", obscure: false, showError: pwMismatch, errorMsg: "비밀번호가 일치하지 않습니다."),
                  const SizedBox(height: 24),

                  // -----------------------------------------------------------
                  // [하단] 회원가입 완료 버튼
                  // -----------------------------------------------------------
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      // 로딩 중이면 버튼 비활성화
                      onPressed: state.isBusy
                          ? null
                          : () async {
                        // 1. 에러 검사 시작 알림
                        setState(() => _showErrors = true);

                        try {
                          // 2. 입력값 추출 및 검증
                          final id = idController.text.trim();
                          final name = nameController.text.trim();
                          final email = "${emailIdController.text.trim()}@castis.com";
                          final pw = pwController.text;
                          final code = codeController.text.trim(); // 인증 코드 (미사용 시 무시)

                          if (id.isEmpty || name.isEmpty || pw.length < 6 || pw != confirmPwController.text || !codeSentOk) {
                            setState(() => isRegistering = false);
                            return; // 조건 불만족 시 중단
                          }

                          // 3. ViewModel 호출 (회원가입 요청)
                          final errorMsg = await viewModel.signup(
                            name: nameController.text.trim(),
                            password: pwController.text,
                            accountName: _accountNameController.text.trim(),
                            userId: idController.text.trim(),
                            email: emailIdController.text.trim(),
                          );

                          // 4. 결과 처리
                          if (errorMsg == null) {
                            // 성공 시 로그인 화면으로 이동
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text("가입 및 계좌 개설 완료!"), backgroundColor: ref.color.toastContainer),
                              );
                              Navigator.pushReplacementNamed(context, RoutePath.login);
                            }
                          } else {
                            // 실패 시 알림창 표시
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("가입 실패"),
                                  content: Text(errorMsg),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인"))],
                                ),
                              );
                            }
                          }
                        } catch (e, stackTrace) {
                          if (kDebugMode) {
                            print("🔥 에러 발생: $e");
                            print("📍 위치: $stackTrace");
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ref.color.primary,
                        foregroundColor: ref.color.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: state.isBusy
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text("회원가입 완료", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // [Helper Widget] 공통 입력 필드 빌더
  // ---------------------------------------------------------------------------
  Widget _buildLabeledField(
      int? maxLength,
      String label,
      IconData icon,
      TextEditingController controller,
      String hint, {
        bool obscure = false,
        bool showError = false,
        String errorMsg = "",
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          maxLength: maxLength, // 글자수 제한
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            errorText: showError ? errorMsg : null, // 에러 메시지 표시
            counterText: "", // 카운터(0/10) 숨김
          ),
        ),
      ],
    );
  }
}