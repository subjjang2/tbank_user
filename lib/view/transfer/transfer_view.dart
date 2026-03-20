import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';
import 'package:tbank_user/view/transfer/transfer_view_model.dart';
import 'package:tbank_user/view/transfer/transfer_view_state.dart';

import '../../repository/response/account_response.dart';
import '../../theme/hide_keyboard.dart';
import '../../util/app_dialog.dart';
import '../../util/helper/IntlHelper.dart';
import '../../util/helper/acoountnumberfomatter.dart';
import '../../util/route_path.dart';
import '../account_info/account_info_view_model.dart';
import '../account_info/account_info_view_state.dart';
import '../base_view.dart';

/// ----------------------------------------------------------------------------
/// [TransferScreen]
/// 사용자가 출금 계좌에서 타인에게 돈을 이체하는 화면입니다.
///
/// 주요 기능:
/// 1. 출금 계좌 잔액 확인
/// 2. 받는 사람 계좌번호 입력 및 실명 검증
/// 3. 이체 금액 및 메모 입력 (수수료 자동 계산)
/// 4. 최종 이체 확인 다이얼로그 및 실행
/// ----------------------------------------------------------------------------
class TransferScreen extends ConsumerStatefulWidget {
  final String senderAccountNumber; // 이체를 실행할 출금 계좌번호

  const TransferScreen({super.key, required this.senderAccountNumber});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  // 1. UI 입력을 제어하는 컨트롤러들
  final TextEditingController _targetAccountController = TextEditingController(); // 받는 계좌
  final TextEditingController _amountController = TextEditingController();        // 보낼 금액
  final TextEditingController _noteController = TextEditingController();          // 메모

  // 로컬 상태 (검증 로딩 표시용)
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // 2. 화면 진입 시 초기 데이터 로드
    // addPostFrameCallback: 위젯 빌드가 끝난 후 안전하게 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // (1) 시스템 설정(이체 수수료 등) 가져오기
      ref.read(transferViewModelProvider.notifier).fetchSystemConfig();
      // (2) 출금 계좌의 상세 정보(잔액 등) 가져오기
      ref.read(accountInfoViewModelProvider.notifier).accountInfo(widget.senderAccountNumber);
    });
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _targetAccountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // 3. [로직] 받는 계좌 실명 검증
  Future<void> _verifyTargetAccount() async {
    final accountNum = _targetAccountController.text;
    if (accountNum.isEmpty) return;

    // ViewModel을 통해 서버에 계좌 조회 요청
    await ref.read(transferViewModelProvider.notifier).checkAccountName(accountNum);

    // 키보드 내리기 (UX 향상)
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {

    // -------------------------------------------------------------------------
    // 4. 상태 리스너 (Side Effects 처리)
    // 화면 이동이나 다이얼로그 표시는 build 내부가 아닌 listen으로 처리해야 안전합니다.
    // -------------------------------------------------------------------------

    // [성공 리스너] 이체 성공 시 홈 화면으로 이동
    ref.listen<TransferViewState>(transferViewModelProvider, (previous, next) {
      if (next.isTransferOk && (previous?.isTransferOk == false)) {
        AppDialog.showSuccess(
          context,
          message: "이체가 완료 되었습니다.",
          onConfirm: () {
            // 모든 스택을 지우고 홈으로 이동 (뒤로가기 방지)
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutePath.home,
                  (route) => false,
            );
          },
        );
      }
    });

    // [에러 리스너] 에러 발생 시 다이얼로그 표시
    ref.listen<TransferViewState>(transferViewModelProvider, (previous, next) {
      if (next.isError && (previous?.isError == false)) {
        AppDialog.showError(
          context,
          message: next.errorMessage ?? "알 수 없는 오류가 발생했습니다.",
          onConfirm: () {
            // 확인 버튼 클릭 시 로직 (필요하면 추가)
          },
        );
      }
    });

    // 5. UI 구성
    return BaseView(
      viewModelProvider: transferViewModelProvider,
      builder: (ref, viewModel, state) => HideKeyboard( // 화면 터치 시 키보드 내림
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6FA), // 배경색

          // 상단 앱바
          appBar: AppBar(
            title: const Text("이체하기", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: const Color(0xFFF4F6FA),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            centerTitle: true,
          ),

          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------------------------------------
                      // [섹션 1] 출금 계좌 정보 카드
                      // ------------------------------------------------
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("출금 계좌", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 계좌명 및 번호
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(ref.watch(accountInfoViewModelProvider).accountSearchResponse?.accountName ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(ref.watch(accountInfoViewModelProvider).accountSearchResponse?.accountNumber ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // 출금 가능 잔액
                            const Text("출금 가능 잔액", style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: IntlHelper.currency(ref.watch(accountInfoViewModelProvider).accountSearchResponse?.balance ?? ""),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.black87),
                                  ),
                                  TextSpan(
                                    text: " cas",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: ref.color.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ------------------------------------------------
                      // [섹션 2] 받는 계좌 입력 및 검증
                      // ------------------------------------------------
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("받는 분 계좌", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAccountNumberTextField(
                              controller: _targetAccountController,
                              hintText: "계좌번호 입력",
                              inputType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // [확인] 버튼
                          ElevatedButton(
                            onPressed: _isVerifying ? null : _verifyTargetAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ref.color.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isVerifying
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("확인", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),

                      // [검증 결과 표시] 계좌 확인 성공 시 이름 표시
                      if (state.accountName != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: ref.color.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: ref.color.primary, size: 20),
                              const SizedBox(width: 10),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                                  children: [
                                    const TextSpan(text: "[계좌명] : "),
                                    TextSpan(text: state.accountName, style: TextStyle(fontWeight: FontWeight.bold, color: ref.color.primary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ------------------------------------------------
                      // [섹션 3] 금액 및 메모 입력
                      // ------------------------------------------------
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text("이체 정보", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          ),
                          // 수수료 표시 (ViewModel에서 계산된 값)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("수수료", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(width: 6),
                              Text(
                                "${IntlHelper.currency(ref.watch(transferViewModelProvider).fee)} cas",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 금액 입력 필드 (Currency Formatter 적용됨)
                      _buildAmountTextField(
                        controller: _amountController,
                        hintText: "0",
                        suffixText: "cas",
                        inputType: TextInputType.number,
                        isAmount: true,
                      ),
                      const SizedBox(height: 12),

                      // 메모 입력 필드
                      _buildTextField(
                        controller: _noteController,
                        hintText: "통장에 표시할 내용 (선택)",
                      ),

                      const SizedBox(height: 40), // 하단 여백
                    ],
                  ),
                ),
              ),

              // ------------------------------------------------
              // [하단] 이체하기 버튼 (고정 영역)
              // ------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ]
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      // 조건: 받는 사람 계좌 검증 완료 && 금액 입력됨
                      onPressed: (ref.watch(transferViewModelProvider).accountName != null && _amountController.text.isNotEmpty)
                          ? () {
                        // 키보드 내리기
                        FocusScope.of(context).unfocus();
                        // 최종 확인 다이얼로그 띄우기
                        _showConfirmationDialog();
                      }
                          : null, // 조건 불충족 시 비활성화
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ref.color.primary,
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("이체하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
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
  // [Helper Widgets] 입력 필드 빌더들
  // ---------------------------------------------------------------------------

  // 1. 계좌번호 입력 필드 (하이픈 자동 삽입)
  Widget _buildAccountNumberTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType inputType = TextInputType.text,
    String? suffixText,
    bool isAmount = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        style: TextStyle(
            fontSize: isAmount ? 18 : 16,
            fontWeight: isAmount ? FontWeight.bold : FontWeight.normal
        ),
        controller: _targetAccountController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixText: suffixText,
          suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ref.color.primary.withOpacity(0.5), width: 1.5),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // 숫자만 허용
          AccountNumberFormatter(), // ****-**** 형태로 자동 변환
        ],
        onChanged: (value) {
          // 필요 시 입력값 변경 감지 로직 추가
        },
      ),
    );
  }

  // 2. 금액 입력 필드 (3자리 콤마 자동 삽입)
  Widget _buildAmountTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType inputType = TextInputType.text,
    String? suffixText,
    bool isAmount = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        textAlign: isAmount ? TextAlign.end : TextAlign.start,
        style: TextStyle(
            fontSize: isAmount ? 18 : 16,
            fontWeight: isAmount ? FontWeight.bold : FontWeight.normal
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixText: suffixText,
          suffixStyle:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ref.color.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ref.color.primary.withOpacity(0.5), width: 1.5),
          ),
        ),
        inputFormatters: [
          CurrencyTextInputFormatter.currency(
            locale: 'ko_KR', // 한국어 로케일 (3자리 콤마 자동)
            decimalDigits: 0, // 소수점 제거
            symbol: '',       // 화폐 기호 제거 (숫자만)
          )
        ],
      ),
    );
  }

  // 3. 일반 텍스트 필드 (메모용)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType inputType = TextInputType.text,
    String? suffixText,
    bool isAmount = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        textAlign: isAmount ? TextAlign.end : TextAlign.start,
        style: TextStyle(
            fontSize: isAmount ? 18 : 16,
            fontWeight: isAmount ? FontWeight.bold : FontWeight.normal
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixText: suffixText,
          suffixStyle:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ref.color.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ref.color.primary.withOpacity(0.5), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [Dialog] 최종 이체 확인 다이얼로그
  // ---------------------------------------------------------------------------
  void _showConfirmationDialog() {
    final state = ref.read(transferViewModelProvider);
    final amount = _amountController.text;
    final receiverName = state.accountName ?? "이름 없음";
    final receiverAccount = _targetAccountController.text;

    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 터치로 닫기 방지 (중요한 작업이므로)
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Icon(Icons.monetization_on_outlined, color: Colors.blueAccent, size: 40),
              SizedBox(height: 10),
              Text("이체 정보를 확인해주세요", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                // 1. 받는 분 정보 확인
                _buildConfirmRow("받는 분", "$receiverName 님"),
                _buildConfirmRow("계좌번호", receiverAccount),

                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),

                // 2. 보낼 금액 확인 (강조)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("보낼 금액", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),

                    // Text.rich로 금액과 단위를 분리하여 스타일링
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: amount,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ref.color.text,
                            ),
                          ),
                          const TextSpan(
                            text: " cas",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green, // 요청하신 녹색 강조
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 3. 메모 확인 (입력했을 경우만)
                if (_noteController.text.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "메모: ${_noteController.text}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                // 취소 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("취소"),
                  ),
                ),
                const SizedBox(width: 8),
                // 보내기(확정) 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // 1. 금액에서 콤마(,) 제거하여 순수 숫자로 변환
                      final rawAmount = _amountController.text.replaceAll(',', '');

                      Navigator.pop(context); // 다이얼로그 먼저 닫기

                      // 2. ViewModel의 이체 로직 실행 (비동기)
                      await ref.read(transferViewModelProvider.notifier).transfer(
                          fromAccountNumber: ref.watch(accountInfoViewModelProvider).accountSearchResponse?.accountNumber ?? '',
                          toAccountNumber: _targetAccountController.text,
                          amount: rawAmount ?? "",
                          memo: _noteController.text
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ref.color.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text("보내기", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // [Dialog Helper] 확인창 내부 행 위젯
  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}