import 'package:ceramix_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ceramix mobile app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CeramixMobileApp());
    expect(find.text('Ceramix Mobile App'), findsOneWidget);
  });
}

