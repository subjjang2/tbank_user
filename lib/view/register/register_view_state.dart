import '../base_view_state.dart';

/// ----------------------------------------------------------------------------
/// [RegisterViewState]
/// 회원가입 화면의 모든 UI 상태를 담는 클래스입니다.
/// 이메일 인증 진행 단계, 로딩 상태, 감찰 동의 여부 등을 포함합니다.
/// ----------------------------------------------------------------------------
class RegisterViewState extends BaseViewState {

  // 1. [로딩 상태] 버튼 스피너 제어용
  final bool isSendingCode;    // 인증코드 '전송' 버튼 로딩 중인가?
  final bool isVerifyingCode;  // 인증코드 '확인' 버튼 로딩 중인가?

  // 2. [UI 제어 플래그] 이메일 인증 단계 관리
  final bool codeSent;            // 코드가 전송되었는가? (이메일 입력창 비활성화 용)
  final bool showVerificationUI;  // 인증코드 입력창을 보여줄 것인가?
  final bool codeSentOk;          // 인증이 최종 성공했는가? (가입 버튼 활성화 용)

  // 3. [에러 메시지] 이메일 인증 전용
  final String? verificationError; // 예: "코드가 일치하지 않습니다"

  // 4. [비즈니스 로직] 약관 동의
  final bool isAuditorAllowed;     // 감찰 부서 조회 동의 여부 (체크박스)

  const RegisterViewState({
    // BaseViewState 상속 필드
    required this.isBusy,        // 전체 화면 로딩 (가입 요청 중)
    required this.isError,       // 전체 화면 에러 (가입 실패)
    required this.errorMessage,  // 에러 메시지

    // 초기값 설정
    this.isSendingCode = true,   // (참고: 보통 false로 시작하나, 코드상 true로 되어있음)
    this.isVerifyingCode = false,
    this.codeSent = false,
    this.showVerificationUI = false,
    this.codeSentOk = true,      // (참고: 기본값이 true면 인증 없이 넘어갈 수 있으니 로직 확인 필요)
    this.verificationError,
    this.isAuditorAllowed = true, // 기본적으로 동의 상태로 시작
  });

  @override
  final bool isBusy;
  @override
  final bool isError;
  @override
  final String errorMessage;

  // ---------------------------------------------------------------------------
  // [copyWith] 상태 불변성 유지를 위한 복사 메서드
  // 변경하고 싶은 값만 인자로 넘겨서 새로운 객체를 만듭니다.
  // ---------------------------------------------------------------------------
  RegisterViewState copyWith({
    bool? isBusy,
    bool? isError,
    String? errorMessage,
    bool? isSendingCode,
    bool? isVerifyingCode,
    bool? codeSent,
    bool? showVerificationUI,
    bool? codeSentOk,
    String? verificationError,
    bool? isAuditorAllowed,
  }) {
    return RegisterViewState(
      isBusy: isBusy ?? this.isBusy,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      isSendingCode: isSendingCode ?? this.isSendingCode,
      isVerifyingCode: isVerifyingCode ?? this.isVerifyingCode,
      codeSent: codeSent ?? this.codeSent,
      showVerificationUI: showVerificationUI ?? this.showVerificationUI,
      codeSentOk: codeSentOk ?? this.codeSentOk,
      verificationError: verificationError, // null일 수도 있으므로 ?? 사용 안 함 (새 값으로 덮어씀)
      isAuditorAllowed: isAuditorAllowed ?? this.isAuditorAllowed,
    );
  }
}