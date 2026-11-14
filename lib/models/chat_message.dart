class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.isSentByMe,
  });

  final String text;
  final String time;
  final bool isSentByMe;
}
