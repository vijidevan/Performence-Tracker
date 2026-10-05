import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Team Performance test environment loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const TestApp(),
    );

    expect(
      find.text('Team Performance'),
      findsOneWidget,
    );
  });
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Team Performance'),
        ),
      ),
    );
  }
}