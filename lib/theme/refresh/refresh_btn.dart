import 'package:flutter/material.dart';

class RefreshIconButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final ScrollController? scrollController; // ✨ [추가] 스크롤 컨트롤러
  final IconData icon;
  final Color color;
  final double size;

  const RefreshIconButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.scrollController, // ✨ [추가] 생성자
    this.icon = Icons.refresh,
    this.color = Colors.white,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: CircularProgressIndicator(
          color: color,
          strokeWidth: 2.5,
        ),
      ),
    )
        : IconButton(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      icon: Icon(icon, color: color),
      onPressed: () {
        // ✨ [로직 추가] 스크롤 컨트롤러가 있고, 리스트에 연결되어 있다면 맨 위로 이동
        if (scrollController != null && scrollController!.hasClients) {
          scrollController!.animateTo(
            0, // 맨 위(0) 위치로
            duration: const Duration(milliseconds: 300), // 0.3초 동안 부드럽게
            curve: Curves.easeOut,
          );
        }

        // 기존 새로고침 로직 실행
        onPressed();
      },
    );
  }
}