import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/models/country.dart';

enum LsStatus { none, online, offline }

/// Cached network image used across the friends / LifeSeen light UI.
class LsCachedImage extends StatelessWidget {
  const LsCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.error,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? error;

  bool get _hasUrl {
    final value = url?.trim() ?? '';
    return value.isNotEmpty && (value.startsWith('http://') || value.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final child = !_hasUrl
        ? (error ?? placeholder ?? const SizedBox.shrink())
        : CachedNetworkImage(
            imageUrl: url!.trim(),
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 180),
            fadeOutDuration: const Duration(milliseconds: 120),
            placeholder: (_, __) =>
                placeholder ??
                ColoredBox(
                  color: AppColors.mint,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.green.withValues(alpha: .7),
                      ),
                    ),
                  ),
                ),
            errorWidget: (_, __, ___) => error ?? placeholder ?? const ColoredBox(color: AppColors.stroke),
          );

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class LsAvatar extends StatelessWidget {
  const LsAvatar({
    super.key,
    required this.index,
    this.size = 48,
    this.status = LsStatus.none,
    this.photoUrl,
    this.image,
  });

  final int index;
  final double size;
  final LsStatus status;
  /// Remote profile photo — loaded with [CachedNetworkImage].
  final String? photoUrl;
  /// Local image (e.g. picked bytes). Prefer [photoUrl] for network.
  final ImageProvider? image;

  static const _bg = [
    Color(0xFFDDF5E4),
    Color(0xFFE6E3FA),
    Color(0xFFD6F1EC),
    Color(0xFFFBEBCF),
    Color(0xFFDCE7FF),
    Color(0xFFFBDDE8),
  ];

  Widget _fallback() {
    return CustomPaint(
      size: Size.square(size),
      painter: _AvatarPainter(index % 6, _bg[index % 6]),
    );
  }

  Widget _face() {
    if (image != null) {
      return Image(image: image!, width: size, height: size, fit: BoxFit.cover);
    }
    final url = photoUrl?.trim() ?? '';
    if (url.isEmpty) return _fallback();
    return LsCachedImage(
      url: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: _fallback(),
      error: _fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final on = status == LsStatus.online;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (on) BoxShadow(color: AppColors.neon.withValues(alpha: .55), blurRadius: 18, spreadRadius: 1),
          BoxShadow(color: on ? AppColors.neon : AppColors.stroke2, spreadRadius: 3.5),
          const BoxShadow(color: AppColors.bg, spreadRadius: 2),
        ],
      ),
      child: ClipOval(child: _face()),
    );
    if (status == LsStatus.none) return avatar;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: size * .25,
              height: size * .25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? AppColors.neon : AppColors.offline,
                border: Border.all(color: AppColors.white, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.i, this.bg);
  final int i;
  final Color bg;

  static const _skin = [
    Color(0xFFE3AE88),
    Color(0xFFF1C6A6),
    Color(0xFFC99372),
    Color(0xFFF0C2A0),
    Color(0xFF8D5B3E),
    Color(0xFFE9B996),
  ];
  static const _hair = [
    Color(0xFF2B1B12),
    Color(0xFFC79A50),
    Color(0xFF3A2618),
    Color(0xFF5A2D1A),
    Color(0xFF120C08),
    Color(0xFF7A3B1E),
  ];
  static const _shirt = [
    AppColors.neon,
    Color(0xFF8B9CF7),
    AppColors.aqua,
    AppColors.amberFill,
    Color(0xFF6E9BFF),
    Color(0xFFFF8FB1),
  ];
  static const _long = [false, true, false, true, false, true];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    canvas.save();
    canvas.scale(size.width / 40);
    final hair = Paint()..color = _hair[i];
    final skin = Paint()..color = _skin[i];
    if (_long[i]) {
      canvas.drawPath(
        Path()
          ..moveTo(10.5, 31)
          ..lineTo(10.5, 17.5)
          ..cubicTo(10.5, 11, 14.6, 7, 20, 7)
          ..cubicTo(25.4, 7, 29.5, 11, 29.5, 17.5)
          ..lineTo(29.5, 31)
          ..close(),
        hair,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(5, 41)
        ..cubicTo(6, 32, 12.5, 27.5, 20, 27.5)
        ..cubicTo(27.5, 27.5, 34, 32, 35, 41)
        ..close(),
      Paint()..color = _shirt[i],
    );
    canvas.drawRRect(RRect.fromLTRBR(17, 21, 23, 29, const Radius.circular(3)), skin);
    canvas.drawOval(Rect.fromCenter(center: const Offset(20, 17.5), width: 14, height: 16), skin);
    if (_long[i]) {
      canvas.drawPath(
        Path()
          ..moveTo(12.6, 17)
          ..cubicTo(13, 11.5, 16.2, 8.4, 20, 8.4)
          ..cubicTo(23.8, 8.4, 27, 11.5, 27.4, 17)
          ..cubicTo(24.8, 15.6, 22.8, 13.4, 21.8, 11.2)
          ..cubicTo(19.8, 13.8, 16.4, 15.8, 12.6, 17)
          ..close(),
        hair,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(12.8, 16.5)
          ..cubicTo(12.4, 11.1, 15.6, 7.5, 20, 7.5)
          ..cubicTo(24.4, 7.5, 27.8, 10.9, 27.2, 16.5)
          ..cubicTo(26.2, 14.1, 24.6, 12.7, 22.4, 12.3)
          ..cubicTo(19.2, 11.8, 15.6, 13.1, 12.8, 16.5)
          ..close(),
        hair,
      );
    }
    final eye = Paint()..color = const Color(0xFF2A1A12);
    canvas.drawCircle(const Offset(17.2, 18.6), .95, eye);
    canvas.drawCircle(const Offset(22.8, 18.6), .95, eye);
    canvas.drawPath(
      Path()
        ..moveTo(18, 22.2)
        ..cubicTo(19.2, 23.1, 20.8, 23.1, 22, 22.2),
      Paint()
        ..color = const Color(0xFF9A5A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => old.i != i || old.bg != bg;
}

class LsGridFloor extends StatelessWidget {
  const LsGridFloor({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _GridFloorPainter(), size: Size.infinite),
    );
  }
}

class _GridFloorPainter extends CustomPainter {
  const _GridFloorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.green.withValues(alpha: .22)
      ..strokeWidth = 1;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const rows = 7;
    for (var i = 0; i <= rows; i++) {
      final t = i / rows;
      final y = h * (t * t * .85 + t * .15);
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }
    const cell = 28.0;
    final n = (w / cell / 2).ceil() + 4;
    for (var j = -n; j <= n; j++) {
      canvas.drawLine(Offset(cx + j * cell * .42, 0), Offset(cx + j * cell * 1.25, h), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LsTubeClamp {
  const LsTubeClamp(this.rect, this.angleDeg);
  final Rect rect;
  final double angleDeg;
}

class LsNeonTubes extends StatefulWidget {
  const LsNeonTubes({super.key, required this.paths, this.width = 5, this.clamps = const []});

  final List<Path> paths;
  final double width;
  final List<LsTubeClamp> clamps;

  @override
  State<LsNeonTubes> createState() => _LsNeonTubesState();
}

class _LsNeonTubesState extends State<LsNeonTubes> with TickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (lsReduceMotion(context)) {
      _draw.value = 1;
    } else if (_draw.status == AnimationStatus.dismissed) {
      _draw.forward();
    }
    if (!lsReduceMotion(context) && !_flow.isAnimating) _flow.repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_flow, _draw]),
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _TubePainter(
            widget.paths,
            widget.width,
            widget.clamps,
            Curves.easeInOutCubic.transform(_draw.value),
            _flow.value,
          ),
        ),
      ),
    );
  }
}

class _TubePainter extends CustomPainter {
  _TubePainter(this.paths, this.width, this.clamps, this.drawT, this.flowT);
  final List<Path> paths;
  final double width;
  final List<LsTubeClamp> clamps;
  final double drawT;
  final double flowT;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = AppColors.neon.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final tube = Paint()
      ..color = AppColors.neon
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final dash = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final path in paths) {
      for (final m in path.computeMetrics()) {
        final part = m.extractPath(0, m.length * drawT);
        canvas.drawPath(part, glow);
        canvas.drawPath(part, tube);
        if (drawT >= 1) _dashes(canvas, m, dash, 4, 14, flowT * 36);
      }
    }
  }

  void _dashes(Canvas canvas, ui.PathMetric m, Paint p, double dash, double gap, double phase) {
    final period = dash + gap;
    var start = (phase % period) - period;
    while (start < m.length) {
      final s0 = math.max(start, 0.0);
      final e0 = math.min(start + dash, m.length);
      if (e0 > s0) canvas.drawPath(m.extractPath(s0, e0), p);
      start += period;
    }
  }

  @override
  bool shouldRepaint(covariant _TubePainter old) => old.drawT != drawT || old.flowT != flowT;
}

class LsDashedCircle extends StatelessWidget {
  const LsDashedCircle({super.key, required this.radius, this.color = AppColors.neon});
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(radius * 2), painter: _DashedCirclePainter(radius, color));
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.r, this.color);
  final double r;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final c = Offset(size.width / 2, size.height / 2);
    const dash = 3.0;
    const gap = 7.0;
    final n = (2 * math.pi * r / (dash + gap)).floor();
    for (var i = 0; i < n; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * (dash + gap) / r, dash / r, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LsDashedRing extends StatelessWidget {
  const LsDashedRing({super.key, required this.size, this.dashed = true});
  final double size;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _DashedRingPainter(dashed));
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter(this.dashed);
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    final glow = Paint()
      ..color = AppColors.neon.withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final p = Paint()
      ..color = AppColors.neon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (!dashed) {
      canvas.drawCircle(c, r, glow);
      canvas.drawCircle(c, r, p);
      return;
    }
    const dash = 6.0;
    const gap = 8.0;
    final n = (2 * math.pi * r / (dash + gap)).floor();
    final step = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, i * step - math.pi / 2, dash / r, false, glow);
      canvas.drawArc(rect, i * step - math.pi / 2, dash / r, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => old.dashed != dashed;
}

class LsProgressRing extends StatelessWidget {
  const LsProgressRing({super.key, required this.value, this.size = 150, this.stroke = 10, this.center});

  final double value;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final reduce = lsReduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? value : 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size.square(size), painter: _RingPainter(v, stroke)),
            if (child != null) child,
          ],
        ),
      ),
      child: center,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke);
  final double v;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke * 2) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (v <= 0) return;
    final sweep = 2 * math.pi * v;
    final arc = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.greenDeep, AppColors.neon, AppColors.greenLight],
        stops: [0, .6, 1],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
    final a = -math.pi / 2 + sweep;
    final head = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(head, stroke * .55, Paint()..color = AppColors.greenLight);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v || old.stroke != stroke;
}

class LsTextField extends StatefulWidget {
  const LsTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.iconColor = AppColors.muted,
    this.mono = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.autofillHints,
    this.trailing,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final LsIconType? icon;
  final Color iconColor;
  final bool mono;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? trailing;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  State<LsTextField> createState() => _LsTextFieldState();
}

class _LsTextFieldState extends State<LsTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool get _ownsFocus => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (_ownsFocus) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final style = widget.mono
        ? AppText.mono(15, FontWeight.w500, color: AppColors.text, spacing: .5)
        : AppText.jakarta(15, FontWeight.w500);
    final hintStyle = widget.mono
        ? AppText.mono(15, FontWeight.w400, color: AppColors.muted, spacing: .5)
        : AppText.jakarta(15, FontWeight.w400, color: AppColors.muted);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: focused ? AppColors.green : AppColors.stroke2, width: focused ? 1.5 : 1),
        boxShadow: focused ? [BoxShadow(color: AppColors.neon.withValues(alpha: .12), spreadRadius: 3)] : const [],
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            LsIcon(widget.icon!, size: 18, color: widget.iconColor, stroke: 1.9),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              textCapitalization: widget.textCapitalization,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: AppColors.green,
              style: style,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: hintStyle,
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}

class LsFlag extends StatelessWidget {
  const LsFlag(this.country, {super.key, this.size = 24});
  final Country country;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        boxShadow: [BoxShadow(color: AppColors.text.withValues(alpha: .12), spreadRadius: 1)],
      ),
      child: ClipOval(
        child: FittedBox(
          fit: BoxFit.cover,
          child: Text(country.flagEmoji, style: const TextStyle(fontSize: 28, height: 1)),
        ),
      ),
    );
  }
}

class LsCountryCodeChip extends StatelessWidget {
  const LsCountryCodeChip({super.key, required this.country, this.onTap});
  final Country country;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LsFlag(country),
            const SizedBox(width: 8),
            Text(country.formattedDialCode, style: AppText.jakarta(15, FontWeight.w500)),
            const SizedBox(width: 8),
            const LsIcon(LsIconType.chevron, size: 14, color: AppColors.muted, stroke: 2),
          ],
        ),
      ),
    );
  }
}

enum LsSmallCtaVariant { green, ghost, danger }

class LsSmallCta extends StatefulWidget {
  const LsSmallCta({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LsSmallCtaVariant.green,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final LsSmallCtaVariant variant;
  final LsIconType? icon;

  @override
  State<LsSmallCta> createState() => _LsSmallCtaState();
}

class _LsSmallCtaState extends State<LsSmallCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final green = widget.variant == LsSmallCtaVariant.green;
    final danger = widget.variant == LsSmallCtaVariant.danger;
    final fg = green ? AppColors.ink : (danger ? AppColors.white : AppColors.text);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.selectionClick();
        widget.onPressed?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: 52,
        transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: green ? null : (danger ? AppColors.red : AppColors.white),
          gradient: green ? AppColors.btnGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: green || danger ? null : Border.all(color: AppColors.stroke2),
          boxShadow: [
            BoxShadow(
              color: green ? AppColors.edge : (danger ? const Color(0xFFA8323A) : AppColors.stroke2),
              offset: Offset(0, _down ? 0 : 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              LsIcon(widget.icon!, size: 18, color: fg, stroke: 2.2),
              const SizedBox(width: 8),
            ],
            Text(widget.label.toUpperCase(), style: AppText.jakarta(14.5, FontWeight.w800, color: fg, spacing: .6)),
          ],
        ),
      ),
    );
  }
}

Future<bool> showLsConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  LsIconType icon = LsIconType.trash,
  bool danger = true,
}) async {
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: AppColors.text.withValues(alpha: .42),
    transitionDuration: Duration(milliseconds: lsReduceMotion(context) ? 0 : 220),
    pageBuilder: (ctx, _, __) => Center(
      child: LsDialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LsIconChip(icon, color: danger ? AppColors.red : AppColors.green, size: 46, radius: 14, iconSize: 22),
            const SizedBox(height: 12),
            Text(title, style: AppText.jakarta(20, FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LsSmallCta(
                    label: 'Cancel',
                    variant: LsSmallCtaVariant.ghost,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LsSmallCta(
                    label: confirmLabel,
                    variant: danger ? LsSmallCtaVariant.danger : LsSmallCtaVariant.green,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    transitionBuilder: (ctx, a, _, child) => Opacity(
      opacity: a.value,
      child: Transform.scale(scale: .94 + .06 * a.value, child: child),
    ),
  );
  return r ?? false;
}

class LsSheet extends StatelessWidget {
  const LsSheet({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 24, 16, 26 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: AppColors.neon.withValues(alpha: .18))),
        boxShadow: [
          BoxShadow(color: AppColors.text.withValues(alpha: .06), offset: const Offset(0, -8), blurRadius: 24),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class LsDialogCard extends StatelessWidget {
  const LsDialogCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = math.min(330.0, MediaQuery.sizeOf(context).width - 40);
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: w,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.neon.withValues(alpha: .25)),
          boxShadow: [
            BoxShadow(color: AppColors.neon.withValues(alpha: .3), blurRadius: 50, spreadRadius: -10),
          ],
        ),
        child: child,
      ),
    );
  }
}

const lsWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const lsMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

List<DateTime> lsWeekOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final monday = day.subtract(Duration(days: day.weekday - 1));
  return [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
}

bool lsSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class LsWeekStrip extends StatelessWidget {
  const LsWeekStrip({super.key, required this.selected, this.onSelect});
  final DateTime selected;
  final ValueChanged<DateTime>? onSelect;

  @override
  Widget build(BuildContext context) {
    final days = lsWeekOf(selected);
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _cell(days[i], lsSameDay(days[i], selected))),
        ],
      ],
    );
  }

  Widget _cell(DateTime d, bool on) {
    return GestureDetector(
      onTap: onSelect == null ? null : () => onSelect!(d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.only(top: 9, bottom: 10),
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.btnTop, AppColors.neon],
                )
              : null,
          color: on ? null : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? Colors.transparent : AppColors.stroke),
          boxShadow: on ? [BoxShadow(color: AppColors.neon.withValues(alpha: .7), blurRadius: 22, spreadRadius: -4)] : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lsWeekdays[d.weekday - 1].toUpperCase(),
              style: AppText.mono(10, FontWeight.w500, color: on ? AppColors.ink : AppColors.muted, spacing: .8),
            ),
            const SizedBox(height: 6),
            Text('${d.day}', style: AppText.jakarta(16, FontWeight.w700, color: on ? AppColors.ink : AppColors.grey)),
          ],
        ),
      ),
    );
  }
}

class LsUsageBar extends StatefulWidget {
  const LsUsageBar({super.key, required this.value, this.amber = false, this.height = 8});
  final double value;
  final bool amber;
  final double height;

  @override
  State<LsUsageBar> createState() => _LsUsageBarState();
}

class _LsUsageBarState extends State<LsUsageBar> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!lsReduceMotion(context) && !_sheen.isAnimating) _sheen.repeat();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.amber
        ? const [Color(0xFF8A5A16), AppColors.amberFill, Color(0xFFF8D27E)]
        : const [AppColors.greenDeep, AppColors.neon, AppColors.greenLight];
    final r = BorderRadius.circular(widget.height / 1.6);
    return ClipRRect(
      borderRadius: r,
      child: Container(
        height: widget.height,
        color: AppColors.text.withValues(alpha: .07),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widget.value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: ClipRRect(
            borderRadius: r,
            child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
          ),
        ),
      ),
    );
  }
}

class LsSegmentedToggle extends StatelessWidget {
  const LsSegmentedToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.icons,
    this.badges,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final List<LsIconType?>? icons;
  final List<String?>? badges;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke2),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.btnTop, AppColors.neon],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icons != null && icons![i] != null) ...[
                            LsIcon(icons![i]!, size: 13, color: i == index ? AppColors.ink : AppColors.muted, stroke: 2),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            labels[i].toUpperCase(),
                            style: AppText.mono(12, FontWeight.w700, color: i == index ? AppColors.ink : AppColors.muted, spacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum LsNavTab { persons, history, home, messages, settings }

class LsShellScope extends InheritedWidget {
  const LsShellScope({
    super.key,
    required this.active,
    required this.goTo,
    this.historyBadge = 0,
    required super.child,
  });

  final LsNavTab active;
  final ValueChanged<LsNavTab> goTo;
  final int historyBadge;

  static LsShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LsShellScope>();

  @override
  bool updateShouldNotify(LsShellScope old) =>
      old.active != active || old.historyBadge != historyBadge;
}

class LsBottomNav extends StatelessWidget {
  const LsBottomNav({
    super.key,
    required this.active,
    this.onTap,
    this.historyBadge,
  });

  final LsNavTab active;
  final ValueChanged<LsNavTab>? onTap;
  final int? historyBadge;

  void _go(BuildContext context, LsNavTab tab) {
    HapticFeedback.selectionClick();
    final scope = LsShellScope.maybeOf(context);
    if (scope != null) {
      scope.goTo(tab);
    } else {
      onTap?.call(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final badge = historyBadge ?? LsShellScope.maybeOf(context)?.historyBadge ?? 0;
    final showBadge = badge > 0 && active != LsNavTab.history;
    return SizedBox(
      height: 90 + inset + 34,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90 + inset,
            child: Container(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 16 + inset),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: const Border(top: BorderSide(color: AppColors.stroke)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text.withValues(alpha: .15),
                    offset: const Offset(0, -8),
                    blurRadius: 24,
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _item(context, LsNavTab.persons, LsIconType.users, 'Persons')),
                  Expanded(child: _item(context, LsNavTab.history, LsIconType.bell, 'History', badge: showBadge ? badge : 0)),
                  const SizedBox(width: 74),
                  Expanded(child: _item(context, LsNavTab.messages, LsIconType.msg, 'Messages')),
                  Expanded(child: _item(context, LsNavTab.settings, LsIconType.gear, 'Settings')),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 57 + inset,
            child: GestureDetector(
              onTap: () => _go(context, LsNavTab.home),
              child: Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.btnGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    const BoxShadow(color: AppColors.bg, spreadRadius: 6),
                    const BoxShadow(color: AppColors.edge, offset: Offset(0, 4)),
                    BoxShadow(
                      color: AppColors.neon.withValues(alpha: .7),
                      offset: const Offset(0, 12),
                      blurRadius: 30,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icons/3d/home.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, LsNavTab tab, LsIconType icon, String label, {int badge = 0}) {
    final on = tab == active;
    final color = on ? AppColors.green : AppColors.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(context, tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 30,
            decoration: BoxDecoration(
              color: on ? AppColors.neon.withValues(alpha: .16) : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                LsIcon(icon, size: 22, color: color, stroke: on ? 2 : 1.8),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.neon,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: AppText.mono(9, FontWeight.w700, color: AppColors.ink, height: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              style: AppText.mono(9.5, on ? FontWeight.w700 : FontWeight.w500, color: color, spacing: .6),
            ),
          ),
        ],
      ),
    );
  }
}

class LsDashedBorder extends StatelessWidget {
  const LsDashedBorder({super.key, required this.child, this.radius = 19});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: _LsDashPainter(radius),
        child: child,
      );
}

class _LsDashPainter extends CustomPainter {
  _LsDashPainter(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(.5);
    final paint = Paint()
      ..color = AppColors.stroke2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LsDashPainter o) => o.radius != radius;
}

class LsEmptyCard extends StatelessWidget {
  const LsEmptyCard({super.key, required this.icon, required this.text});
  final LsIconType icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.stroke2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LsIconChip(icon, color: AppColors.green, size: 36, iconSize: 19),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: AppText.jakarta(14, FontWeight.w400, color: AppColors.grey, height: 1.45))),
        ],
      ),
    );
  }
}

class LsToast extends StatelessWidget {
  const LsToast({super.key, required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neon.withValues(alpha: .5)),
      ),
      child: Row(
        children: [
          const LsIconChip(LsIconType.check, color: AppColors.green, size: 32, radius: 10, iconSize: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title.toUpperCase(), style: AppText.mono(10.5, FontWeight.w500, color: AppColors.green, spacing: 1.05)),
                Text(text, style: AppText.jakarta(13.5, FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LsAreaChart extends StatelessWidget {
  const LsAreaChart({super.key, required this.values, this.height = 96});
  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: height, child: CustomPaint(painter: _AreaPainter(values), size: Size.infinite)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in const ['00', '06', '12', '18', '23'])
              Text(l, style: AppText.mono(9.5, FontWeight.w400)),
          ],
        ),
      ],
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height * .33), Offset(size.width, size.height * .33), grid);
    canvas.drawLine(Offset(0, size.height * .66), Offset(size.width, size.height * .66), grid);
    if (values.length < 2) return;
    final maxV = values.reduce(math.max) <= 0 ? 1.0 : values.reduce(math.max);
    const top = 6.0;
    final bottom = size.height - 4;
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(size.width * i / (values.length - 1), bottom - (bottom - top) * (values[i] / maxV)),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
      line.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    line.lineTo(pts.last.dx, pts.last.dy);
    final fill = Path.from(line)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.neon.withValues(alpha: .45), AppColors.neon.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.neon
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) => old.values != values;
}

class LsMiniCta extends StatelessWidget {
  const LsMiniCta({super.key, required this.label, required this.icon, this.onPressed});
  final String label;
  final LsIconType icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          gradient: AppColors.btnGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: AppColors.edge, offset: Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LsIcon(icon, size: 15, color: AppColors.ink, stroke: 2.3),
            const SizedBox(width: 8),
            Text(label.toUpperCase(), style: AppText.jakarta(12, FontWeight.w800, color: AppColors.ink, spacing: .6)),
          ],
        ),
      ),
    );
  }
}
