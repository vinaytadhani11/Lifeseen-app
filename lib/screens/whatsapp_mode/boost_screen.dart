import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/config/app_config.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';

/* ============================== THEME ============================== */

const kBg = AppColors.boostBg;
const kCard = AppColors.boostCard;
const kLine = AppColors.boostLine;
const kLine2 = AppColors.boostLine2;
const kGreen = AppColors.boostGreen;
const kGreenDeep = AppColors.boostGreenDeep;
const kYellow = AppColors.boostYellow;
const kText = AppColors.boostText;
const kMuted = AppColors.boostMuted;
const kInk = AppColors.boostInk;
const kInkGold = AppColors.boostInkGold;

Color _a(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());

TextStyle sans(double size, FontWeight w, Color c, {double ls = 0, double? h}) =>
    GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
      height: h,
    );

/// RobotoMono is bundled as Regular + Medium only — clamp heavier weights.
TextStyle mono(double size, FontWeight w, Color c, {double ls = 0, double? h}) =>
    GoogleFonts.robotoMono(
      fontSize: size,
      fontWeight: (w.value >= FontWeight.w600.value) ? FontWeight.w500 : w,
      color: c,
      letterSpacing: ls,
      height: h,
    );

double loop(double t, double period, [double delay = 0]) =>
    ((t - delay) / period) % 1.0;

double pingPong(double u) => (1 - math.cos(u * 2 * math.pi)) / 2;

const _revealCurve = Cubic(0.2, 0.8, 0.2, 1.0);
const _popCurve = Curves.easeOutBack;

/* ============================== PLANS ============================== */

class _BoostUiPlan {
  const _BoostUiPlan({
    required this.plan,
    required this.name,
    required this.sub,
    required this.daily,
    required this.period,
    required this.ctaSub,
    required this.color,
    this.tag,
  });

  final BoostPlan plan;
  final String name;
  final String sub;
  final String daily;
  final String period;
  final String ctaSub;
  final Color color;
  final String? tag;
}

enum CtaMode { idle, loading, ok }

enum TileS { off, boot, on }

/* ============================== PAGE ============================== */

/// Opened by "Speed Up". Local boost only — no Play Store purchase.
/// Hours come from Remote Config `settings` (normal_boost / super_boost).
class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const BoostScreen()),
    );
  }

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> with TickerProviderStateMixin {
  // Faster boot so cluster animation is visible immediately and feels snappy.
  static const step0 = 420, stepMs = 380, bootMs = 780;

  late final bool _superCardVisible;
  late BoostPlan _selected;
  bool _showClose = false;
  Timer? _closeTimer;

  final clock = ValueNotifier<double>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final sim = PipeSim();

  final _contentKey = GlobalKey();
  final _rackKey = GlobalKey();
  final _slotKey = GlobalKey();
  final _ctaKey = GlobalKey();

  final tiles = List<TileS>.filled(8, TileS.off);
  final flash = List<bool>.filled(8, false);
  late final List<AnimationController> bars;
  int onCount = 0;
  double fill = 0;
  bool allOn = false;

  CtaMode mode = CtaMode.idle;

  final _timers = <Timer>[];
  final _rnd = math.Random();

  late final List<_BoostUiPlan> _plans;

  void _after(int ms, VoidCallback fn) => _timers.add(
        Timer(Duration(milliseconds: ms), () {
          if (mounted) fn();
        }),
      );

  @override
  void initState() {
    super.initState();
    _superCardVisible = !AppBootstrap.subscription.isNormalBoostActive;
    _selected = BoostPlan.normal;

    final config = AppBootstrap.remoteConfig.config;
    _plans = [
      _BoostUiPlan(
        plan: BoostPlan.normal,
        name: config.boostSelected1Title,
        sub: config.boostSelected1SubTitle,
        daily: BoostPlan.normal.dailyPrice,
        period: BoostPlan.normal.periodPrice,
        ctaSub: BoostPlan.normal.periodPrice.replaceAll(' ', ''),
        color: kGreen,
      ),
      if (_superCardVisible)
        _BoostUiPlan(
          plan: BoostPlan.superBoost,
          name: config.boostSelected2Title,
          sub: config.boostSelected2SubTitle,
          daily: BoostPlan.superBoost.dailyPrice,
          period: BoostPlan.superBoost.periodPrice,
          ctaSub: BoostPlan.superBoost.periodPrice.replaceAll(' ', ''),
          color: kYellow,
          tag: 'MAX',
        ),
    ];

    final delay = config.closeButtonDelay;
    if (delay == Duration.zero) {
      _showClose = true;
    } else if (delay != null) {
      _closeTimer = Timer(delay, () {
        if (mounted) setState(() => _showClose = true);
      });
    }

    bars = List.generate(8, (_) => AnimationController(vsync: this));
    // 60fps clock — only CustomPainters / tiny AnimatedBuilders listen to this.
    _ticker = createTicker((elapsed) {
      final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
      _last = elapsed;
      final now = elapsed.inMicroseconds / 1e6;
      sim.target = mode == CtaMode.loading
          ? 3.4
          : mode == CtaMode.ok
              ? 2.2
              : 1.0;
      sim.step(dt, now);
      clock.value = now;
    })
      ..start();
    _bootCluster();

    if (AppBootstrap.subscription.isSubscriptionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _subscriptionEnded());
    }
  }

  void _bootCluster() {
    for (var i = 0; i < 8; i++) {
      _after(step0 + i * stepMs, () {
        setState(() {
          tiles[i] = TileS.boot;
          fill = (onCount + 0.5) / 8;
        });
        bars[i].value = 0;
        bars[i].animateTo(
          1,
          duration: const Duration(milliseconds: 1300),
          curve: Curves.linear,
        );
      });
      _after(step0 + i * stepMs + bootMs, () {
        setState(() {
          tiles[i] = TileS.on;
          flash[i] = true;
          onCount++;
          fill = onCount / 8;
        });
        bars[i].value = 0;
        bars[i].animateTo(
          1,
          duration: const Duration(milliseconds: 1100),
          curve: Curves.ease,
        );
        _after(900, () => setState(() => flash[i] = false));
      });
    }
    _after(step0 + 7 * stepMs + bootMs + 1200, () {
      setState(() => allOn = true);
      _timers.add(
        Timer.periodic(const Duration(milliseconds: 1400), (_) {
          if (!mounted) return;
          final b = bars[_rnd.nextInt(8)];
          b.animateTo(
            0.55 + _rnd.nextDouble() * 0.45,
            duration: const Duration(milliseconds: 1100),
            curve: Curves.ease,
          );
          _after(
            1600,
            () => b.animateTo(
              1,
              duration: const Duration(milliseconds: 1100),
              curve: Curves.ease,
            ),
          );
        }),
      );
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    _ticker.dispose();
    for (final b in bars) {
      b.dispose();
    }
    clock.dispose();
    super.dispose();
  }

  void _subscriptionEnded() {
    if (!mounted) return;
    Fluttertoast.showToast(
      msg: 'Subscription ended. Please subscribe again.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.secureCardBackground,
      textColor: Colors.white,
      fontSize: 15,
    );
    Navigator.of(context).maybePop();
  }

  Future<void> _activate() async {
    if (mode != CtaMode.idle) return;
    if (AppBootstrap.subscription.isSubscriptionExpired) {
      _subscriptionEnded();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => mode = CtaMode.loading);
    final started = DateTime.now();

    await AppBootstrap.subscription.activateBoostLocally(_selected);
    await AppBootstrap.applyBoostOnChatResume();
    if (!mounted) return;

    final waited = DateTime.now().difference(started).inMilliseconds;
    _after(math.max(0, 1400 - waited), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => mode = CtaMode.ok);
      Fluttertoast.showToast(
        msg: 'Boost activated locally',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.secureCardBackground,
        textColor: Colors.white,
        fontSize: 15,
      );
      _after(900, () {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  Future<void> _openLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _close() {
    if (!_showClose || mode == CtaMode.loading) return;
    Navigator.of(context).pop();
  }

  Widget _pad(Widget w, {double top = 0}) =>
      Padding(padding: EdgeInsets.fromLTRB(30, top, 30, 0), child: w);

  _BoostUiPlan get _activePlan =>
      _plans.firstWhere((p) => p.plan == _selected, orElse: () => _plans.first);

  @override
  Widget build(BuildContext context) {
    final config = AppBootstrap.remoteConfig.config;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final canPop = _showClose && mode != CtaMode.loading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: kBg,
      ),
      child: PopScope(
        canPop: canPop,
        child: Scaffold(
          backgroundColor: kBg,
          body: Stack(
            children: [
              const Positioned(
                top: -140,
                left: 0,
                right: 0,
                height: 420,
                child: _AmbientGlow(),
              ),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Stack(
                    key: _contentKey,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: PipesPainter(
                                clock: clock,
                                sim: sim,
                                contentKey: _contentKey,
                                rackKey: _rackKey,
                                slotKey: _slotKey,
                                ctaKey: _ctaKey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          _pad(
                            Reveal(
                              delay: 0,
                              child: TopBar(
                                showClose: _showClose,
                                enabled: mode != CtaMode.loading,
                                onClose: _close,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Reveal(
                              delay: 0.08,
                              child: RepaintBoundary(
                                child: Hero3D(
                                  clock: clock,
                                  sim: sim,
                                  allOn: allOn,
                                  rackKey: _rackKey,
                                  slotKey: _slotKey,
                                ),
                              ),
                            ),
                          ),
                          _pad(
                            Reveal(
                              delay: 0.18,
                              child: ClusterCard(
                                clock: clock,
                                tiles: tiles,
                                flash: flash,
                                bars: bars,
                                onCount: onCount,
                                fill: fill,
                              ),
                            ),
                            top: 10,
                          ),
                          _pad(
                            Reveal(
                              delay: 0.28,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  config.boostTitle,
                                  style: sans(
                                    26,
                                    FontWeight.w800,
                                    kText,
                                    ls: -0.26,
                                    h: 1.15,
                                  ),
                                ),
                              ),
                            ),
                            top: 22,
                          ),
                          _pad(
                            Reveal(
                              delay: 0.36,
                              child: Text(
                                config.boostSubTitle,
                                textAlign: TextAlign.center,
                                style: sans(
                                  13.5,
                                  FontWeight.w400,
                                  AppColors.boostDesc,
                                  h: 1.45,
                                ),
                              ),
                            ),
                            top: 8,
                          ),
                          _pad(
                            Reveal(
                              delay: 0.5,
                              child: Column(
                                children: [
                                  for (var i = 0; i < _plans.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 10),
                                    _PlanCard(
                                      plan: _plans[i],
                                      selected: _selected == _plans[i].plan,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(
                                          () => _selected = _plans[i].plan,
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            top: 20,
                          ),
                          _pad(
                            Reveal(
                              delay: 0.58,
                              child: _BoostButton(
                                key: _ctaKey,
                                clock: clock,
                                plan: _activePlan,
                                buttonLabel: config.boostButton,
                                mode: mode,
                                onTap: _activate,
                              ),
                            ),
                            top: 16,
                          ),
                          _pad(
                            Reveal(
                              delay: 0.66,
                              child: Footer(
                                onPrivacy: () =>
                                    _openLink(AppConfig.privacyPolicyUrl),
                                onTerms: () =>
                                    _openLink(AppConfig.termsOfUseUrl),
                              ),
                            ),
                            top: 14,
                          ),
                          SizedBox(height: 18 + bottomInset),
                        ],
                      ),
                    ],
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

/* ============================== REVEAL ============================== */

/// One-shot fade + slide (same pattern as analyzed screen).
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.delay,
    required this.child,
  });
  final double delay;
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
      CurvedAnimation(parent: _c, curve: _revealCurve);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(_curve);

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: (widget.delay * 1000).round()),
      () {
        if (mounted) _c.forward();
      },
    );
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

/* ============================== AMBIENT GLOW ============================== */

class _AmbientGlow extends StatefulWidget {
  const _AmbientGlow();

  @override
  State<_AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<_AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final u = Curves.easeInOut.transform(_c.value);
          return Opacity(
            opacity: 0.55 + 0.45 * u,
            child: Center(
              child: Transform.scale(
                scaleX: 520 / 420,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_a(kGreen, 0.12), _a(kGreen, 0)],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ============================== TOP BAR ============================== */

class TopBar extends StatefulWidget {
  const TopBar({
    super.key,
    required this.showClose,
    required this.enabled,
    required this.onClose,
  });
  final bool showClose;
  final bool enabled;
  final VoidCallback onClose;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.16),
            child: Text(
              'LIFESEEN · BOOST',
              style: mono(
                13,
                FontWeight.w500,
                AppColors.boostTitleMuted,
                ls: 4.16,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedOpacity(
              opacity: widget.showClose ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !widget.showClose || !widget.enabled,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _down = true),
                  onTapUp: (_) => setState(() => _down = false),
                  onTapCancel: () => setState(() => _down = false),
                  onTap: widget.onClose,
                  child: AnimatedScale(
                    scale: _down ? 0.92 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _down
                            ? AppColors.boostCloseBgDown
                            : AppColors.boostCloseBg,
                        border: Border.all(color: kLine2),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.boostCloseIcon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================== PIPE SIMULATION ============================== */

class _Particle {
  _Particle(this.off, this.k, this.data);
  final double off, k;
  final bool data;
  double prev = 0;
}

class PipeSim {
  double phase = 0, speed = 1, target = 1;
  final flash = [0.0, 0.0];
  double rackHitUntil = -1;
  final parts = List.generate(
    2,
    (_) => [
      for (var i = 0; i < 4; i++) _Particle(i / 4, 1 / 3.2, false),
      for (var i = 0; i < 3; i++) _Particle(i / 3 + 1 / 6, 1 / 4.2, true),
    ],
  );

  void step(double dt, double now) {
    speed += (target - speed) * (1 - math.pow(0.95, dt * 60));
    phase += dt * speed;
    for (var s = 0; s < 2; s++) {
      flash[s] = math.max(0, flash[s] - dt / 0.35);
      for (final q in parts[s]) {
        final f = (phase * q.k + q.off) % 1.0;
        if (f < q.prev) {
          flash[s] = 1;
          rackHitUntil = now + 0.14;
        }
        q.prev = f;
      }
    }
  }
}

/* ============================== HERO ============================== */

class Hero3D extends StatelessWidget {
  const Hero3D({
    super.key,
    required this.clock,
    required this.sim,
    required this.allOn,
    required this.rackKey,
    required this.slotKey,
  });
  final ValueListenable<double> clock;
  final PipeSim sim;
  final bool allOn;
  final GlobalKey rackKey, slotKey;

  @override
  Widget build(BuildContext context) {
    // Widget tree is static; only CustomPainters tick with [clock].
    return SizedBox(
      height: 136,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: HeroLinesPainter(clock: clock, dim: !allOn),
                ),
              ),
              Positioned(
                top: 18,
                left: w / 2 - 61,
                width: 122,
                child: Container(
                  key: rackKey,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF151A17), Color(0xFF101411)],
                    ),
                    border: Border.all(
                      color: const Color(0xFF29332E),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _a(Colors.black, 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RackSlot(clock: clock, on: true),
                      const SizedBox(height: 4),
                      RackSlot(clock: clock, on: allOn),
                      const SizedBox(height: 4),
                      RackSlot(key: slotKey, clock: clock, on: allOn),
                    ],
                  ),
                ),
              ),
              // Soft hit flash — tiny rebuild only.
              Positioned(
                top: 18,
                left: w / 2 - 61,
                width: 122,
                height: 100,
                child: IgnorePointer(
                  child: ValueListenableBuilder<double>(
                    valueListenable: clock,
                    builder: (_, t, __) {
                      final hit = t < sim.rackHitUntil;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: hit ? 80 : 400),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: _a(kGreen, hit ? 0.35 : 0),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: w / 2 + 24,
                top: -10,
                child: BoltBadge(clock: clock),
              ),
            ],
          );
        },
      ),
    );
  }
}

class HeroLinesPainter extends CustomPainter {
  HeroLinesPainter({required this.clock, required this.dim})
      : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool dim;

  static const _ease = Cubic(0.45, 0, 0.2, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final lw = size.width / 2 - 62;
    const lines = [
      (38.0, true, 0.8, true),
      (68.0, true, 0.0, false),
      (38.0, false, 1.6, true),
      (68.0, false, 0.0, false),
    ];
    for (final (y, left, delay, startsDim) in lines) {
      final rect = left
          ? Rect.fromLTWH(0, y, lw, 2)
          : Rect.fromLTWH(size.width - lw, y, lw, 2);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end: left ? Alignment.centerRight : Alignment.centerLeft,
            colors: const [
              Color(0x001F2924),
              Color(0xFF1F2924),
              Color(0xFF1F2924),
            ],
            stops: const [0, 0.18, 1],
          ).createShader(rect),
      );
      final u = loop(t, 2.4, -delay);
      final p = _ease.transform(u);
      final op = u < 0.15
          ? u / 0.15
          : (u > 0.85 ? (1 - u) / 0.15 : 1.0);
      final d = -20 + (lw + 20) * p;
      final x = left ? d : size.width - d - 18;
      final isDim = dim && startsDim;
      final pk = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y - 1, 18, 4),
        const Radius.circular(2),
      );
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(rect.left, y - 3, rect.right, y + 5));
      canvas.drawRRect(
        pk,
        Paint()..color = _a(isDim ? const Color(0xFF7A6A3A) : kYellow, op),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant HeroLinesPainter old) => old.dim != dim;
}

class RackSlot extends StatelessWidget {
  const RackSlot({super.key, required this.clock, required this.on});
  final ValueListenable<double> clock;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: on ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: const CustomPaint(
                painter: DashedRRectPainter(Color(0xFF26302B), 6, 1.5),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.only(left: 7, right: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: on ? _a(kYellow, 0.07) : _a(kYellow, 0),
              border: Border.all(
                color: on ? _a(kYellow, 0.75) : _a(kYellow, 0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dot(on ? kYellow : const Color(0xFF2B342F)),
                    const SizedBox(height: 3),
                    _dot(on ? kYellow : const Color(0xFF2B342F)),
                  ],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 13,
                    child: CustomPaint(
                      painter: _EqBarsPainter(clock: clock, on: on),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(
                    painter: _SpinFanPainter(clock: clock, on: on),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dot(Color c) => Container(
        width: 3.5,
        height: 3.5,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );
}

class _EqBarsPainter extends CustomPainter {
  _EqBarsPainter({required this.clock, required this.on})
      : super(repaint: on ? clock : null);
  final ValueListenable<double> clock;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 6;
    const gap = 3.0;
    const barW = 5.0;
    final t = clock.value;
    const total = count * barW + (count - 1) * gap;
    var x = (size.width - total).clamp(0.0, size.width) / 2;
    for (var i = 0; i < count; i++) {
      final op = on ? _eq(t, i) : 1.0;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barW, size.height),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = on ? _a(kYellow, op) : const Color(0xFF202824),
      );
      x += barW + gap;
    }
  }

  static double _eq(double t, int i) {
    final u = loop(t, 1.1, -i * 0.14);
    final v = u < 0.5
        ? Curves.easeInOut.transform(u / 0.5)
        : 1 - Curves.easeInOut.transform((u - 0.5) / 0.5);
    return 1 - 0.82 * v;
  }

  @override
  bool shouldRepaint(covariant _EqBarsPainter old) => old.on != on;
}

class _SpinFanPainter extends CustomPainter {
  _SpinFanPainter({required this.clock, required this.on})
      : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final angle = (t / (on ? 0.7 : 3.5)) * 2 * math.pi;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);
    FanPainter(on ? kYellow : const Color(0xFF38433D)).paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpinFanPainter old) => old.on != on;
}

class BoltBadge extends StatelessWidget {
  const BoltBadge({super.key, required this.clock});
  final ValueListenable<double> clock;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: _BoltBadgePainter(clock: clock),
        child: const Center(
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: CustomPaint(
                size: Size(17, 17),
                painter: BoltPainter(
                  kYellow,
                  stroke: Color(0xFF0B1A10),
                  strokeWidth: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoltBadgePainter extends CustomPainter {
  _BoltBadgePainter({required this.clock}) : super(repaint: clock);
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final halo = Curves.easeOut.transform(loop(t, 1.8));
    final pulse = Curves.easeInOut.transform(pingPong(loop(t, 1.8)));
    final c = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      c,
      30,
      Paint()
        ..shader = RadialGradient(
          colors: [_a(kGreen, 0.20), _a(kGreen, 0.06), _a(kGreen, 0)],
          stops: const [0, 0.6, 0.7],
        ).createShader(Rect.fromCircle(center: c, radius: 30)),
    );

    final ringR = (0.7 + 0.55 * halo) * 26;
    canvas.drawCircle(
      c,
      ringR,
      Paint()..color = _a(kGreen, 0.10 * (1 - halo)),
    );

    canvas.drawCircle(
      c,
      19,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFF8BEAA4), kGreen, Color(0xFF2F9E57)],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: 19)),
    );
    canvas.drawCircle(
      c,
      19,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = kBg,
    );
    canvas.drawCircle(
      c,
      22,
      Paint()..color = _a(kGreen, 0.18 + 0.12 * pulse),
    );
  }

  @override
  bool shouldRepaint(covariant _BoltBadgePainter old) => false;
}

/* ============================== CLUSTER CARD ============================== */

class ClusterCard extends StatelessWidget {
  const ClusterCard({
    super.key,
    required this.clock,
    required this.tiles,
    required this.flash,
    required this.bars,
    required this.onCount,
    required this.fill,
  });
  final ValueListenable<double> clock;
  final List<TileS> tiles;
  final List<bool> flash;
  final List<AnimationController> bars;
  final int onCount;
  final double fill;

  @override
  Widget build(BuildContext context) {
    final booting = onCount < 8;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CustomPaint(
                size: Size(18, 18),
                painter: ServerIconPainter(Color(0xFFB4BBB6)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CLUSTER · EU-CENTRAL-1',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: mono(
                    11,
                    FontWeight.w400,
                    const Color(0xFFB4BBB6),
                    ls: 0.66,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: mono(
                  11,
                  FontWeight.w700,
                  booting ? kYellow : kGreen,
                  ls: 0.66,
                ),
                child: Text(booting ? '$onCount/8 · BOOTING' : '8/8 · ACTIVE'),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 5,
              color: const Color(0xFF1D2420),
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 1000),
                curve: const Cubic(0.3, 0.8, 0.3, 1),
                widthFactor: fill,
                heightFactor: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kGreenDeep, kGreen],
                          ),
                        ),
                      ),
                      CustomPaint(
                        painter: _ProgressShimmerPainter(clock: clock),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (var r = 0; r < 2; r++) ...[
            if (r > 0) const SizedBox(height: 6),
            Row(
              children: [
                for (var c = 0; c < 4; c++) ...[
                  if (c > 0) const SizedBox(width: 6),
                  Expanded(
                    child: ServerTile(
                      index: r * 4 + c,
                      clock: clock,
                      state: tiles[r * 4 + c],
                      flash: flash[r * 4 + c],
                      bar: bars[r * 4 + c],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ServerTile extends StatelessWidget {
  const ServerTile({
    super.key,
    required this.index,
    required this.clock,
    required this.state,
    required this.flash,
    required this.bar,
  });
  final int index;
  final ValueListenable<double> clock;
  final TileS state;
  final bool flash;
  final AnimationController bar;

  @override
  Widget build(BuildContext context) {
    const dur = Duration(milliseconds: 800);
    const durTxt = Duration(milliseconds: 700);
    final boot = state == TileS.boot, on = state == TileS.on;
    final accent = boot ? kYellow : kGreen;
    final border = boot
        ? _a(kYellow, 0.6)
        : on
            ? _a(kGreen, 0.55)
            : _a(kGreen, 0);
    final bg = boot
        ? _a(kYellow, 0.05)
        : on
            ? _a(kGreen, 0.06)
            : _a(kGreen, 0);
    final nameC = boot
        ? const Color(0xFFD9C08A)
        : on
            ? const Color(0xFFDCE3DE)
            : const Color(0xFF4A544E);
    final stC = boot
        ? kYellow
        : on
            ? kGreen
            : const Color(0xFF3E4842);
    final status = boot
        ? 'booting'
        : on
            ? 'active'
            : 'offline';

    return SizedBox(
      height: 46,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: state == TileS.off ? 1 : 0,
              duration: dur,
              child: const CustomPaint(
                painter: DashedRRectPainter(Color(0xFF263029), 9, 1.5),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedContainer(
              duration: dur,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: border, width: 1.5),
                boxShadow: [
                  BoxShadow(color: _a(kGreen, flash ? 0.18 : 0), spreadRadius: 3),
                  BoxShadow(
                    color: _a(kGreen, flash ? 0.25 : 0),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: durTxt,
                    style: mono(10.5, FontWeight.w400, nameC, h: 1.1),
                    child: Text(
                      'srv-0${index + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 3.5,
                      color: const Color(0xFF1C231F),
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: bar,
                        builder: (_, __) => FractionallySizedBox(
                          widthFactor: state == TileS.off ? 0 : bar.value,
                          heightFactor: 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: durTxt,
                    style: mono(10, FontWeight.w400, stC, h: 1),
                    child: Text(status, maxLines: 1),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 6,
            child: boot
                ? ValueListenableBuilder<double>(
                    valueListenable: clock,
                    builder: (_, t, __) {
                      final blink = 1 -
                          0.8 *
                              Curves.easeInOut
                                  .transform(pingPong(loop(t, 0.9)));
                      return Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _a(kYellow, blink),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? kGreen : const Color(0xFF2B342F),
                      boxShadow: on
                          ? const [BoxShadow(color: kGreen, blurRadius: 6)]
                          : const [],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/* ============================== PLAN CARD ============================== */

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });
  final _BoostUiPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.plan, sel = widget.selected, c = p.color;
    const dur = Duration(milliseconds: 300);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: dur,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? c : kLine2, width: 1.5),
            gradient: sel
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(_a(c, 0.09), kCard),
                      Color.alphaBlend(_a(c, 0.02), kCard),
                    ],
                  )
                : null,
            boxShadow: [
              BoxShadow(color: _a(c, sel ? 0.12 : 0), blurRadius: 22),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: dur,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? c : _a(c, 0),
                      border: Border.all(
                        color: sel ? c : const Color(0xFF4A544F),
                        width: 2,
                      ),
                    ),
                    child: AnimatedScale(
                      scale: sel ? 1 : 0,
                      duration: const Duration(milliseconds: 350),
                      curve: _popCurve,
                      child: CustomPaint(
                        painter: CheckPainter(
                          p.plan == BoostPlan.normal ? kInk : kInkGold,
                          3.6,
                          inset: 3.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: sans(17, FontWeight.w800, c, h: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.sub,
                          style: sans(12.5, FontWeight.w400, kMuted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                p.daily,
                                style: sans(14.5, FontWeight.w700, kText),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: AnimatedDefaultTextStyle(
                                duration: dur,
                                style: mono(
                                  10.5,
                                  FontWeight.w400,
                                  sel
                                      ? const Color(0xFFC7CCC9)
                                      : const Color(0xFF7E8682),
                                ),
                                child: Text(p.period),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (p.tag != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      p.tag!,
                      style: mono(
                        9.5,
                        FontWeight.w700,
                        kInkGold,
                        ls: 1.14,
                        h: 1,
                      ),
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

/* ============================== ACTIVATE BOOST BUTTON ============================== */

class _BoostButton extends StatefulWidget {
  const _BoostButton({
    super.key,
    required this.clock,
    required this.plan,
    required this.buttonLabel,
    required this.mode,
    required this.onTap,
  });
  final ValueListenable<double> clock;
  final _BoostUiPlan plan;
  final String buttonLabel;
  final CtaMode mode;
  final VoidCallback onTap;

  @override
  State<_BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<_BoostButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final ok = mode == CtaMode.ok, loading = mode == CtaMode.loading;
    final gold = widget.plan.plan == BoostPlan.superBoost && mode == CtaMode.idle;
    final ink = ok
        ? kGreen
        : gold
            ? kInkGold
            : kInk;
    final t1 = loading
        ? 'ACTIVATING…'
        : ok
            ? 'BOOST ACTIVE'
            : widget.buttonLabel.toUpperCase();
    final name = widget.plan.name.toLowerCase();
    final t2 = loading
        ? 'routing to cluster…'
        : ok
            ? '$name · P0 · 16 vCPU'
            : '$name · ${widget.plan.ctaSub}';

    final gradient = ok
        ? const [Color(0xFF183324), Color(0xFF11261A), Color(0xFF11261A)]
        : gold
            ? const [Color(0xFFF8D27E), Color(0xFFF2B84B), Color(0xFFE0A43A)]
            : const [Color(0xFF86E8A0), Color(0xFF5BD47A), Color(0xFF47BF66)];

    final baseShadows = ok
        ? [
            const BoxShadow(
              color: Color(0xFF0C1D13),
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: _a(kGreen, 0.2),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ]
        : _down
            ? [
                BoxShadow(
                  color: gold
                      ? const Color(0xFF8A6118)
                      : const Color(0xFF23753C),
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: _a(gold ? kYellow : kGreen, 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: gold
                      ? const Color(0xFF8A6118)
                      : const Color(0xFF23753C),
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: _a(gold ? kYellow : kGreen, 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ];

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: mode == CtaMode.idle ? widget.onTap : null,
      child: Transform.translate(
        offset: Offset(0, _down && !ok ? 3 : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradient,
              stops: const [0, 0.48, 1],
            ),
            border: ok ? Border.all(color: kGreen, width: 1.5) : null,
            boxShadow: baseShadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ok ? 18.5 : 20),
            child: Stack(
              children: [
                if (!ok)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CtaTexturePainter(gold ? kInkGold : kInk),
                    ),
                  ),
                if (!ok)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CtaShinePainter(clock: widget.clock),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 10, 0),
                  child: Row(
                    children: [
                      _icon(ok, loading, gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sans(
                                18,
                                FontWeight.w800,
                                ink,
                                ls: 0.9,
                                h: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Opacity(
                              opacity: ok ? 0.85 : 0.72,
                              child: Text(
                                t2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: mono(
                                  10,
                                  FontWeight.w500,
                                  ink,
                                  ls: 0.4,
                                  h: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _arrows(ok, loading, ink),
                    ],
                  ),
                ),
                if (!ok)
                  Positioned(
                    left: 69,
                    right: 62,
                    bottom: 9,
                    height: 2,
                    child: CustomPaint(
                      painter: _ChargePainter(
                        clock: widget.clock,
                        loading: loading,
                        ink: gold ? kInkGold : kInk,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(bool ok, bool loading, bool gold) {
    Widget inner;
    if (loading) {
      inner = CustomPaint(
        size: const Size(22, 22),
        painter: _SpinnerSpinPainter(clock: widget.clock),
      );
    } else if (ok) {
      inner = TweenAnimationBuilder<double>(
        key: const ValueKey('ok'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: _popCurve,
        builder: (_, v, __) => Transform.scale(
          scale: v,
          child: const CustomPaint(
            size: Size(24, 24),
            painter: CheckPainter(kInk, 3),
          ),
        ),
      );
    } else {
      inner = CustomPaint(
        size: const Size(22, 22),
        painter: _BoltPulsePainter(clock: widget.clock),
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _IconRingPainter(
                clock: widget.clock,
                ok: ok,
                gold: gold,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: ok ? kGreen : null,
              gradient: ok
                  ? null
                  : RadialGradient(
                      center: const Alignment(0, -0.3),
                      colors: gold
                          ? const [Color(0xFF2B2110), Color(0xFF130D04)]
                          : const [Color(0xFF163222), Color(0xFF0A1810)],
                    ),
              border: ok
                  ? null
                  : Border.all(
                      color: gold ? _a(kYellow, 0.4) : _a(kGreen, 0.35),
                    ),
              boxShadow: ok
                  ? [BoxShadow(color: _a(kGreen, 0.6), blurRadius: 18)]
                  : [
                      BoxShadow(
                        color: _a(Colors.black, 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(child: inner),
          ),
        ],
      ),
    );
  }

  Widget _arrows(bool ok, bool loading, Color ink) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ok ? _a(kGreen, 0.12) : _a(ink, 0.12),
        border: Border.all(
          color: ok ? _a(kGreen, 0.3) : _a(ink, 0.15),
        ),
      ),
      child: CustomPaint(
        painter: _ChevronsPainter(
          clock: widget.clock,
          ink: ink,
          loading: loading,
        ),
      ),
    );
  }
}

class _CtaShinePainter extends CustomPainter {
  _CtaShinePainter({required this.clock}) : super(repaint: clock);
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    if (t < 1.5) return;
    final u = loop(t, 3.4, 1.5);
    if (u > 0.45) return;
    final x = -0.6 + 1.85 * Curves.easeInOut.transform(u / 0.45);
    final rect = Rect.fromLTWH(size.width * x, 0, size.width * 0.45, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.2),
          end: const Alignment(1, 0.2),
          colors: [
            _a(Colors.white, 0),
            _a(Colors.white, 0.45),
            _a(Colors.white, 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CtaShinePainter old) => false;
}

class _ChargePainter extends CustomPainter {
  _ChargePainter({
    required this.clock,
    required this.loading,
    required this.ink,
  }) : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool loading;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final dur = loading ? 0.7 : 2.0;
    final segW = loading ? 0.45 : 0.30;
    final u = const Cubic(0.5, 0, 0.3, 1).transform(loop(clock.value, dur));
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(r, Paint()..color = _a(ink, 0.12));
    final left = size.width * (-segW + (1 + segW) * u);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, size.width * segW, size.height),
        const Radius.circular(2),
      ),
      Paint()..color = _a(ink, 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _ChargePainter old) =>
      old.loading != loading || old.ink != ink;
}

class _IconRingPainter extends CustomPainter {
  _IconRingPainter({
    required this.clock,
    required this.ok,
    required this.gold,
  }) : super(repaint: clock);
  final ValueListenable<double> clock;
  final bool ok, gold;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Curves.easeOut.transform(loop(clock.value, 1.8));
    final base = ok ? kGreen : gold ? kInkGold : kInk;
    final scale = 0.92 + 0.26 * ring;
    final w = size.width * scale;
    final h = size.height * scale;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: w,
      height: h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(17)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _a(base, (ok ? 0.5 : 0.35) * (1 - ring)),
    );
  }

  @override
  bool shouldRepaint(covariant _IconRingPainter old) =>
      old.ok != ok || old.gold != gold;
}

class _SpinnerSpinPainter extends CustomPainter {
  _SpinnerSpinPainter({required this.clock}) : super(repaint: clock);
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(loop(clock.value, 0.7) * 2 * math.pi);
    canvas.translate(-size.width / 2, -size.height / 2);
    const SpinnerPainter().paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpinnerSpinPainter old) => false;
}

class _BoltPulsePainter extends CustomPainter {
  _BoltPulsePainter({required this.clock}) : super(repaint: clock);
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final z = loop(clock.value, 1.8);
    double zs = 1, zr = 0;
    if (z < 0.08) {
      final k = Curves.easeInOut.transform(z / 0.08);
      zs = 1 + 0.18 * k;
      zr = -6 * k;
    } else if (z < 0.16) {
      final k = Curves.easeInOut.transform((z - 0.08) / 0.08);
      zs = 1.18 - 0.18 * k;
      zr = -6 + 6 * k;
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(zr * math.pi / 180);
    canvas.scale(zs);
    canvas.translate(-size.width / 2, -size.height / 2);
    const BoltPainter(
      kYellow,
      stroke: Color(0xFF7A5410),
      strokeWidth: 0.8,
    ).paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoltPulsePainter old) => false;
}

class _ChevronsPainter extends CustomPainter {
  _ChevronsPainter({
    required this.clock,
    required this.ink,
    required this.loading,
  }) : super(repaint: clock);
  final ValueListenable<double> clock;
  final Color ink;
  final bool loading;

  @override
  void paint(Canvas canvas, Size size) {
    final dur = loading ? 0.45 : 1.2;
    final t = clock.value;
    for (var i = 0; i < 3; i++) {
      final v =
          Curves.easeInOut.transform(pingPong(loop(t, dur, i * 0.15)));
      final dx = -2 + 4 * v - i * 3.0;
      canvas.save();
      canvas.translate(size.width / 2 + dx - 4, size.height / 2 - 7);
      ChevronPainter(_a(ink, 0.25 + 0.75 * v)).paint(canvas, const Size(8, 14));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronsPainter old) =>
      old.ink != ink || old.loading != loading;
}

class _ProgressShimmerPainter extends CustomPainter {
  _ProgressShimmerPainter({required this.clock}) : super(repaint: clock);
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -1 + 2 * loop(clock.value, 1.6);
    final rect = Rect.fromLTWH(size.width * x, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _a(Colors.white, 0),
            _a(Colors.white, 0.45),
            _a(Colors.white, 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressShimmerPainter old) => false;
}

/* ============================== FOOTER ============================== */

class Footer extends StatelessWidget {
  const Footer({super.key, required this.onPrivacy, required this.onTerms});
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    final s = sans(13.5, FontWeight.w400, const Color(0xFF7E8682));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(onTap: onPrivacy, child: Text('Privacy Policy', style: s)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('·', style: s),
        ),
        GestureDetector(onTap: onTerms, child: Text('Terms of Use', style: s)),
      ],
    );
  }
}

/* ============================== PIPES ============================== */

class PipesPainter extends CustomPainter {
  PipesPainter({
    required this.clock,
    required this.sim,
    required this.contentKey,
    required this.rackKey,
    required this.slotKey,
    required this.ctaKey,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  final PipeSim sim;
  final GlobalKey contentKey, rackKey, slotKey, ctaKey;

  Rect? _rect(GlobalKey k, RenderBox root) {
    final b = k.currentContext?.findRenderObject();
    if (b is! RenderBox || !b.hasSize || !b.attached) return null;
    return b.localToGlobal(Offset.zero, ancestor: root) & b.size;
  }

  void _dashed(
    Canvas canvas,
    ui.PathMetric m,
    double dash,
    double gap,
    double offset,
    Paint p,
  ) {
    final period = dash + gap;
    for (var d = (offset % period) - period; d < m.length; d += period) {
      final a = math.max(0.0, d), b = math.min(m.length, d + dash);
      if (b > a) canvas.drawPath(m.extractPath(a, b), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final opacity = Curves.ease.transform(((t - 0.8) / 1.2).clamp(0.0, 1.0));
    if (opacity <= 0) return;
    final root = contentKey.currentContext?.findRenderObject();
    if (root is! RenderBox) return;
    final B = _rect(ctaKey, root),
        R = _rect(rackKey, root),
        S = _rect(slotKey, root);
    if (B == null || R == null || S == null) return;

    final W = size.width, hy = S.center.dy;
    canvas.save();

    for (var si = 0; si < 2; si++) {
      final s = si == 0 ? -1.0 : 1.0;
      double X(double x) => s < 0 ? x : W - x;
      final bx = s < 0 ? B.left + 2 : B.right - 2, by = B.center.dy;
      final mx = X(12), y1 = by - 34, y2 = hy + 50;
      // Gentle sway (smaller = cheaper + smoother on mid devices).
      final sw1 = math.sin(t * 1.1 + (s > 0 ? 1.7 : 0)) * 2.2;
      final sw2 = math.sin(t * 0.9 + (s > 0 ? 0.6 : 2.2)) * 2.2;
      final sag = 8 + math.sin(t * 1.2 + (s > 0 ? 1 : 0)) * 2.0;
      final rx = s < 0 ? R.left - 9 : R.right + 9, hx = X(44);

      final path = Path()
        ..moveTo(bx, by)
        ..cubicTo((bx + mx) / 2, by, mx, by, mx, y1)
        ..cubicTo(
          mx + sw1,
          y1 - (y1 - y2) * 0.33,
          mx + sw2,
          y1 - (y1 - y2) * 0.66,
          mx,
          y2,
        )
        ..cubicTo(mx, hy + 20, X(26), hy, hx, hy)
        ..cubicTo(
          hx + (rx - hx) * 0.35,
          hy + sag,
          hx + (rx - hx) * 0.65,
          hy + sag,
          rx,
          hy,
        );

      Paint st(Color c, double w, {StrokeCap cap = StrokeCap.round}) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round
        ..color = _a(c, opacity);

      canvas.drawPath(path, st(_a(Colors.black, 0.45), 14));
      canvas.drawPath(path, st(const Color(0xFF0F1913), 11));
      canvas.drawPath(path, st(const Color(0xFF1B3226), 8));
      final metric = path.computeMetrics().first;
      _dashed(
        canvas,
        metric,
        3,
        34,
        0,
        st(const Color(0xFF2C4D3A), 11, cap: StrokeCap.butt),
      );
      canvas.drawPath(path, st(const Color(0xFF07100B), 3.8));
      final flowOff = sim.phase * 42;
      _dashed(canvas, metric, 1.5, 12, flowOff, st(_a(kGreen, 0.85), 2));

      final fill = Paint()
        ..color = const Color(0xFF1B3226).withAlpha((255 * opacity).round());
      final edge = st(const Color(0xFF3A6650), 1);
      final collar = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s < 0 ? B.left - 8 : B.right - 1,
          by - 12,
          9,
          24,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(collar, fill);
      canvas.drawRRect(collar, edge);
      final sock = RRect.fromRectAndRadius(
        Rect.fromLTWH(s < 0 ? R.left - 9 : R.right, hy - 10, 9, 20),
        const Radius.circular(3),
      );
      canvas.drawRRect(sock, fill);
      canvas.drawRRect(sock, edge);
      final f = sim.flash[si];
      final led = Offset(s < 0 ? R.left - 4.5 : R.right + 4.5, hy);
      canvas.drawCircle(
        led,
        2.2 + f * 1.8,
        Paint()..color = _a(kGreen, (0.45 + f * 0.55) * opacity),
      );

      final L = metric.length;
      for (final q in sim.parts[si]) {
        final u = (sim.phase * q.k + q.off) % 1.0;
        final pos = metric.getTangentForOffset(u * L)?.position;
        if (pos == null) continue;
        final op = (math.min(1.0, math.min(u / 0.05, (1 - u) / 0.06)) * opacity)
            .clamp(0.0, 1.0);
        if (!q.data) {
          canvas.drawCircle(
            pos,
            3.4,
            Paint()..color = _a(const Color(0xFFA6F2BC), op),
          );
        } else {
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          final box = RRect.fromRectAndRadius(
            const Rect.fromLTWH(-5, -4, 10, 8),
            const Radius.circular(2),
          );
          canvas.drawRRect(box, Paint()..color = _a(kYellow, op));
          final lock = Path()
            ..moveTo(-2, -1)
            ..lineTo(-2, -2.2)
            ..arcToPoint(
              const Offset(2, -2.2),
              radius: const Radius.circular(2),
              clockwise: true,
            )
            ..lineTo(2, -1)
            ..addRect(const Rect.fromLTWH(-2.6, -1, 5.2, 3.6));
          canvas.drawPath(
            lock,
            st(_a(const Color(0xFF4A3508), op), 1, cap: StrokeCap.butt),
          );
          canvas.restore();
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PipesPainter old) => true;
}

/* ============================== SMALL PAINTERS ============================== */

class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter(this.color, this.radius, this.width);
  final Color color;
  final double radius, width;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius),
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      for (double d = 0; d < m.length; d += 7.5) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4.5, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter o) => o.color != color;
}

class BoltPainter extends CustomPainter {
  const BoltPainter(
    this.fill, {
    this.stroke,
    this.strokeWidth = 1,
  });
  final Color fill;
  final Color? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
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
    canvas.drawPath(p, Paint()..color = fill);
    if (stroke != null) {
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..color = stroke!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoltPainter o) => o.fill != fill;
}

class CheckPainter extends CustomPainter {
  const CheckPainter(this.color, this.width, {this.inset = 0});
  final Color color;
  final double width, inset;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide - inset * 2;
    if (s <= 0) return;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    final k = s / 24;
    canvas.scale(k);
    canvas.drawPath(
      Path()
        ..moveTo(5, 12.5)
        ..lineTo(9.5, 17)
        ..lineTo(19, 7.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CheckPainter o) => o.color != color;
}

class ChevronPainter extends CustomPainter {
  const ChevronPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 10, size.height / 16);
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
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant ChevronPainter o) => o.color != color;
}

class FanPainter extends CustomPainter {
  const FanPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(const Offset(12, 12), 9, p);
    canvas.drawCircle(const Offset(12, 12), 2.2, p);
    canvas.drawLine(const Offset(12, 9.8), const Offset(12, 3.2), p);
    canvas.drawLine(const Offset(10.1, 13.1), const Offset(4.4, 16.4), p);
    canvas.drawLine(const Offset(13.9, 13.1), const Offset(19.6, 16.4), p);
  }

  @override
  bool shouldRepaint(covariant FanPainter o) => o.color != color;
}

class ServerIconPainter extends CustomPainter {
  const ServerIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = color;
    canvas.drawRRect(
      RRect.fromLTRBR(3, 4, 21, 11, const Radius.circular(2)),
      p,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(3, 13, 21, 20, const Radius.circular(2)),
      p,
    );
    final d = Paint()..color = color;
    canvas.drawCircle(const Offset(7, 7.5), 1.3, d);
    canvas.drawCircle(const Offset(7, 16.5), 1.3, d);
  }

  @override
  bool shouldRepaint(covariant ServerIconPainter o) => o.color != color;
}

class SpinnerPainter extends CustomPainter {
  const SpinnerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(1.25);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(r, p..color = _a(kGreen, 0.25));
    canvas.drawArc(
      r,
      -math.pi / 2 - math.pi / 4,
      math.pi / 2,
      false,
      p
        ..color = kGreen
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class CtaTexturePainter extends CustomPainter {
  const CtaTexturePainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: [_a(ink, 0), _a(ink, 0.13)],
        stops: const [0.3, 0.8],
      ).createShader(Offset.zero & size);
    for (double x = 0.5; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0.5; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.5),
      Paint()..color = _a(Colors.white, 0.55),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 2, size.width, 2),
      Paint()..color = _a(Colors.black, 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CtaTexturePainter o) => o.ink != ink;
}
