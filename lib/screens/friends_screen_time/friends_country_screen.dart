import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/data/countries.dart';
import 'package:tableflow_plus/models/country.dart';

/// Light country list for the friends flow. WhatsApp keeps its own dark picker.
class FriendsCountryScreen extends StatefulWidget {
  const FriendsCountryScreen({super.key, this.selected});

  final Country? selected;

  @override
  State<FriendsCountryScreen> createState() => _FriendsCountryScreenState();
}

class _FriendsCountryScreenState extends State<FriendsCountryScreen> {
  final _query = TextEditingController();
  List<Country> _shown = countries;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final s = q.trim().toLowerCase().replaceAll('+', '');
    setState(() {
      _shown = s.isEmpty
          ? countries
          : countries
              .where((c) =>
                  c.name.toLowerCase().contains(s) ||
                  c.dialCode.startsWith(s) ||
                  c.isoCode.toLowerCase() == s)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LsScaffold(
      safeBottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LsTopBar(onBack: () => Get.back<void>()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Country', style: AppText.h1),
                const SizedBox(height: 4),
                LsCaption('// ${countries.length} regions'),
                const SizedBox(height: 14),
                LsTextField(
                  controller: _query,
                  hint: 'Search country',
                  icon: LsIconType.search,
                  iconColor: AppColors.neon,
                  onChanged: _filter,
                  trailing: Text('A–Z', style: AppText.mono(11, FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _shown.isEmpty
                ? Center(child: Text('No country found', style: AppText.jakarta(14, FontWeight.w500, color: AppColors.muted)))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
                    itemCount: _shown.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = _shown[i];
                      final selected = c.isoCode == widget.selected?.isoCode;
                      return GestureDetector(
                        onTap: () => Get.back(result: c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? Color.alphaBlend(AppColors.neon.withValues(alpha: .08), AppColors.white)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? AppColors.neon.withValues(alpha: .6) : AppColors.stroke,
                            ),
                          ),
                          child: Row(
                            children: [
                              LsFlag(c),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(15, FontWeight.w600)),
                              ),
                              Text(
                                c.formattedDialCode,
                                style: AppText.mono(13, FontWeight.w500, color: selected ? AppColors.green : AppColors.muted),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 12),
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
                                  child: const LsIcon(LsIconType.check, size: 13, color: AppColors.ink, stroke: 3),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
