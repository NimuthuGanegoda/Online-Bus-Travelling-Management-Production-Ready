import 'package:flutter_test/flutter_test.dart';
import 'package:busgo_drive/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BusGoDriveApp());
    await tester.pumpAndSettle();
    expect(find.text('BusGo Drive'), findsOneWidget);
  });
}
