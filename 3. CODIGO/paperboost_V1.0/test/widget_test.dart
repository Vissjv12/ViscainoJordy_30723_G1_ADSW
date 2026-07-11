import 'package:flutter_test/flutter_test.dart';

import 'package:paperboost/app_dependencies.dart';
import 'package:paperboost/main.dart';

void main() {
  testWidgets('La pantalla de login se muestra correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PaperBoostApp(
        dependencies: AppDependencies(),
      ),
    );

    expect(find.text('PaperBoost'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
