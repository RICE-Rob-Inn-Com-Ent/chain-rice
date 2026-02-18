import 'package:flutter_test/flutter_test.dart';
import 'package:meowtopia_mobile/main.dart';

void main() {
  testWidgets('Meowtopia mobile app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MeoWTopiaMobileApp());
    expect(find.text('MeoWTopia Mobile App'), findsOneWidget);
  });
}

