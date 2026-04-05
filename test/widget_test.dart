import 'package:flutter_test/flutter_test.dart';

import 'package:connect_app/app.dart';

void main() {
  testWidgets('Connect app boots', (tester) async {
    await tester.pumpWidget(const ConnectApp());
    expect(find.byType(ConnectApp), findsOneWidget);
  });
}
