import 'package:flutter_test/flutter_test.dart';

import 'package:family_finance_app/main.dart';

void main() {
  testWidgets('App inicia na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyFinanceApp());

    expect(find.text('Family Finance'), findsOneWidget);
  });
}