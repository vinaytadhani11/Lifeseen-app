// LifeSeen – full-screen notification image viewer (S36)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/screens/history/history_ui.dart';
import 'package:tableflow_plus/services/notification_history.dart';

class NhMediaViewer extends StatefulWidget {
  const NhMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.service,
  });

  final List<NhItem> items;
  final int initialIndex;
  final NotificationHistory? service;

  @override
  State<NhMediaViewer> createState() => _NhMediaViewerState();
}

class _NhMediaViewerState extends State<NhMediaViewer> {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;
  late final PageController _page;
  late int _index;
  bool _chrome = true;
  double _dragY = 0;
  final _transforms = <int, TransformationController>{};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.isEmpty ? 0 : widget.items.length - 1);
    _page = PageController(initialPage: _index);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _page.dispose();
    for (final c in _transforms.values) {
      c.dispose();
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  TransformationController _tc(int i) => _transforms.putIfAbsent(i, TransformationController.new);

  double get _scale {
    final m = _tc(_index).value;
    return m.getMaxScaleOnAxis();
  }

  NhItem get _item => widget.items[_index];

  Future<void> _share() => _svc.shareImage(
        _item.mediaPath!,
        text: _item.caption.isEmpty ? null : _item.caption,
      );

  Future<void> _save() async {
    final ok = await _svc.saveImageToGallery(_item.mediaPath!);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(ok ? 'Saved to Pictures/LifeSeen' : "Couldn't save the image"),
      ),
    );
  }

  Future<void> _copy() async {
    if (_item.caption.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _item.caption));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Caption copied')),
    );
  }

  void _toggleZoom(TapDownDetails d) {
    final c = _tc(_index);
    if (_scale > 1.05) {
      c.value = Matrix4.identity();
    } else {
      final pos = d.localPosition;
      c.value = Matrix4.identity()
        ..translateByDouble(-pos.dx * 1.5, -pos.dy * 1.5, 0, 1)
        ..scaleByDouble(2.5, 2.5, 2.5, 1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final opacity = (1 - (_dragY.abs() / 400)).clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: AppColors.ink.withValues(alpha: opacity),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => setState(() => _chrome = !_chrome),
              onVerticalDragUpdate: _scale > 1.05
                  ? null
                  : (d) => setState(() => _dragY += d.delta.dy),
              onVerticalDragEnd: _scale > 1.05
                  ? null
                  : (d) {
                      if (_dragY.abs() > 120 || (d.primaryVelocity?.abs() ?? 0) > 800) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _dragY = 0);
                      }
                    },
              child: Transform.translate(
                offset: Offset(0, _dragY),
                child: PageView.builder(
                  controller: _page,
                  physics: _scale > 1.05
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: widget.items.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _index = i;
                      _dragY = 0;
                    });
                  },
                  itemBuilder: (_, i) {
                    final item = widget.items[i];
                    return InteractiveViewer(
                      transformationController: _tc(i),
                      minScale: 1,
                      maxScale: 4,
                      onInteractionEnd: (_) => setState(() {}),
                      child: GestureDetector(
                        onDoubleTapDown: _toggleZoom,
                        onDoubleTap: () {},
                        child: Center(
                          child: Hero(
                            tag: 'nh-img-${item.id}',
                            child: NhImage(
                              path: item.mediaPath,
                              fit: BoxFit.contain,
                              decodeWidth: MediaQuery.sizeOf(context).width,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                opacity: _chrome ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(12, top + 8, 12, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: .55), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          _GlassBtn(icon: LsIconType.back, onTap: () => Navigator.of(context).pop()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.jakarta(15, FontWeight.w700, color: Colors.white),
                                ),
                                Text(
                                  '${nhDayLabel(_item.time)} · ${nhTime(_item.time)}',
                                  style: AppText.mono(11, FontWeight.w500, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_index + 1} / ${widget.items.length}',
                            style: AppText.mono(12, FontWeight.w700, color: AppColors.neon),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withValues(alpha: .7), Colors.transparent],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_item.removed)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: NhRemovedTag(text: 'removed by sender · saved'),
                              ),
                            ),
                          if (_item.caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _item.caption,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.jakarta(14.5, FontWeight.w400, color: Colors.white, height: 1.35),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(child: _Action(label: 'Share', icon: LsIconType.share, onTap: _share)),
                              const SizedBox(width: 10),
                              Expanded(child: _Action(label: 'Save', icon: LsIconType.image, onTap: _save)),
                              if (_item.caption.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Expanded(child: _Action(label: 'Copy', icon: LsIconType.copy, onTap: _copy)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBtn extends StatelessWidget {
  const _GlassBtn({required this.icon, required this.onTap});
  final LsIconType icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: LsIcon(icon, size: 18, color: Colors.white, stroke: 2),
        ),
      );
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.icon, required this.onTap});
  final String label;
  final LsIconType icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LsIcon(icon, size: 16, color: Colors.white, stroke: 2),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: AppText.mono(11, FontWeight.w700, color: Colors.white, spacing: .8)),
            ],
          ),
        ),
      );
}
