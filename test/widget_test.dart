import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/main.dart';

void main() {
  testWidgets('renders hydration setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TomateloApp(showSetupScreen: true));

    expect(find.text('Inicio'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('HidrataSet'), findsOneWidget);
    expect(find.text('Iniciar hidratación'), findsOneWidget);
  });
}
