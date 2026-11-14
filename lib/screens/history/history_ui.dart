// LifeSeen – Notification History parts (Light Green theme):
// switch, real app icon (with fallback), letter avatar, notification card,
// filter chips, 7-day mini bars, small formatters.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/services/notification_history.dart';


// ============================================================================
// Formatters
// ============================================================================
String nhTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Today · Yesterday · Mon, 3 Nov
String nhDayLabel(DateTime t) {
  final n = DateTime.now();
  final d = DateTime(t.year, t.month, t.day);
  final today = DateTime(n.year, n.month, n.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_wd[t.weekday - 1]}, ${t.day} ${_mo[t.month - 1]}';
}

/// "16:32" today, "YDAY" yesterday, "3 Nov" older
String nhShortWhen(DateTime t) {
  final l = nhDayLabel(t);
  if (l == 'Today') return nhTime(t);
  if (l == 'Yesterday') return 'YDAY';
  return '${t.day} ${_mo[t.month - 1]}';
}

String nhDate(DateTime t) => '${t.day.toString().padLeft(2, '0')} ${_mo[t.month - 1]} ${t.year}';

/// 1284 → 1,284
String nhNumber(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 4404019 → 4.2 MB
String nhBytes(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
}

// ============================================================================
// Switch (46 x 28, green gradient + glow when on)
// ============================================================================
class LsSwitch extends StatelessWidget {
  const LsSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onChanged!(!value);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 28,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? null : AppColors.stroke2,
              gradient: value
                  ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.btnTop, AppColors.btnBottom])
                  : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: value ? [BoxShadow(color: AppColors.neon.withValues(alpha: .8), blurRadius: 12, spreadRadius: -2)] : const [],
            ),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: [BoxShadow(color: AppColors.text.withValues(alpha: .25), offset: const Offset(0, 2), blurRadius: 5)],
              ),
            ),
          ),
        ),
      );
}

// ============================================================================
// App icon: real launcher icon from Android, else a tinted chip
// ============================================================================
const _known = <String, (Color, LsIconType)>{
  'com.whatsapp': (Color(0xFF25D366), LsIconType.msg),
  'com.whatsapp.w4b': (Color(0xFF25D366), LsIconType.msg),
  'com.instagram.android': (Color(0xFFE1306C), LsIconType.insta),
  'org.telegram.messenger': (Color(0xFF44A8F0), LsIconType.send),
  'com.snapchat.android': (Color(0xFFD4B800), LsIconType.spark),
  'com.facebook.katana': (Color(0xFF1877F2), LsIconType.users),
  'com.facebook.orca': (Color(0xFF1877F2), LsIconType.msg),
  'com.google.android.apps.messaging': (Color(0xFF3B6FE0), LsIconType.msg),
  'com.google.android.gm': (Color(0xFFEA4335), LsIconType.doc),
  'com.google.android.youtube': (Color(0xFFFF3B30), LsIconType.play),
};

class NhAppIcon extends StatelessWidget {
  const NhAppIcon({super.key, required this.package, required this.name, this.size = 40, this.icon, this.service});
  final String package, name;
  final double size;
  final Uint8List? icon;
  final NotificationHistory? service;

  @override
  Widget build(BuildContext context) {
    if (icon != null) return _image(icon!);
    return FutureBuilder<Uint8List?>(
      future: (service ?? NotificationHistory.instance).appIcon(package),
      builder: (_, snap) => snap.data != null ? _image(snap.data!) : _fallback(),
    );
  }

  Widget _image(Uint8List bytes) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .08),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(size * .3),
          border: Border.all(color: AppColors.stroke),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * .22),
          child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      );

  Widget _fallback() {
    final k = _known[package];
    final color = k?.$1 ?? AppColors.green;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(size * .3),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: k != null
          ? LsIcon(k.$2, size: size * .5, color: color, stroke: 2)
          : Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: AppText.jakarta(size * .42, FontWeight.w800, color: color, height: 1)),
    );
  }
}

/// Round initials avatar for chat / sender names.
class NhLetterAvatar extends StatelessWidget {
  const NhLetterAvatar({super.key, required this.name, this.size = 46});
  final String name;
  final double size;

  static const _tints = [Color(0xFFDDF5E4), Color(0xFFE6E3FA), Color(0xFFD6F1EC), Color(0xFFFBEBCF), Color(0xFFDCE7FF), Color(0xFFFBDDE8)];
  static const _inks = [Color(0xFF1E7A43), Color(0xFF5B6CE0), Color(0xFF0F9C8B), Color(0xFFC97A0A), Color(0xFF3B6FE0), Color(0xFFC2306A)];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1 ? parts.first.characters.take(2).toString() : '${parts[0].characters.first}${parts[1].characters.first}')
            .toUpperCase();
    final i = name.codeUnits.fold<int>(0, (a, b) => a + b) % _tints.length;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _tints[i],
        boxShadow: const [BoxShadow(color: AppColors.stroke2, spreadRadius: 1.5)],
      ),
      child: Text(initials, style: AppText.jakarta(size * .36, FontWeight.w800, color: _inks[i], height: 1)),
    );
  }
}

class NhImage extends StatelessWidget {
  const NhImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.decodeWidth,
    this.radius = 0,
  });

  final String? path;
  final BoxFit fit;
  final double? decodeWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = path;
    final cw = decodeWidth == null ? null : (decodeWidth! * MediaQuery.devicePixelRatioOf(context)).round();
    final Widget img;
    if (p == null) {
      img = const NhImageMissing();
    } else if (p.startsWith('asset:')) {
      img = Image.asset(
        p.substring(6),
        fit: fit,
        cacheWidth: cw,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const NhImageMissing(),
      );
    } else {
      img = Image.file(
        File(p),
        fit: fit,
        cacheWidth: cw,
        gaplessPlayback: true,
        frameBuilder: (_, child, frame, sync) => sync || frame != null
            ? child
            : const ColoredBox(color: Color(0xFFE9F2EC)),
        errorBuilder: (_, __, ___) => const NhImageMissing(),
      );
    }
    return radius == 0 ? img : ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }
}

class NhImageMissing extends StatelessWidget {
  const NhImageMissing({super.key, this.label = 'Image not available'});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFEFF5F1),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LsIcon(LsIconType.image, size: 26, color: AppColors.muted),
            const SizedBox(height: 6),
            Text(label, style: AppText.mono(10.5, FontWeight.w500)),
          ],
        ),
      );
}

/// Amber "REMOVED" tag.
class NhRemovedTag extends StatelessWidget {
  const NhRemovedTag({super.key, this.text = 'removed'});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.amberFill.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.amberFill.withValues(alpha: .5)),
        ),
        child: Text(text.toUpperCase(), style: AppText.mono(8.5, FontWeight.w700, color: AppColors.amber, spacing: .6, height: 1.2)),
      );
}

// ============================================================================
// Notification card (app icon • APP NAME • time • dot / title / 2 lines)
// ============================================================================
class NhNotificationCard extends StatelessWidget {
  const NhNotificationCard({super.key, required this.item, this.unread = false, this.onTap, this.service});
  final NhItem item;
  final bool unread;
  final VoidCallback? onTap;
  final NotificationHistory? service;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: unread ? AppColors.neon.withValues(alpha: .45) : AppColors.stroke),
            boxShadow: [BoxShadow(color: AppColors.text.withValues(alpha: .22), offset: const Offset(0, 6), blurRadius: 16, spreadRadius: -12)],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            NhAppIcon(package: item.package, name: item.appName, size: 40, service: service),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(item.appName.toUpperCase(),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.mono(10, FontWeight.w500, spacing: 1)),
                  ),
                  if (item.removed) ...[const SizedBox(width: 6), const NhRemovedTag()],
                  const Spacer(),
                  Text(nhTime(item.time), style: AppText.mono(11, FontWeight.w500, color: unread ? AppColors.green : AppColors.muted)),
                  if (unread) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neon,
                        boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: .8), blurRadius: 6)],
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(14.5, FontWeight.w700)),
                Text(
                  item.hasImage
                      ? (item.caption.isEmpty ? '📷 Photo' : '📷 ${item.caption}')
                      : item.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.jakarta(13.5, FontWeight.w400, color: AppColors.grey, height: 1.4),
                ),
              ]),
            ),
            if (item.hasImage) ...[
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.stroke),
                ),
                clipBehavior: Clip.antiAlias,
                child: NhImage(path: item.thumbPath ?? item.mediaPath, decodeWidth: 44, radius: 10),
              ),
            ],
          ]),
        ),
      );
}

// ============================================================================
// Filter chips (All 211 · WhatsApp 128 · …)
// ============================================================================
class NhChip {
  const NhChip(this.id, this.label, this.count);
  final String? id; // null = All
  final String label;
  final int count;
}

class NhChips extends StatelessWidget {
  const NhChips({super.key, required this.chips, required this.selected, required this.onSelect});
  final List<NhChip> chips;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = chips[i];
            final on = c.id == selected;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(c.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppColors.neon : AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: on ? Colors.transparent : AppColors.stroke),
                  boxShadow: on ? [BoxShadow(color: AppColors.neon.withValues(alpha: .8), blurRadius: 14, spreadRadius: -4)] : const [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(c.label, style: AppText.jakarta(12.5, FontWeight.w600, color: on ? AppColors.ink : AppColors.text)),
                  const SizedBox(width: 6),
                  Text(nhNumber(c.count), style: AppText.mono(11, FontWeight.w500, color: on ? AppColors.ink.withValues(alpha: .75) : AppColors.muted)),
                ]),
              ),
            );
          },
        ),
      );
}

// ============================================================================
// Vertical mini bars (7 days on the stats card / 24 hours on app history)
// ============================================================================
class NhBars extends StatelessWidget {
  const NhBars({super.key, required this.values, required this.highlight, this.height = 38, this.barWidth = 7, this.gap = 3});
  final List<int> values;
  final int highlight; // index drawn in solid green
  final double height, barWidth, gap;

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final reduce = lsReduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        height: height,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Container(
              width: barWidth,
              height: (height * (values[i] / maxV) * t).clamp(3.0, height),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(barWidth / 2),
                gradient: i == highlight
                    ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.btnTop, AppColors.btnBottom])
                    : null,
                color: i == highlight ? null : AppColors.neon.withValues(alpha: .32),
                boxShadow: i == highlight ? [BoxShadow(color: AppColors.neon.withValues(alpha: .7), blurRadius: 10)] : const [],
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
