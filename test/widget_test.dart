import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/main.dart';

void main() {
  testWidgets('renders hydration setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TomateloApp(showSetupScreen: true));

    expect(find.text('HidrataSet'), findsOneWidget);
    expect(find.text('Iniciar hidratación'), findsOneWidget);
  });
}
