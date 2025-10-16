import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('Home screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the home screen title is displayed.
    expect(find.text('Rice Dev Flutter App'), findsOneWidget);
    expect(find.text('Welcome to Rice Dev!'), findsOneWidget);
    expect(find.text('Features:'), findsOneWidget);
  });

  testWidgets('About button exists', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the about button exists.
    expect(find.text('About'), findsOneWidget);
  });
}
