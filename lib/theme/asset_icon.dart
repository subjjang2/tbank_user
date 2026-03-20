import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tbank_user/service/theme_service.dart';
import 'package:flutter_svg/svg.dart';

class AssetIcon extends ConsumerWidget {
  const AssetIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
  });

  final String icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgPicture.asset(
      'assets/icons/$icon.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? ref.color.text,
        BlendMode.srcIn,
      ),
    );
  }
}
