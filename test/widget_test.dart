// Basic smoke test: the app boots and shows the home screen title.
import 'package:flutter_test/flutter_test.dart';

import 'package:kalarm/main.dart';
import 'package:kalarm/widgets/k_alarm_logo.dart';

void main() {
  testWidgets('K-Alarm boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KAlarmApp());
    await tester.pumpAndSettle();

    expect(find.byType(KAlarmWordmark), findsWidgets);
  });
}
