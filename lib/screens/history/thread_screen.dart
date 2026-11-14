// LifeSeen – S36 Saved Thread (one sender / chat in one app) · Light Green theme

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/screens/history/history_ui.dart';
import 'package:tableflow_plus/screens/history/media_viewer_screen.dart';
import 'package:tableflow_plus/services/notification_history.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.package,
    required this.appName,
    required this.title,
    this.service,
  });
  final String package, appName, title;
  final NotificationHistory? service;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;
  List<NhItem>? _items; // newest first
  bool _searching = false;
  String _q = '';
  final _search = TextEditingController();
  StreamSubscription<NhItem?>? _sub;
  int _imageCount = 0;

  @override
  void initState() {
    super.initState();
    _sub = _svc.onChange.listen((i) {
      if (i == null || (i.package == widget.package && i.title == widget.title)) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _svc.items(package: widget.package, title: widget.title, limit: 1000);
    if (!mounted) return;
    setState(() {
      _items = items;
      _imageCount = items.where((i) => i.hasImage).length;
    });
    var n = 0;
    for (final i in items) {
      if (!i.hasImage || i.thumbPath == null) continue;
      final p = i.thumbPath!;
      if (p.startsWith('asset:')) {
        unawaited(precacheImage(AssetImage(p.substring(6)), context));
      } else {
        unawaited(precacheImage(FileImage(File(p)), context));
      }
      if (++n >= 6) break;
    }
  }

  String _lineText(NhItem i) {
    if (i.hasImage) {
      final cap = i.caption;
      return cap.isEmpty ? '[Photo]' : '[Photo] $cap';
    }
    return i.text;
  }

  String _asText(List<NhItem> list) => [
        '${widget.title} · ${widget.appName}',
        for (final i in list.reversed)
          '[${nhDate(i.time)} ${nhTime(i.time)}] ${_lineText(i)}${i.removed ? '  (removed by sender)' : ''}',
      ].join('\n');

  Future<void> _copyAll() async {
    final list = _items ?? const [];
    await Clipboard.setData(ClipboardData(text: _asText(list)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text('Copied ${list.length} messages')),
    );
  }

  Future<void> _delete() async {
    final ok = await showLsConfirm(
      context,
      title: 'Delete this chat?',
      message:
          'All ${_items?.length ?? 0} saved notifications from ${widget.title} will be removed from LifeSeen.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await _svc.deleteThread(widget.package, widget.title);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openImage(NhItem tapped) async {
    final images = await _svc.media(widget.package, widget.title);
    if (!mounted || images.isEmpty) return;
    final start = images.indexWhere((i) => i.id == tapped.id).clamp(0, images.length - 1);
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => NhMediaViewer(
          items: images,
          initialIndex: start,
          service: widget.service,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _openMediaGrid() async {
    final images = await _svc.media(widget.package, widget.title);
    if (!mounted || images.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MediaGridSheet(
        title: widget.title,
        images: images,
        onTap: (item) async {
          Navigator.of(ctx).pop();
          await _openImage(item);
        },
      ),
    );
  }

  Future<void> _imageMenu(NhItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LsSheet(
        children: [
          Text('Photo', style: AppText.jakarta(20, FontWeight.w800)),
          const SizedBox(height: 12),
          LsSmallCta(
            label: 'Share image',
            icon: LsIconType.share,
            variant: LsSmallCtaVariant.ghost,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _svc.shareImage(item.mediaPath!, text: item.caption.isEmpty ? null : item.caption);
            },
          ),
          const SizedBox(height: 8),
          LsSmallCta(
            label: 'Save to gallery',
            icon: LsIconType.image,
            variant: LsSmallCtaVariant.ghost,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await _svc.saveImageToGallery(item.mediaPath!);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(ok ? 'Saved to Pictures/LifeSeen' : "Couldn't save"),
                ),
              );
            },
          ),
          if (item.caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            LsSmallCta(
              label: 'Copy caption',
              icon: LsIconType.copy,
              variant: LsSmallCtaVariant.ghost,
              onPressed: () async {
                Navigator.of(ctx).pop();
                await Clipboard.setData(ClipboardData(text: item.caption));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Caption copied')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _items;
    final list = all == null
        ? const <NhItem>[]
        : (_q.isEmpty
            ? all
            : all.where((i) {
                if (i.hasImage) {
                  final c = i.caption.toLowerCase();
                  return c.isNotEmpty && c.contains(_q);
                }
                return i.text.toLowerCase().contains(_q);
              }).toList());
    final inset = MediaQuery.paddingOf(context).bottom;

    return LsScaffold(
      safeBottom: false,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.stroke)),
          ),
          child: Column(children: [
            Row(children: [
              LsHeaderButton(icon: LsIconType.back, onTap: () => Navigator.of(context).maybePop(), semanticLabel: 'Back'),
              const SizedBox(width: 12),
              NhLetterAvatar(name: widget.title, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(15.5, FontWeight.w700)),
                  Row(children: [
                    NhAppIcon(package: widget.package, name: widget.appName, size: 16, service: widget.service),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${widget.appName} · ${all?.length ?? 0} saved'.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(10.5, FontWeight.w500, color: AppColors.green, spacing: 1),
                      ),
                    ),
                  ]),
                ]),
              ),
              if (_imageCount > 0)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    LsHeaderButton(
                      icon: LsIconType.image,
                      semanticLabel: 'Photos',
                      onTap: _openMediaGrid,
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.neon,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.white, width: 1.5),
                        ),
                        child: Text(
                          '$_imageCount',
                          style: AppText.mono(8.5, FontWeight.w700, color: AppColors.ink, height: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              LsHeaderButton(
                icon: _searching ? LsIconType.close : LsIconType.search,
                semanticLabel: 'Search in chat',
                onTap: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _search.clear();
                    _q = '';
                  }
                }),
              ),
            ]),
            if (_searching) ...[
              const SizedBox(height: 10),
              LsTextField(
                controller: _search,
                hint: 'Search in ${widget.title}',
                icon: LsIconType.search,
                autofocus: true,
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              ),
            ],
          ]),
        ),
        Expanded(
          child: all == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.neon, strokeWidth: 3))
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  itemCount: list.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Center(
                          child: Text.rich(TextSpan(style: AppText.mono(11.5, FontWeight.w400), children: [
                            const TextSpan(text: '> saved from notifications · '),
                            TextSpan(
                              text: 'replies are not sent',
                              style: AppText.mono(11.5, FontWeight.w500, color: AppColors.green),
                            ),
                          ])),
                        ),
                      );
                    }
                    final item = list[i - 1];
                    final older = i < list.length ? list[i] : null;
                    final newDay = older == null || nhDayLabel(older.time) != nhDayLabel(item.time);
                    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (newDay)
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 4),
                          child: Center(child: LsPill(_dayPill(item.time), variant: LsPillVariant.off)),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _Bubble(
                          item: item,
                          onOpenImage: _openImage,
                          onImageMenu: _imageMenu,
                        ),
                      ),
                    ]);
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + (inset > 0 ? inset : 20)),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.stroke)),
          ),
          child: Row(children: [
            Expanded(
              child: LsSmallCta(
                label: 'Copy all',
                icon: LsIconType.copy,
                variant: LsSmallCtaVariant.ghost,
                onPressed: _copyAll,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LsSmallCta(
                label: 'Share',
                icon: LsIconType.share,
                variant: LsSmallCtaVariant.ghost,
                onPressed: () => _svc.shareText(_asText(_items ?? const [])),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'Delete chat',
              child: GestureDetector(
                onTap: _delete,
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.red.withValues(alpha: .35)),
                    boxShadow: [BoxShadow(color: AppColors.red.withValues(alpha: .25), offset: const Offset(0, 4))],
                  ),
                  child: const LsIcon(LsIconType.trash, size: 19, color: AppColors.red, stroke: 2),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

String _dayPill(DateTime t) {
  final l = nhDayLabel(t);
  if (l == 'Today' || l == 'Yesterday') return '$l · ${t.day} ${nhDate(t).split(' ')[1]}';
  return l;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.item,
    required this.onOpenImage,
    required this.onImageMenu,
  });
  final NhItem item;
  final void Function(NhItem) onOpenImage;
  final void Function(NhItem) onImageMenu;

  @override
  Widget build(BuildContext context) {
    final maxW = (MediaQuery.sizeOf(context).width * .76).clamp(0.0, 260.0).toDouble();
    if (!item.hasImage) {
      if (nhIsMediaPlaceholder(item.text.split(': ').last)) {
        return _placeholderBubble(maxW);
      }
      return _textBubble(context, maxW);
    }

    final caption = item.caption;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onOpenImage(item),
            onLongPress: () => onImageMenu(item),
            child: Container(
              width: maxW,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(
                  color: item.removed ? AppColors.amberFill.withValues(alpha: .6) : AppColors.stroke,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.removed)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: NhRemovedTag(text: 'removed by sender · saved'),
                    ),
                  Hero(
                    tag: 'nh-img-${item.id}',
                    child: AspectRatio(
                      aspectRatio: item.aspect,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          NhImage(
                            path: item.thumbPath ?? item.mediaPath,
                            decodeWidth: maxW,
                            radius: 14,
                          ),
                          if (caption.isEmpty)
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0x8C0E1A14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  nhTime(item.time),
                                  style: AppText.mono(10.5, FontWeight.w500, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 9, 8, 5),
                      child: Text(caption, style: AppText.jakarta(14.5, FontWeight.w400)),
                    ),
                ],
              ),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(nhTime(item.time), style: AppText.mono(10.5, FontWeight.w400)),
          ],
        ],
      ),
    );
  }

  Widget _placeholderBubble(double maxW) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: maxW,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.stroke),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(5),
            ),
          ),
          child: Row(
            children: [
              const LsIcon(LsIconType.image, size: 18, color: AppColors.muted, stroke: 1.8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Photo · not included in notification',
                  style: AppText.jakarta(13.5, FontWeight.w400, color: AppColors.grey),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _textBubble(BuildContext context, double maxW) => Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: item.text));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Message copied')),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(
                      color: item.removed ? AppColors.amberFill.withValues(alpha: .6) : AppColors.stroke,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.removed) ...[
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LsIcon(LsIconType.trash, size: 11, color: AppColors.amber, stroke: 2.2),
                            SizedBox(width: 4),
                            NhRemovedTag(text: 'removed by sender · saved'),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(item.text, style: AppText.jakarta(14.5, FontWeight.w400)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(nhTime(item.time), style: AppText.mono(10.5, FontWeight.w400)),
              ],
            ),
          ),
        ),
      );
}

class _MediaGridSheet extends StatelessWidget {
  const _MediaGridSheet({
    required this.title,
    required this.images,
    required this.onTap,
  });

  final String title;
  final List<NhItem> images;
  final ValueChanged<NhItem> onTap;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final byMonth = <String, List<NhItem>>{};
    for (final i in images.reversed) {
      final key = '${_mo[i.time.month - 1]} ${i.time.year}';
      byMonth.putIfAbsent(key, () => []).add(i);
    }
    return Container(
      height: MediaQuery.sizeOf(context).height * .72,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(color: AppColors.stroke2, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos · ${images.length}', style: AppText.jakarta(20, FontWeight.w800)),
                Text('// from $title', style: AppText.mono(12, FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + inset),
              children: [
                for (final e in byMonth.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Text(e.key, style: AppText.mono(11, FontWeight.w700, spacing: 1)),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: e.value.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemBuilder: (_, i) {
                      final item = e.value[i];
                      return GestureDetector(
                        onTap: () => onTap(item),
                        child: NhImage(
                          path: item.thumbPath ?? item.mediaPath,
                          decodeWidth: 130,
                          radius: 10,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _mo = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
