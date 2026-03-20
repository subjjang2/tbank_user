import 'package:flutter/material.dart';

import '../../common/app_global.dart';
import '../../main.dart';

abstract class Toast {
  static void show(String text) {
    // 키보드 위로 자동으로 올라가는 SnackBar 사용
    final messenger = scaffoldMessengerKey.currentState;

    if (messenger != null) {
      // 기존 떠있는 스낵바가 있다면 바로 제거 (빠른 반응성)
      messenger.removeCurrentSnackBar();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          behavior: SnackBarBehavior.floating, // 🔥 핵심: 둥둥 떠있게 설정
          backgroundColor: Colors.black.withOpacity(0.8), // 반투명 검정
          elevation: 0,
          margin: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24, // 바닥에서 얼마나 띄울지
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}