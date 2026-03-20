import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class CircularIndicator extends ConsumerWidget {
  const CircularIndicator({
    super.key,
    required this.child,
    required this.isBusy,
  });

  final Widget child;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,

        /// CircularIndicator
        IgnorePointer(
          ignoring: !isBusy,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 222),
            opacity: isBusy ? 1 : 0,
            child: Container(

              alignment: Alignment.center,
              child: CircularProgressIndicator(
                color:Color(0xFF3367B2),        // 돌아가는 선: 파란색
                backgroundColor: Color(0xFFE8F5D6),
                value: isBusy ? null : 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
