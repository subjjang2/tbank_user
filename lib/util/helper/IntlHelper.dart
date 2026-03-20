import 'package:intl/intl.dart';
class IntlHelper {
  // 1. 통화 포맷 (예: 1,234,567)
  static String currency(dynamic number) {
    if (number == null) return '0';

    // 숫자가 문자열로 들어오면 double로 변환 시도
    double value = 0;
    if (number is String) {
      value = double.tryParse(number) ?? 0;
    } else if (number is num) {
      value = number.toDouble();
    }

    // 3자리마다 콤마 찍기 (#,###)
    // (소수점 이하는 버림 처리하려면 decimalDigits: 0)
    final formatter = NumberFormat("#,###", "ko_KR");
    return formatter.format(value);
  }

// 백엔드에서 받은 UTC 시간을 한국 시간으로 변환해서 보여줌
  static String dateTimeStr(String? dateString) {
    if (dateString == null) return '';

    // UTC로 파싱 후 한국 시간으로 변환
    final date = DateTime.parse(dateString).toLocal();

    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }

  // 1. 반환 타입에 ?를 붙여야 null을 반환할 수 있습니다.
  static DateTime? dateTime(String? dateString) {
    if (dateString == null) {
      return DateTime(2000, 1, 1);
    }

    // 2. 안전한 파싱을 위해 tryParse 권장 (형식이 잘못됐을 때 에러 방지)
    // UTC('Z'로 끝나는 문자열)를 받아서 기기 설정 시간(한국이면 KST)으로 변환
    return DateTime.tryParse(dateString)?.toLocal();
  }
}