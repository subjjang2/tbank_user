import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/transfer_repository.dart';
import '../repository/response/account_search/account_searchtype_response.dart';

// ✨ [수정] 에러가 발생해도 앱이 죽지 않도록 try-catch 추가
final accountStatusProvider = FutureProvider.family.autoDispose<String, String>((ref, accountNumber) async {
  try {
    // 1. Repository 호출 (여기서 네트워크 에러가 나면 throw가 발생함)
    final result = await ref.read(transRepositoryProvider).searchAccount(
      accountNumber: accountNumber,
      type: AccountSearchType.check,
    );

    // 2. 정상 성공 시 상태값 리턴
    return result?.status ?? 'UNKNOWN';

  } catch (e) {
    // 🛡️ [방어 코드]
    // 서버가 꺼졌거나 인터넷이 안 돼서 에러가 날아오면 여기서 잡습니다.
    // 에러를 무시하고 'UNKNOWN'을 리턴해서 UI가 계속 그려지게 합니다.

    return 'UNKNOWN';
  }
});