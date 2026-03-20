import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tbank_user/service/fcm_service.dart';
import 'package:tbank_user/util/route_path.dart';

import 'common/app_global.dart';

/// ----------------------------------------------------------------------------
/// [백그라운드 메시지 핸들러]
/// 앱이 꺼져있거나(Terminated) 백그라운드(Background) 상태일 때 알림을 수신하면 호출됩니다.
/// ⚠️ 주의: 이 함수는 반드시 최상위 수준(Top-level)에 선언되어야 합니다.
/// ----------------------------------------------------------------------------
@pragma('vm:entry-point') // 네이티브(Android/iOS)에서 Dart 코드를 호출할 수 있도록 진입점 표시
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서는 UI를 갱신할 수 없으므로 주로 로컬 알림을 띄우거나 로그를 남깁니다.
  print("백그라운드 메시지 수신 ID: ${message.messageId}");
}

void main() async {
  // 1. 플러터 엔진 초기화 (비동기 함수 호출 전 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 파이어베이스 초기화 (google-services.json 설정 로드)
  await Firebase.initializeApp();

  // 3. 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ---------------------------------------------------------------------------
  // ✨ [Riverpod 컨테이너 수동 생성]
  // 보통은 runApp 내부의 ProviderScope가 컨테이너를 알아서 관리하지만,
  // 앱이 렌더링되기 전에(runApp 실행 전) Provider를 사용하기 위해 직접 생성합니다.
  // ---------------------------------------------------------------------------
  final container = ProviderContainer();

  // 4. FCM 서비스 초기화
  // fcmServiceProvider를 읽어서 초기화 함수를 실행합니다.
  // await를 사용했으므로, 초기화(토큰 발급 등)가 끝날 때까지 스플래시 화면 진입이 지연될 수 있습니다.
  // (앱 시작 속도를 높이려면 await를 제거해도 됩니다.)
  await container.read(fcmServiceProvider).initialize();

  runApp(
    // ✨ [UncontrolledProviderScope 사용]
    // 위에서 만든 'container' 변수(이미 초기화된 상태)를 앱 전체에 그대로 주입합니다.
    // 만약 여기서 일반 ProviderScope를 쓰면 새 컨테이너가 만들어져서,
    // 위에서 초기화한 FCM 설정이 증발할 수 있습니다.
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. FCM 토큰 상태 감지 (디버깅용)
    // fcmTokenProvider의 값이 바뀌면(토큰 갱신 등) 이 위젯이 다시 빌드됩니다.
    final token = ref.watch(fcmTokenProvider);
    // 필요하다면 여기서 print(token); 등으로 로그 확인 가능

    return MaterialApp(
      // 🔑 전역 키 설정 (Context 없이 스낵바/네비게이션 제어용)
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,

      // 🌀 로딩 인디케이터(EasyLoading) 초기화 빌더
      builder: EasyLoading.init(),

      debugShowCheckedModeBanner: false,
      title: 'T-BANK',

      // 🚀 라우팅 설정
      initialRoute: RoutePath.splash, // 첫 화면은 스플래시
      onGenerateRoute: RoutePath.onGenerateRoute, // 라우트 생성 로직 연결
    );
  }
}