import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';

class FriendsDatabaseService {
  FriendsDatabaseService._();

  static final FriendsDatabaseService instance = FriendsDatabaseService._();

  DatabaseReference get _root => FirebaseDatabase.instance.ref('screenTime');

  String digitsKey(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  Future<ScreenTimeUser?> loadUser(String uid) async {
    final snap = await _root.child('users').child(uid).get();
    if (!snap.exists || snap.value is! Map) return null;
    return ScreenTimeUser.fromMap(uid, snap.value! as Map);
  }

  Stream<ScreenTimeUser?> watchUser(String uid) {
    return _root.child('users').child(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      return ScreenTimeUser.fromMap(uid, value);
    });
  }

  Future<String?> uidForPhone(String phone) async {
    final snap = await _root.child('phoneIndex').child(digitsKey(phone)).get();
    if (!snap.exists) return null;
    final uid = snap.value?.toString() ?? '';
    return uid.isEmpty ? null : uid;
  }

  Future<ScreenTimeUser> createUser({
    required String phone,
    required String username,
  }) async {
    final ref = _root.child('users').push();
    final uid = ref.key!;
    final user = ScreenTimeUser(uid: uid, phone: phone, username: username);
    await ref.set(user.toMap());
    await _root.child('phoneIndex').child(digitsKey(phone)).set(uid);
    return user;
  }

  Future<void> updateUsername(String uid, String username) {
    return _root.child('users').child(uid).update({'username': username});
  }

  Future<void> updatePhoto(String uid, String url) {
    return _root.child('users').child(uid).update({'photo': url});
  }

  Future<void> sendRequest(String myId, String theirId) {
    return _root.child('users').update({
      '$myId/sentRequests/$theirId': true,
      '$theirId/receivedRequests/$myId': true,
    });
  }

  Future<void> acceptRequest(String myId, String theirId) {
    return _root.child('users').update({
      '$myId/receivedRequests/$theirId': null,
      '$theirId/sentRequests/$myId': null,
      '$myId/friends/$theirId': true,
      '$theirId/friends/$myId': true,
    });
  }

  Future<void> cancelOrReject(String myId, String theirId) {
    return _root.child('users').update({
      '$myId/sentRequests/$theirId': null,
      '$theirId/receivedRequests/$myId': null,
      '$myId/receivedRequests/$theirId': null,
      '$theirId/sentRequests/$myId': null,
    });
  }

  Future<void> removeFriend(String myId, String theirId) {
    return _root.child('users').update({
      '$myId/friends/$theirId': null,
      '$theirId/friends/$myId': null,
    });
  }

  Future<List<ScreenTimeUser>> usersByIds(Iterable<String> ids) async {
    final users = <ScreenTimeUser>[];
    for (final id in ids) {
      final user = await loadUser(id);
      if (user != null) users.add(user);
    }
    return users;
  }

  Future<ScreenTimeDay> fetchDay(String uid, String dayKey) async {
    final snap =
        await _root.child('users').child(uid).child('screenTimes').child(dayKey).get();
    if (!snap.exists || snap.value is! Map) return const ScreenTimeDay();
    return ScreenTimeDay.fromMap(snap.value! as Map);
  }

  Stream<ScreenTimeDay> watchDay(String uid, String dayKey) {
    return _root
        .child('users')
        .child(uid)
        .child('screenTimes')
        .child(dayKey)
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return const ScreenTimeDay();
      return ScreenTimeDay.fromMap(value);
    });
  }

  Future<void> uploadToday({
    required String uid,
    required String dayKey,
    required List<ScreenTimeApp> apps,
    required List<double> hourly,
  }) async {
    final ref = _root.child('users').child(uid).child('screenTimes').child(dayKey);
    final existing = await ref.get();
    final merged = <String, Map<String, Object>>{};
    if (existing.value is Map) {
      for (final app in ScreenTimeDay.fromMap(existing.value! as Map).apps) {
        if (app.name.isNotEmpty) merged[app.name] = app.toMap();
      }
    }
    for (final app in apps) {
      merged[app.name] = app.toMap();
    }
    await ref.set({
      'data': merged.values.toList(),
      if (hourly.length == 24) 'hourly': hourly,
    });
  }

  String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> chatExists(String chatId) async {
    final snap = await _root.child('chats').child(chatId).get();
    return snap.exists;
  }

  Future<void> ensureChat({
    required String chatId,
    required ScreenTimeUser me,
    required ScreenTimeUser them,
  }) async {
    final chat = _root.child('chats').child(chatId);
    final snap = await chat.get();
    if (!snap.exists) {
      await chat.set({
        'members': {me.uid: true, them.uid: true},
      });
    }
    final previewForMe = {
      'otherUid': them.uid,
      'otherName': them.username,
      'otherPhoto': them.photo,
      'text': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
      'hidden': false,
    };
    final previewForThem = {
      'otherUid': me.uid,
      'otherName': me.username,
      'otherPhoto': me.photo,
      'text': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
      'hidden': false,
    };
    final meRef = _root.child('userChats').child(me.uid).child(chatId);
    final themRef = _root.child('userChats').child(them.uid).child(chatId);
    if (!(await meRef.get()).exists) await meRef.set(previewForMe);
    if (!(await themRef.get()).exists) await themRef.set(previewForThem);
  }

  Stream<List<FriendChatPreview>> watchChats(String myId) {
    return _root.child('userChats').child(myId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <FriendChatPreview>[];
      final rooms = <FriendChatPreview>[];
      value.forEach((key, raw) {
        if (raw is Map) {
          rooms.add(FriendChatPreview.fromMap(key.toString(), raw));
        }
      });
      rooms.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return rooms.where((room) => !room.hidden).toList();
    });
  }

  Stream<List<FriendChatMessage>> watchMessages(String chatId, String myId) {
    return _root.child('chats').child(chatId).child('messages').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <FriendChatMessage>[];
      final messages = <FriendChatMessage>[];
      value.forEach((key, raw) {
        if (raw is Map) {
          final message = FriendChatMessage.fromMap(key.toString(), raw);
          if (message.deletedBy[myId] != true) messages.add(message);
        }
      });
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Future<void> sendText({
    required String chatId,
    required String myId,
    required String text,
    required ScreenTimeUser me,
    required String otherUid,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final messageRef =
        _root.child('chats').child(chatId).child('messages').push();
    await messageRef.set({
      'senderId': myId,
      'messageType': 'text',
      'text': text,
      'timestamp': now,
    });
    await _root.child('userChats').child(myId).child(chatId).update({
      'text': text,
      'timestamp': now,
      'senderId': myId,
    });
    await _root.child('userChats').child(otherUid).child(chatId).update({
      'text': text,
      'timestamp': now,
      'senderId': myId,
      'hidden': false,
      'otherName': me.username,
      'otherPhoto': me.photo,
    });
  }

  Future<void> hideChatForMe({
    required String chatId,
    required String myId,
  }) async {
    await _root.child('userChats').child(myId).child(chatId).update({
      'hidden': true,
    });
    final messages =
        await _root.child('chats').child(chatId).child('messages').get();
    if (messages.value is! Map) return;
    final updates = <String, Object?>{};
    (messages.value! as Map).forEach((key, _) {
      updates['$key/delete/$myId'] = true;
    });
    if (updates.isNotEmpty) {
      await _root
          .child('chats')
          .child(chatId)
          .child('messages')
          .update(updates);
    }
  }

  Future<void> deleteAccount(ScreenTimeUser me) async {
    final updates = <String, Object?>{
      'users/${me.uid}': null,
      'phoneIndex/${digitsKey(me.phone)}': null,
      'userChats/${me.uid}': null,
    };
    for (final friendId in me.friends.keys) {
      updates['users/$friendId/friends/${me.uid}'] = null;
    }
    for (final id in me.sentRequests.keys) {
      updates['users/$id/receivedRequests/${me.uid}'] = null;
    }
    for (final id in me.receivedRequests.keys) {
      updates['users/$id/sentRequests/${me.uid}'] = null;
    }
    final chats = await _root.child('chats').get();
    if (chats.value is Map) {
      (chats.value! as Map).forEach((key, _) {
        if (key.toString().contains(me.uid)) {
          updates['chats/$key'] = null;
          final other = key.toString().split('_').firstWhere(
                (part) => part != me.uid,
                orElse: () => '',
              );
          if (other.isNotEmpty) {
            updates['userChats/$other/$key'] = null;
          }
        }
      });
    }
    await _root.update(updates);
  }
}
