import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friend_chat_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = FriendsFlowController.instance;
    final inset = MediaQuery.paddingOf(context).bottom;
    return AnimatedBuilder(
      animation: flow,
      builder: (context, _) {
        final myId = flow.documentId;
        final all = myId.isEmpty ? const <FriendChatPreview>[] : flow.chats;
        final shown = _q.isEmpty
            ? all
            : all
                .where(
                  (c) =>
                      c.otherName.toLowerCase().contains(_q) ||
                      c.text.toLowerCase().contains(_q),
                )
                .toList();
        final inbound = all.where((c) => c.senderId.isNotEmpty && c.senderId != myId).length;

        final header = Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 42,
                child: Row(
                  children: [
                    LsHeaderButton(
                      icon: LsIconType.plus,
                      semanticLabel: 'New chat',
                      onTap: () => flow.setTab(0),
                    ),
                    const Expanded(child: Center(child: LsWordmark())),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Messages', style: AppText.h1),
              const SizedBox(height: 4),
              LsRichCaption([
                if (inbound > 0) ...[
                  ('// $inbound unread', true),
                  (' · ', false),
                ] else
                  ('// ', false),
                ('${all.length} conversations', false),
              ]),
            ],
          ),
        );

        if (all.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const Expanded(child: _Empty()),
                SizedBox(height: 96 + inset),
              ],
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 130 + inset),
          children: [
            header,
            const SizedBox(height: 14),
            LsTextField(
              controller: _search,
              hint: 'Search messages',
              icon: LsIconType.search,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            for (final chat in shown) ...[
              _MessageRow(chat: chat, myId: myId),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: LsArt(LsArts.noMessages, height: 280));
  }
}

class _MessageRow extends StatefulWidget {
  const _MessageRow({required this.chat, required this.myId});

  final FriendChatPreview chat;
  final String myId;

  @override
  State<_MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends State<_MessageRow> {
  bool _deleteVisible = false;

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    final inbound = chat.senderId.isNotEmpty && chat.senderId != widget.myId;
    return GestureDetector(
      onLongPress: () => setState(() => _deleteVisible = !_deleteVisible),
      onTap: _deleteVisible
          ? null
          : () {
              Get.to<void>(
                () => FriendChatScreen(
                  chatId: chat.chatId,
                  otherUid: chat.otherUid,
                  otherName: chat.otherName,
                  otherPhoto: chat.otherPhoto,
                ),
              );
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: inbound ? AppColors.neon.withValues(alpha: .55) : AppColors.stroke,
            width: inbound ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: inbound ? AppColors.neon.withValues(alpha: .18) : AppColors.text.withValues(alpha: .05),
              blurRadius: inbound ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            LsAvatar(
              index: chat.otherName.hashCode.abs(),
              size: 50,
              status: LsStatus.none,
              photoUrl: chat.otherPhoto,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.jakarta(15.5, FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.text.isEmpty ? 'No messages yet' : chat.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.jakarta(13, FontWeight.w400, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_deleteVisible)
              TextButton(
                onPressed: () => FriendsFlowController.instance.hideChat(chat.chatId),
                child: Text('Delete', style: AppText.jakarta(13, FontWeight.w700, color: AppColors.red)),
              )
            else
              Text(
                chatListTimeLabel(chat.timestamp),
                style: AppText.mono(
                  11,
                  FontWeight.w600,
                  color: inbound ? AppColors.green : AppColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
