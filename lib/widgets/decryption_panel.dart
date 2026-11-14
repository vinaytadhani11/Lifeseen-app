import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_screen_time_screen.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/boost_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/decryption_timer_service.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:tableflow_plus/widgets/machine_pro.dart';

/// Bottom panel after a local premium buy. Duration hours come from
/// Remote Config (`start_time`, `normal_boost`, `super_boost`, `extended_time`).
class DecryptionPanel extends StatelessWidget {
  const DecryptionPanel({super.key});

  static const _extraText =
      'Encryption is in progress, but we need additional time.';

  void _openTracker(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const FriendsScreenTimeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AppBootstrap.decryption;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final view = _PanelView.of(service);
          return SheetPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const MachineHero(),
                const SizedBox(height: 8),
                Text(
                  view.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.decryptionNeon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  view.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: AppColors.decryptionSubtitle,
                  ),
                ),
                const SizedBox(height: 16),
                _CountdownCard(
                  remainingSeconds: service.remainingSeconds,
                  progress: service.progress,
                  running: service.isCounting,
                ),
                if (view.speedUp) ...[
                  const SizedBox(height: 14),
                  AppCtaButton(
                    label: 'Speed Up',
                    onTap: () => BoostScreen.open(context),
                  ),
                ],
                if (view.buttonLabel != null) ...[
                  const SizedBox(height: 14),
                  AppCtaButton(
                    label: view.buttonLabel!,
                    onTap: () => _onButton(context, service),
                  ),
                ],
                if (view.showFollowMode) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _openTracker(context),
                    child: Text(
                      'GO TO FOLLOW MODE',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.logoWhiteText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _onButton(BuildContext context, DecryptionTimerService service) {
    if (service.isPaused) {
      service.resume();
      return;
    }
    switch (service.stage) {
      case DecryptionStage.awaitingExtra:
        service.startExtra(AppBootstrap.remoteConfig.settings.extendedTime);
      case DecryptionStage.completed:
        _openTracker(context);
      case DecryptionStage.initial:
      case DecryptionStage.none:
      case DecryptionStage.boost:
      case DecryptionStage.extra:
        break;
    }
  }

  /// `119 Hours 59 Minutes 58 Seconds`, or `0 Seconds` when finished.
  static String formatCountdown(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final parts = <String>[];
    if (h > 0) parts.add('$h ${h == 1 ? 'Hour' : 'Hours'}');
    if (m > 0) parts.add('$m ${m == 1 ? 'Minute' : 'Minutes'}');
    if (s > 0 || parts.isEmpty) {
      parts.add('$s ${s == 1 ? 'Second' : 'Seconds'}');
    }
    return parts.join(' ');
  }
}

/// Shared bottom-sheet chrome: rounded top + drag handle.
class SheetPanel extends StatelessWidget {
  const SheetPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.sheetHandle,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Machine illustration — full bleed to sheet edges, cropped (no empty sky).
class MachineHero extends StatelessWidget {
  const MachineHero({super.key});

  static const double _sheetPad = 18;
  static const double _aspect = 1200 / 390;

  @override
  Widget build(BuildContext context) {
    // Cancel SheetPanel horizontal padding without negative EdgeInsets.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth + _sheetPad * 2;
        final h = w / _aspect;
        return SizedBox(
          height: h,
          width: constraints.maxWidth,
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: w,
            maxWidth: w,
            minHeight: h,
            maxHeight: h,
            child: SizedBox(
              width: w,
              height: h,
              child: const MachinePro(),
            ),
          ),
        );
      },
    );
  }
}

class _PanelView {
  const _PanelView({
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.speedUp = false,
    this.showFollowMode = true,
  });

  final String title;
  final String subtitle;
  final String? buttonLabel;
  final bool speedUp;
  final bool showFollowMode;

  static const _continueTitle = 'Continue Where You Left Off';

  static _PanelView of(DecryptionTimerService service) {
    if (service.isPaused) {
      return const _PanelView(
        title: _continueTitle,
        subtitle: DecryptionPanel._extraText,
        buttonLabel: 'Continue',
      );
    }
    switch (service.stage) {
      case DecryptionStage.initial:
        return const _PanelView(
          title: _continueTitle,
          subtitle: DecryptionPanel._extraText,
          speedUp: true,
        );
      case DecryptionStage.boost:
      case DecryptionStage.extra:
      case DecryptionStage.none:
        return const _PanelView(
          title: _continueTitle,
          subtitle: DecryptionPanel._extraText,
        );
      case DecryptionStage.awaitingExtra:
        return const _PanelView(
          title: _continueTitle,
          subtitle: DecryptionPanel._extraText,
          buttonLabel: 'Start Additional Time',
          showFollowMode: false,
        );
      case DecryptionStage.completed:
        return const _PanelView(
          title: 'Decryption Completed',
          subtitle: 'Continue applying',
          buttonLabel: 'SHOW QR',
        );
    }
  }
}

/// Reference countdown block: label → timer → seek bar → terminal.
class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.remainingSeconds,
    required this.progress,
    required this.running,
  });

  final int remainingSeconds;
  final double progress;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.countdownCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.countdownCardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 16,
                color: AppColors.logoWhiteText,
              ),
              const SizedBox(width: 8),
              Text(
                'UNTIL YOUR MESSAGES IS',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                  color: AppColors.countdownLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            DecryptionPanel.formatCountdown(remainingSeconds),
            textAlign: TextAlign.left,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: AppColors.countdownValue,
            ),
          ),
          const SizedBox(height: 12),
          _SeekBar(progress: progress, animate: running),
          const SizedBox(height: 12),
          _TypingTerminal(running: running),
        ],
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.progress, this.animate = true});

  final double progress;
  final bool animate;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.animate) _shimmer.repeat();
  }

  @override
  void didUpdateWidget(covariant _SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_shimmer.isAnimating) {
      _shimmer.repeat();
    } else if (!widget.animate && _shimmer.isAnimating) {
      _shimmer.stop();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.progress.clamp(0.0, 1.0);
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillW = constraints.maxWidth * value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.countdownBarTrack,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                width: fillW,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.analyzedGreenDeep,
                      AppColors.countdownBarFill,
                      AppColors.analyzedGreenLight,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.countdownBarFill.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: widget.animate && value > 0
                    ? AnimatedBuilder(
                        animation: _shimmer,
                        builder: (context, _) {
                          return ShaderMask(
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (rect) {
                              final t = _shimmer.value;
                              return LinearGradient(
                                begin: Alignment(-1.5 + 3 * t, 0),
                                end: Alignment(-0.5 + 3 * t, 0),
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.35),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ).createShader(rect);
                            },
                            child: const ColoredBox(color: Colors.white),
                          );
                        },
                      )
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Types one fake terminal line at a time, like the reference panel.
class _TypingTerminal extends StatefulWidget {
  const _TypingTerminal({required this.running});

  final bool running;

  @override
  State<_TypingTerminal> createState() => _TypingTerminalState();
}

class _TypingTerminalState extends State<_TypingTerminal> {
  static const _lines = [
    "os.system('echo Starting background scan...')",
    "exec(\"import subprocess\\nsubprocess.Popen(['echo', 'Reading keys'])\")",
    "exec(\"import subprocess\\nsubprocess.Popen(['echo', 'Performing network analysis...'])\")",
    "os.system('echo Decrypting message blocks...')",
    "exec(\"import hashlib\\nhashlib.sha256(b'session').hexdigest()\")",
  ];

  Timer? _timer;
  int _line = 0;
  int _chars = 0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _TypingTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!widget.running) return;
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!mounted) return;
      final line = _lines[_line % _lines.length];
      if (_chars < line.length) {
        setState(() => _chars++);
      } else {
        setState(() {
          _line++;
          _chars = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = _lines[_line % _lines.length];
    final shown = widget.running
        ? line.substring(0, _chars.clamp(0, line.length))
        : line;
    final style = GoogleFonts.robotoMono(
      fontSize: 11,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: AppColors.countdownTerminal,
    );
    return SizedBox(
      width: double.infinity,
      height: 11 * 1.35 * 2,
      child: Text(
        shown,
        textAlign: TextAlign.left,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
