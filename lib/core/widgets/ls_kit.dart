import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/widgets/lifeseen_logo.dart';

// ---------------------------------------------------------------------------
// Scaffold, wordmark, pills, cards, CTA
// ---------------------------------------------------------------------------

class LsScaffold extends StatelessWidget {
  const LsScaffold({
    super.key,
    required this.child,
    this.glowColor = AppColors.neon,
    this.glowOpacity = .28,
    this.safeBottom = true,
    this.safeTop = true,
  });

  final Widget child;
  final Color glowColor;
  final double glowOpacity;
  final bool safeBottom;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            Positioned(
              left: -w * .2,
              right: -w * .2,
              top: -170,
              height: 420,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: .75,
                      colors: [
                        glowColor.withValues(alpha: glowOpacity),
                        glowColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(top: safeTop, bottom: safeBottom, child: child),
          ],
        ),
      ),
    );
  }
}

class LsWordmark extends StatelessWidget {
  const LsWordmark({super.key, this.fontSize = 13, this.dotSize = 8});

  final double fontSize;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    // LifeSeen logo mark (replaces old green-dot + LIFESEEN text).
    final height = (fontSize * 2.7).clamp(28.0, 48.0);
    return LifeSeenLogo(height: height);
  }
}

enum LsPillVariant { green, fill, amber, off }

class LsPill extends StatelessWidget {
  const LsPill(this.text, {super.key, this.variant = LsPillVariant.green, this.dot = false, this.fontSize = 10.5});

  final String text;
  final LsPillVariant variant;
  final bool dot;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    late Color bg, border, fg;
    switch (variant) {
      case LsPillVariant.green:
        bg = AppColors.neon.withValues(alpha: .12);
        border = AppColors.neon.withValues(alpha: .45);
        fg = AppColors.green;
      case LsPillVariant.fill:
        bg = AppColors.neon;
        border = AppColors.neon;
        fg = AppColors.ink;
      case LsPillVariant.amber:
        bg = AppColors.amberFill.withValues(alpha: .12);
        border = AppColors.amberFill.withValues(alpha: .5);
        fg = AppColors.amber;
      case LsPillVariant.off:
        bg = AppColors.muted.withValues(alpha: .12);
        border = AppColors.dash;
        fg = AppColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
            const SizedBox(width: 6),
          ],
          Text(text.toUpperCase(), style: AppText.mono(fontSize, FontWeight.w700, color: fg, spacing: fontSize * .08)),
        ],
      ),
    );
  }
}

class LsIconChip extends StatelessWidget {
  const LsIconChip(
    this.icon, {
    super.key,
    this.color = AppColors.green,
    this.size = 36,
    this.radius = 11,
    this.iconSize,
    this.spin = false,
  });

  final LsIconType icon;
  final Color color;
  final double size;
  final double radius;
  final double? iconSize;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    Widget i = LsIcon(icon, size: iconSize ?? size * .5, color: color, stroke: 1.9);
    if (spin) i = LsSpin(child: i);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: i,
    );
  }
}

enum LsAppKind { instagram, whatsapp, youtube, telegram, other }

LsAppKind lsAppKind(String name, String packageName) {
  final blob = '${name.toLowerCase()} ${packageName.toLowerCase()}';
  if (blob.contains('instagram')) return LsAppKind.instagram;
  if (blob.contains('whatsapp')) return LsAppKind.whatsapp;
  if (blob.contains('youtube')) return LsAppKind.youtube;
  if (blob.contains('telegram')) return LsAppKind.telegram;
  return LsAppKind.other;
}

class LsAppChip extends StatelessWidget {
  const LsAppChip(this.kind, {super.key, this.size = 44, this.bytes});

  final LsAppKind kind;
  final double size;
  final Uint8List? bytes;

  static const _data = {
    LsAppKind.instagram: (AppColors.instagram, LsIconType.insta),
    LsAppKind.whatsapp: (AppColors.whatsAppGreen, LsIconType.msg),
    LsAppKind.youtube: (AppColors.youtube, LsIconType.play),
    LsAppKind.telegram: (AppColors.telegram, LsIconType.send),
  };

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * .3),
        child: Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }
    final known = _data[kind];
    final color = known?.$1 ?? AppColors.green;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(size * .3),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: known == null
          ? Icon(Icons.apps_rounded, color: color, size: size * .5)
          : LsIcon(known.$2, size: size * .5, color: color, stroke: 2),
    );
  }
}

class LsDots extends StatelessWidget {
  const LsDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 26 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? AppColors.neon : AppColors.stroke2,
              borderRadius: BorderRadius.circular(4),
              boxShadow: i == index ? [BoxShadow(color: AppColors.neon.withValues(alpha: .7), blurRadius: 10)] : const [],
            ),
          ),
      ],
    );
  }
}

class LsCta extends StatefulWidget {
  const LsCta({
    super.key,
    required this.label,
    this.icon = LsIconType.bolt,
    this.onPressed,
    this.gold = false,
    this.centerLabel = false,
  });

  final String label;
  final LsIconType icon;
  final VoidCallback? onPressed;
  final bool gold;
  final bool centerLabel;

  @override
  State<LsCta> createState() => _LsCtaState();
}

class _LsCtaState extends State<LsCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final ink = widget.gold ? AppColors.boostInkGold : AppColors.ink;
    final label = Text(
      widget.label.toUpperCase(),
      textAlign: widget.centerLabel ? TextAlign.center : TextAlign.start,
      style: AppText.jakarta(
        15.5,
        FontWeight.w800,
        color: ink,
        spacing: .5,
      ),
    );
    final leading = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.gold ? AppColors.chipAmberBg : AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LsIcon(
        widget.icon,
        size: 22,
        color: widget.gold ? AppColors.goldEdge : AppColors.ink,
        stroke: 2.2,
      ),
    );
    final trailing = LsIcon(LsIconType.chevron, size: 18, color: ink, stroke: 2.2);

    return Opacity(
      opacity: enabled ? 1 : .55,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 64,
          transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
          decoration: BoxDecoration(
            gradient: widget.gold ? AppColors.goldGradient : AppColors.btnGradient,
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: widget.gold ? AppColors.goldEdge : AppColors.edge,
                offset: Offset(0, _down ? 0 : 4),
              ),
              BoxShadow(
                color: (widget.gold ? AppColors.amberFill : AppColors.neon).withValues(alpha: _down ? .3 : .55),
                offset: const Offset(0, 14),
                blurRadius: 30,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: widget.centerLabel
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 56),
                        child: label,
                      ),
                      Row(
                        children: [
                          leading,
                          const Spacer(),
                          trailing,
                          const SizedBox(width: 6),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(child: label),
                      trailing,
                      const SizedBox(width: 6),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class LsCard extends StatelessWidget {
  const LsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.radius = 19,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: .12),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: -12,
          ),
        ],
      ),
      child: child,
    );
  }
}

class LsFeatureRow extends StatelessWidget {
  const LsFeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppColors.green,
  });

  final LsIconType icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          LsIconChip(icon, color: color, size: 36, iconSize: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.jakarta(14, FontWeight.w700)),
                Text(subtitle, style: AppText.small),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.neon.withValues(alpha: .15)),
            child: const LsIcon(LsIconType.check, size: 14, color: AppColors.green, stroke: 2.6),
          ),
        ],
      ),
    );
  }
}

class LsHeroTile extends StatelessWidget {
  const LsHeroTile({super.key, required this.icon, this.size = 118, this.iconSize = 56});

  final LsIconType icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.btnGradient,
        borderRadius: BorderRadius.circular(size * .305),
        boxShadow: [
          const BoxShadow(color: AppColors.edge, offset: Offset(0, 5)),
          BoxShadow(
            color: AppColors.neon.withValues(alpha: .6),
            offset: const Offset(0, 18),
            blurRadius: 30,
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .305),
        child: SizedBox.expand(
          child: Stack(
            children: [
              const Positioned(left: 0, right: 0, top: 0, height: 2, child: ColoredBox(color: Color(0x80FFFFFF))),
              Center(child: LsIcon(icon, size: iconSize, color: AppColors.ink, stroke: 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class LsPulse extends StatefulWidget {
  const LsPulse({super.key, required this.child, required this.borderRadius});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<LsPulse> createState() => _LsPulseState();
}

class _LsPulseState extends State<LsPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!lsReduceMotion(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(color: AppColors.neon.withValues(alpha: .55 * (1 - t)), spreadRadius: 22 * t),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class LsReveal extends StatelessWidget {
  const LsReveal({super.key, required this.child, this.delay = 0, this.dy = 14});

  final Widget child;
  final int delay;
  final double dy;

  @override
  Widget build(BuildContext context) {
    if (lsReduceMotion(context)) return child;
    final total = 500 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (_, v, c) {
        final t = Curves.easeOutCubic.transform(((v * total - delay) / 500).clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: c),
        );
      },
      child: child,
    );
  }
}

class LsHeaderButton extends StatelessWidget {
  const LsHeaderButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color = AppColors.text,
    this.semanticLabel,
  });

  final LsIconType icon;
  final VoidCallback? onTap;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.stroke),
            boxShadow: [
              BoxShadow(
                color: AppColors.text.withValues(alpha: .12),
                offset: const Offset(0, 4),
                blurRadius: 10,
                spreadRadius: -6,
              ),
            ],
          ),
          child: LsIcon(icon, size: 20, color: color, stroke: 1.9),
        ),
      ),
    );
  }
}

class LsTopBar extends StatelessWidget {
  const LsTopBar({super.key, this.onBack, this.right});

  final VoidCallback? onBack;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: onBack == null
                  ? null
                  : LsHeaderButton(icon: LsIconType.back, onTap: onBack, semanticLabel: 'Back'),
            ),
            const Expanded(child: Center(child: LsWordmark())),
            SizedBox(width: 40, child: right),
          ],
        ),
      ),
    );
  }
}

class LsCaption extends StatelessWidget {
  const LsCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppText.mono(11, FontWeight.w500, spacing: .9));
  }
}

class LsRichCaption extends StatelessWidget {
  const LsRichCaption(this.parts, {super.key});

  final List<(String, bool)> parts;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final p in parts)
            TextSpan(
              text: p.$1.toUpperCase(),
              style: AppText.mono(
                11,
                p.$2 ? FontWeight.w700 : FontWeight.w500,
                color: p.$2 ? AppColors.green : AppColors.muted,
                spacing: .9,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
