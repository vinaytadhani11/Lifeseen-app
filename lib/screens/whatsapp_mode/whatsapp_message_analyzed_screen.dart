import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/models/country.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/connecting_whatsapp_screen.dart';
import 'package:tableflow_plus/widgets/block_back_navigation.dart';

Color _a(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

class _SyncItem {
  const _SyncItem(
    this.asset,
    this.tint,
    this.title,
    this.sub,
    this.from,
    this.to,
  );
  final String asset;
  final Color tint;
  final String title, sub;
  final double from, to;
}

const _items = [
  _SyncItem(
    'assets/icons/analyzed_chats.png',
    AppColors.analyzedGreen,
    'Chats',
    'chat count and activity',
    0.0,
    0.35,
  ),
  _SyncItem(
    'assets/icons/analyzed_messages.png',
    AppColors.analyzedOrange,
    'Messages',
    'message counts, hourly distribution',
    0.35,
    0.70,
  ),
  _SyncItem(
    'assets/icons/analyzed_calls.png',
    AppColors.analyzedIndigo,
    'Calls',
    'call count and durations',
    0.70,
    1.0,
  ),
];

class WhatsAppMessageAnalyzedScreen extends StatefulWidget {
  const WhatsAppMessageAnalyzedScreen({
    super.key,
    required this.country,
    required this.phoneNumber,
    this.duration = const Duration(milliseconds: 7000),
    this.progress,
  });

  final Country country;
  final String phoneNumber;
  final Duration duration;
  final double? progress;

  static const Duration holdDuration = Duration(seconds: 9);

  @override
  State<WhatsAppMessageAnalyzedScreen> createState() =>
      _WhatsAppMessageAnalyzedScreenState();
}

class _WhatsAppMessageAnalyzedScreenState
    extends State<WhatsAppMessageAnalyzedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _prog =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _progCurve =
      CurvedAnimation(parent: _prog, curve: const Cubic(0.3, 0.0, 0.2, 1.0));
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _prog.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    if (widget.progress == null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _prog.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant WhatsAppMessageAnalyzedScreen old) {
    super.didUpdateWidget(old);
    if ((widget.progress ?? 0) >= 1) _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConnectingWhatsAppScreen(
            country: widget.country,
            phoneNumber: widget.phoneNumber,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _prog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.analyzedBackground,
      ),
      child: BlockBackNavigation(
        child: Scaffold(
          backgroundColor: AppColors.analyzedBackground,
          body: AnimatedBuilder(
            animation: _progCurve,
            builder: (context, _) {
              final p = (widget.progress ?? _progCurve.value).clamp(0.0, 1.0).toDouble();
              final done = p >= 1.0;
              return Stack(
                children: [
                  Positioned.fill(child: AmbientGlow(done: done)),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final h = c.maxHeight;
                        final scale = (h / 780).clamp(0.78, 1.0);
                        final headerH = 120.0 * scale;
                        final titleSize = 26.0 * scale;
                        final descSize = 13.5 * scale;
                        final gapSm = 8.0 * scale;
                        final gapMd = 12.0 * scale;
                        final gapLg = 18.0 * scale;
                        final ringSize = 118.0 * scale;
                        final bottomPad = 12.0 * scale;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              SizedBox(height: gapSm),
                              Reveal(
                                delayMs: 0,
                                child: HeaderIllustration(
                                  done: done,
                                  height: headerH,
                                ),
                              ),
                              SizedBox(height: gapLg),
                              Reveal(
                                delayMs: 150,
                                child: _Title(fontSize: titleSize),
                              ),
                              SizedBox(height: gapSm),
                              Reveal(
                                delayMs: 300,
                                child: _Description(fontSize: descSize),
                              ),
                              SizedBox(height: gapLg),
                              Reveal(
                                delayMs: 450,
                                child: DataCard(
                                  progress: p,
                                  compact: scale < 0.92,
                                ),
                              ),
                              const Spacer(),
                              Reveal(
                                delayMs: 600,
                                child: ProgressRing(
                                  progress: p,
                                  done: done,
                                  size: ringSize,
                                ),
                              ),
                              SizedBox(height: gapSm),
                              StatusLine(progress: p, done: done),
                              SizedBox(height: bottomPad),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({this.fontSize = 26});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.montserrat(
      color: AppColors.logoWhiteText,
      fontSize: fontSize,
      height: 1.2,
      fontWeight: FontWeight.w800,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Connect your ', style: style),
          TextSpan(
            text: 'WhatsApp',
            style: style.copyWith(color: AppColors.analyzedGreen),
          ),
          TextSpan(text: ' account', style: style),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({this.fontSize = 13.5});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Connect your own account using WhatsApp\'s "Linked Devices" feature. '
      'Your messages will be prepared based on your chats, messages, and call data.',
      textAlign: TextAlign.center,
      style: GoogleFonts.montserrat(
        color: AppColors.analyzedDescription,
        fontSize: fontSize,
        height: 1.4,
      ),
    );
  }
}

/* ============================ ENTRY ANIMATION ============================ */

class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.delayMs, required this.child});
  final int delayMs;
  final Widget child;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.fastOutSlowIn);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(_curve);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _curve,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

Widget _pop(Widget child, Animation<double> anim) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
    );

/* ============================ BACKGROUND GLOW ============================ */

class AmbientGlow extends StatefulWidget {
  const AmbientGlow({super.key, required this.done});
  final bool done;

  @override
  State<AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.done ? 1.8 : 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, boost, _) => CustomPaint(
        painter: _GlowPainter(_c, boost),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.anim, this.boost) : super(repaint: anim);
  final Animation<double> anim;
  final double boost;

  void _glow(Canvas canvas, Offset c, double r, double alpha) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _a(AppColors.analyzedGreen, alpha),
          _a(AppColors.analyzedGreen, 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = 0.08 + 0.08 * Curves.easeInOut.transform(anim.value);
    _glow(canvas, Offset(size.width / 2, 72), size.width * 0.7, a);
    _glow(
      canvas,
      Offset(size.width / 2, size.height - 130),
      size.width * 0.6,
      math.min(a * boost, 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.boost != boost;
}

/* ============================ HEADER ============================ */

class HeaderIllustration extends StatefulWidget {
  const HeaderIllustration({
    super.key,
    required this.done,
    this.height = 120,
  });
  final bool done;
  final double height;

  @override
  State<HeaderIllustration> createState() => _HeaderIllustrationState();
}

class _HeaderIllustrationState extends State<HeaderIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _dash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _row = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _dash.dispose();
    _t.dispose();
    _row.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = (widget.height / 112).clamp(0.85, 1.15);
    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _LinePainter(_dash, _t))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(scale: scale, child: const PhoneNode()),
                Transform.scale(
                  scale: scale,
                  child: LinkNode(done: widget.done),
                ),
                Transform.scale(
                  scale: scale,
                  child: AnimatedBuilder(
                    animation: _row,
                    builder: (context, _) => ServerStack(
                      active: widget.done
                          ? -1
                          : math.min((_row.value * 3).floor(), 2),
                      done: widget.done,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.dash, this.t) : super(repaint: Listenable.merge([dash, t]));
  final Animation<double> dash, t;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const start = 78.0;
    final end = size.width - 88.0;
    const dashW = 9.0, period = 18.0;

    final line = Paint()
      ..color = _a(AppColors.analyzedGreen, 0.45)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (double x = start - period + dash.value * period; x < end; x += period) {
      final s = math.max(x, start), e = math.min(x + dashW, end);
      if (e > s) canvas.drawLine(Offset(s, y), Offset(e, y), line);
    }

    for (var i = 0; i < 3; i++) {
      final f = (t.value + i / 3) % 1.0;
      final x = start + (end - start) * f;
      final alpha = math.sin(f * math.pi);
      canvas.drawCircle(
        Offset(x, y),
        7,
        Paint()..color = _a(AppColors.analyzedGreen, 0.18 * alpha),
      );
      canvas.drawCircle(
        Offset(x, y),
        2.6,
        Paint()..color = _a(AppColors.analyzedGreen, alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PhoneNode extends StatefulWidget {
  const PhoneNode({super.key});

  @override
  State<PhoneNode> createState() => _PhoneNodeState();
}

class _PhoneNodeState extends State<PhoneNode> with TickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ripple.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -2 + 4 * Curves.fastOutSlowIn.transform(_bob.value)),
        child: child,
      ),
      child: Container(
        width: 68,
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.analyzedPhoneFillTop,
              AppColors.analyzedPhoneFillBottom,
            ],
          ),
          border: Border.all(color: AppColors.analyzedPhoneBorder, width: 1.6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: CustomPaint(painter: _RipplePainter(_ripple))),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.analyzedGreenLight,
                      AppColors.analyzedGreen,
                      AppColors.analyzedGreenDeep,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/json/social.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                child: Container(
                  width: 16,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.analyzedPhoneNotch,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                bottom: 7,
                child: Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.analyzedPhoneBar,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 2; i++) {
      final r = Curves.easeOut.transform((anim.value + i * 0.5) % 1.0);
      canvas.drawCircle(
        c,
        18 + r * 16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _a(AppColors.analyzedGreen, (1 - r) * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LinkNode extends StatefulWidget {
  const LinkNode({super.key, required this.done});
  final bool done;

  @override
  State<LinkNode> createState() => _LinkNodeState();
}

class _LinkNodeState extends State<LinkNode> with SingleTickerProviderStateMixin {
  late final AnimationController _rot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _rot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    return AnimatedScale(
      scale: done ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _rot,
              child: CustomPaint(
                size: const Size(48, 48),
                painter: _SweepRingPainter(),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.analyzedGreen : AppColors.analyzedLinkNodeBg,
                border: Border.all(color: _a(AppColors.analyzedGreen, 0.35)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: _pop,
                child: Icon(
                  done ? Icons.check_rounded : Icons.link_rounded,
                  key: ValueKey(done),
                  color: done ? AppColors.analyzedBackground : AppColors.analyzedGreen,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SweepRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1.5;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            _a(AppColors.analyzedGreen, 0),
            _a(AppColors.analyzedGreen, 0.3),
            AppColors.analyzedGreen,
            _a(AppColors.analyzedGreen, 0),
          ],
          stops: const [0.0, 0.5, 0.9, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ServerStack extends StatelessWidget {
  const ServerStack({super.key, required this.active, required this.done});
  final int active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.analyzedServerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.analyzedStroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final on = done || i == active;
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 5),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: on
                    ? _a(AppColors.analyzedGreen, 0.07)
                    : _a(AppColors.analyzedGreen, 0),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: _a(AppColors.analyzedGreen, on ? 0.9 : 0.35),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on
                          ? AppColors.analyzedGreen
                          : _a(AppColors.analyzedGreen, 0.3),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                color: _a(AppColors.analyzedGreen, 0.8),
                                blurRadius: 6,
                              ),
                            ]
                          : const [],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: _a(AppColors.analyzedGreen, 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/* ============================ DATA CARD ============================ */

class DataCard extends StatelessWidget {
  const DataCard({
    super.key,
    required this.progress,
    this.compact = false,
  });
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.analyzedCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.analyzedStroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.analyzedStroke,
                indent: 10,
                endIndent: 10,
              ),
            _InfoRow(
              item: _items[i],
              state: progress >= _items[i].to
                  ? 2
                  : progress >= _items[i].from
                      ? 1
                      : 0,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.item,
    required this.state,
    this.compact = false,
  });
  final _SyncItem item;
  final int state; // 0 waiting, 1 syncing, 2 done
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tint = item.tint;
    final iconBox = compact ? 44.0 : 50.0;
    final iconSize = compact ? 24.0 : 26.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: state == 1 ? _a(tint, 0.07) : _a(tint, 0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AnimatedScale(
            scale: state == 1 ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            child: Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: _a(tint, 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _a(tint, 0.22), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _a(tint, 0.22),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Image.asset(
                item.asset,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.montserrat(
                    color: AppColors.logoWhiteText,
                    fontSize: compact ? 15.5 : 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: AppColors.analyzedMuted,
                    fontSize: compact ? 12 : 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            height: 28,
            child: Center(child: StatusBadge(state: state, tint: tint)),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.state, required this.tint});
  final int state;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    late final Widget child;
    switch (state) {
      case 0:
        child = Container(
          key: const ValueKey(0),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.analyzedWaitingDot,
          ),
        );
        break;
      case 1:
        child = SizedBox(
          key: const ValueKey(1),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: tint,
            backgroundColor: _a(tint, 0.15),
            strokeCap: StrokeCap.round,
          ),
        );
        break;
      default:
        child = Container(
          key: const ValueKey(2),
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.analyzedGreen,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.analyzedBackground,
            size: 16,
          ),
        );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: _pop,
      child: child,
    );
  }
}

/* ============================ PROGRESS RING ============================ */

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.done,
    this.size = 118,
  });
  final double progress;
  final bool done;
  final double size;

  @override
  Widget build(BuildContext context) {
    final checkSize = size * 0.42;
    final numSize = size * 0.28;
    final pctSize = size * 0.13;
    return AnimatedScale(
      scale: done ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(progress),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: _pop,
              child: done
                  ? Container(
                      key: const ValueKey('done'),
                      width: checkSize,
                      height: checkSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.analyzedGreen,
                        boxShadow: [
                          BoxShadow(
                            color: _a(AppColors.analyzedGreen, 0.5),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.analyzedBackground,
                        size: checkSize * 0.58,
                      ),
                    )
                  : Row(
                      key: const ValueKey('num'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(progress * 100).floor()}',
                          style: GoogleFonts.montserrat(
                            color: AppColors.logoWhiteText,
                            fontSize: numSize,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 3),
                          child: Text(
                            '%',
                            style: GoogleFonts.montserrat(
                              color: AppColors.analyzedMuted,
                              fontSize: pctSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width * 0.068).clamp(7.0, 10.0);
    final rect = Rect.fromLTWH(s, s, size.width - 2 * s, size.height - 2 * s);
    final c = rect.center;
    final r = rect.width / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s
        ..color = AppColors.analyzedRingTrack,
    );
    if (p <= 0) return;

    final sweep = 2 * math.pi * p;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 2.4
        ..strokeCap = StrokeCap.round
        ..color = _a(AppColors.analyzedGreen, 0.15),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [
            AppColors.analyzedGreenDeep,
            AppColors.analyzedGreen,
            AppColors.analyzedGreenLight,
            AppColors.analyzedGreen,
          ],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
    if (p > 0.01 && p < 0.999) {
      final ang = -math.pi / 2 + sweep;
      final head = c + Offset(r * math.cos(ang), r * math.sin(ang));
      canvas.drawCircle(
        head,
        s * 1.1,
        Paint()..color = _a(AppColors.analyzedGreen, 0.3),
      );
      canvas.drawCircle(
        head,
        s * 0.35,
        Paint()..color = AppColors.logoWhiteText,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.p != p;
}

/* ============================ STATUS LINE ============================ */

class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.progress, required this.done});
  final double progress;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final label = done
        ? 'All set! Your account is linked'
        : progress < 0.35
            ? 'Reading your chats…'
            : progress < 0.70
                ? 'Analyzing messages…'
                : 'Fetching call data…';

    return SizedBox(
      height: 22,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) {
            final incoming = child.key == ValueKey(label);
            final offset = Tween<Offset>(
              begin: Offset(0, incoming ? 1 : -1),
              end: Offset.zero,
            ).animate(anim);
            return SlideTransition(
              position: offset,
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: Text(
            label,
            key: ValueKey(label),
            style: GoogleFonts.montserrat(
              color: done ? AppColors.analyzedGreen : AppColors.analyzedMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
