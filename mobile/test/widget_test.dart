import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DayPlanApp());

    // Verify that the app starts and shows Dashboard.
    // Since it's clean, we expect to see 'Dashboard' or similar title from screens.
    // We can just check that it pumps without error for now.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
