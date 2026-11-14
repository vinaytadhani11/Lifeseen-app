// Basic splash screen smoke test.

import 'package:flutter_test/flutter_test.dart';
import 'package:tableflow_plus/main.dart';
import 'package:tableflow_plus/widgets/lifeseen_logo.dart';

void main() {
  testWidgets('Splash screen shows LifeSeen logo', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeSeenApp());

    expect(find.byType(LifeSeenLogo), findsOneWidget);
    expect(find.text('Lif'), findsOneWidget);
    expect(find.text('Seen'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}
