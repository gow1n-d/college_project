import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:college_bus_attendance/app/theme.dart';

void main() {
  testWidgets('AppTheme light and dark themes initialize with Material 3', (WidgetTester tester) async {
    final lightTheme = AppTheme.light;
    final darkTheme = AppTheme.dark;

    expect(lightTheme.useMaterial3, isTrue);
    expect(darkTheme.useMaterial3, isTrue);
    expect(lightTheme.brightness, equals(Brightness.light));
    expect(darkTheme.brightness, equals(Brightness.dark));

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: const Scaffold(
          body: Center(child: Text('Theme Smoke Test')),
        ),
      ),
    );

    expect(find.text('Theme Smoke Test'), findsOneWidget);
  });
}
