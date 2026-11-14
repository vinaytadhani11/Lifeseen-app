import 'package:flutter/material.dart';

class LifeSeenLogo extends StatelessWidget {
  const LifeSeenLogo({
    super.key,
    this.fontSize = 42,
    this.height,
    this.dark = false,
  });

  /// Call-site compatibility; maps to logo height when [height] is null.
  final double fontSize;

  /// Explicit logo height. Prefer this for small header marks.
  final double? height;

  /// `true` on dark backgrounds (splash / WhatsApp dark screens).
  final bool dark;

  static const asset = 'assets/lifeseen_logo.png';
  static const assetOnDark = 'assets/lifeseen_logo_on_dark.png';

  @override
  Widget build(BuildContext context) {
    final h = height ?? fontSize * 1.9;
    return Image.asset(
      dark ? assetOnDark : asset,
      height: h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
