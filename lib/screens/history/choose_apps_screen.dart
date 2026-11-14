// LifeSeen – S33 Choose Apps to Save · Light Green theme
// Real installed apps (Android launcher apps) with on/off switches.

import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/services/notification_history.dart';
import 'package:tableflow_plus/screens/history/history_ui.dart';


class ChooseAppsScreen extends StatefulWidget {
  const ChooseAppsScreen({super.key, required this.onSaved, this.onSkip, this.onBack, this.service});

  /// Called after the choice is saved to the device.
  final ValueChanged<Set<String>> onSaved;

  /// Shows "SKIP" top-right (used during onboarding).
  final VoidCallback? onSkip;
  final VoidCallback? onBack;
  final NotificationHistory? service;

  @override
  State<ChooseAppsScreen> createState() => _ChooseAppsScreenState();
}

class _ChooseAppsScreenState extends State<ChooseAppsScreen> {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;
  final _search = TextEditingController();
  List<NhApp>? _apps;
  final Set<String> _on = {};
  String _q = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final apps = await _svc.installedApps();
    final enabled = await _svc.enabledApps();
    apps.sort((a, b) {
      if (a.social != b.social) return a.social ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _on
        ..clear()
        ..addAll(enabled.isNotEmpty ? enabled : apps.map((a) => a.package).where(nhSuggestedPackages.contains));
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _svc.setEnabledApps({..._on});
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved({..._on});
  }

  void _toggle(String pkg, bool v) => setState(() => v ? _on.add(pkg) : _on.remove(pkg));

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    final inset = MediaQuery.paddingOf(context).bottom;
    final shown = apps == null
        ? const <NhApp>[]
        : apps.where((a) => _q.isEmpty || a.name.toLowerCase().contains(_q) || a.package.contains(_q)).toList();
    final social = shown.where((a) => a.social).toList();
    final other = shown.where((a) => !a.social).toList();
    final allOn = apps != null && apps.isNotEmpty && _on.length == apps.length;

    return LsScaffold(
      safeBottom: false,
      child: Stack(children: [
        Positioned.fill(
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: LsTopBar(
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
                right: widget.onSkip == null
                    ? null
                    : GestureDetector(
                        onTap: widget.onSkip,
                        behavior: HitTestBehavior.opaque,
                        child: Center(child: Text('SKIP', style: AppText.mono(11, FontWeight.w700, spacing: 1.1))),
                      ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 130 + inset),
              sliver: SliverList.list(children: [
                Text('Choose Apps to Save', style: AppText.h1),
                const SizedBox(height: 4),
                LsRichCaption([
                  ('// ', false),
                  ('${_on.length} of ${apps?.length ?? 0} apps on', true),
                  (' · tap to turn on/off', false),
                ]),
                const SizedBox(height: 14),
                LsTextField(
                  controller: _search,
                  hint: 'Search apps',
                  icon: LsIconType.search,
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                if (apps == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(color: AppColors.neon, strokeWidth: 3)),
                  )
                else ...[
                  LsCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      const LsIconChip(LsIconType.check, color: AppColors.green, size: 36, iconSize: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text('Select all apps', style: AppText.jakarta(15, FontWeight.w700)),
                          Text('Save notifications from every app', style: AppText.small),
                        ]),
                      ),
                      LsSwitch(
                        value: allOn,
                        semanticLabel: 'Select all apps',
                        onChanged: (v) => setState(() {
                          _on.clear();
                          if (v) _on.addAll(apps.map((a) => a.package));
                        }),
                      ),
                    ]),
                  ),
                  if (social.isNotEmpty) ...[
                    _label('Social & chat', social.where((a) => _on.contains(a.package)).length),
                    _group(social),
                  ],
                  if (other.isNotEmpty) ...[
                    _label('Other apps', other.where((a) => _on.contains(a.package)).length),
                    _group(other),
                  ],
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(child: Text('No apps found', style: AppText.jakarta(14, FontWeight.w500, color: AppColors.muted))),
                    ),
                ],
              ]),
            ),
          ]),
        ),
        // fixed CTA with fade
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 26, 16, 16 + inset),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.bg, AppColors.bg, AppColors.bg.withValues(alpha: 0)],
                stops: const [0, .7, 1],
              ),
            ),
            child: LsCta(
              label: _on.isEmpty ? 'Save' : 'Save ${_on.length} App${_on.length == 1 ? '' : 's'}',
              icon: LsIconType.check,
              onPressed: apps == null ? null : _save,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String t, int on) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
        child: Row(children: [
          Expanded(child: Text(t.toUpperCase(), style: AppText.mono(11, FontWeight.w700, spacing: 1.1))),
          Text('$on ON', style: AppText.mono(11, FontWeight.w700, color: AppColors.green, spacing: 1.1)),
        ]),
      );

  Widget _group(List<NhApp> list) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.stroke),
            _AppRow(app: list[i], on: _on.contains(list[i].package), onChanged: (v) => _toggle(list[i].package, v), service: _svc),
          ],
        ]),
      );
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.on, required this.onChanged, required this.service});
  final NhApp app;
  final bool on;
  final ValueChanged<bool> onChanged;
  final NotificationHistory service;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!on),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            NhAppIcon(package: app.package, name: app.name, icon: app.icon, size: 40, service: service),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(15, FontWeight.w700)),
                Text(
                  on ? (app.todayCount > 0 ? '${nhNumber(app.todayCount)} saved today' : 'saving') : 'not saving',
                  style: AppText.mono(11, FontWeight.w500, color: on ? AppColors.green : AppColors.muted),
                ),
              ]),
            ),
            LsSwitch(value: on, onChanged: onChanged, semanticLabel: app.name),
          ]),
        ),
      );
}
