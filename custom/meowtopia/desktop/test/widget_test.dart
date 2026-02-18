import 'package:flutter_test/flutter_test.dart';
import 'package:meowtopia_desktop/main.dart';

void main() {
  testWidgets('Meowtopia desktop app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MeoWTopiaDesktopApp());
    expect(find.text('MeoWTopia Desktop App'), findsOneWidget);
  });
}

