import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Error: 읽을 파일 경로를 입력하세요.');
    return;
  }

  final apiKey ='';
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY 환경변수가 설정되지 않았습니다. 터미널을 완전히 껐다 켜보세요.');
    return;
  }

  final file = File(args[0]);
  final content = await file.readAsString();

  // 💡 해결! 구글 최신 API 정책에 맞춘 gemini-2.5-flash 모델로 변경
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
  final request = await HttpClient().postUrl(url);
  request.headers.set('Content-Type', 'application/json');
  request.add(utf8.encode(jsonEncode({
    "contents": [{"parts": [{"text": "너는 시니어 Flutter 아키텍트야. 다음 클로드의 개발 플랜을 읽고, 아키텍처 규칙 위반이나 잠재적 버그를 날카롭게 리뷰해줘:\n\n$content"}]}]
  })));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  final jsonResponse = jsonDecode(responseBody);

  // 🚨 에러가 발생했는지 먼저 확인하는 로직
  if (jsonResponse.containsKey('error')) {
    print('\n[제미나이 API 에러 발생!]');
    print('에러 메시지: ${jsonResponse['error']['message']}');
    return;
  }

  // 정상 응답일 경우 처리
  if (jsonResponse['candidates'] != null && jsonResponse['candidates'].isNotEmpty) {
    print(jsonResponse['candidates'][0]['content']['parts'][0]['text']);
  } else {
    print('알 수 없는 응답입니다: $responseBody');
  }
}