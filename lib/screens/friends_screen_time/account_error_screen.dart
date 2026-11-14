import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';

class AccountErrorScreen extends StatelessWidget {
  const AccountErrorScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LsScaffold(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Could not load your account', textAlign: TextAlign.center, style: AppText.h1),
            const SizedBox(height: 12),
            Text(
              'Home stays closed until your saved profile can be read.',
              textAlign: TextAlign.center,
              style: AppText.sub,
            ),
            const SizedBox(height: 28),
            AppCtaButton(label: 'Retry', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}