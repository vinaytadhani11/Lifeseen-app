import 'package:flutter/material.dart';

/// Prevents the system back gesture/button from leaving the current route.
class BlockBackNavigation extends StatelessWidget {
  const BlockBackNavigation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, child: child);
  }
}
