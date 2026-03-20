// lib/common/app_global.dart
import 'package:flutter/material.dart';

// 앱 전체에서 사용할 전역 키
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

// FCM 토큰을 저장할 전역 변수
String? fcmToken;