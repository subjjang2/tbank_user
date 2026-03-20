import 'package:flutter/material.dart';

class AppDialog {
  // 인스턴스화 방지 (static 메서드만 사용)
  AppDialog._();

  /// 에러 다이얼로그 (붉은색 테마)
  static void showError(
      BuildContext context, {
        required String message,
        String title = "알림",
        String buttonText = "확인",
        VoidCallback? onConfirm, // 확인 버튼 눌렀을 때 추가 동작 (예: resetError)
      }) {
    showDialog(
      context: context,
      barrierDismissible: false, // 1. 바깥 터치 막기
      builder: (context) {
        // ✨ 2. 뒤로가기 버튼 막기 (PopScope 추가)
        return PopScope(
          canPop: false, // 뒤로가기 제스처/버튼을 아예 무시함
          child: _BaseDialog(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            bgColor: Colors.red.withOpacity(0.1),
            title: title,
            message: message,
            buttonText: buttonText,
            buttonColor: Colors.red,
            onConfirm: onConfirm,
          ),
        );
      },
    );
  }


  /// (옵션) 성공 다이얼로그 (파란색/초록색 테마) - 나중에 필요하면 쓰세요
  static void showSuccess(
      BuildContext context, {
        required String message,
        String title = "성공",
        VoidCallback? onConfirm,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
      canPop: false, // 뒤로가기 제스처/버튼을 아예 무시함
      child: _BaseDialog(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        bgColor: Colors.green.withOpacity(0.1),
        title: title,
        message: message,
        buttonText: "확인",
        buttonColor: Colors.green,
        onConfirm: onConfirm,
      ),
      ),
    );
  }
}

// 내부적으로만 쓰이는 다이얼로그 UI 위젯
class _BaseDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String message;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback? onConfirm;

  const _BaseDialog({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.buttonColor,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 아이콘 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 40),
          ),
          const SizedBox(height: 20),

          // 2. 제목
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // 3. 메시지
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 24),

          // 4. 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 닫기 먼저 수행
                if (onConfirm != null) onConfirm!(); // 추가 동작 실행
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}