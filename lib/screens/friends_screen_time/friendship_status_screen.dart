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
import 'package:tableflow_plus/screens/friends_screen_time/friends_statistics_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';

enum FriendshipMode { friendsStatics, requestsReceived, sentRequests, friends }

class FriendshipStatusScreen extends StatefulWidget {
  const FriendshipStatusScreen({super.key, required this.mode});

  final FriendshipMode mode;

  @override
  State<FriendshipStatusScreen> createState() => _FriendshipStatusScreenState();
}

class _FriendshipStatusScreenState extends State<FriendshipStatusScreen> {
  final _flow = FriendsFlowController.instance;
  List<ScreenTimeUser> _people = const [];
  bool _loading = true;
  String? _deleteUid;

  @override
  void initState() {
    super.initState();
    _flow.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _flow.removeListener(_load);
    super.dispose();
  }

  List<String> get _ids {
    final user = _flow.user;
    if (user == null) return const [];
    return switch (widget.mode) {
      FriendshipMode.sentRequests => user.sentRequests.keys.toList(),
      FriendshipMode.requestsReceived => user.receivedRequests.keys.toList(),
      _ => user.friends.keys.toList(),
    };
  }

  Future<void> _load() async {
    final people = await _flow.peopleFor(_ids);
    if (!mounted) return;
    setState(() {
      _people = people;
      _loading = false;
    });
  }

  String get _title => switch (widget.mode) {
        FriendshipMode.sentRequests => 'Sent Requests',
        FriendshipMode.requestsReceived => 'Received Requests',
        _ => 'Friends',
      };

  String get _empty => switch (widget.mode) {
        FriendshipMode.sentRequests =>
          'There are no sent friend requests yet. You can see them here after sending an invitation.',
        FriendshipMode.requestsReceived =>
          'There are no friend requests yet. You can see them here after receiving an invitation.',
        _ =>
          "You don't have any friends yet. You can see them here after adding them.",
      };

  String get _emptyArt => switch (widget.mode) {
        FriendshipMode.sentRequests => LsArts.paperPlaneCard,
        FriendshipMode.requestsReceived => LsArts.addFriends,
        _ => LsArts.noFriends,
      };

  bool get _emptyHasCopy => switch (widget.mode) {
        FriendshipMode.sentRequests => false,
        FriendshipMode.requestsReceived => true,
        _ => true,
      };

  Future<void> _run(Future<void> Function() action, String ok, String fail) async {
    showFlowProcessing();
    try {
      await action();
      hideFlowProcessing();
      await showFlowToast(ok);
    } catch (_) {
      hideFlowProcessing();
      await showFlowToast(fail);
    }
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
                Text(_title, style: AppText.h1),
                const SizedBox(height: 4),
                LsCaption('// ${_people.length}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.green)))
          else if (_people.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LsArt(_emptyArt, height: 200),
                    if (!_emptyHasCopy) ...[
                      const SizedBox(height: 16),
                      Text(
                        _empty,
                        textAlign: TextAlign.center,
                        style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
                itemCount: _people.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _row(_people[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(ScreenTimeUser person) {
    final received = widget.mode == FriendshipMode.requestsReceived;
    return GestureDetector(
      onLongPress: widget.mode == FriendshipMode.friends
          ? () => setState(() {
                _deleteUid = _deleteUid == person.uid ? null : person.uid;
              })
          : null,
      child: LsCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                LsAvatar(
                  index: person.username.hashCode.abs(),
                  size: 46,
                  photoUrl: person.photo,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(15.5, FontWeight.w700)),
                      Text(person.phone, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.mono(11.5, FontWeight.w500)),
                    ],
                  ),
                ),
                if (received) ...[
                  const SizedBox(width: 8),
                  const LsPill('new', variant: LsPillVariant.amber, fontSize: 10),
                ] else ...[
                  const SizedBox(width: 8),
                  _actions(person),
                ],
              ],
            ),
            if (received) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LsSmallCta(
                      label: 'Delete',
                      icon: LsIconType.close,
                      variant: LsSmallCtaVariant.ghost,
                      onPressed: () => _run(
                        () => _flow.reject(person.uid),
                        'Friendship request rejected.',
                        'Failed to decline request',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LsSmallCta(
                      label: 'Approve',
                      icon: LsIconType.check,
                      onPressed: () => _run(
                        () => _flow.accept(person.uid),
                        'Friendship request accepted.',
                        'We encountered a problem accepting your request',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actions(ScreenTimeUser person) {
    if (widget.mode == FriendshipMode.friends && _deleteUid == person.uid) {
      return LsMiniCta(
        label: 'Delete',
        icon: LsIconType.close,
        onPressed: () => _run(
          () => _flow.removeFriend(person.uid),
          'Removed from friendship',
          'Could not remove this friend',
        ),
      );
    }
    return switch (widget.mode) {
      FriendshipMode.friendsStatics => LsMiniCta(
          label: 'Stats',
          icon: LsIconType.trend,
          onPressed: () {
            Get.off<void>(
              () => FriendsStatisticsScreen(
                uid: person.uid,
                name: person.username,
                photo: person.photo,
              ),
            );
          },
        ),
      FriendshipMode.requestsReceived => const SizedBox.shrink(),
      FriendshipMode.sentRequests => LsMiniCta(
          label: 'Cancel',
          icon: LsIconType.close,
          onPressed: () => _run(
            () => _flow.reject(person.uid),
            'Friendship request rejected.',
            'Failed to decline request',
          ),
        ),
      FriendshipMode.friends => LsMiniCta(
          label: 'Message',
          icon: LsIconType.msg,
          onPressed: () async {
            showFlowProcessing();
            try {
              final chatId = await _flow.openChatId(person);
              hideFlowProcessing();
              await Get.off<void>(
                () => FriendChatScreen(
                  chatId: chatId,
                  otherUid: person.uid,
                  otherName: person.username,
                  otherPhoto: person.photo,
                ),
              );
            } catch (_) {
              hideFlowProcessing();
              await showFlowToast('Could not open the chat');
            }
          },
        ),
    };
  }
}
