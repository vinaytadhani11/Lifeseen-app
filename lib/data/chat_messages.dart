import 'package:tableflow_plus/models/chat_message.dart';

const _obfuscatedSnippets = [
  r'~!@#$%^&*()_+',
  r'/**-_**_/?&^',
  r'@#$%&*()_+{}|',
  r'<>?/.,;:[]\\',
  r'+=`-~!@#$%^&',
  r'(*&^%$#@!)',
  r'{}|:<>?~`',
  r'[]\\;,./',
  r'&*()_+-=~!',
  r'^%$#@!~`',
];

const _timeSlots = [
  '07:10',
  '07:22',
  '07:35',
  '07:48',
  '08:01',
  '08:14',
  '08:27',
  '08:40',
  '08:53',
  '09:06',
  '09:19',
  '09:32',
  '09:45',
  '09:58',
  '10:11',
  '10:24',
  '10:37',
  '10:50',
  '11:03',
  '11:16',
  '11:29',
  '11:42',
  '11:55',
  '12:08',
  '12:21',
  '12:34',
  '12:47',
  '13:00',
  '13:13',
  '13:26',
  '13:39',
  '13:52',
  '14:05',
  '14:18',
  '14:31',
  '14:44',
  '14:57',
  '15:10',
  '15:23',
  '15:36',
  '15:49',
  '16:02',
  '16:15',
  '16:28',
  '16:41',
  '16:54',
  '17:07',
  '17:20',
];

final Map<int, List<ChatMessage>> _chatMessagesCache = {};

/// Returns 50–60 obfuscated messages for the given [chatId] (0-based).
List<ChatMessage> getChatMessages(int chatId) {
  return _chatMessagesCache.putIfAbsent(chatId, () => _buildMessages(chatId));
}

List<ChatMessage> _buildMessages(int chatId) {
  final messageCount = 50 + (chatId % 11);
  final messages = <ChatMessage>[];

  for (var i = 0; i < messageCount; i++) {
    final snippet =
        _obfuscatedSnippets[(chatId + i) % _obfuscatedSnippets.length];
    final suffix =
        _obfuscatedSnippets[(chatId * 3 + i) % _obfuscatedSnippets.length];
    final time = _timeSlots[i % _timeSlots.length];

    messages.add(
      ChatMessage(text: '$snippet $suffix', time: time, isSentByMe: i.isEven),
    );
  }

  return messages;
}
