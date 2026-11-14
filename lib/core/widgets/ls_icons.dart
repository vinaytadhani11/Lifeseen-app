import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';

enum LsIconType {
  bolt,
  chevron,
  eye,
  insta,
  msg,
  play,
  send,
  fan,
  target,
  lock,
  clock,
  shield,
  check,
  plus,
  back,
  gear,
  menu,
  calendar,
  user,
  userPlus,
  userX,
  search,
  close,
  crown,
  hourglass,
  trend,
  users,
  bell,
  doc,
  star,
  share,
  trash,
  logout,
  edit,
  camera,
  image,
  media,
  phone,
  spark,
  grid,
  pause,
  copy,
}

class LsIcon extends StatelessWidget {
  const LsIcon(this.type, {super.key, this.size = 22, this.color = AppColors.text, this.stroke = 2});

  final LsIconType type;
  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _IconPainter(type, color, stroke));
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.type, this.color, this.stroke);

  final LsIconType type;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (type) {
      case LsIconType.bolt:
        canvas.drawPath(
          Path()
            ..moveTo(13, 2.5)
            ..lineTo(4.5, 13.5)
            ..lineTo(11, 13.5)
            ..lineTo(10, 21.5)
            ..lineTo(18.5, 10.5)
            ..lineTo(12, 10.5)
            ..close(),
          p,
        );
      case LsIconType.chevron:
        canvas.drawPath(Path()..moveTo(9, 6)..lineTo(15, 12)..lineTo(9, 18), p);
      case LsIconType.back:
        canvas.drawPath(Path()..moveTo(15, 6)..lineTo(9, 12)..lineTo(15, 18), p);
      case LsIconType.check:
        canvas.drawPath(Path()..moveTo(5, 12.5)..lineTo(9.5, 17)..lineTo(19, 7.5), p);
      case LsIconType.plus:
        canvas.drawLine(const Offset(12, 5), const Offset(12, 19), p);
        canvas.drawLine(const Offset(5, 12), const Offset(19, 12), p);
      case LsIconType.close:
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), p);
        canvas.drawLine(const Offset(18, 6), const Offset(6, 18), p);
      case LsIconType.eye:
        canvas.drawPath(
          Path()
            ..moveTo(2.5, 12)
            ..cubicTo(2.5, 12, 6, 5.5, 12, 5.5)
            ..cubicTo(18, 5.5, 21.5, 12, 21.5, 12)
            ..cubicTo(21.5, 12, 18, 18.5, 12, 18.5)
            ..cubicTo(6, 18.5, 2.5, 12, 2.5, 12)
            ..close(),
          p,
        );
        canvas.drawCircle(const Offset(12, 12), 3, p);
      case LsIconType.insta:
        canvas.drawRRect(RRect.fromLTRBR(4, 4, 20, 20, const Radius.circular(5)), p);
        canvas.drawCircle(const Offset(12, 12), 3.8, p);
        canvas.drawCircle(const Offset(17, 7), 1, fill);
      case LsIconType.msg:
        canvas.drawPath(
          Path()
            ..moveTo(20, 15)
            ..arcToPoint(const Offset(18, 17), radius: const Radius.circular(2))
            ..lineTo(8, 17)
            ..lineTo(4, 21)
            ..lineTo(4, 6)
            ..arcToPoint(const Offset(6, 4), radius: const Radius.circular(2))
            ..lineTo(18, 4)
            ..arcToPoint(const Offset(20, 6), radius: const Radius.circular(2))
            ..close(),
          p,
        );
      case LsIconType.play:
        canvas.drawPath(Path()..moveTo(9, 7.5)..lineTo(9, 16.5)..lineTo(16.5, 12)..close(), fill);
      case LsIconType.send:
        canvas.drawLine(const Offset(21, 3), const Offset(10, 14), p);
        canvas.drawPath(
          Path()
            ..moveTo(21, 3)
            ..lineTo(14, 21)
            ..lineTo(10, 14)
            ..lineTo(3, 10)
            ..close(),
          p,
        );
      case LsIconType.fan:
        canvas.drawCircle(const Offset(12, 12), 1.8, p);
        for (var i = 0; i < 4; i++) {
          canvas.save();
          canvas.translate(12, 12);
          canvas.rotate(i * math.pi / 2);
          canvas.translate(-12, -12);
          canvas.drawPath(
            Path()
              ..moveTo(12, 10.2)
              ..cubicTo(12, 6.7, 12.5, 4, 15, 4)
              ..cubicTo(17.2, 4, 17.4, 7, 12, 10.2)
              ..close(),
            p,
          );
          canvas.restore();
        }
      case LsIconType.target:
        canvas.drawCircle(const Offset(12, 12), 8.5, p);
        canvas.drawCircle(const Offset(12, 12), 4.5, p);
        canvas.drawCircle(const Offset(12, 12), 1, p);
      case LsIconType.lock:
        canvas.drawRRect(RRect.fromLTRBR(5, 10.5, 19, 20.5, const Radius.circular(2.5)), p);
        canvas.drawPath(
          Path()
            ..moveTo(8, 10.5)
            ..lineTo(8, 7.5)
            ..arcToPoint(const Offset(16, 7.5), radius: const Radius.circular(4))
            ..lineTo(16, 10.5),
          p,
        );
      case LsIconType.clock:
        canvas.drawCircle(const Offset(12, 12), 8.5, p);
        canvas.drawPath(Path()..moveTo(12, 7.5)..lineTo(12, 12)..lineTo(15, 14), p);
      case LsIconType.shield:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(19.5, 6)
            ..lineTo(19.5, 11.5)
            ..cubicTo(19.5, 16.1, 16.3, 19.8, 12, 21)
            ..cubicTo(7.7, 19.8, 4.5, 16.1, 4.5, 11.5)
            ..lineTo(4.5, 6)
            ..close(),
          p,
        );
        canvas.drawPath(Path()..moveTo(8.5, 12)..lineTo(11, 14.5)..lineTo(15.5, 9.5), p);
      case LsIconType.menu:
        // Left-aligned staggered bars: short / mid / long (matches home header art).
        canvas.drawLine(const Offset(5, 7.5), const Offset(13, 7.5), p);
        canvas.drawLine(const Offset(5, 12), const Offset(16.5, 12), p);
        canvas.drawLine(const Offset(5, 16.5), const Offset(19.5, 16.5), p);
      case LsIconType.search:
        canvas.drawCircle(const Offset(11, 11), 6, p);
        canvas.drawLine(const Offset(15.5, 15.5), const Offset(20, 20), p);
      case LsIconType.user:
        canvas.drawCircle(const Offset(12, 8), 3.2, p);
        canvas.drawPath(
          Path()
            ..moveTo(5.5, 19.5)
            ..cubicTo(6.5, 15.2, 9, 13.2, 12, 13.2)
            ..cubicTo(15, 13.2, 17.5, 15.2, 18.5, 19.5),
          p,
        );
      case LsIconType.userPlus:
        canvas.drawCircle(const Offset(10, 8), 3, p);
        canvas.drawPath(
          Path()
            ..moveTo(4, 19)
            ..cubicTo(4.8, 15.2, 7, 13.4, 10, 13.4)
            ..cubicTo(13, 13.4, 15.2, 15.2, 16, 19),
          p,
        );
        canvas.drawLine(const Offset(19, 8), const Offset(19, 14), p);
        canvas.drawLine(const Offset(16, 11), const Offset(22, 11), p);
      case LsIconType.userX:
        canvas.drawCircle(const Offset(10, 8), 3, p);
        canvas.drawPath(
          Path()
            ..moveTo(4, 19)
            ..cubicTo(4.8, 15.2, 7, 13.4, 10, 13.4)
            ..cubicTo(13, 13.4, 15.2, 15.2, 16, 19),
          p,
        );
        canvas.drawLine(const Offset(16.5, 6.5), const Offset(21.5, 11.5), p);
        canvas.drawLine(const Offset(21.5, 6.5), const Offset(16.5, 11.5), p);
      case LsIconType.users:
        canvas.drawCircle(const Offset(9, 8), 2.8, p);
        canvas.drawCircle(const Offset(16, 9), 2.2, p);
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 19)
            ..cubicTo(4.2, 15.4, 6.2, 13.6, 9, 13.6)
            ..cubicTo(11.8, 13.6, 13.8, 15.4, 14.5, 19),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(14, 14.2)
            ..cubicTo(15.6, 13.6, 16.8, 14.6, 18.2, 16)
            ..cubicTo(19.2, 17, 20, 18.2, 20.5, 19),
          p,
        );
      case LsIconType.gear:
        // Rounded 8-tooth outline gear (matches home settings header art).
        final gear = Path();
        const teeth = 8;
        for (var i = 0; i < teeth; i++) {
          final a0 = (i / teeth) * math.pi * 2 - math.pi / teeth;
          final a1 = a0 + math.pi / teeth * .55;
          final a2 = a0 + math.pi / teeth * .95;
          final a3 = a0 + math.pi / teeth * 1.45;
          final a4 = a0 + math.pi / teeth * 2;
          Offset pt(double a, double r) => Offset(12 + math.cos(a) * r, 12 + math.sin(a) * r);
          if (i == 0) {
            gear.moveTo(pt(a0, 6.2).dx, pt(a0, 6.2).dy);
          }
          gear.lineTo(pt(a1, 6.2).dx, pt(a1, 6.2).dy);
          gear.quadraticBezierTo(pt(a1 + .08, 8.6).dx, pt(a1 + .08, 8.6).dy, pt(a2, 8.7).dx, pt(a2, 8.7).dy);
          gear.quadraticBezierTo(pt(a3 - .08, 8.6).dx, pt(a3 - .08, 8.6).dy, pt(a3, 6.2).dx, pt(a3, 6.2).dy);
          gear.lineTo(pt(a4, 6.2).dx, pt(a4, 6.2).dy);
        }
        gear.close();
        canvas.drawPath(gear, p);
        canvas.drawCircle(const Offset(12, 12), 2.8, p);
      case LsIconType.calendar:
        canvas.drawRRect(RRect.fromLTRBR(4, 5.5, 20, 20, const Radius.circular(2)), p);
        canvas.drawLine(const Offset(4, 10), const Offset(20, 10), p);
        canvas.drawLine(const Offset(8, 3.5), const Offset(8, 7), p);
        canvas.drawLine(const Offset(16, 3.5), const Offset(16, 7), p);
      case LsIconType.crown:
        canvas.drawPath(
          Path()
            ..moveTo(4, 16)
            ..lineTo(6, 8)
            ..lineTo(12, 13)
            ..lineTo(18, 8)
            ..lineTo(20, 16)
            ..close(),
          p,
        );
      case LsIconType.hourglass:
        canvas.drawPath(
          Path()
            ..moveTo(7, 4)
            ..lineTo(17, 4)
            ..lineTo(12, 12)
            ..lineTo(17, 20)
            ..lineTo(7, 20)
            ..lineTo(12, 12)
            ..close(),
          p,
        );
      case LsIconType.trend:
        canvas.drawPath(Path()..moveTo(4, 16)..lineTo(10, 10)..lineTo(13, 13)..lineTo(20, 6), p);
        canvas.drawLine(const Offset(14, 6), const Offset(20, 6), p);
        canvas.drawLine(const Offset(20, 6), const Offset(20, 12), p);
      case LsIconType.bell:
        canvas.drawPath(
          Path()
            ..moveTo(6, 16)
            ..lineTo(6, 11)
            ..arcToPoint(const Offset(18, 11), radius: const Radius.circular(6), clockwise: true)
            ..lineTo(18, 16)
            ..close(),
          p,
        );
        canvas.drawLine(const Offset(4, 16), const Offset(20, 16), p);
        canvas.drawCircle(const Offset(12, 19), 1.2, fill);
      case LsIconType.doc:
        canvas.drawRRect(RRect.fromLTRBR(6, 3, 18, 21, const Radius.circular(2)), p);
        canvas.drawLine(const Offset(9, 8), const Offset(15, 8), p);
        canvas.drawLine(const Offset(9, 12), const Offset(15, 12), p);
        canvas.drawLine(const Offset(9, 16), const Offset(13, 16), p);
      case LsIconType.star:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.5)
            ..lineTo(14.2, 9)
            ..lineTo(20, 9.4)
            ..lineTo(15.6, 13.2)
            ..lineTo(17, 19)
            ..lineTo(12, 15.8)
            ..lineTo(7, 19)
            ..lineTo(8.4, 13.2)
            ..lineTo(4, 9.4)
            ..lineTo(9.8, 9)
            ..close(),
          p,
        );
      case LsIconType.share:
        canvas.drawCircle(const Offset(6, 12), 2.2, p);
        canvas.drawCircle(const Offset(17, 6.5), 2.2, p);
        canvas.drawCircle(const Offset(17, 17.5), 2.2, p);
        canvas.drawLine(const Offset(8, 11), const Offset(15, 7.5), p);
        canvas.drawLine(const Offset(8, 13), const Offset(15, 16.5), p);
      case LsIconType.trash:
        canvas.drawRRect(RRect.fromLTRBR(6, 7, 18, 20, const Radius.circular(1.5)), p);
        canvas.drawLine(const Offset(4, 7), const Offset(20, 7), p);
        canvas.drawLine(const Offset(9, 4), const Offset(15, 4), p);
        canvas.drawLine(const Offset(10, 11), const Offset(10, 16), p);
        canvas.drawLine(const Offset(14, 11), const Offset(14, 16), p);
      case LsIconType.logout:
        canvas.drawPath(Path()..moveTo(10, 4)..lineTo(5, 4)..lineTo(5, 20)..lineTo(10, 20), p);
        canvas.drawLine(const Offset(10, 12), const Offset(20, 12), p);
        canvas.drawLine(const Offset(16, 8), const Offset(20, 12), p);
        canvas.drawLine(const Offset(16, 16), const Offset(20, 12), p);
      case LsIconType.edit:
        canvas.drawPath(
          Path()
            ..moveTo(14, 5)
            ..lineTo(19, 10)
            ..lineTo(8, 21)
            ..lineTo(3, 21)
            ..lineTo(3, 16)
            ..close(),
          p,
        );
      case LsIconType.camera:
        canvas.drawRRect(RRect.fromLTRBR(3, 7, 21, 19, const Radius.circular(2)), p);
        canvas.drawCircle(const Offset(12, 13), 3, p);
        canvas.drawLine(const Offset(8, 7), const Offset(10, 4.5), p);
        canvas.drawLine(const Offset(10, 4.5), const Offset(14, 4.5), p);
      case LsIconType.image:
        canvas.drawRRect(RRect.fromLTRBR(3, 5, 21, 19, const Radius.circular(2)), p);
        canvas.drawCircle(const Offset(8, 9), 1.4, fill);
        canvas.drawPath(Path()..moveTo(4, 17)..lineTo(9, 12)..lineTo(13, 16)..lineTo(16, 13)..lineTo(20, 17), p);
      case LsIconType.media:
        canvas.drawRRect(RRect.fromLTRBR(3, 6, 21, 18, const Radius.circular(2)), p);
        canvas.drawPath(Path()..moveTo(10, 9)..lineTo(10, 15)..lineTo(15, 12)..close(), fill);
      case LsIconType.phone:
        canvas.drawRRect(RRect.fromLTRBR(7, 2.5, 17, 21.5, const Radius.circular(2.5)), p);
        canvas.drawLine(const Offset(10, 18.5), const Offset(14, 18.5), p);
      case LsIconType.spark:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(14.2, 9.3)
            ..lineTo(21, 12)
            ..lineTo(14.2, 14.7)
            ..lineTo(12, 21)
            ..lineTo(9.8, 14.7)
            ..lineTo(3, 12)
            ..lineTo(9.8, 9.3)
            ..close(),
          p,
        );
      case LsIconType.grid:
        for (final o in const [Offset(4, 4), Offset(13.5, 4), Offset(4, 13.5), Offset(13.5, 13.5)]) {
          canvas.drawRRect(RRect.fromLTRBR(o.dx, o.dy, o.dx + 6.5, o.dy + 6.5, const Radius.circular(1.5)), p);
        }
      case LsIconType.pause:
        canvas.drawRRect(RRect.fromLTRBR(6.5, 5, 10, 19, const Radius.circular(1)), p);
        canvas.drawRRect(RRect.fromLTRBR(14, 5, 17.5, 19, const Radius.circular(1)), p);
      case LsIconType.copy:
        canvas.drawRRect(RRect.fromLTRBR(8, 8, 20, 20, const Radius.circular(2.5)), p);
        canvas.drawPath(
          Path()
            ..moveTo(16, 8)
            ..lineTo(16, 5.5)
            ..arcToPoint(const Offset(14.5, 4), radius: const Radius.circular(1.5), clockwise: false)
            ..lineTo(5.5, 4)
            ..arcToPoint(const Offset(4, 5.5), radius: const Radius.circular(1.5), clockwise: false)
            ..lineTo(4, 14.5)
            ..arcToPoint(const Offset(5.5, 16), radius: const Radius.circular(1.5), clockwise: false)
            ..lineTo(8, 16),
          p,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.type != type || old.color != color || old.stroke != stroke;
}

class LsSpin extends StatefulWidget {
  const LsSpin({super.key, required this.child, this.duration = const Duration(milliseconds: 2400)});

  final Widget child;
  final Duration duration;

  @override
  State<LsSpin> createState() => _LsSpinState();
}

class _LsSpinState extends State<LsSpin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(turns: _c, child: widget.child);
}
