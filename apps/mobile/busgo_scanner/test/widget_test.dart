import 'package:flutter_test/flutter_test.dart';
import 'package:busgo_scanner/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BusgoScannerApp());
    expect(find.text('Start Session'), findsOneWidget);
    expect(find.text('Start Scanning Session'), findsOneWidget);
  });
}
