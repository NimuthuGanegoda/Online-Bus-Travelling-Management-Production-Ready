import 'package:flutter_test/flutter_test.dart';
import 'package:busgo_client/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BusGoApp());
    expect(find.text('BUSGO'), findsOneWidget);
  });
}
