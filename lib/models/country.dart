class Country {
  const Country({
    required this.name,
    required this.isoCode,
    required this.dialCode,
  });

  final String name;
  final String isoCode;
  final String dialCode;

  String get flagEmoji {
    final code = isoCode.toUpperCase();
    return String.fromCharCodes(code.codeUnits.map((unit) => unit + 127397));
  }

  String get formattedDialCode => '+$dialCode';
}
