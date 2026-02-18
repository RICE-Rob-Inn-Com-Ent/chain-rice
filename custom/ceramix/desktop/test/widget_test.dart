import 'package:ceramix_desktop/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ceramix desktop app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CeramixDesktopApp());
    expect(find.text('Ceramix Desktop App'), findsOneWidget);
  });
}

