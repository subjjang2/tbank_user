import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // 1. 애니메이션 컨트롤러 설정 (1초 주기로 반복)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // 밝아졌다 어두워졌다 반복

    // 2. 색상 변경 범위 설정 (연한 회색 <-> 조금 더 진한 회색)
    _colorAnimation = ColorTween(
      begin: const Color(0xFFEEEEEE), // Colors.grey[200]
      end: const Color(0xFFE0E0E0),   // Colors.grey[300]
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value, // ✨ 여기서 색상이 계속 변합니다
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}