import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';

enum AppCtaVariant { green, gold }

/// Global primary CTA — Vortex / Boost “Speed Up” style.
///
/// Green (or gold) gradient pill, circuit grid, bolt badge, label, chevrons.
class AppCtaButton extends StatefulWidget {
  const AppCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.variant = AppCtaVariant.green,
    this.height = 54,
    this.showBolt = true,
    this.showChevrons = true,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final AppCtaVariant variant;
  final double height;
  final bool showBolt;
  final bool showChevrons;

  @override
  State<AppCtaButton> createState() => _AppCtaButtonState();
}

class _AppCtaButtonState extends State<AppCtaButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _gold => widget.variant == AppCtaVariant.gold;
  bool get _active => widget.enabled && widget.onTap != null;

  List<Color> get _gradient => _gold
      ? const [Color(0xFFF8D27E), Color(0xFFF2B84B), Color(0xFFE0A43A)]
      : const [Color(0xFF86E8A0), Color(0xFF5BD47A), Color(0xFF47BF66)];

  Color get _ink => _gold ? AppColors.boostInkGold : AppColors.boostInk;

  Color _a(Color c, double o) =>
      c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

  @override
  Widget build(BuildContext context) {
    final accent = _gold ? AppColors.boostYellow : AppColors.boostGreen;
    final depth = _gold ? const Color(0xFF8A6118) : const Color(0xFF23753C);

    return GestureDetector(
      onTapDown: _active ? (_) => setState(() => _down = true) : null,
      onTapUp: _active ? (_) => setState(() => _down = false) : null,
      onTapCancel: _active ? () => setState(() => _down = false) : null,
      onTap: !_active
          ? null
          : () {
              HapticFeedback.vibrate();
              widget.onTap!();
            },
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = Curves.easeInOut.transform(_pulse.value);
          return Opacity(
            opacity: _active ? 1 : 0.55,
            child: Transform.translate(
              offset: Offset(0, _down ? 3 : 0),
              child: Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _gradient,
                    stops: const [0, 0.48, 1],
                  ),
                  boxShadow: _down
                      ? [
                          BoxShadow(color: depth, offset: const Offset(0, 1)),
                          BoxShadow(
                            color: _a(accent, 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(color: depth, offset: const Offset(0, 2)),
                          BoxShadow(
                            color: _a(accent, 0.14 + 0.08 * glow),
                            blurRadius: 10 + 3 * glow,
                            offset: Offset(0, 4 + glow),
                          ),
                        ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CtaGridPainter(_ink)),
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 0, 8, 0),
                child: Row(
                  children: [
                    if (widget.showBolt) ...[
                      _BoltBadge(gold: _gold, pulse: _pulse),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: 0.3,
                              height: 1,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 3),
                            Opacity(
                              opacity: 0.72,
                              child: Text(
                                widget.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: _ink,
                                  letterSpacing: 0.25,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.showChevrons) ...[
                      const SizedBox(width: 6),
                      _ChevronCluster(ink: _ink, pulse: _pulse),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================== PARTS ============================== */

class _BoltBadge extends StatelessWidget {
  const _BoltBadge({required this.gold, required this.pulse});
  final bool gold;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final z = pulse.value;
        double zs = 1;
        if (z < 0.08) {
          zs = 1 + 0.12 * Curves.easeInOut.transform(z / 0.08);
        } else if (z < 0.16) {
          zs = 1.12 -
              0.12 * Curves.easeInOut.transform((z - 0.08) / 0.08);
        }
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              colors: gold
                  ? const [Color(0xFF2B2110), Color(0xFF130D04)]
                  : const [Color(0xFF163222), Color(0xFF0A1810)],
            ),
            border: Border.all(
              color: gold
                  ? AppColors.boostYellow.withAlpha(102)
                  : AppColors.boostGreen.withAlpha(90),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Transform.scale(
              scale: zs,
              child: const CustomPaint(
                size: Size(17, 17),
                painter: _BoltPainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChevronCluster extends StatelessWidget {
  const _ChevronCluster({required this.ink, required this.pulse});
  final Color ink;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          return CustomPaint(
            painter: _ChevronsPainter(ink: ink, t: pulse.value),
          );
        },
      ),
    );
  }
}

/* ============================== PAINTERS ============================== */

class _CtaGridPainter extends CustomPainter {
  const _CtaGridPainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: [
          ink.withAlpha(0),
          ink.withAlpha(33),
        ],
        stops: const [0.3, 0.85],
      ).createShader(Offset.zero & size);
    for (double x = 0.5; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0.5; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.5),
      Paint()..color = Colors.white.withAlpha(140),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 2, size.width, 2),
      Paint()..color = Colors.black.withAlpha(30),
    );
  }

  @override
  bool shouldRepaint(covariant _CtaGridPainter old) => old.ink != ink;
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final k = size.width / 24;
    canvas.scale(k);
    final p = Path()
      ..moveTo(13.5, 2)
      ..lineTo(4, 14)
      ..lineTo(11, 14)
      ..lineTo(9.5, 22)
      ..lineTo(20, 10)
      ..lineTo(13, 10)
      ..lineTo(13.5, 2)
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.boostYellow);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF7A5410),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChevronsPainter extends CustomPainter {
  _ChevronsPainter({required this.ink, required this.t});
  final Color ink;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final u = (t + i * 0.18) % 1.0;
      final v = (1 - math.cos(u * 2 * math.pi)) / 2;
      final dx = -2 + 4 * v - i * 3.0;
      canvas.save();
      canvas.translate(size.width / 2 + dx - 4, size.height / 2 - 7);
      final op = 0.25 + 0.75 * v;
      canvas.drawPath(
        Path()
          ..moveTo(2, 2)
          ..lineTo(8, 8)
          ..lineTo(2, 14),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ink.withAlpha((op * 255).round()),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronsPainter old) =>
      old.t != t || old.ink != ink;
}
