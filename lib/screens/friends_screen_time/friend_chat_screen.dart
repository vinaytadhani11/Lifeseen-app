import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_statistics_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';

class FriendChatScreen extends StatefulWidget {
  const FriendChatScreen({
    super.key,
    required this.chatId,
    required this.otherUid,
    required this.otherName,
    required this.otherPhoto,
  });

  final String chatId;
  final String otherUid;
  final String otherName;
  final String otherPhoto;

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final _text = TextEditingController();
  final _flow = FriendsFlowController.instance;
  String? _todayUsage;

  @override
  void initState() {
    super.initState();
    _flow.activeChatId = widget.chatId;
    _loadToday();
  }

  @override
  void dispose() {
    if (_flow.activeChatId == widget.chatId) _flow.activeChatId = null;
    _text.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    try {
      final day = await _flow.dayFor(widget.otherUid, DateTime.now());
      final seconds = day.apps.fold<int>(0, (sum, app) => sum + app.sortSeconds);
      if (!mounted) return;
      setState(() => _todayUsage = seconds > 0 ? _usageLabel(seconds) : null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _todayUsage = null);
    }
  }

  String _usageLabel(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h <= 0) return '${m}M TODAY';
    return '${h}H ${m.toString().padLeft(2, '0')}M TODAY';
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    HapticFeedback.selectionClick();
    await _flow.sendText(
      chatId: widget.chatId,
      otherUid: widget.otherUid,
      text: value,
    );
    _text.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final myId = _flow.documentId;
    final inset = MediaQuery.paddingOf(context).bottom;
    final canSend = _text.text.trim().isNotEmpty;
    final statusLine = _todayUsage == null ? 'ONLINE' : 'ONLINE · $_todayUsage';

    return LsScaffold(
      safeBottom: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.stroke)),
            ),
            child: Row(
              children: [
                _HeaderBtn(
                  icon: LsIconType.back,
                  onTap: () => Get.back<void>(),
                ),
                const SizedBox(width: 10),
                _HeaderAvatar(
                  name: widget.otherName,
                  photoUrl: widget.otherPhoto,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.jakarta(17, FontWeight.w800, height: 1.05),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '● $statusLine',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(10, FontWeight.w700, color: AppColors.green, spacing: .55),
                      ),
                    ],
                  ),
                ),
                _HeaderBtn(
                  icon: LsIconType.trend,
                  color: AppColors.green,
                  onTap: () => Get.to<void>(
                    () => FriendsStatisticsScreen(
                      uid: widget.otherUid,
                      name: widget.otherName,
                      photo: widget.otherPhoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FriendChatMessage>>(
              stream: _flow.messages(widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <FriendChatMessage>[];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final mine = message.senderId == myId;
                    final day = DateTime.fromMillisecondsSinceEpoch((message.timestamp * 1000).round());
                    // Older neighbor in reverse list (toward top of screen).
                    final olderIndex = messages.length - 2 - index;
                    final older = olderIndex < 0 ? null : messages[olderIndex];
                    final showDay = older == null ||
                        !isSameDay(
                          day,
                          DateTime.fromMillisecondsSinceEpoch((older.timestamp * 1000).round()),
                        );

                    // Column is not flipped by reverse — put day chip above the
                    // oldest message of that day so it sits on top of the group.
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Column(
                        children: [
                          if (showDay) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4EBE6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  chatDayPillLabel(day),
                                  style: AppText.mono(10, FontWeight.w700, color: AppColors.grey, spacing: .9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          _Bubble(
                            message: message,
                            mine: mine,
                            otherName: widget.otherName,
                            otherPhoto: widget.otherPhoto,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + inset),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.stroke)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.stroke2),
                    ),
                    child: TextField(
                      controller: _text,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                      style: AppText.jakarta(15, FontWeight.w500),
                      cursorColor: AppColors.green,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Message',
                        hintStyle: AppText.jakarta(15, FontWeight.w400, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: canSend ? _send : null,
                  child: Opacity(
                    opacity: canSend ? 1 : .55,
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.btnGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neon.withValues(alpha: .32),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                          const BoxShadow(color: AppColors.edge, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const LsIcon(LsIconType.send, size: 21, color: AppColors.ink, stroke: 2.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neon.withValues(alpha: .28),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: LsCachedImage(
                  url: photoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: ColoredBox(
                    color: AppColors.mint,
                    child: Center(
                      child: Text(
                        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                        style: AppText.jakarta(15, FontWeight.w800, color: AppColors.green),
                      ),
                    ),
                  ),
                  error: ColoredBox(
                    color: AppColors.mint,
                    child: Center(
                      child: Text(
                        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                        style: AppText.jakarta(15, FontWeight.w800, color: AppColors.green),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({
    required this.icon,
    required this.onTap,
    this.color = AppColors.text,
  });

  final LsIconType icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: .10),
              offset: const Offset(0, 3),
              blurRadius: 10,
              spreadRadius: -4,
            ),
          ],
        ),
        child: LsIcon(icon, size: 18, color: color, stroke: 1.9),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.otherName,
    required this.otherPhoto,
  });

  final FriendChatMessage message;
  final bool mine;
  final String otherName;
  final String otherPhoto;

  static const _outGreen = Color(0xFF7FE59A);

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: mine ? _outGreen : AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: mine ? .03 : .06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: AppText.jakarta(14.5, FontWeight.w500, color: AppColors.text, height: 1.35),
      ),
    );

    final timeStyle = AppText.mono(10, FontWeight.w500, color: AppColors.muted);

    if (mine) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bubble,
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(clockLabel(message.timestamp), style: timeStyle),
                  const SizedBox(width: 3),
                  Text('✓✓', style: timeStyle),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _TinyAvatar(name: otherName, photoUrl: otherPhoto),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bubble,
                const SizedBox(height: 4),
                Text(clockLabel(message.timestamp), style: timeStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyAvatar extends StatelessWidget {
  const _TinyAvatar({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.stroke2, width: 1.2),
      ),
      child: ClipOval(
        child: LsCachedImage(
          url: photoUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          placeholder: ColoredBox(
            color: AppColors.mint,
            child: Center(
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: AppText.jakarta(11, FontWeight.w700, color: AppColors.green),
              ),
            ),
          ),
          error: ColoredBox(
            color: AppColors.mint,
            child: Center(
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: AppText.jakarta(11, FontWeight.w700, color: AppColors.green),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
