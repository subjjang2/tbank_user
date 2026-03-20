import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';
import '../../util/app_dialog.dart';
import '../../util/route_path.dart';
import '../base_view.dart';
import 'create_account_view_model.dart';
import 'create_account_view_state.dart';

/// ----------------------------------------------------------------------------
/// [CreateAccountView]
/// 신규 계좌 개설 신청 화면입니다.
/// 기능: 계좌 별칭 입력, 감찰 동의, 개설 신청 API 호출
/// ----------------------------------------------------------------------------
class CreateAccountView extends ConsumerStatefulWidget {
  const CreateAccountView({super.key});

  @override
  ConsumerState<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends ConsumerState<CreateAccountView> {
  // 계좌 별칭 입력 컨트롤러
  final _accountNameController = TextEditingController();

  // '신청' 버튼 클릭 후 에러 메시지를 표시하기 위한 플래그
  bool _showErrors = false;

  @override
  void dispose() {
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel 상태 구독
    final state = ref.watch(createAccountViewModelProvider);

    // 🔹 [상태 리스너] API 결과(성공/실패)에 따른 팝업 처리
    ref.listen<CreateAccountState>(createAccountViewModelProvider, (previous, next) {
      // 1. 성공 시: 성공 팝업 -> 홈 화면으로 이동 (스택 초기화)
      if (next.isSuccess && (previous?.isSuccess == false)) {
        AppDialog.showSuccess(
          context,
          message: "계좌 개설 신청이 완료되었습니다.\n관리자 승인 후 사용 가능합니다.",
          onConfirm: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutePath.home,
                  (route) => false,
            );
          },
        );
      }
      // 2. 실패 시: 에러 팝업 표시
      if (next.isError && (previous?.isError == false)) {
        AppDialog.showError(
          context,
          message: next.errorMessage ?? "알 수 없는 오류가 발생했습니다.",
          onConfirm: () {},
        );
      }
    });

    // 실시간 에러 상태 계산 (버튼 누른 후 && 텍스트 비었을 때)
    final accountNameEmpty = _showErrors && _accountNameController.text.trim().isEmpty;

    return BaseView(
      backgroundColor: ref.color.background,
      viewModelProvider: createAccountViewModelProvider,
      builder: (ref, viewModel, state) {

        // 화면 빈 곳 터치 시 키보드 내리기
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // 1. 상단 헤더 (고정)
              _buildHeader(context, ref.color.primary),

              // 2. 입력 폼 영역 (스크롤 가능)
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: Container(
                      // 웹/태블릿 대응: 최대 너비 제한
                      constraints: const BoxConstraints(maxWidth: 400),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      margin: const EdgeInsets.only(top: 20, bottom: 40),

                      // 카드 스타일 디자인
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 5)
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 타이틀 및 설명
                          const Text(
                            "새로운 계좌를\n만들어 드릴게요",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "용도에 맞는 별칭을 입력해주세요.",
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          // [입력 필드] 계좌 별칭
                          _buildLabeledField(
                            label: "계좌 별칭",
                            icon: Icons.edit_note_rounded,
                            controller: _accountNameController,
                            hint: "예: 예시 사업부",
                            showError: accountNameEmpty,
                            errorMsg: "계좌 별칭을 입력해주세요.",
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 16),

                          // [체크박스] 감찰 동의
                          InkWell(
                            onTap: () => viewModel.toggleAuditorAllowed(!state.isAuditorAllowed),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: state.isAuditorAllowed,
                                      activeColor: ref.color.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) => viewModel.toggleAuditorAllowed(val ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "감찰부 모니터링 허용",
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "거래 내역 조회를 허용합니다.",
                                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // [버튼] 개설 신청
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: state.isBusy
                                  ? null
                                  : () async {
                                // 1. 유효성 검사 시작
                                setState(() => _showErrors = true);
                                FocusScope.of(context).unfocus(); // 키보드 내림

                                if (_accountNameController.text.trim().isEmpty) {
                                  return;
                                }

                                // 2. ViewModel 호출 (계좌 생성 요청)
                                await viewModel.createAccount(
                                  accountName: _accountNameController.text.trim(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ref.color.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: state.isBusy
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text("계좌 개설 신청", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // [UI Helper] 라벨이 있는 입력 필드
  // ---------------------------------------------------------------------------
  Widget _buildLabeledField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool showError = false,
    String errorMsg = "",
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, size: 22, color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFFF5F6F8), // 연한 회색 배경
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF3F51B5).withOpacity(0.5), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            errorText: showError ? errorMsg : null, // 에러 메시지 표시
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // [UI Helper] 상단 그라데이션 헤더
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 24, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3F51B5), // 상단 포인트 컬러
            primaryColor,            // 테마 메인 컬러
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_card, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "계좌 개설",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}