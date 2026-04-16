import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_health/app.dart';

void main() {
  testWidgets('Mboa Health app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MboaHealthApp());
    expect(find.byType(MboaHealthApp), findsOneWidget);
  });
}
