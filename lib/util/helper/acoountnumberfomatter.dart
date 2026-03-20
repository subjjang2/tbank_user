import 'package:flutter/services.dart';

class AccountNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 1. 입력된 값에서 숫자만 추출
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. 8자리까지만 입력 허용
    if (newText.length > 8) {
      newText = newText.substring(0, 8);
    }

    // 3. 포맷팅 로직 (4자리-4자리)
    String formattedText = newText;
    if (newText.length > 4) {
      formattedText = '${newText.substring(0, 4)}-${newText.substring(4)}';
    }

    // 4. 커서 위치 조정 (항상 끝으로 이동하지 않고 자연스럽게 처리)
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}