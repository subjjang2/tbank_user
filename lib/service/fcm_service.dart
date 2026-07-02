import 'dart:convert'; // jsonEncode, jsonDecode 사용을 위해 필요
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 패키지 추가
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/common/app_global.dart';

// 1. FCM 토큰 상태 관리
final fcmTokenProvider = StateProvider<String?>((ref) => null);

// 2. FCM 서비스 프로바이더
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});

class FcmService {
  final Ref _ref;

  // 로컬 알림 플러그인 인스턴스
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 안드로이드 알림 채널 정의
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // name
    description: 'This channel is used for important notifications.',
    importance: Importance.high, // 상단에 팝업처럼 뜨게 함
  );

  FcmService(this._ref);

  Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // --- [1. 로컬 알림 초기화] ---
    await _initLocalNotifications();

    // --- [2. 기본 권한 요청] ---
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // --- [3. 토큰 처리] ---
    final token = await messaging.getToken();
    _ref.read(fcmTokenProvider.notifier).state = token;
    if (kDebugMode) {
      print("FCM Token: $token");
    }

    messaging.onTokenRefresh.listen((newToken) {
      _ref.read(fcmTokenProvider.notifier).state = newToken;
      // TODO: 서버 전송 로직
    });

    // --- [4. 알림 수신 처리] ---

    // Foreground (앱이 켜져 있을 때) -> 로컬 알림 표시
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (kDebugMode) {
        print('Foreground Message: ${notification?.title}');
      }

      if (notification != null && android != null) {
        // 스낵바 대신 로컬 알림 띄우기
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher', // 앱 아이콘 리소스 이름 확인 필요
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          // 핵심: 알림 클릭 시 데이터를 전달하기 위해 payload에 data를 문자열로 변환해 넣음
          payload: jsonEncode(message.data),
        );
      }
    });

    // Background & Terminated 클릭 액션 설정
    await _setupInteractedMessage();
  }

  Future<void> _initLocalNotifications() async {
    // 안드로이드 초기화 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 초기화 설정
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 플러그인 초기화 및 클릭 리스너 등록
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Foreground 알림을 클릭했을 때 실행됨
        if (details.payload != null) {
          try {
            // payload(문자열)를 다시 Map으로 변환하여 핸들링
            final Map<String, dynamic> data = jsonDecode(details.payload!);
            _handleData(data);
          } catch (e) {
            if (kDebugMode) {
              print('Payload 파싱 에러: $e');
            }
          }
        }
      },
    );

    // 안드로이드 채널 생성 (필수)
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _setupInteractedMessage() async {
    // Terminated 상태에서 클릭
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Background 상태에서 클릭
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // Firebase RemoteMessage를 처리하는 래퍼 함수
  void _handleMessage(RemoteMessage message) {
    _handleData(message.data);
  }

  // 실제 네비게이션 로직 (RemoteMessage와 LocalNotification 양쪽에서 사용)
  void _handleData(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('알림 클릭 로직 실행: $data');
    }
    String? route = data['route'];

    if (route != null) {
      navigatorKey.currentState?.pushNamed(route);
    } else {
      // navigatorKey.currentState?.pushNamed('/notification');
    }
  }
}