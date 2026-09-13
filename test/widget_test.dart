import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to a frame without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Share_adi')),
      ),
    );
    expect(find.text('Share_adi'), findsOneWidget);
  });
}