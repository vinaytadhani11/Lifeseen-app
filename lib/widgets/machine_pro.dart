import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';

class MachinePro extends StatefulWidget {
  const MachinePro({super.key});

  @override
  State<MachinePro> createState() => _MachineProState();
}

class _MachineProState extends State<MachinePro>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _t.value = e.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  // transparent — only the machine is painted
  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: CustomPaint(painter: _Painter(_t)));
}

class _Painter extends CustomPainter {
  _Painter(this.t) : super(repaint: t);
  final ValueListenable<double> t;

  Color _a(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());
  double _tri(double now, double period, double delay) {
    final ph = (((now - delay) / period) % 1.0 + 1.0) % 1.0;
    final v = ph < 0.45 ? ph / 0.45 : (1 - ph) / 0.55;
    return v;
  }

  double _sin01(double now, double period, [double delay = 0]) =>
      0.5 + 0.5 * math.sin((now - delay) / period * 2 * math.pi);

  Paint _st(Color c, double w,
          {double blur = 0, StrokeCap cap = StrokeCap.round}) =>
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round
        ..color = c
        ..maskFilter =
            blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;

  void _dashed(
      Canvas c, Path p, Paint paint, double dash, double gap, double offset) {
    final period = dash + gap;
    for (final m in p.computeMetrics()) {
      double d = -(offset % period);
      while (d < m.length) {
        final a = d.clamp(0.0, m.length), b = (d + dash).clamp(0.0, m.length);
        if (b > a) c.drawPath(m.extractPath(a, b), paint);
        d += period;
      }
    }
  }

  // Crop empty sky above the machine; artboard still 1200 wide.
  static const double _artW = 1200;
  static const double _artTop = 400;
  static const double _artBottom = 790;
  static const double _artH = _artBottom - _artTop;

  @override
  void paint(Canvas canvas, Size size) {
    final now = t.value;
    // Fill width so neon tubes reach the left/right edges.
    final s = size.width / _artW;
    canvas.save();
    canvas.translate(0, (size.height - _artH * s) / 2 - _artTop * s);
    canvas.scale(s);

    _floor(canvas);
    _tubes(canvas, now);
    _clamps(canvas);
    _base(canvas, now);
    _upper(canvas, now);
    _topModule(canvas, now);

    canvas.restore();
  }

  /* ---------- floor ---------- */
  void _floor(Canvas c) {
    c.drawOval(
      Rect.fromCenter(
          center: const Offset(600, 716), width: 680, height: 132),
      Paint()
        ..shader = ui.Gradient.radial(
            const Offset(600, 740),
            340,
            [
              _a(AppColors.machineFloorGlow, .45),
              _a(AppColors.machineDeepBlack, 0)
            ])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  /* ---------- tubes ---------- */
  Path _tubePath(String k) {
    final p = Path();
    switch (k) {
      case 'll':
        p.moveTo(520, 652);
        p.cubicTo(440, 652, 430, 702, 360, 726);
        p.cubicTo(280, 746, 140, 746, 0, 746);
        break;
      case 'lu':
        p.moveTo(468, 566);
        p.cubicTo(360, 566, 340, 644, 250, 664);
        p.cubicTo(150, 682, 70, 676, 0, 670);
        break;
      case 'rl':
        p.moveTo(680, 652);
        p.cubicTo(760, 652, 770, 702, 840, 726);
        p.cubicTo(920, 746, 1060, 746, 1200, 746);
        break;
      case 'ru':
        p.moveTo(732, 566);
        p.cubicTo(840, 566, 860, 644, 950, 664);
        p.cubicTo(1050, 682, 1130, 676, 1200, 670);
        break;
    }
    return p;
  }

  void _tube(Canvas c, double now, String k, double w) {
    final p = _tubePath(k);
    final b = p.getBounds();
    c.drawPath(
        p, _st(_a(AppColors.machineNeon, .2), w * 1.55, blur: 7)); // halo
    c.drawPath(p, _st(AppColors.machineCasing, w + 6)); // casing
    c.drawPath(
      p,
      _st(Colors.white, w)
        ..shader = ui.Gradient.linear(
            Offset(0, b.top),
            Offset(0, b.bottom),
            const [
              AppColors.machineTubeDeep,
              AppColors.machineTubeBright,
              AppColors.machineTubeCore,
              AppColors.machineTubeMid,
              AppColors.machineTubeDark,
            ],
            const [0, 0.4, 0.54, 0.7, 1]),
    ); // glossy body
    c.drawPath(
        p,
        _st(_a(AppColors.machineTubeCore, .52), w * 0.3,
            blur: 2.4)); // bright core
    _dashed(
        c,
        p,
        _st(AppColors.machineFlow, w * 0.21, blur: 1.5),
        24,
        54,
        now / 1.5 * 78); // flow
  }

  void _tubes(Canvas c, double now) {
    _tube(c, now, 'll', 24);
    _tube(c, now, 'lu', 22);
    _tube(c, now, 'rl', 24);
    _tube(c, now, 'ru', 22);
  }

  void _clamps(Canvas c) {
    void clamp(double x, double y, double w, double h, double deg) {
      c.save();
      c.translate(x + w / 2, y + h / 2);
      c.rotate(deg * math.pi / 180);
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(8));
      c.drawRRect(r, Paint()..color = AppColors.machineClamp);
      c.drawRRect(r, _st(AppColors.machineDeepBlack, 2));
      c.restore();
    }

    clamp(300, 702, 26, 54, 14);
    clamp(150, 648, 24, 46, 6);
    clamp(862, 702, 26, 54, -14);
    clamp(1024, 648, 24, 46, -6);
  }

  /* ---------- base ---------- */
  void _base(Canvas c, double now) {
    final r = RRect.fromRectAndRadius(
        const Rect.fromLTWH(452, 602, 296, 132), const Radius.circular(30));
    c.drawRRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
            const Offset(0, 602),
            const Offset(0, 734),
            const [AppColors.machineBaseTop, AppColors.machineBaseBottom]),
    );
    c.drawRRect(r, _st(AppColors.machineStroke, 2));
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(462, 610, 276, 16),
            const Radius.circular(8)),
        Paint()..color = _a(AppColors.machineBaseRim, .4));
    // center display
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(556, 648, 88, 40),
            const Radius.circular(10)),
        Paint()..color = AppColors.machinePortBg);
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(556, 648, 88, 40),
            const Radius.circular(10)),
        _st(AppColors.machineDisplayBorder, 1.5));
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(568, 660, 40, 6),
            const Radius.circular(3)),
        Paint()
          ..color = AppColors.machineLedBright
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(568, 672, 26, 6),
            const Radius.circular(3)),
        Paint()..color = AppColors.machineLedDim);
    _port(c, now, const Offset(470, 656));
    _port(c, now, const Offset(730, 656));
  }

  void _port(Canvas c, double now, Offset o) {
    final pl = 0.75 + 0.25 * _sin01(now, 2.4);
    c.drawCircle(
        o,
        46,
        Paint()
          ..color = _a(AppColors.machineNeon, .28 * pl)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    c.drawCircle(o, 32, Paint()..color = AppColors.machinePortBg);
    c.drawCircle(o, 32, _st(AppColors.machinePortRing, 4));
    c.drawCircle(
      o,
      22,
      Paint()
        ..shader = ui.Gradient.radial(
            o + const Offset(0, -2),
            22,
            const [
              AppColors.machineTubeCore,
              AppColors.machinePortMid,
              AppColors.machineTubeDeep,
              AppColors.machinePortOuter,
            ],
            const [0, 0.35, 0.72, 1]),
    );
    c.drawCircle(o, 9, Paint()..color = AppColors.machineTubeCore);
  }

  /* ---------- upper box + screen + fan grid ---------- */
  void _upper(Canvas c, double now) {
    // top face
    final top = Path()
      ..moveTo(454, 472)
      ..quadraticBezierTo(454, 452, 476, 452)
      ..lineTo(724, 452)
      ..quadraticBezierTo(746, 452, 746, 472)
      ..lineTo(746, 502)
      ..lineTo(454, 502)
      ..close();
    c.drawPath(
        top,
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(0, 452),
              const Offset(0, 502),
              const [AppColors.machineTopFace, AppColors.machineTopFaceDeep]));
    final rim = Path()
      ..moveTo(462, 471)
      ..quadraticBezierTo(462, 460, 476, 460)
      ..lineTo(724, 460)
      ..quadraticBezierTo(738, 460, 738, 471);
    c.drawPath(rim, _st(_a(AppColors.machineRimGlow, .9), 3, blur: 1.5));

    // front bezel
    final bez = RRect.fromRectAndRadius(
        const Rect.fromLTWH(452, 498, 296, 130), const Radius.circular(26));
    c.drawRRect(
        bez,
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(0, 498),
              const Offset(0, 628),
              const [
                AppColors.machineBezelTop,
                AppColors.machineBezelMid,
                AppColors.machineBezelBottom,
              ],
              const [0, 0.5, 1]));
    c.drawRRect(bez, _st(AppColors.machineStroke, 2));
    c.drawRRect(bez, _st(_a(AppColors.analyzedGreen, .16), 1));

    // recessed screen
    final scr = RRect.fromRectAndRadius(
        const Rect.fromLTWH(474, 512, 252, 104), const Radius.circular(16));
    c.drawRRect(
        scr,
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(0, 512),
              const Offset(0, 616),
              const [AppColors.machineScreenTop, AppColors.machineScreenBottom]));
    c.drawRRect(scr, _st(_a(Colors.black, .5), 3)); // inner shadow edge
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(476, 514, 248, 10),
            const Radius.circular(5)),
        Paint()..color = _a(AppColors.machineScreenShade, .7));

    // 2x2 fan cells
    const cells = [
      [540.0, 534.0, 3.3],
      [660.0, 534.0, 2.7],
      [540.0, 584.0, 3.0],
      [660.0, 584.0, 3.6],
    ];
    for (final cell in cells) {
      _cell(c, now, cell[0], cell[1], cell[2]);
    }
  }

  void _cell(Canvas c, double now, double cx, double cy, double dur) {
    final inset = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 56, cy - 23, 112, 46), const Radius.circular(11));
    c.drawRRect(
        inset,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(0, cy - 23),
              Offset(0, cy + 23),
              const [AppColors.machineCellTop, AppColors.machinePortBg]));
    c.drawRRect(inset, _st(AppColors.machineCellBorder, 1.5));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 56, cy - 23, 112, 11), const Radius.circular(11)),
        Paint()..color = _a(AppColors.machineCellShade, .4));
    // mini meter: track + bars
    final bx = [cx - 44, cx - 36, cx - 28, cx - 20];
    final lit = [true, true, true, false];
    for (int i = 0; i < 4; i++) {
      final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx[i], cy - 13, 5, 26), const Radius.circular(2));
      c.drawRRect(rr, Paint()..color = AppColors.machineBarTrack);
      if (lit[i]) {
        c.drawRRect(
          rr,
          Paint()
            ..shader = ui.Gradient.linear(
                Offset(0, cy + 13),
                Offset(0, cy - 13),
                const [
                  AppColors.machineBarDeep,
                  AppColors.machineBarMid,
                  AppColors.machineBarLight,
                ],
                const [0, 0.6, 1]),
        );
        // per-bar opacity (0.4..1 triangle)
        final op = 1 - (0.6 * (1 - _tri(now, 2.2, i * 0.14)));
        c.drawRRect(rr, Paint()..color = _a(AppColors.machineBarDim, 1 - op));
      } else {
        c.drawRRect(rr, Paint()..color = AppColors.machineBarOff);
      }
    }
    // fan
    _fan(c, now, Offset(cx + 24, cy), 14, dur);
    // leds
    c.drawCircle(Offset(cx + 48, cy - 14), 2.4,
        Paint()..color = AppColors.analyzedGreen);
    c.drawCircle(Offset(cx + 48, cy - 6), 2.4,
        Paint()..color = AppColors.machineLedOff);
  }

  Path _blade(double r) {
    return Path()
      ..moveTo(0, -3)
      ..cubicTo(r * .42, -r * .5, r * .6, -r * 1.0, r * .16, -r * 1.22)
      ..cubicTo(-r * .14, -r * 1.3, -r * .22, -r * .9, -r * .14, -r * .46)
      ..cubicTo(-r * .08, -r * .2, 0, -r * .1, 0, -3)
      ..close();
  }

  void _fan(Canvas c, double now, Offset o, double r, double dur) {
    c.save();
    c.translate(o.dx, o.dy);
    // glow ring (pulse 0.3..0.6)
    final gp = 0.3 + 0.3 * _sin01(now, 2.4);
    c.drawCircle(
        Offset.zero,
        r + 5,
        Paint()
          ..shader = ui.Gradient.radial(Offset.zero, r + 5, [
            _a(AppColors.machineLedBright, gp),
            _a(AppColors.machineLedBright, 0)
          ]));
    c.drawCircle(Offset.zero, r, Paint()..color = AppColors.machineFanHub);
    c.drawCircle(Offset.zero, r, _st(AppColors.machineFanRing, 2));
    // spinning blades
    c.save();
    c.rotate(now / dur * 2 * math.pi);
    final blade = _blade(r);
    final bladePaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, -r * 0.7),
          r * 1.2,
          const [
            AppColors.machineBladeLight,
            AppColors.machineBladeMid,
            AppColors.machineBladeDark,
          ],
          const [0, 0.5, 1]);
    for (int k = 0; k < 3; k++) {
      c.save();
      c.rotate(k * 2 * math.pi / 3);
      c.drawPath(blade, bladePaint);
      c.restore();
    }
    c.restore();
    c.drawCircle(
        Offset.zero, r * 0.22, Paint()..color = AppColors.machineBladeCore);
    c.restore();
  }

  /* ---------- top module ---------- */
  void _topModule(Canvas c, double now) {
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(562, 406, 116, 62),
            const Radius.circular(13)),
        Paint()..color = AppColors.machineModule);
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(562, 406, 116, 62),
            const Radius.circular(13)),
        _st(AppColors.machineStroke, 2));
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(558, 418, 124, 28),
            const Radius.circular(10)),
        Paint()..color = AppColors.machineModuleBand);
    final cables = [
      [592.0, 416.0, AppColors.machineCableA],
      [608.0, 412.0, AppColors.machineCableB],
      [624.0, 410.0, AppColors.machineCableA],
      [640.0, 412.0, AppColors.machineCableB],
      [656.0, 416.0, AppColors.machineCableA],
    ];
    for (final cb in cables) {
      final x = cb[0] as double;
      c.drawLine(
          Offset(x, 468),
          Offset(x, cb[1] as double),
          _st(cb[2] as Color, 6, blur: 1.5));
    }
    c.drawCircle(
        const Offset(664, 438), 12, Paint()..color = AppColors.machinePortBg);
    c.drawCircle(const Offset(664, 438), 12, _st(AppColors.machineFanRing, 2));
    c.drawCircle(
        const Offset(664, 438),
        5.5,
        Paint()
          ..color = _a(
              AppColors.machineBarLight, 0.75 + 0.25 * _sin01(now, 2.4)));
  }

  @override
  bool shouldRepaint(covariant _Painter old) => false;
}
