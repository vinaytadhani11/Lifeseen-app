import 'package:flutter/material.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';

enum IpLocationField { label, city, country }

class IpLocationText extends StatelessWidget {
  const IpLocationText({
    super.key,
    required this.style,
    this.field = IpLocationField.label,
    this.textAlign,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final TextStyle style;
  final IpLocationField field;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final store = AppBootstrap.ipLocation;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final text = switch (field) {
          IpLocationField.label => store.locationLabel,
          IpLocationField.city => store.city,
          IpLocationField.country => store.country,
        };
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
