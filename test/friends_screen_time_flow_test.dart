import 'package:flutter_test/flutter_test.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';

void main() {
  test('phone lookup matches the Android friend states', () {
    const me = ScreenTimeUser(uid: 'a', phone: '+911', username: 'A');
    expect(classifyLookup(me, 'a'), 'ownProfile');
    expect(classifyLookup(null, 'a'), 'UserNotFound');

    const friend = ScreenTimeUser(
      uid: 'b',
      phone: '+912',
      username: 'B',
      friends: {'a': true},
    );
    expect(classifyLookup(friend, 'a'), 'alreadyFriends');

    const sent = ScreenTimeUser(
      uid: 'b',
      phone: '+912',
      username: 'B',
      receivedRequests: {'a': true},
    );
    expect(classifyLookup(sent, 'a'), 'requestSent');

    const received = ScreenTimeUser(
      uid: 'b',
      phone: '+912',
      username: 'B',
      sentRequests: {'a': true},
    );
    expect(classifyLookup(received, 'a'), 'requestReceived');

    const stranger = ScreenTimeUser(uid: 'b', phone: '+912', username: 'B');
    expect(classifyLookup(stranger, 'a'), 'notConnected');
  });

  test('day key is local midnight epoch seconds without a decimal', () {
    final day = DateTime(2026, 10, 29);
    final expected =
        (DateTime(2026, 10, 29).millisecondsSinceEpoch ~/ 1000).toString();
    expect(screenTimeDayKey(day), expected);
    expect(screenTimeDayKey(day).contains('.'), isFalse);
    expect(screenTimeDayKey(DateTime(2026, 10, 29, 18, 30)), expected);
  });

  test('stored screen time reads list and map shapes', () {
    final fromList = ScreenTimeDay.fromMap({
      'data': [
        {
          'name': 'zapptest',
          'package': 'com.app.logsense',
          'duration': [0, 56, 27],
        },
      ],
      'hourly': List<double>.filled(24, 0),
    });
    expect(fromList.apps.single.name, 'zapptest');
    expect(fromList.apps.single.minutes, 56);

    final fromMap = ScreenTimeDay.fromMap({
      'data': {
        '0': {
          'name': 'Logio',
          'duration': {'0': 0, '1': 20, '2': 27},
        },
      },
    });
    expect(fromMap.apps.single.name, 'Logio');
    expect(fromMap.apps.single.seconds, 27);
  });

  test('chat ids sort the two user ids', () {
    final ids = ['b', 'a']..sort();
    expect('${ids[0]}_${ids[1]}', 'a_b');
  });
}
