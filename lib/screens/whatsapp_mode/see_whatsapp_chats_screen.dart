import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/data/whatsapp_chats.dart';
import 'package:tableflow_plus/models/whatsapp_chat.dart';
import 'package:tableflow_plus/screens/settings/settings_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';
import 'package:tableflow_plus/services/settings_actions_service.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:tableflow_plus/widgets/block_back_navigation.dart';
import 'package:tableflow_plus/widgets/decryption_panel.dart';
import 'package:tableflow_plus/widgets/open_messages_dialog.dart';
import 'package:tableflow_plus/widgets/open_whatsapp_messages_dialog.dart';
import 'package:tableflow_plus/widgets/whatsapp_analyzed_dialog.dart';

class SeeWhatsAppChatsScreen extends StatefulWidget {
  const SeeWhatsAppChatsScreen({super.key});

  @override
  State<SeeWhatsAppChatsScreen> createState() => _SeeWhatsAppChatsScreenState();
}

class _SeeWhatsAppChatsScreenState extends State<SeeWhatsAppChatsScreen> {
  /// True once this screen has been shown before (`isUserWhiteLineDialog`).
  /// Returning users skip the analysis and get [OpenWhatsAppMessagesDialog].
  late final bool _isReturningUser;
  late bool _showAnalyzedDialog;

  @override
  void initState() {
    super.initState();
    _isReturningUser = AppBootstrap.prefs.isUserWhiteLineDialog;
    _showAnalyzedDialog =
        !AppBootstrap.prefs.isUserPremium && !_isReturningUser;
    unawaited(_prepareChatList());
  }

  Future<void> _prepareChatList() async {
    await NotificationScheduler.syncForWhatsAppFlow(
      prefs: AppBootstrap.prefs,
      remoteConfig: AppBootstrap.remoteConfig,
    );
    if (!mounted) return;
    if (AppBootstrap.prefs.isUserPremium) {
      await AppBootstrap.applyBoostOnChatResume();
      if (AppBootstrap.decryption.needsInitialStart) {
        AppBootstrap.decryption.startInitial(
          AppBootstrap.remoteConfig.settings.startTime,
        );
      }
      return;
    }
    if (_isReturningUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPaywall());
    }
  }

  void _openPaywall() {
    if (!mounted) return;
    // Premium users never see the paywall again; chat rows do nothing.
    if (AppBootstrap.decryption.isActive) return;
    if (_isReturningUser) {
      OpenWhatsAppMessagesDialog.show(context);
    } else {
      OpenMessagesDialog.show(context);
    }
  }

  void _onAnalyzedDialogCompleted() {
    if (!mounted) return;
    setState(() => _showAnalyzedDialog = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPaywall());
  }

  Future<void> _onSeeMessages() async {
    final prefs = AppBootstrap.prefs;
    final star = AppBootstrap.remoteConfig.config.star;
    final askForReview = (star == 1 || star == 2) && !prefs.isStarDialogDone;
    if (!askForReview) {
      _openPaywall();
      return;
    }

    // First tap: star == 1 -> Play review dialog, star == 2 -> Play Store
    // page. Shown instead of the paywall; the next tap opens the paywall.
    await prefs.setStarDialogDone(true);
    try {
      if (star == 2) {
        await SettingsActionsService.openStoreListing();
      } else {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      }
    } catch (error) {
      debugPrint('[SeeMessages] review failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF05070A),
      ),
      child: BlockBackNavigation(
        child: Scaffold(
          backgroundColor: const Color(0xFF05070A),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _ChatsScreenBody(onOpenPaywall: _openPaywall),
              if (!_showAnalyzedDialog)
                ListenableBuilder(
                  listenable: AppBootstrap.decryption,
                  builder: (context, _) => AppBootstrap.decryption.isActive
                      ? const DecryptionPanel()
                      : _ChatsEncryptedSheet(onSeeMessages: _onSeeMessages),
                ),
              if (_showAnalyzedDialog)
                WhatsAppAnalyzedDialogOverlay(
                  onCompleted: _onAnalyzedDialogCompleted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatsScreenBody extends StatefulWidget {
  const _ChatsScreenBody({required this.onOpenPaywall});

  final VoidCallback onOpenPaywall;

  @override
  State<_ChatsScreenBody> createState() => _ChatsScreenBodyState();
}

class _ChatsScreenBodyState extends State<_ChatsScreenBody> {
  static const Duration _scrambleInterval = Duration(milliseconds: 30);

  final ValueNotifier<int> _scrambleTick = ValueNotifier<int>(0);
  Timer? _scrambleTimer;

  @override
  void initState() {
    super.initState();
    AppBootstrap.decryption.addListener(_syncScramble);
    _syncScramble();
  }

  /// Names and messages scramble every 30 ms while a countdown is running.
  void _syncScramble() {
    final counting = AppBootstrap.decryption.isCounting;
    if (counting && _scrambleTimer == null) {
      _scrambleTimer = Timer.periodic(_scrambleInterval, (_) {
        _scrambleTick.value++;
      });
    } else if (!counting && _scrambleTimer != null) {
      _scrambleTimer!.cancel();
      _scrambleTimer = null;
    }
  }

  @override
  void dispose() {
    AppBootstrap.decryption.removeListener(_syncScramble);
    _scrambleTimer?.cancel();
    _scrambleTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: AppBootstrap.decryption,
        builder: (context, _) {
          final premium = AppBootstrap.decryption.isActive;
          // Premium: chat rows, edit, New Group and Broadcast Lists do nothing.
          final VoidCallback? onTap = premium ? null : widget.onOpenPaywall;
          return Column(
            children: [
              _ChatsAppBar(onOpenPaywall: onTap),
              _ChatsActionRow(onOpenPaywall: onTap),
              Expanded(
                child: whatsAppChats.isEmpty
                  ? Center(
                    child: Text(
                      'No chats available',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF8696A0),
                      ),
                    ),
                  )
                : ListView.separated(
                  padding: EdgeInsets.only(bottom: premium ? 340 : 220),
                  itemCount: whatsAppChats.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFF1A1F24),
                  ),
                  itemBuilder: (context, index) {
                    final chat = whatsAppChats.elementAt(index);
                    return _ChatListTile(
                      chat: chat,
                      onTap: onTap,
                      scrambleTick: premium ? _scrambleTick : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatsAppBar extends StatelessWidget {
  const _ChatsAppBar({required this.onOpenPaywall});

  final VoidCallback? onOpenPaywall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.settings_rounded,
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Expanded(
            child: Text(
              'Chats',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.logoWhiteText,
              ),
            ),
          ),
          _CircleIconButton(
            icon: Icons.edit_outlined,
            onPressed: onOpenPaywall,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2126),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.logoWhiteText, size: 20),
        ),
      ),
    );
  }
}

class _ChatsActionRow extends StatelessWidget {
  const _ChatsActionRow({required this.onOpenPaywall});

  final VoidCallback? onOpenPaywall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionLink(label: 'Broadcast Lists', onTap: onOpenPaywall),
          _ActionLink(label: 'New Group', onTap: onOpenPaywall),
        ],
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.chat,
    required this.onTap,
    required this.scrambleTick,
  });

  final WhatsAppChat chat;
  final VoidCallback? onTap;

  /// Non-null once premium: name and message show scrambled random letters.
  final ValueListenable<int>? scrambleTick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BlurredAvatar(assetPath: chat.avatarAsset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ObfuscatedText(
                            text: chat.obfuscatedName,
                            seed: chat.id * 2,
                            scrambleLength: 10 + chat.id % 5,
                            tick: scrambleTick,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.logoWhiteText,
                            ),
                          ),
                        ),
                        Text(
                          chat.time,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF8696A0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: chat.isRead
                              ? const Color(0xFF53BDEB)
                              : const Color(0xFF8696A0),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _ObfuscatedText(
                            text: chat.obfuscatedPreview,
                            seed: chat.id * 2 + 1,
                            scrambleLength: 24 + chat.id % 7,
                            tick: scrambleTick,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8696A0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [text] (symbols) until [tick] is provided, then random letters that
/// change on every tick.
class _ObfuscatedText extends StatelessWidget {
  const _ObfuscatedText({
    required this.text,
    required this.seed,
    required this.scrambleLength,
    required this.tick,
    required this.style,
  });

  static const _letters =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final String text;
  final int seed;
  final int scrambleLength;
  final ValueListenable<int>? tick;
  final TextStyle style;

  String _scrambled(int tick) {
    final random = Random(tick * 7919 + seed * 104729);
    return String.fromCharCodes(
      List.generate(
        scrambleLength,
        (_) => _letters.codeUnitAt(random.nextInt(_letters.length)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenable = tick;
    if (listenable == null) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: listenable,
      builder: (context, value, _) => Text(
        _scrambled(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class _BlurredAvatar extends StatelessWidget {
  const _BlurredAvatar({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFF2D3748),
          child: const Icon(Icons.person_rounded, color: Color(0xFF8696A0)),
        );
      },
    );
  }
}

class _ChatsEncryptedSheet extends StatelessWidget {
  const _ChatsEncryptedSheet({required this.onSeeMessages});

  final VoidCallback onSeeMessages;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SheetPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const MachineHero(),
            const SizedBox(height: 8),
            Text(
              'Chats are Encrypted',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.whatsAppGreen,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Received messages are encrypted by WhatsApp using end-to-end '
              'encryption technology. Click to decrypt.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.logoWhiteText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            AppCtaButton(
              label: 'See Messages',
              onTap: onSeeMessages,
            ),
          ],
        ),
      ),
    );
  }
}

