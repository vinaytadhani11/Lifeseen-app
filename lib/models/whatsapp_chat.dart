class WhatsAppChat {
  const WhatsAppChat({
    required this.id,
    required this.avatarAsset,
    required this.time,
    required this.isRead,
    this.obfuscatedName = '/**-_**_/?&^',
    this.obfuscatedPreview = r'~!@#$%^&*()_+{}|:<>?',
  });

  final int id;
  final String avatarAsset;
  final String time;
  final bool isRead;
  final String obfuscatedName;
  final String obfuscatedPreview;
}
