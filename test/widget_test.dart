import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/main.dart';
import 'package:tomatelo/widgets/water_tracker_card.dart';

void main() {
  testWidgets('renders hydration setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TomateloApp(showSetupScreen: true));

    expect(find.text('Inicio'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Configuración de Hidratación'), findsOneWidget);
    expect(find.text('Iniciar hidratación'), findsOneWidget);
  });

  testWidgets('water tracker card adds and removes one glass', (
    WidgetTester tester,
  ) async {
    var glasses = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return WaterTrackerCard(
                currentGlasses: glasses,
                goalGlasses: 8,
                onAddWater: () => setState(() => glasses++),
                onRemoveWater: () => setState(() => glasses--),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('1 / 8'), findsOneWidget);

    await tester.tap(find.text('-1'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 8'), findsOneWidget);

    await tester.tap(find.text('-1'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 8'), findsOneWidget);

    await tester.tap(find.text('+1 💧'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 8'), findsOneWidget);
  });
}
