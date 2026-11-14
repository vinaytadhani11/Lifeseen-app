import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Global type scale for every screen.
///
/// Layouts in this app were tuned on a ~400dp-wide phone. Android display
/// size changes the logical width, and the system font setting scales type
/// on top of that. This keeps body text readable while pulling large titles
/// back so cards, buttons, and headings do not look oversized.
abstract final class AppTextScale {
  /// Logical width the current font sizes were designed against.
  static const double designWidth = 400;

  static const double minLayoutScale = 0.88;
  static const double maxLayoutScale = 1;

  static TextScaler resolve(MediaQueryData media) {
    return _ResponsiveTextScaler(_layoutScale(media));
  }

  static Widget wrap(BuildContext context, Widget? child) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: resolve(media)),
      child: child ?? const SizedBox.shrink(),
    );
  }

  static double _layoutScale(MediaQueryData media) {
    final width = media.size.width;
    if (width <= 0) return maxLayoutScale;

    final device = (width / designWidth).clamp(minLayoutScale, maxLayoutScale);
    final system = (media.textScaler.scale(16) / 16).clamp(
      minLayoutScale,
      maxLayoutScale,
    );
    return math.min(device, system);
  }
}

final class _ResponsiveTextScaler extends TextScaler {
  const _ResponsiveTextScaler(this.layoutScale);

  final double layoutScale;

  /// Large titles shrink more than captions, so 11px notes stay readable
  /// while 28–34px headlines stop dominating the screen.
  static double comfort(double fontSize) {
    final t = ((fontSize - 14) / 22).clamp(0.0, 1.0);
    return 1 - (0.20 * t);
  }

  @override
  double scale(double fontSize) => fontSize * comfort(fontSize) * layoutScale;

  @override
  double get textScaleFactor => layoutScale;

  @override
  bool operator ==(Object other) {
    return other is _ResponsiveTextScaler && other.layoutScale == layoutScale;
  }

  @override
  int get hashCode => layoutScale.hashCode;
}
