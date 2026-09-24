import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/widgets/water_tracker_card.dart';

import 'package:tomatelo/screens/setup_screen.dart';

void main() {
  testWidgets('renders hydration setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SetupScreen(skipAutoRedirect: true),
      ),
    );

    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Guardar y Sincronizar'), findsOneWidget);
  });

  testWidgets('renders quick log pill card', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickLogPillCard(
            onAddWaterMl: (ml) {},
            onUndo: () {},
            weeklyData: const [0, 0, 0, 0, 0, 0, 0],
          ),
        ),
      ),
    );

    expect(find.text('Registro Rápido'), findsOneWidget);
    expect(find.text('+250 ml'), findsOneWidget);
  });
}
